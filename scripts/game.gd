extends Node2D
const PlayerScript=preload("res://actors/player.gd")
const EnemyScript=preload("res://actors/enemy.gd")
const DungeonScript=preload("res://world/dungeon.gd")
const EffectScript=preload("res://world/effects.gd")
const DropScript=preload("res://world/drop.gd")
const ProjectileScript=preload("res://actors/projectile.gd")
const OverlayScript=preload("res://world/combat_overlay.gd")
const UIScript=preload("res://ui/interface.gd")
const UPGRADE_POOL=[
 {"name":"TEMPERED EDGE","detail":"+15% attack speed. Let the third strike fall sooner.","icon":"sword","key":"haste","value":.15},
 {"name":"HEARTWOOD","detail":"+42 maximum life. Recover 30% life now.","icon":"armor","key":"hp","value":42.0},
 {"name":"EXECUTIONER","detail":"+8% critical chance and +20% critical damage.","icon":"crit","key":"crit","value":.08},
 {"name":"QUICKENING","detail":"+9% cooldown reduction. Every skill returns sooner.","icon":"dash","key":"cdr","value":.09},
 {"name":"COLD SUN","detail":"Soul Nova grows 45 pixels wider. +20% skill damage.","icon":"nova","key":"nova_radius","value":45.0},
 {"name":"FORKED PROMISE","detail":"Spirit Lance releases two additional piercing spears.","icon":"bolt","key":"spear_count","value":1.0},
 {"name":"SOUL TAKER","detail":"Restore 2 life on every kill. Advance to recover.","icon":"potion","key":"leech","value":2.0},
 {"name":"OATH OF STEEL","detail":"+9 Attack. Strengthens the sword and all three skills.","icon":"cleave","key":"attack","value":9.0},
 {"name":"WAYFARER","detail":"+10% movement speed and +10 armor.","icon":"dash","key":"speed","value":.1}]
const ROOM_ENEMY_POOLS={
 1:["hollow","hollow","hollow","cantor"],
 2:["hollow","hollow","hound","hound","cantor"],
 3:["hound","hound","hollow","cantor"],
 4:["hollow","hollow","warden","cantor"],
 5:["cantor","cantor","hollow","warden"],
 6:["hound","hound","hound","hollow","warden"],
 8:["hollow","cantor","hound","warden","hollow"]}
const ROOM_MODIFIER_TEXT={
 4:"FORGE VENTS / EMBERS ERUPT BENEATH YOU",
 5:"EMBER SCRIPT / SIGILS FORM IN LINES",
 6:"CINDER TRAIL / KEEP MOVING",
 8:"THORN PROCESSION / CROSS-SIGILS FOLLOW YOU"}
const ASCENSION_VOWS=[
 {"id":"ember_tide","name":"EMBER TIDE","detail":"Sanctuary hazards return 22% faster."},
 {"id":"thickened_veil","name":"THICKENED VEIL","detail":"Oathless Knights gain 28% life and 8% damage."},
 {"id":"hollow_choir","name":"HOLLOW CHOIR","detail":"Each non-boss wave gains one additional foe."}]
var mode="title"
var profile=ProfileStore.new()
var sound:Soundscape
var dungeon
var player
var fx
var overlay
var ui
var camera:Camera2D
var enemies=[]
var projectiles=[]
var drops=[]
var hazards=[]
var enemy_data={}
var rng=RandomNumberGenerator.new()
var run_seed=0
var elapsed=0.0
var kills=0
var ascension=0
var pending_upgrades=0
var upgrade_choices=[]
var wave=0
var wave_delay=0.0
var encounter_room=-1
var room_modifier_timer=0.0
var hitstop=0.0
var shake_amount=0.0
var banner_title=""
var banner_sub=""
var banner_time=0.0
var toast_text=""
var toast_time=0.0
var last_room=-1
var victory_pending=false
var test_mode=false
var metrics={}
func _ready()->void:
 configure_input();test_mode=OS.get_cmdline_user_args().has("--test")
 if test_mode:profile.path="user://ashen_vow_test.json"
 profile.read_save();enemy_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 sound=Soundscape.new();add_child(sound);sound.settings=profile.settings;sound.set_music("menu")
 var layer=CanvasLayer.new();layer.layer=10;add_child(layer)
 ui=UIScript.new();ui.game=self;layer.add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_tree().auto_accept_quit=false
 for flag in ["qa","campaign"]:
  if OS.get_cmdline_user_args().has("--"+flag):
   var harness=load("res://tests/"+flag+"_runner.gd").new();harness.game=self;add_child(harness)
func configure_input()->void:
 var keys={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"attack":[KEY_J],"dash":[KEY_SPACE,KEY_SHIFT],"skill_0":[KEY_Q,KEY_1],"skill_1":[KEY_E,KEY_2],"skill_2":[KEY_R,KEY_3],"heal":[KEY_F],"interact":[KEY_C],"inventory":[KEY_I,KEY_TAB],"pause":[KEY_ESCAPE],"map":[KEY_M]}
 for action in keys:
  if not InputMap.has_action(action):InputMap.add_action(action)
  for k in keys[action]:
   var ev=InputEventKey.new();ev.physical_keycode=k;InputMap.action_add_event(action,ev)
 for spec in [["attack",MOUSE_BUTTON_LEFT],["skill_0",MOUSE_BUTTON_RIGHT]]:
  var ev=InputEventMouseButton.new();ev.button_index=spec[1];InputMap.action_add_event(spec[0],ev)
 var pad={"attack":JOY_BUTTON_X,"dash":JOY_BUTTON_A,"skill_0":JOY_BUTTON_Y,"skill_1":JOY_BUTTON_LEFT_SHOULDER,"skill_2":JOY_BUTTON_RIGHT_SHOULDER,"heal":JOY_BUTTON_B,"inventory":JOY_BUTTON_BACK,"pause":JOY_BUTTON_START,"interact":JOY_BUTTON_DPAD_UP}
 for action in pad:
  var ev=InputEventJoypadButton.new();ev.button_index=pad[action];InputMap.action_add_event(action,ev)
 for spec in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0]]:
  var ev=InputEventJoypadMotion.new();ev.axis=spec[1];ev.axis_value=spec[2];InputMap.action_add_event(spec[0],ev)
func ascension_vow()->Dictionary:
 if ascension<=0:return {}
 return ASCENSION_VOWS[(ascension-1)%ASCENSION_VOWS.size()]
func has_ascension_vow(id:String)->bool:
 var vow=ascension_vow()
 return not vow.is_empty() and String(vow.id)==id
func room_modifier_interval(base:float)->float:return base*(.78 if has_ascension_vow("ember_tide") else 1.0)
func ascension_wave_bonus()->int:return 1 if has_ascension_vow("hollow_choir") else 0
func ascension_elite_hp_mult()->float:return 1.28 if has_ascension_vow("thickened_veil") else 1.0
func ascension_elite_damage_mult()->float:return 1.08 if has_ascension_vow("thickened_veil") else 1.0
func clear_world()->void:
 for child in get_children():
  if child is Node2D:remove_child(child);child.queue_free()
 enemies.clear();projectiles.clear();drops.clear();hazards.clear()
 pending_upgrades=0;victory_pending=false;wave=0;encounter_room=-1;room_modifier_timer=0;last_room=-1;hitstop=0;shake_amount=0;toast_time=0;banner_time=0
 metrics={"hits_taken":0,"damage_dealt":0.0,"kills":0,"drops":0,"pickups":0,"equips":0,"level_ups":0,"boss_patterns":0}
func start_run(resume:bool=false,ascend:bool=false)->void:
 if ascend and is_instance_valid(player) and player.inventory.size()>40:
  toast("Salvage to 40 items before descending again.");return
 var carry={}
 if ascend and is_instance_valid(player):carry={"equipment":player.equipment.duplicate(true),"inventory":player.inventory.duplicate(true),"level":player.level,"upgrades":player.upgrades.duplicate(true),"ascension":ascension+1}
 clear_world();rng.randomize();run_seed=20260920 if OS.get_cmdline_user_args().has("--campaign") else rng.randi();rng.seed=run_seed
 elapsed=0;kills=0;ascension=0
 dungeon=DungeonScript.new();add_child(dungeon);dungeon.setup(self)
 fx=EffectScript.new();fx.z_index=2000;add_child(fx)
 overlay=OverlayScript.new();overlay.game=self;overlay.z_index=100;add_child(overlay)
 player=PlayerScript.new();add_child(player);player.setup(self);player.position=Vector2(-240,0)
 camera=Camera2D.new();camera.position=player.position;add_child(camera);camera.make_current()
 if resume and profile.valid_run(profile.run):
  var s=profile.run;player.equipment=s.equipment.duplicate(true);player.inventory=s.inventory.duplicate(true)
  player.level=int(s.level);player.xp=int(s.xp);player.upgrades=s.upgrades.duplicate(true);player.potions=int(s.potions)
  player.rebuild_stats();player.hp=clampf(s.hp,1,player.stats.hp)
  dungeon.cleared=s.cleared.duplicate();dungeon.visited=s.get("visited",dungeon.cleared).duplicate()
  run_seed=int(s.seed);rng.seed=run_seed;ascension=int(s.ascension);kills=int(s.kills);elapsed=float(s.elapsed)
  var saved_metrics=s.get("metrics",{})
  if saved_metrics is Dictionary:
   for key in metrics:
    if saved_metrics.has(key) and (saved_metrics[key] is int or saved_metrics[key] is float):metrics[key]=saved_metrics[key]
  var pos=Vector2(s.position[0],s.position[1]);player.position=pos if dungeon.walkable(pos,18,false) else Vector2.ZERO
  var id=dungeon.room_at(player.position)
  if id<0 or id not in dungeon.cleared:player.position=dungeon.rooms[int(dungeon.cleared[-1])].center
  pending_upgrades=int(s.get("pending_upgrades",0))
  for record in s.get("drops",[]):
   var d=DropScript.new();add_child(d);d.setup(self,Vector2(record.position[0],record.position[1]),record.item.duplicate(true),record.kind);d.age=1;d.z_index=230;drops.append(d)
 elif not carry.is_empty():
  player.equipment=carry.equipment;player.inventory=carry.inventory;player.level=carry.level;player.upgrades=carry.upgrades;ascension=carry.ascension;player.rebuild_stats();player.hp=player.stats.hp
 else:profile.records.runs+=1
 camera.position=player.position;mode="play";sound.set_music("dungeon")
 if ascension>0:
  var vow=ascension_vow();banner("ASCENSION %02d / %s"%[ascension,vow.name],vow.detail)
 else:banner("ASHEN VOW","Descend into the cathedral. Leave with a different build.")
 if not resume:
  var gift=ItemDB.generate(rng,1,1);gift.slot="weapon";gift.name="Pilgrim's First Flame";gift.base={"attack":16.0}
  spawn_drop(Vector2(80,-25),gift);spawn_chest(Vector2(160,100),1,false)
 ui.selected=0;save_run()
func _process(dt:float)->void:
 banner_time=maxf(0,banner_time-dt);toast_time=maxf(0,toast_time-dt)
 if is_instance_valid(player):
  camera.position=camera.position.lerp(player.position+(player.facing*42 if mode=="play" else Vector2.ZERO),1-exp(-dt*7))
  shake_amount=move_toward(shake_amount,0,dt*25);var strength=shake_amount*profile.settings.shake
  camera.offset=Vector2(randf_range(-strength,strength),randf_range(-strength,strength));overlay.queue_redraw()
 ui.queue_redraw()
func _physics_process(dt:float)->void:
 if mode=="play":step(dt)
func step(dt:float)->void:
 if hitstop>0:hitstop-=dt;return
 elapsed+=dt;player.tick(dt)
 if mode!="play":return
 for e in enemies.duplicate():
  if is_instance_valid(e):e.tick(dt)
 for p in projectiles.duplicate():
  if is_instance_valid(p) and not p.dead:p.tick(dt)
 for d in drops.duplicate():
  if is_instance_valid(d) and not d.taken:d.tick(dt)
 tick_hazards(dt);tick_room_modifier(dt);fx.tick(dt)
 if mode!="play":return
 if Input.is_action_just_pressed("interact") and not test_mode:interact()
 check_rooms(dt)
 if pending_upgrades>0 and not victory_pending:prepare_upgrade()
 if victory_pending and enemies.is_empty():finish_run()
func check_rooms(dt:float)->void:
 var id=dungeon.room_at(player.position)
 if id>=0 and id!=last_room:
  last_room=id
  if id not in dungeon.visited:dungeon.visited.append(id)
  var room=dungeon.rooms[id];banner(room.name,room.lore)
  if id not in dungeon.cleared and dungeon.active<0:
   if room.waves==0:
    dungeon.cleared.append(id);player.heal(player.stats.hp);player.potions=3
    spawn_chest(room.center+Vector2(0,125),room.tier,true);toast("Life and flasks restored.");save_run()
   else:begin_encounter(id)
 if dungeon.active>=0:
  wave_delay-=dt
  if victory_pending:return
  if enemies.is_empty() and wave_delay<=0:
   if wave<dungeon.rooms[dungeon.active].waves:spawn_wave()
   else:clear_encounter()
func begin_encounter(id:int)->void:
 dungeon.active=id;encounter_room=id;wave=0;wave_delay=.9;room_modifier_timer=room_modifier_interval(4.5)
 if id in ROOM_MODIFIER_TEXT:toast(ROOM_MODIFIER_TEXT[id])
 if id==9:sound.set_music("boss_music");sound.play("boss")
func room_hazard_point(p:Vector2)->Vector2:
 var room=dungeon.rooms[dungeon.active];var r=room.rect.grow(-125.0)
 var q=Vector2(clampf(p.x,r.position.x,r.end.x),clampf(p.y,r.position.y,r.end.y))
 return q if dungeon.walkable(q,30) else player.position
func tick_room_modifier(dt:float)->void:
 if dungeon.active not in ROOM_MODIFIER_TEXT:return
 room_modifier_timer-=dt
 if room_modifier_timer>0:return
 var id=int(dungeon.active);var damage=(9.0+id*.7)*(1+ascension*.15)
 match id:
  4:
   room_modifier_timer=room_modifier_interval(8.6)
   var angle=rng.randf_range(0,TAU)
   add_hazard(room_hazard_point(player.position),68,.12,damage,false,1.05)
   add_hazard(room_hazard_point(player.position+Vector2.from_angle(angle)*145),62,.12,damage,false,1.35)
  5:
   room_modifier_timer=room_modifier_interval(9.5)
   var line=Vector2.from_angle(rng.randf_range(0,TAU))
   for i in range(-1,2):add_hazard(room_hazard_point(player.position+line*145*i),72,.12,damage,false,1.05+abs(i)*.18)
  6:
   room_modifier_timer=room_modifier_interval(7.8)
   var trail=player.last_move if player.last_move.length()>.1 else player.facing
   for i in range(3):add_hazard(room_hazard_point(player.position-trail*90*i),58,.12,damage,false,.9+i*.18)
  8:
   room_modifier_timer=room_modifier_interval(8.8)
   var offsets=[Vector2.ZERO,Vector2(145,0),Vector2(-145,0),Vector2(0,145),Vector2(0,-145)]
   for i in range(offsets.size()):add_hazard(room_hazard_point(player.position+offsets[i]),62,.12,damage,false,1.0+i*.08)
func encounter_pool(room_id:int,current_wave:int)->Array:
 var pool=ROOM_ENEMY_POOLS.get(room_id,["hollow","hollow","hollow","cantor"]).duplicate()
 if current_wave>=2:
  match room_id:
   1:pool.append("cantor")
   2,3:pool.append("hound")
   4:pool.append("warden")
   5:pool.append("cantor")
   6:pool.append_array(["hound","warden"])
   8:pool.append_array(["cantor","hound","warden"])
 return pool
func spawn_wave()->void:
 var room=dungeon.rooms[dungeon.active];wave+=1;wave_delay=3
 if room.id==9:spawn_enemy("boss",room.center+Vector2(200,0),7,9);return
 var pool=encounter_pool(room.id,wave)
 var enemy_total=room.count+wave*2+ascension_wave_bonus()
 for i in range(enemy_total):
  var kind=pool[rng.randi_range(0,pool.size()-1)]
  if i==0 and wave==room.waves and room.id in [3,4,6,8]:kind="elite"
  spawn_enemy(kind,dungeon.spawn_point(room.id,i),room.tier,room.id)
 if wave>1:toast("%s  /  WAVE %d OF %d"%[room.encounter,wave,room.waves])
func spawn_enemy(kind:String,p:Vector2,tier:int,room:int,affix:String=""):
 var e=EnemyScript.new();add_child(e);e.setup(self,kind,p,tier,room,affix);enemies.append(e);return e
func clear_encounter()->void:
 var id=dungeon.active
 if id<0:return
 var room=dungeon.rooms[id];dungeon.cleared.append(id);dungeon.active=-1
 for p in projectiles.duplicate():p.remove()
 hazards.clear();player.heal(player.stats.hp*.22);player.potions=mini(3,player.potions+1)
 spawn_chest(room.center+Vector2(0,125),room.tier,id in [3,4,6,8]);banner("SANCTUARY RECLAIMED","+1 flask. A reliquary opens. Compare your spoils before moving on.");save_run()
func nearest_enemy(p:Vector2,reach:float=1000):
 var nearest=null;var best=reach*reach
 for e in enemies:
  if e.dead or e.state=="spawn":continue
  var d=e.position.distance_squared_to(p)
  if d<best:best=d;nearest=e
 return nearest
func melee(p:Vector2,dir:Vector2,reach:float,half_angle:float,amount:float,knock:float)->void:
 var hit=false
 for e in enemies.duplicate():
  var delta=e.position-p
  if not e.dead and delta.length()<reach+e.radius*.3 and absf(dir.angle_to(delta))<half_angle and dungeon.line_clear(p,e.position):
   var crit=rng.randf()<player.stats.crit;e.take_damage(amount*(1+player.stats.crit_damage if crit else 1),delta.normalized()*knock,crit)
   if crit:critical_effect(e.position)
   hit=true
 if hit:hitstop=.035;shake(2.5);sound.play("hit",.7)
func area_damage(p:Vector2,radius:float,amount:float,proc:bool=true,allow_crit:bool=false)->void:
 for e in enemies.duplicate():
  if e.dead or e.position.distance_to(p)>radius or not dungeon.line_clear(p,e.position):continue
  var crit=allow_crit and rng.randf()<player.stats.crit
  e.take_damage(amount*(1+player.stats.crit_damage if crit else 1),(e.position-p).normalized()*160,crit,proc)
  if crit:critical_effect(e.position)
func critical_effect(p:Vector2)->void:
 sound.play("crit",.7);shake(4)
 if player.has_effect("crit_blast") and player.crit_blast_cd<=0:
  player.crit_blast_cd=.7;fx.ring(p,125,Color("eeaf7c"),.35);area_damage(p,125,player.stats.attack*.8,true,false)
func fire(p:Vector2,v:Vector2,amount:float,friendly:bool=false,pierce:int=0,color:Color=Color("e0a8d7")):
 var bolt=ProjectileScript.new();add_child(bolt);bolt.game=self;bolt.position=p;bolt.velocity=v;bolt.damage=amount;bolt.friendly=friendly;bolt.pierce=pierce;bolt.color=color
 bolt.radius=8 if friendly else 10;bolt.z_index=1500;projectiles.append(bolt);return bolt
func add_hazard(p:Vector2,radius:float,duration:float,amount:float,friendly:bool,delay:float)->void:
 hazards.append({"p":p,"radius":radius,"life":duration,"damage":amount,"friendly":friendly,"delay":delay,"max_delay":maxf(.01,delay),"tick":0.0})
func tick_hazards(dt:float)->void:
 for i in range(hazards.size()-1,-1,-1):
  var h=hazards[i]
  if h.delay>0:
   h.delay-=dt
   if h.delay<=0:fx.burst(h.p,Color("edaa80"),20,180);fx.ring(h.p,h.radius,Color("f2bc91"),.3)
   continue
  h.life-=dt;h.tick-=dt
  if h.tick<=0:
   h.tick=.33
   if h.friendly:area_damage(h.p,h.radius,h.damage*.33,true)
   elif h.p.distance_to(player.position)<h.radius:player.take_damage(h.damage)
  if h.life<=0:hazards.remove_at(i)
func enemy_died(e,proc:bool=false)->void:
 enemies.erase(e);kills+=1;metrics.kills+=1
 if enemies.is_empty() and dungeon.active>=0:wave_delay=2.3
 fx.burst(e.position,Color("caad86"),85 if e.kind=="boss" else 15,200);sound.play("enemy_death",.55);player.gain_xp(e.xp);player.heal(player.upgrades.get("leech",0))
 if player.has_effect("chain") and not proc:
  var count=0
  for other in enemies.duplicate():
   if other.dead or other.position.distance_to(e.position)>235:continue
   fx.lightning(e.position,other.position);other.take_damage(player.stats.attack*.9,Vector2.ZERO,false,true);count+=1
   if count>=3:break
 var tier=maxi(1,dungeon.rooms[e.room_id].tier+ascension*2)
 if e.kind=="boss":
  for i in range(4):
   var reward=ItemDB.generate(rng,tier,3,i);reward.boss_reward=true;spawn_drop(e.position+Vector2.from_angle(i*TAU/4)*70,reward)
  for other in enemies.duplicate():other.dead=true;enemies.erase(other);other.queue_free()
  victory_pending=true
 elif e.kind=="elite":
  spawn_drop(e.position,ItemDB.generate(rng,tier,3,{3:2,4:0,6:1,8:3}.get(e.room_id,0)))
  for i in range(2):spawn_drop(e.position+Vector2(i*42-20,40),ItemDB.generate(rng,tier,2))
 elif rng.randf()<.38:spawn_drop(e.position,ItemDB.generate(rng,tier))
 if rng.randf()<.2:
  var d=DropScript.new();add_child(d);d.setup(self,e.position+Vector2(25,15),{},"health");d.z_index=200;drops.append(d)
func spawn_drop(p:Vector2,item:Dictionary):
 var d=DropScript.new();add_child(d);d.setup(self,p,item);d.z_index=230;drops.append(d);metrics.drops+=1
 if item.rarity>=2:
  sound.play("legendary" if item.rarity==3 else "rare",.75);fx.ring(p,110 if item.rarity==3 else 60,ItemDB.COLORS[int(item.rarity)],1);fx.burst(p,ItemDB.COLORS[int(item.rarity)],38 if item.rarity==3 else 18,210)
  if item.rarity==3:toast("LEGENDARY  /  "+item.name)
 return d
func spawn_chest(p:Vector2,tier:int,gilded:bool)->void:
 var d=DropScript.new();add_child(d);d.setup(self,p,{"tier":tier,"gilded":gilded},"chest");d.z_index=230;drops.append(d)
func collect(d)->bool:
 if d.taken or d.kind!="item":return false
 if player.inventory.size()>=40:
  if toast_time<.3:toast("Pack full. [I] Compare and salvage unwanted items.")
  return false
 player.inventory.append(d.item.duplicate(true));metrics.pickups+=1;sound.play("loot",.65);toast("Recovered "+d.item.name+"  [I] compare");d.take();return true
func interact()->void:
 for d in drops.duplicate():
  if d.position.distance_to(player.position)>150 or d.taken:continue
  if d.kind=="chest":
   var at=d.position;var tier=int(d.item.tier);var gilded=d.item.gilded;d.take();sound.play("chest")
   for i in range(4 if gilded else 3):spawn_drop(at+Vector2.from_angle(i*1.7)*50,ItemDB.generate(rng,maxi(1,tier),2 if i==0 else -1))
  elif d.kind=="item":collect(d)
func salvage(i:int)->void:
 if i<0 or i>=player.inventory.size():return
 var rarity=int(player.inventory[i].rarity);player.inventory.remove_at(i);player.heal(player.stats.hp*(.025+rarity*.0125));sound.play("equip",.6)
 toast("Salvaged into embers. A little life returns.");ui.selected=clampi(ui.selected,0,maxi(0,player.inventory.size()-1));save_run()
func prepare_upgrade()->void:
 upgrade_choices.clear();var pool=UPGRADE_POOL.duplicate(true)
 for i in range(pool.size()-1,-1,-1):
  if pool[i].key=="spear_count" and player.upgrades.get("spear_count",0)>0:pool.remove_at(i)
  elif pool[i].key=="cdr" and player.stats.cdr>=.52:pool.remove_at(i)
 for i in range(3):upgrade_choices.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
 mode="upgrade"
func choose_upgrade(i:int)->void:
 if i<0 or i>=upgrade_choices.size():return
 var c=upgrade_choices[i];player.upgrades[c.key]=player.upgrades.get(c.key,0)+c.value
 for pair in [["crit","crit_damage",.2],["nova_radius","skill",.2],["speed","armor",10]]:
  if c.key==pair[0]:player.upgrades[pair[1]]=player.upgrades.get(pair[1],0)+pair[2]
 player.rebuild_stats();player.heal(player.stats.hp*.3);pending_upgrades=maxi(0,pending_upgrades-1);mode="play";sound.play("equip");toast("OATH TAKEN / "+c.name);save_run()
func toggle_inventory()->void:
 if mode=="play":mode="inventory";sound.play("ui")
 elif mode=="inventory":mode="play";save_run()
func banner(title:String,subtitle:String)->void:banner_title=title;banner_sub=subtitle;banner_time=4.5
func toast(message:String)->void:toast_text=message;toast_time=3.7
func shake(amount:float)->void:shake_amount=maxf(shake_amount,amount)
func player_died()->void:
 mode="dead";sound.play("death");profile.records.best_level=maxi(profile.records.best_level,player.level);profile.records.total_kills+=kills;profile.run={};profile.write_save();fx.burst(player.position,Color("dfb888"),55,230)
func finish_run()->void:
 victory_pending=false;mode="victory"
 if 9 not in dungeon.cleared:dungeon.cleared.append(9)
 dungeon.active=-1;profile.records.wins+=1;profile.records.best_level=maxi(profile.records.best_level,player.level);profile.records.total_kills+=kills
 for d in drops.duplicate():
  if d.kind=="item" and d.item.get("boss_reward",false):player.inventory.append(d.item.duplicate(true));metrics.pickups+=1;d.take()
 profile.run={};profile.write_save();sound.set_music("menu");sound.play("legendary")
func save_run()->void:
 if not is_instance_valid(player) or player.dead or mode in ["title","dead","victory","victory_inventory"]:return
 var pos=player.position;var id=dungeon.room_at(pos)
 if id<0 or id not in dungeon.cleared:pos=dungeon.rooms[int(dungeon.cleared[-1])].center
 var saved_drops=[]
 for d in drops:
  if not d.taken and d.kind!="health":saved_drops.append({"kind":d.kind,"item":d.item.duplicate(true),"position":[d.position.x,d.position.y]})
 profile.run={"drops":saved_drops,"level":player.level,"xp":player.xp,"hp":player.hp,"potions":player.potions,"equipment":player.equipment.duplicate(true),"inventory":player.inventory.duplicate(true),"upgrades":player.upgrades.duplicate(true),"cleared":dungeon.cleared.duplicate(),"visited":dungeon.visited.duplicate(),"seed":run_seed,"kills":kills,"elapsed":elapsed,"ascension":ascension,"position":[pos.x,pos.y],"pending_upgrades":pending_upgrades,"metrics":metrics.duplicate(true)}
 if not profile.write_save():toast("Could not write save. Check user data folder permissions.")
func return_to_title()->void:save_run();mode="title";sound.set_music("menu")
func _notification(what:int)->void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:shutdown()
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode=="play" and not test_mode:mode="pause"
func shutdown(code:int=0)->void:
 save_run();profile.write_save();mode="title"
 if is_instance_valid(sound):
  sound.dispose()
  sound.free()
  sound=null
  for i in range(3):await get_tree().process_frame
 await get_tree().create_timer(.25).timeout
 get_tree().quit(code)
func next_passage(id:int)->Dictionary:
 if id<0:return {}
 var target=-1
 for r in [1,2,4,5,6,7,8,9]:
  if r not in dungeon.cleared:target=r;break
 if target<0:return {}
 var queue=[[id]];var seen=[id]
 while not queue.is_empty():
  var path=queue.pop_front();var at=path[-1]
  if at==target and path.size()>1:
   var next=dungeon.rooms[path[1]];var d=next.center-dungeon.rooms[id].center
   return {"heading":("EAST" if d.x>0 else "WEST") if absf(d.x)>absf(d.y) else ("SOUTH" if d.y>0 else "NORTH"),"name":next.name}
  for edge in dungeon.connections:
   var n=edge[1] if edge[0]==at else (edge[0] if edge[1]==at else -1)
   if n>=0 and n not in seen:seen.append(n);var route=path.duplicate();route.append(n);queue.append(route)
 return {}
