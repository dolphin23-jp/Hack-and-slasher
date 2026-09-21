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
 {"name":"鍛えた刃","detail":"+15% 攻撃速度。3段目まで素早くつなげる。","icon":"sword","key":"haste","value":.15},
 {"name":"生命の木","detail":"+42 最大生命。即座に生命を30%回復。","icon":"armor","key":"hp","value":42.0},
 {"name":"処刑人","detail":"+8% クリティカル率、+20% クリティカル威力。","icon":"crit","key":"crit","value":.08},
 {"name":"加速","detail":"+9% クールダウン短縮。全スキルを早く再使用できる。","icon":"dash","key":"cdr","value":.09},
 {"name":"冷たい太陽","detail":"ソウルノヴァの範囲 +45。スキル威力 +20%。","icon":"nova","key":"nova_radius","value":45.0},
 {"name":"分かれた誓い","detail":"スピリットランスが追加で2本の貫通弾を放つ。","icon":"bolt","key":"spear_count","value":1.0},
 {"name":"魂狩り","detail":"敵を倒すたび生命を2回復。","icon":"potion","key":"leech","value":2.0},
 {"name":"鋼の誓い","detail":"+9 攻撃力。剣と3つの攻撃スキルを強化。","icon":"cleave","key":"attack","value":9.0},
 {"name":"旅人","detail":"+10% 移動速度、+10 防御力。","icon":"dash","key":"speed","value":.1}]
const ROOM_ENEMY_POOLS={
 1:["hollow","hollow","hollow","cantor"],
 2:["hollow","hollow","hound","hound","cantor"],
 3:["hound","hound","hollow","cantor"],
 4:["hollow","hollow","warden","cantor"],
 5:["cantor","cantor","hollow","warden"],
 6:["hound","hound","hound","hollow","warden"],
 8:["hollow","cantor","hound","warden","hollow"]}
const ROOM_MODIFIER_TEXT={
 4:"工房の噴出口 / 足元から炎が噴き出す",
 5:"炎の刻印 / 直線状に危険地帯が出現",
 6:"火の軌跡 / 立ち止まるな",
 8:"いばらの行進 / 十字の危険地帯が追ってくる"}
const ENCOUNTER_PATTERN_TEXT={
 "lane":"縦列進軍 / 奥へ重なった敵を貫け",
 "surround":"円形包囲 / 周囲をまとめて崩せ",
 "shield_line":"盾陣と後衛 / 前衛を崩して射線を開け",
 "arcane_court":"遠隔散開 / 距離のある詠唱者を連続で捉えろ",
 "rush_cross":"交差突撃 / 直線突進を避けて群れを束ねろ",
 "combined":"混成陣 / 盾・突撃・後衛を三連で処理しろ"}
const ASCENSION_VOWS=[
 {"id":"ember_tide","name":"炎の波","detail":"聖域のギミック発生間隔が22%短くなる。"},
 {"id":"thickened_veil","name":"厚い帳","detail":"誓いなき騎士の生命 +28%、攻撃 +8%。"},
 {"id":"hollow_choir","name":"虚ろな合唱","detail":"ボス以外の各ウェーブに敵が1体追加される。"}]
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
var delayed_blasts=[]
var event_choices={}
var event_room=-1
var loot_favor=0.0
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
 if test_mode:
  profile.path="user://ashen_vow_test.json"
  for suite in ["qa","expansion","campaign","southern"]:
   if OS.get_cmdline_user_args().has("--"+suite):profile.path="user://ashen_vow_test_"+suite+".json"
 profile.read_save();enemy_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 sound=Soundscape.new();add_child(sound);sound.settings=profile.settings;sound.set_music("menu")
 var layer=CanvasLayer.new();layer.layer=10;add_child(layer)
 ui=UIScript.new();ui.game=self;layer.add_child(ui);ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_tree().auto_accept_quit=false
 for flag in ["qa","campaign","expansion"]:
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
 enemies.clear();projectiles.clear();drops.clear();hazards.clear();delayed_blasts.clear();event_choices.clear();event_room=-1;loot_favor=0
 pending_upgrades=0;victory_pending=false;wave=0;encounter_room=-1;room_modifier_timer=0;last_room=-1;hitstop=0;shake_amount=0;toast_time=0;banner_time=0
 metrics=ProfileStore.empty_run_metrics()
func start_run(resume:bool=false,ascend:bool=false)->void:
 if ascend and is_instance_valid(player) and player.inventory.size()>40:
  toast("所持品を40個以下に分解してから次へ進んでください。");return
 var carry={}
 if ascend and is_instance_valid(player):carry={"materials":player.materials,"active_oaths":player.active_oaths.duplicate(),"equipment":player.equipment.duplicate(true),"inventory":player.inventory.duplicate(true),"level":player.level,"upgrades":player.upgrades.duplicate(true),"ascension":ascension+1}
 clear_world();rng.randomize();run_seed=20260920 if OS.get_cmdline_user_args().has("--campaign") else rng.randi();rng.seed=run_seed
 elapsed=0;kills=0;ascension=0
 if resume and profile.valid_run(profile.run):run_seed=int(profile.run.seed)
 rng.seed=run_seed
 dungeon=DungeonScript.new();dungeon.layout_version=int(profile.run.get("world_version",1)) if resume and profile.valid_run(profile.run) else 2;add_child(dungeon);dungeon.setup(self)
 fx=EffectScript.new();fx.z_index=2000;add_child(fx)
 overlay=OverlayScript.new();overlay.game=self;overlay.z_index=100;add_child(overlay)
 player=PlayerScript.new();add_child(player);player.setup(self);player.position=Vector2(-240,0)
 camera=Camera2D.new();camera.position=player.position;add_child(camera);camera.make_current()
 if resume and profile.valid_run(profile.run):
  var s=profile.run;player.materials=int(s.get("materials",0));player.active_oaths=OathBoard.sanitize({"active":s.get("active_oaths",profile.oaths.active)}).active;player.combo=clampi(int(s.get("combo",0)),0,3);player.equipment=s.equipment.duplicate(true);player.inventory=s.inventory.duplicate(true)
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
   var d=DropScript.new();add_child(d);d.setup(self,Vector2(record.position[0],record.position[1]),record.item.duplicate(true),record.kind);d.age=1;d.z_index=1400;drops.append(d)
 elif not carry.is_empty():
  player.materials=carry.materials;player.active_oaths=carry.active_oaths;player.equipment=carry.equipment;player.inventory=carry.inventory;player.level=carry.level;player.upgrades=carry.upgrades;ascension=carry.ascension;player.rebuild_stats();player.hp=player.stats.hp
 else:
  profile.records.runs+=1
  match profile.chronicle.start:
   "lance":
    if "first_clear" in profile.chronicle.achievements:player.upgrades.lance_fan=1;player.upgrades.haste=-.1
   "ember":
    if "collector" in profile.chronicle.achievements:player.upgrades.ember_start=1;player.upgrades.hp=-15
  player.rebuild_stats();player.hp=player.stats.hp
 if resume and profile.valid_run(profile.run):
  event_choices=profile.run.get("event_choices",{}).duplicate(true);loot_favor=float(profile.run.get("loot_favor",0))
 for item in player.inventory:record_item(item)
 for slot in ItemDB.SLOTS:record_item(player.equipment[slot])
 camera.position=player.position
 if resume and profile.valid_run(profile.run) and bool(profile.run.get("victory_ready",false)):
  mode="victory";dungeon.active=-1;victory_pending=false;sound.set_music("victory_music");ui.selected=0;return
 mode="play";sound.set_music("dungeon")
 if ascension>0:
  var vow=ascension_vow();banner("アセンション %02d / %s"%[ascension,vow.name],vow.detail)
 else:banner("ASHEN VOW","大聖堂へ降り、毎回違うビルドを作り上げよう。")
 if not resume:
  var gift=ItemDB.generate(rng,1,1);gift.slot="weapon";gift.name="巡礼者の最初の火";gift.base={"attack":16.0}
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
 tick_hazards(dt);tick_delayed_blasts(dt);tick_room_modifier(dt);fx.tick(dt)
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
    spawn_chest(room.center+Vector2(0,125),room.tier,true);toast("生命と回復薬を補充しました。");save_run()
   elif room.get("optional",false) and not event_choices.has(str(id)):
    event_room=id;mode="event";ui.reset_touch()
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
 if id==9:
  sound.set_music("boss_music");sound.play("boss");toast("王の攻撃を見極めろ / 青緑の輪は反撃の機会")
 elif id in [3,4,6,8,10,11]:sound.set_music("elite_music")
 else:sound.set_music("dungeon")
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
 var pool=ROOM_ENEMY_POOLS.get(room_id,["hollow","hound","warden","summoner"]).duplicate()
 if room_id in [4,5,6,8,10,11]:pool.append("summoner")
 var variant=int(dungeon.rooms[room_id].get("variant",0))
 if variant==1:pool.append_array(["hound","cantor"])
 elif variant==2:pool.append_array(["warden","summoner"])
 if current_wave>=2:
  match room_id:
   1:pool.append("cantor")
   2,3:pool.append("hound")
   4:pool.append("warden")
   5:pool.append("cantor")
   6:pool.append_array(["hound","warden"])
   8:pool.append_array(["cantor","hound","warden"])
 return pool
func encounter_pattern(room_id:int,current_wave:int)->String:
 match room_id:
  1:return "lane" if current_wave%2==1 else "surround"
  2,3:return "surround" if current_wave%2==1 else "lane"
  4:return "shield_line"
  5:return "arcane_court"
  6:return "rush_cross"
  8:return "combined"
  10:return "surround"
  11:return "shield_line"
 return ""
func formation_point(room:Dictionary,offset:Vector2,index:int)->Vector2:
 var p=room.center+offset
 if dungeon.walkable(p,35) and p.distance_to(player.position)>170:return p
 return dungeon.spawn_point(room.id,index)
func encounter_plan(room:Dictionary,current_wave:int,total:int)->Array:
 var pattern=encounter_pattern(int(room.id),current_wave);var plan=[];var center=room.center
 var inward=(center-player.position).normalized()
 if inward.length()<.1:inward=Vector2.RIGHT
 var side=inward.orthogonal()
 match pattern:
  "lane":
   var kinds=["hollow","hound","hollow","cantor","hound","hollow"]
   for i in range(mini(total,6)):
    var depth=-220+i*92
    plan.append({"kind":kinds[i%kinds.size()],"p":formation_point(room,inward*depth+side*((i%2)*28-14),i)})
  "surround":
   var kinds=["hollow","hound","hollow","hound","cantor","hollow","hound","cantor"]
   for i in range(mini(total,8)):
    var radius=175+(i%2)*55;var a=i*TAU/maxi(1,mini(total,8))+.22*current_wave
    plan.append({"kind":kinds[i%kinds.size()],"p":formation_point(room,Vector2.from_angle(a)*radius,i)})
  "shield_line":
   var front_count=mini(3,total)
   for i in range(front_count):
    plan.append({"kind":"warden","p":formation_point(room,inward*-65+side*((i-(front_count-1)/2.0)*120),i)})
   var back_kinds=["cantor","summoner","cantor"]
   for i in range(front_count,total):
    var j=i-front_count
    plan.append({"kind":back_kinds[j%back_kinds.size()],"p":formation_point(room,inward*185+side*((j%3)-1)*170,i)})
  "arcane_court":
   var offsets=[Vector2(-260,-190),Vector2(260,-190),Vector2(-260,190),Vector2(260,190),Vector2(0,-250),Vector2(0,250)]
   for i in range(mini(total,offsets.size())):
    plan.append({"kind":"summoner" if i==0 and current_wave>1 else "cantor","p":formation_point(room,offsets[i],i)})
  "rush_cross":
   var offsets=[Vector2(-250,0),Vector2(250,0),Vector2(0,-230),Vector2(0,230),Vector2(-170,-170),Vector2(170,170)]
   for i in range(mini(total,offsets.size())):
    plan.append({"kind":"hound" if i<4 else "hollow","p":formation_point(room,offsets[i],i)})
  "combined":
   var specs=[
    ["warden",inward*-90+side*-105],["warden",inward*-90+side*105],
    ["summoner",inward*220],["cantor",inward*170+side*230],
    ["hound",side*-270],["hound",side*270]]
   for i in range(mini(total,specs.size())):
    plan.append({"kind":specs[i][0],"p":formation_point(room,specs[i][1],i)})
 return plan
func spawn_wave()->void:
 var room=dungeon.rooms[dungeon.active];wave+=1;wave_delay=3
 if room.id==9:spawn_enemy("boss",room.center+Vector2(200,0),7,9);return
 var pool=encounter_pool(room.id,wave)
 var enemy_total=room.count+wave*2+ascension_wave_bonus()
 var pattern=encounter_pattern(room.id,wave);var plan=encounter_plan(room,wave,enemy_total)
 for i in range(enemy_total):
  var kind=String(plan[i].kind) if i<plan.size() else String(pool[rng.randi_range(0,pool.size()-1)])
  var spawn_at=plan[i].p if i<plan.size() else dungeon.spawn_point(room.id,i)
  if i==0 and wave==room.waves and room.id in [3,4,6,8]:kind="elite"
  spawn_enemy(kind,spawn_at,room.tier,room.id)
 if not pattern.is_empty():toast(ENCOUNTER_PATTERN_TEXT[pattern]+"  /  %d-%d"%[wave,room.waves])
 elif wave>1:toast("%s  /  ウェーブ %d / %d"%[room.encounter,wave,room.waves])
func spawn_enemy(kind:String,p:Vector2,tier:int,room:int,affix:String=""):
 var e=EnemyScript.new();add_child(e);e.setup(self,kind,p,tier,room,affix);enemies.append(e);return e
func clear_encounter()->void:
 var id=dungeon.active
 if id<0:return
 var room=dungeon.rooms[id];dungeon.cleared.append(id);dungeon.active=-1
 for p in projectiles.duplicate():p.remove()
 hazards.clear();player.heal(player.stats.hp*.22);player.potions=mini(3,player.potions+1)
 if room.get("optional",false):resolve_contract(id)
 sound.set_music("dungeon")
 spawn_chest(room.center+Vector2(0,125),room.tier,id in [3,4,6,8,10,11]);banner("聖域を解放","回復薬 +1。宝箱が開きました。次へ進む前に戦利品を確認できます。");save_run()
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
  if not e.dead and e.state not in ["spawn","transform"] and delta.length()<reach+e.radius*.3 and absf(dir.angle_to(delta))<half_angle and dungeon.line_clear(p,e.position):
   var crit=rng.randf()<player.stats.crit
   var extra=player.stats.attack if knock>=300 and player.has_effect("execution") and e.hp/e.max_hp<.3 else 0.0
   e.take_damage((amount+extra)*(1+player.stats.crit_damage if crit else 1),delta.normalized()*knock,crit)
   if player.has_effect("ash_edge") and not e.dead:e.ignite(player.stats.attack*.35,2.5)
   if crit:critical_effect(e.position)
   hit=true
 if hit:
  if profile.settings.get("hitstop",true):hitstop=.07 if knock>=300 else (.028 if player.combo==1 else .04)
  shake(5 if knock>=300 else 2);sound.play("hit",.9 if knock>=300 else .65,.75 if knock>=300 else 1.1)
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
func queue_blast(p:Vector2,radius:float,amount:float,delay:float,color:Color)->void:
 if delayed_blasts.size()>=64:return
 delayed_blasts.append({"p":p,"radius":radius,"damage":amount,"delay":delay,"color":color})
 fx.ring(p,radius,color,delay)
func tick_delayed_blasts(dt:float)->void:
 for i in range(delayed_blasts.size()-1,-1,-1):
  var b=delayed_blasts[i];b.delay-=dt
  if b.delay<=0:
   delayed_blasts.remove_at(i);area_damage(b.p,b.radius,b.damage,true);fx.ring(b.p,b.radius,b.color,.35)
func chain_lightning(p:Vector2,amount:float,source=null,limit:int=3)->void:
 var count=0
 if player.synergy("storm"):limit+=2
 if player.has_effect("wide_lightning"):limit+=2
 if player.has_effect("storm_cap"):limit+=1;amount*=1.10
 if player.has_effect("high_voltage"):amount*=1.25
 for e in enemies.duplicate():
  if e==source or e.dead or e.position.distance_to(p)>270 or not dungeon.line_clear(p,e.position):continue
  fx.lightning(p,e.position);e.take_damage(amount,Vector2.ZERO,false,true);count+=1
  if count>=limit:break
func fire(p:Vector2,v:Vector2,amount:float,friendly:bool=false,pierce:int=0,color:Color=Color("e0a8d7")):
 if projectiles.size()>=192:projectiles[0].remove()
 var bolt=ProjectileScript.new();add_child(bolt);bolt.game=self;bolt.position=p;bolt.velocity=v;bolt.damage=amount;bolt.friendly=friendly;bolt.pierce=pierce;bolt.color=color
 bolt.radius=8 if friendly else 10;bolt.z_index=1500;projectiles.append(bolt);return bolt
func add_hazard(p:Vector2,radius:float,duration:float,amount:float,friendly:bool,delay:float)->void:
 if friendly:
  for h in hazards:
   if h.friendly and h.p.distance_to(p)<radius*.85:
    h.life=maxf(h.life,duration);h.damage=maxf(h.damage,amount);return
 if hazards.size()>=96:return
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
   if h.friendly:
    area_damage(h.p,h.radius,h.damage*.33,true)
    for e in enemies:
     if e.position.distance_to(h.p)<h.radius:e.ignite(h.damage*.2,.6)
   elif h.p.distance_to(player.position)<h.radius:player.take_damage(h.damage)
  if h.life<=0:hazards.remove_at(i)
func roll_material_yield(find_bonus:float)->int:
 var bonus=clampf(find_bonus,0,2)
 var whole=floori(bonus);var fraction=bonus-whole
 return 1+whole+(1 if fraction>0 and rng.randf()<fraction else 0)
func enemy_died(e,proc:bool=false)->void:
 enemies.erase(e);kills+=1;metrics.kills+=1
 profile.chronicle.enemies[e.kind]=int(profile.chronicle.enemies.get(e.kind,0))+1
 if e.burn_time>0 and player.upgrades.get("ember_harvest",0)>0:player.heal(4)
 check_achievements()
 if enemies.is_empty() and dungeon.active>=0:wave_delay=2.3
 fx.burst(e.position,Color("caad86"),85 if e.kind=="boss" else 15,200);sound.play("enemy_death",.55);player.gain_xp(e.xp if not e.spawned_minion else 0);player.heal(player.upgrades.get("leech",0))
 if player.has_effect("chain") and not proc:chain_lightning(e.position,player.stats.attack*.9,e)
 if e.spawned_minion:return
 player.materials+=roll_material_yield(player.stats.material_find)
 if e.kind in ["elite","boss"]:profile.oaths.points+=3 if e.kind=="boss" else 1
 var tier=maxi(1,dungeon.rooms[e.room_id].tier+ascension*2)
 if e.kind=="boss":
  for i in range(4):
   var reward=ItemDB.generate(rng,tier,3,(i+ascension*4+int(run_seed%4)*4)%ItemDB.LEGENDS.size());reward.boss_reward=true;spawn_drop(e.position+Vector2.from_angle(i*TAU/4)*70,reward)
  for other in enemies.duplicate():other.dead=true;enemies.erase(other);other.queue_free()
  victory_pending=true
 elif e.kind=="elite":
  spawn_drop(e.position,ItemDB.generate(rng,tier,3,-1))
  for i in range(2):spawn_drop(e.position+Vector2(i*42-20,40),ItemDB.generate(rng,tier,2))
 elif rng.randf()<minf(.9,(.38+loot_favor)*(1+clampf(player.stats.drop_rate,0,2))):spawn_drop(e.position,roll_loot(tier))
 if rng.randf()<.2:
  var d=DropScript.new();add_child(d);d.setup(self,e.position+Vector2(25,15),{},"health");d.z_index=200;drops.append(d)
func spawn_drop(p:Vector2,item:Dictionary):
 var d=DropScript.new();add_child(d);d.setup(self,p,item);d.z_index=1400;drops.append(d);metrics.drops+=1
 if item.rarity>=2:
  sound.play("mythic" if item.rarity==4 else ("legendary" if item.rarity==3 else "rare"),.75);fx.ring(p,110 if item.rarity>=3 else 60,ItemDB.COLORS[int(item.rarity)],1);fx.burst(p,ItemDB.COLORS[int(item.rarity)],38 if item.rarity>=3 else 18,210)
  if item.rarity>=3:toast(("ミシック  /  " if item.rarity==4 else "レジェンダリー  /  ")+item.name)
 return d
func spawn_chest(p:Vector2,tier:int,gilded:bool)->void:
 var d=DropScript.new();add_child(d);d.setup(self,p,{"tier":tier,"gilded":gilded},"chest");d.z_index=1400;drops.append(d)
func collect(d)->bool:
 if d.taken or d.kind!="item":return false
 if player.inventory.size()>=40:
  if toast_time<.3:toast("所持品が満杯です。[I] 不要な装備を比較・分解してください。")
  return false
 player.inventory.append(d.item.duplicate(true));record_item(d.item);metrics.pickups+=1;sound.play("loot",.65);toast("回収: "+d.item.name+"  [I] 比較");d.take();return true
func interact()->void:
 for d in drops.duplicate():
  if d.position.distance_to(player.position)>150 or d.taken:continue
  if d.kind=="chest":
   var at=d.position;var tier=int(d.item.tier);var gilded=d.item.gilded;d.take();sound.play("chest")
   for i in range(4 if gilded else 3):spawn_drop(at+Vector2.from_angle(i*1.7)*50,roll_loot(maxi(1,tier),2 if i==0 else -1))
  elif d.kind=="item":collect(d)
func inventory_before(a:Dictionary,b:Dictionary)->bool:
 var ar:int=int(a.rarity);var br:int=int(b.rarity)
 if ar!=br:return ar>br
 var at:int=int(a.tier);var bt:int=int(b.tier)
 if at!=bt:return at>bt
 var aslot:int=ItemDB.SLOTS.find(String(a.slot));var bslot:int=ItemDB.SLOTS.find(String(b.slot))
 if aslot!=bslot:return aslot<bslot
 return String(a.name).naturalnocasecmp_to(String(b.name))<0
func sort_inventory()->void:
 if not is_instance_valid(player) or player.inventory.size()<2:return
 player.inventory.sort_custom(Callable(self,"inventory_before"));sound.play("ui",.5);save_run()
func salvage(i:int)->void:
 if i<0 or i>=player.inventory.size():return
 if Forge.protected(player.inventory[i]):toast("保護中の装備です");return
 player.materials+=Forge.yield_for(player.inventory[i],player.stats)
 var rarity=int(player.inventory[i].rarity);player.inventory.remove_at(i);player.heal(player.stats.hp*(.025+rarity*.0125));sound.play("equip",.6)
 toast("分解素材を獲得し、少し生命を回復しました。");ui.selected=clampi(ui.selected,0,maxi(0,player.inventory.size()-1));save_run()
func prepare_upgrade()->void:
 upgrade_choices.clear();var pool=UPGRADE_POOL.duplicate(true)
 pool=pool.filter(func(c):return c.key!="spear_count")
 var chain_pool=BuildDB.chain_choices(player.equipment,player.upgrades)
 if not chain_pool.is_empty():upgrade_choices.append(chain_pool.pop_at(rng.randi_range(0,chain_pool.size()-1)))
 pool.append_array(chain_pool)
 var branches=BuildDB.available(player.upgrades,profile.chronicle.achievements)
 pool.append_array(branches)
 for i in range(pool.size()-1,-1,-1):
  if pool[i].key=="spear_count" and player.upgrades.get("spear_count",0)>0:pool.remove_at(i)
  elif pool[i].key=="cdr" and player.stats.cdr>=.52:pool.remove_at(i)
  elif player.upgrades.get(pool[i].key,0)>=pool[i].get("max",99):pool.remove_at(i)
 while upgrade_choices.size()<3 and not pool.is_empty():upgrade_choices.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
 mode="upgrade";ui.reset_touch()
func choose_upgrade(i:int)->void:
 if mode!="upgrade" or i<0 or i>=upgrade_choices.size():return
 var c=upgrade_choices[i]
 if c.get("family","")=="lance" and not BuildDB.lance_key(player.upgrades).is_empty():return
 player.upgrades[c.key]=player.upgrades.get(c.key,0)+c.value
 for pair in [["crit","crit_damage",.2],["nova_radius","skill",.2],["speed","armor",10]]:
  if c.key==pair[0]:player.upgrades[pair[1]]=player.upgrades.get(pair[1],0)+pair[2]
 player.rebuild_stats();player.heal(player.stats.hp*.3);pending_upgrades=maxi(0,pending_upgrades-1);mode="play";sound.play("equip");toast("誓いを選択 / "+c.name);save_run()
func toggle_inventory()->void:
 if mode=="play":mode="inventory";sound.play("ui")
 elif mode=="inventory":mode="play";save_run()
func banner(title:String,subtitle:String)->void:banner_title=title;banner_sub=subtitle;banner_time=4.5
func toast(message:String)->void:toast_text=message;toast_time=3.7
func shake(amount:float)->void:shake_amount=maxf(shake_amount,amount)
func player_died()->void:
 mode="dead";sound.play("death");profile.records.best_level=maxi(profile.records.best_level,player.level);profile.records.best_ascension=maxi(profile.records.best_ascension,ascension);profile.records.total_kills+=kills;profile.run={};profile.write_save();fx.burst(player.position,Color("dfb888"),55,230)
func run_snapshot(victory_ready:bool=false)->Dictionary:
 var pos=player.position;var id=dungeon.room_at(pos)
 if victory_ready:pos=dungeon.rooms[9].center
 elif id<0 or id not in dungeon.cleared:pos=dungeon.rooms[int(dungeon.cleared[-1])].center
 var saved_drops=[]
 if not victory_ready:
  for d in drops:
   if not d.taken and d.kind!="health":saved_drops.append({"kind":d.kind,"item":d.item.duplicate(true),"position":[d.position.x,d.position.y]})
 return {"materials":player.materials,"active_oaths":player.active_oaths.duplicate(),"combo":player.combo,"drops":saved_drops,"level":player.level,"xp":player.xp,"hp":player.hp,"potions":player.potions,"equipment":player.equipment.duplicate(true),"inventory":player.inventory.duplicate(true),"upgrades":player.upgrades.duplicate(true),"cleared":dungeon.cleared.duplicate(),"visited":dungeon.visited.duplicate(),"seed":run_seed,"kills":kills,"elapsed":elapsed,"ascension":ascension,"position":[pos.x,pos.y],"pending_upgrades":pending_upgrades,"victory_ready":victory_ready,"metrics":metrics.duplicate(true),"world_version":dungeon.layout_version,"event_choices":event_choices.duplicate(true),"loot_favor":loot_favor}
func finish_run()->void:
 victory_pending=false;mode="victory"
 if 9 not in dungeon.cleared:dungeon.cleared.append(9)
 dungeon.active=-1;profile.records.wins+=1;check_achievements();profile.records.best_level=maxi(profile.records.best_level,player.level);profile.records.best_ascension=maxi(profile.records.best_ascension,ascension);profile.records.total_kills+=kills
 for d in drops.duplicate():
  if d.kind=="item" and d.item.get("boss_reward",false):player.inventory.append(d.item.duplicate(true));record_item(d.item);metrics.pickups+=1;d.take()
 _persist_run_checkpoint(true);sound.set_music("victory_music");sound.play("legendary")
func _persist_run_checkpoint(victory_ready:bool)->bool:
 profile.records.best_ascension=maxi(profile.records.best_ascension,ascension)
 profile.run=run_snapshot(victory_ready)
 var ok=profile.write_save()
 if not ok:toast("セーブできませんでした。保存先の権限を確認してください。")
 return ok
func save_run()->void:
 if not is_instance_valid(player) or player.dead or mode in ["title","dead"]:return
 _persist_run_checkpoint(mode in ["victory","victory_inventory"])
func return_to_title()->void:save_run();mode="title";sound.set_music("menu")
func _notification(what:int)->void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:shutdown()
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not test_mode:
  if is_instance_valid(ui):ui.reset_touch()
  if mode=="play":mode="pause";save_run()
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
 var required=[1,2,4,5,6,7,8,9]
 if 11 in dungeon.cleared:required=[7,8,9]
 elif id==10:required=[11,7,8,9]
 for r in required:
  if r not in dungeon.cleared:target=r;break
 if target<0:return {}
 var queue=[[id]];var seen=[id]
 while not queue.is_empty():
  var path=queue.pop_front();var at=path[-1]
  if at==target and path.size()>1:
   var next=dungeon.rooms[path[1]];var d=next.center-dungeon.rooms[id].center
   return {"heading":("東" if d.x>0 else "西") if absf(d.x)>absf(d.y) else ("南" if d.y>0 else "北"),"name":next.name}
  for edge in dungeon.connections:
   var n=edge[1] if edge[0]==at else (edge[0] if edge[1]==at else -1)
   if n>=0 and n not in seen:seen.append(n);var route=path.duplicate();route.append(n);queue.append(route)
 return {}

func roll_loot(tier:int,rarity:int=-1)->Dictionary:
 if rarity<0 and loot_favor>0:
  var roll=rng.randf()
  rarity=3 if roll<.035 else (2 if roll<.30 else -1)
 return ItemDB.generate(rng,tier,ItemDB.roll_rarity(rng,player.stats.rarity_find) if rarity<0 else rarity)
func risk_damage_multiplier()->float:return 1.2 if "danger" in event_choices.values() else 1.0
func choose_contract(choice:String)->void:
 if mode!="event" or event_room not in [10,11] or event_choices.has(str(event_room)):return
 if event_room==10 and choice not in ["blood","danger","leave"]:return
 if event_room==11 and choice not in ["wager","leave"]:return
 if choice=="blood":
  var cost=player.stats.hp*.25
  if player.hp<=cost+1:toast("生命が足りません。別の契約を選べます。");return
  player.hp-=cost
 elif choice=="danger":loot_favor=.15
 elif choice=="wager":
  var loan=ItemDB.initial_items().weapon.duplicate(true)
  loan.id="contract-loan";loan.name="契約の貸与剣";loan.base.attack=round(player.equipment.weapon.base.get("attack",9)*.7)
  player.equipment.weapon=loan;player.rebuild_stats()
 event_choices[str(event_room)]=choice;mode="play";begin_encounter(event_room);save_run()
func resolve_contract(id:int)->void:
 var choice=String(event_choices.get(str(id),"leave"))
 if choice=="leave":return
 profile.chronicle.contracts+=1;metrics.contracts+=1;check_achievements()
 player.gain_xp(220+dungeon.rooms[id].tier*75)
 var reward=ItemDB.generate(rng,dungeon.rooms[id].tier+1,3)
 if choice=="wager":
  var weapon_legends=[]
  for i in range(ItemDB.LEGENDS.size()):
   if ItemDB.LEGENDS[i].slot=="weapon":weapon_legends.append(i)
  reward=ItemDB.generate(rng,dungeon.rooms[id].tier+1,3,weapon_legends[rng.randi_range(0,weapon_legends.size()-1)])
 spawn_drop(dungeon.rooms[id].center+Vector2(70,80),reward);toast("契約達成 / 聖遺物が現れた")
func record_item(item:Dictionary)->void:
 if int(item.get("rarity",0))<3:return
 var effect=String(item.effect)
 if not effect.is_empty() and effect not in profile.chronicle.legends:profile.chronicle.legends.append(effect);check_achievements()
func check_achievements()->void:
 var c=profile.chronicle
 var earned={"first_clear":profile.records.wins>0,"collector":c.legends.size()>=6,"evader":c.evades>=5,"risk":c.contracts>=1,"bestiary":c.enemies.size()>=ChronicleDB.ENEMIES.size()}
 for id in earned:
  if earned[id] and id not in c.achievements:
   c.achievements.append(id);toast("記録達成 / "+ChronicleDB.ACHIEVEMENTS[id][0]);sound.play("level",.5)
