class_name OathKnight
extends Node2D
var game
var velocity=Vector2.ZERO
var facing=Vector2.RIGHT
var last_move=Vector2.RIGHT
var dash_direction=Vector2.RIGHT
var stats={}
var materials=0
var active_oaths=[]
var oath_board={}
var equipment=ItemDB.initial_items()
var inventory=[]
var upgrades={}
var level=1
var xp=0
var hp=150.0
var potions=3
var cooldowns=[0.0,0.0,0.0]
var finisher_charge=0
var skill_actions=[]
var normal_serial=0
var normal_group=0
var normal_groups={}
var last_mace_impact=Vector2.ZERO
var last_mace_time=-10.0
var dash_cd=0.0
var dash_time=0.0
var attack_cd=0.0
var attack_time=0.0
var combo=0
var combo_expire=0.0
var last_chain_weapon=""
var chain_streak=0
var chain_history=[]
var repeat_next=false
var repeat_block=false
var skip_next=false
var swing_count=0
var invulnerable=0.0
var flash=0.0
var crit_blast_cd=0.0
var fire_tick=0.0
var counter_time=0.0
var dash_evaded=false
var dash_attack_time=0.0
var dash_nova_cd=0.0
var echo_ready=false
var barrier=0.0
var barrier_time=0.0
var anim=0.0
var dead=false
var touch_move=Vector2.ZERO
var touch_attack=false
var test_move=Vector2.ZERO
var controlled_by_test=false
var texture=preload("res://assets/characters/player.svg")
var weapon_art={}
var sword=preload("res://assets/icons/sword.svg")
func setup(g)->void:
 for kind in WeaponDB.TYPES:weapon_art[kind]=load("res://assets/icons/"+kind+".svg")
 game=g;oath_board=OathBoard.sanitize(game.profile.oaths);active_oaths=oath_board.active.duplicate();rebuild_stats();hp=stats.hp
func calculated(loadout:Dictionary=equipment)->Dictionary:
 var s={"attack":13.0+(level-1)*2.1,"hp":146.0+(level-1)*14,"armor":0.0,"haste":0.0,"crit":.06,"crit_damage":.55,"speed":0.0,"cdr":0.0,"skill":0.0}
 for key in ItemDB.AFFIXES:
  if not s.has(key):s[key]=0.0
 for slot in ItemDB.SLOTS:
  var table=Loadout.equipped_stats(loadout[slot])
  for k in table:
   if slot in Loadout.WEAPONS and k=="attack":continue
   s[k]=s.get(k,0)+float(table[k])
 s.attack+=average_weapon_power(loadout)
 var oath_stats=OathBoard.stats(oath_board,active_oaths) if game!=null else {}
 for k in oath_stats:s[k]=s.get(k,0)+oath_stats[k]
 for k in upgrades:
  if s.has(k):s[k]+=upgrades[k]
 s.haste=clampf(s.haste,0,1.8);s.crit=clampf(s.crit,0,.8);s.speed=clampf(s.speed,0,.65);s.cdr=clampf(s.cdr,0,.55)
 return s
func average_weapon_power(loadout:Dictionary=equipment)->float:
 var value=0.0
 for slot in Loadout.WEAPONS:value+=weapon_power(loadout[slot])/3.0
 return value
func weapon_power(it:Dictionary)->float:return Loadout.equipped_stats(it).get("attack",0)
func build_score(loadout:Dictionary=equipment)->float:
 # This is only an internal replacement-slot heuristic. The UI deliberately
 # exposes multidimensional tags instead of claiming one definitive strength %.
 var s:Dictionary=calculated(loadout)
 var dps:float=float(s.attack)*(1.0+float(s.haste))
 dps*=1.0+float(s.crit)*float(s.crit_damage)
 var score:float=dps+float(s.hp)*.018+float(s.armor)*.10+float(s.speed)*5.0
 score+=chain_affinity(loadout)*dps*.035
 var has_magic=false
 for weapon_slot in Loadout.WEAPONS:
  if "magic" in WeaponDB.get_weapon(loadout[weapon_slot]).types:has_magic=true
  var gear=loadout[weapon_slot];var kind=String(gear.get("weapon_type","sword"));var tier=int(gear.get("tier",1))
  if tier>=3:score+=dps*({"scythe":.055,"spear":.045,"fist":.035,"mace":.04}.get(kind,.025))
  if tier>=4:score+=dps*({"staff":.065,"scythe":.045,"mace":.04,"spellblade":.04}.get(kind,.025))
  if tier>=5:score+=dps*.055
 for slot in ItemDB.SLOTS:
  var item=loadout[slot]
  match String(item.get("effect","")):
   "echo":score+=dps*.28
   "crit_blast":score+=dps*.16
   "chain":score+=dps*.12
  match String(item.get("unique","")):
   "double_spin":score+=dps*.16
   "split_lance":score+=dps*.10
   "ricochet":score+=dps*.12
   "fist_nova":score+=dps*.12
   "shield_reach":score+=dps*.07
   "wide_chain":score+=dps*.07
   "chain_guard","chain_aegis":score+=dps*.045
   "crit_repeat":score+=dps*.11
   "dodge_skip":score+=dps*.065
   "chain_cooldown":score+=dps*.085
   "barrier_burst_armor":score+=dps*.075
   "full_shield_double_magic":
    if has_magic:score+=dps*.12
 return score
func chain_affinity(loadout:Dictionary)->float:
 var kinds=[];var score=0.0
 for slot in Loadout.WEAPONS:
  var kind=String(loadout[slot].get("weapon_type","sword"));kinds.append(kind)
 for i in range(3):
  var previous=String(kinds[i]);var current=String(kinds[(i+1)%3])
  var profile=CombatChain.transition_profile(previous,current,kinds,2,true)
  if not profile.recipes.is_empty():score+=1
 if ChainResolver.triune(kinds):score+=1.5
 if kinds[0]==kinds[1] and kinds[1]==kinds[2]:score+=1.25
 return score
func item_comparison(item:Dictionary,target:String="")->Array:
 if not ItemDB.valid(item):return []
 if target.is_empty():target=item_upgrade_target(item)
 if target.is_empty() or not Loadout.accepts(item,target):return []
 var before=stats;var loadout=equipment.duplicate(true);loadout[target]=item;var after=calculated(loadout)
 var tags=[]
 var attack_delta=float(after.attack)-float(before.attack)
 if attack_delta>1.0:tags.append("攻撃↑")
 elif attack_delta<-1.0:tags.append("攻撃↓")
 var hp_delta=float(after.hp)-float(before.hp)
 if hp_delta>8:tags.append("生命↑")
 elif hp_delta<-8:tags.append("生命↓")
 var armor_delta=float(after.armor)-float(before.armor)
 if armor_delta>3:tags.append("防御↑")
 elif armor_delta<-3:tags.append("防御↓")
 if target in Loadout.WEAPONS:
  var old_weapon=WeaponDB.get_weapon(equipment[target]);var new_weapon=WeaponDB.get_weapon(item)
  if float(new_weapon.reach)>float(old_weapon.reach)*1.08:tags.append("範囲↑")
  elif float(new_weapon.reach)<float(old_weapon.reach)*.92:tags.append("範囲↓")
  if float(new_weapon.cooldown)<float(old_weapon.cooldown)*.92:tags.append("手数↑")
  var before_chain=chain_affinity(equipment);var after_chain=chain_affinity(loadout)
  if after_chain>before_chain+.2:tags.append("連携相性↑")
  elif after_chain<before_chain-.2:tags.append("連携相性↓")
  var attrs=WeaponDB.attributes(item)
  if WeaponDB.attributes(equipment[target])!=attrs:tags.append(attrs)
 if int(item.rarity)>=3:tags.append("固有能力")
 if tags.is_empty():tags.append("数値は近似")
 return tags
func item_upgrade_target(item:Dictionary)->String:
 if not ItemDB.valid(item):return ""
 var current:float=build_score(equipment)
 if current<=0.001:return String(item.slot)
 var best_target="";var best_ratio=-INF
 for target in ItemDB.SLOTS:
  if not Loadout.accepts(item,target):continue
  var loadout:Dictionary=equipment.duplicate(true);loadout[target]=item
  var ratio=build_score(loadout)/current-1.0
  if ratio>best_ratio:best_ratio=ratio;best_target=target
 return best_target
func item_upgrade_ratio(item:Dictionary)->float:
 var target=item_upgrade_target(item)
 if target.is_empty():return 0.0
 var current:float=build_score(equipment)
 if current<=0.001:return 0.0
 var loadout:Dictionary=equipment.duplicate(true);loadout[target]=item
 return build_score(loadout)/current-1.0
func rebuild_stats()->void:stats=calculated();hp=minf(hp,stats.hp)
func has_unique(id:String)->bool:
 for slot in ItemDB.SLOTS:
  if String(equipment[slot].get("unique",""))==id:return true
 return false
func has_effect(effect:String)->bool:
 if OathBoard.has_effect(oath_board,active_oaths,effect):return true
 for slot in ItemDB.SLOTS:
  if effect in ["echo","reaper","execution","judgement_echo","lance_fork","lance_return","echo_guard","dash_nova"] and equipment[slot].effect==effect:return true
 return false
func set_count(family:String,loadout:Dictionary=equipment)->int:
 var count=0
 for slot in ItemDB.SLOTS:
  if ItemDB.set_of(loadout[slot])==family:count+=1
 return count
func synergy(family:String)->bool:return ("storm" in active_oaths if family=="storm" else ("flame" in active_oaths if family=="cinder" else "dance" in active_oaths))
func perfect_evade()->void:
 if dash_evaded:return
 dash_evaded=true;counter_time=2.0;dash_cd=maxf(0,dash_cd-(.35 if upgrades.get("riposte",0)>0 else .2))
 game.metrics.perfect_evades+=1;game.profile.chronicle.evades+=1;game.check_achievements()
 game.fx.number(position,"見切り / 反撃",Color("b0fff0"),true);game.fx.ring(position,100,Color("b0fff0"),.4);game.sound.play("crit",.7)
 if has_effect("storm_guard"):game.chain_lightning(position,stats.attack*1.4,null)
func tick(dt:float)->void:
 if dead:return
 counter_time=maxf(0,counter_time-dt);dash_attack_time=maxf(0,dash_attack_time-dt);dash_nova_cd=maxf(0,dash_nova_cd-dt)
 barrier_time=maxf(0,barrier_time-dt)
 if barrier_time<=0:barrier=minf(barrier,stats.shield_max)
 barrier=minf(maxf(barrier,0)+stats.shield_regen*dt,maxf(barrier,stats.shield_max))
 WeaponActionResolver.tick(self,dt)
 for i in range(3):cooldowns[i]=maxf(0,cooldowns[i]-dt)
 dash_cd=maxf(0,dash_cd-dt);attack_cd=maxf(0,attack_cd-dt);invulnerable=maxf(0,invulnerable-dt);flash=maxf(0,flash-dt)
 crit_blast_cd=maxf(0,crit_blast_cd-dt);attack_time=maxf(0,attack_time-dt);combo_expire=maxf(0,combo_expire-dt)
 var move=Input.get_vector("move_left","move_right","move_up","move_down")
 if touch_move.length()>.1:move=touch_move
 if controlled_by_test:move=test_move.limit_length()
 var pads=Input.get_connected_joypads();var aim=Vector2.ZERO
 if not pads.is_empty():aim=Vector2(Input.get_joy_axis(pads[0],JOY_AXIS_RIGHT_X),Input.get_joy_axis(pads[0],JOY_AXIS_RIGHT_Y))
 if not controlled_by_test:
  if aim.length()>.25:facing=aim.normalized()
  elif game.profile.settings.auto_aim or game.profile.settings.touch or not pads.is_empty():
   var target=game.nearest_enemy(position,550)
   if target!=null:facing=(target.position-position).normalized()
   elif move.length()>.1:facing=move.normalized()
  else:
   var mouse=get_global_mouse_position()-position
   if mouse.length()>10:facing=mouse.normalized()
 if move.length()>.1:last_move=move.normalized()
 if dash_time>0:
  dash_time-=dt;velocity=dash_direction*850*(1+clampf(stats.dodge_distance,0,.5));fire_tick-=dt
  if fire_tick<=0:
   game.fx.burst(position,Color("85e3d4"),4,32)
   if has_effect("fire_dash") or upgrades.get("ember_start",0)>0:game.add_hazard(position,47,3.0,stats.attack*(1.1 if has_effect("fire_dash") else .35),true,0)
   fire_tick=.075
  if dash_time<=0 and has_effect("dash_nova") and dash_nova_cd<=0:
   dash_nova_cd=1.2;game.area_damage(position,125,stats.attack*.7);game.fx.ring(position,125,Color("8cdff6"),.35)
 else:
  velocity=velocity.move_toward(move*235*(1+stats.speed),dt*(1600 if move.length()>.05 else 1900))
  if not controlled_by_test:
   if (Input.is_action_pressed("attack") and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not game.ui.pointer_blocked())) or touch_attack:attack()
   if Input.is_action_just_pressed("dash"):dash()
   for i in range(3):
    if Input.is_action_just_pressed("skill_"+str(i)):cast(i)
   if Input.is_action_just_pressed("heal"):drink()
 position=game.dungeon.move_body(position,velocity*dt,18)
 anim+=dt*(9 if velocity.length()>20 else 2);z_index=clampi(int(position.y/10),-400,400)+500;queue_redraw()
func attack()->bool:
 if dead or attack_cd>0 or dash_time>0:return false
 var linked=combo_expire>0
 chain_streak=chain_streak+1 if linked else 1
 repeat_block=false
 if repeat_next and combo>0:
  repeat_next=false;repeat_block=true
 elif skip_next:
  skip_next=false;combo=(combo+1)%3+1
 else:combo=combo%3+1
 var current_kind=String(equipment[Loadout.WEAPONS[combo-1]].get("weapon_type","sword"))
 if linked:
  chain_history.append(current_kind)
  if chain_history.size()>3:chain_history.pop_front()
 else:chain_history=[current_kind]
 combo_expire=1.25;swing_count+=1
 WeaponActionResolver.begin_strike(self,linked)
 CombatChain.strike(self,linked)
 repeat_block=false
 var amount=stats.attack
 if combo==3:
  if has_effect("reaper"):game.area_damage(position,165,stats.attack*.75);game.fx.ring(position,165,Color("cbd4ff"),.4)
  if upgrades.get("finisher_wave",0)>0:
   var bolt=game.fire(position+facing*25,facing*510,stats.attack*.8,true,6,Color("ffe2b5"));bolt.radius=22;bolt.secondary_effect=true
  if echo_ready:
   echo_ready=false;game.queue_blast(position+facing*65,110,amount*.65,.25,Color("cbd4ff"))
 if has_effect("echo") and swing_count%2==0:
  for a in [-.12,.12]:
   var echo=game.fire(position+facing*26,facing.rotated(a)*610,stats.attack*.55,true,2,Color("b7dffb"));echo.secondary_effect=true
 return true
func dash()->bool:
 if dead or dash_cd>0 or dash_time>0:return false
 dash_time=.19;invulnerable=maxf(invulnerable,.24);dash_cd=1.1*(1-clampf(stats.dodge_cdr,0,.6))*(1-stats.cdr*.55)*(.8 if upgrades.get("dash_hunter",0)>0 else 1.0)
 dash_evaded=false;dash_attack_time=.9;attack_time=0;attack_cd=minf(attack_cd,.12)
 dash_direction=last_move if velocity.length()>20 else facing;fire_tick=0
 if has_unique("dodge_skip"):skip_next=true
 game.fx.ring(position,45,Color("a4ebe0"),.3);game.sound.play("dash");return true
func skill_duration(i:int)->float:return WeaponActionResolver.duration(self,i)
func cast(i:int)->bool:return WeaponActionResolver.cast(self,i)
func take_damage(amount:float,knock:Vector2=Vector2.ZERO,fatal:bool=false)->bool:
 if dead:return false
 if invulnerable>0:
  if dash_time>0:perfect_evade()
  return false
 var damage=amount*100/(100+stats.armor)*(1-clampf(stats.fatal_resist,0,.7) if fatal else 1.0)
 knock*=1-clampf(stats.knock_resist,0,.8)
 var absorbed=minf(barrier,damage);barrier-=absorbed;damage-=absorbed
 hp=maxf(0,hp-damage);invulnerable=.52;flash=.16;velocity+=knock
 position=game.dungeon.move_body(position,knock*.06,18)
 game.fx.number(position,str(ceili(damage)),Color("ef8d84"),true);game.fx.burst(position,Color("d4716f"),10,120)
 game.shake(8);game.sound.play("hurt");game.metrics.hits_taken+=1
 if hp<=0:dead=true;game.player_died()
 return true
func heal(amount:float)->void:hp=minf(stats.hp,hp+amount*(1+clampf(stats.healing,0,2)))
func drink()->bool:
 if dead or potions<=0 or hp>=stats.hp:return false
 potions-=1;heal(stats.hp*.48);game.fx.ring(position,82,Color("a4d5a0"),.7);game.fx.number(position,"回復",Color("b5dfa9"));game.sound.play("heal")
 if has_effect("phoenix"):
  game.area_damage(position,220,stats.attack*2);game.fx.ring(position,220,Color("ffb76f"),.55)
  for e in game.enemies:
   if e.position.distance_to(position)<220:e.ignite(stats.attack*.35,3)
 return true
func equip(index:int,target:String="")->bool:
 if index<0 or index>=inventory.size():return false
 var item=inventory[index]
 var slot=target if not target.is_empty() else String(item.slot)
 if not Loadout.accepts(item,slot):return false
 var old=equipment[slot];equipment[slot]=item;inventory[index]=old
 reset_chain()
 rebuild_stats();game.sound.play("equip");game.metrics.equips+=1;game.save_run();return true
func reset_chain()->void:
 combo_expire=0;chain_streak=0;chain_history.clear();normal_groups.clear();last_mace_time=-10.0
func xp_required()->int:return 60+(level-1)*45+int(pow(level-1,1.65)*16)
func gain_xp(amount:int)->void:
 xp+=amount
 while xp>=xp_required() and level<99:
  xp-=xp_required();level+=1;rebuild_stats();heal(stats.hp*.28);game.pending_upgrades+=1
  game.fx.ring(position,170,Color("edd8a0"),.9);game.fx.burst(position,Color("ffe2a1"),40,230);game.sound.play("level");game.metrics.level_ups+=1
func _draw()->void:
 draw_set_transform(Vector2(0,5),0,Vector2(1,.37));draw_circle(Vector2.ZERO,32,Color(0,0,0,.45));draw_set_transform(Vector2.ZERO)
 draw_arc(Vector2(0,2),26,0,TAU,40,Color(.5,.85,.8,.36),1.3,true)
 var walking=velocity.length()>20;var bob=sin(anim*2)*(3 if walking else .8);var sx=1 if facing.x>=0 else -1
 var tint=Color(2.3,2.3,2.3) if flash>0 else Color.WHITE
 if invulnerable>0 and sin(anim*15)>0:tint.a=.6
 draw_set_transform(Vector2(0,bob-21),velocity.x*.000035,Vector2(sx,1))
 var step_y=sin(anim*2)*4 if walking else 0.0
 draw_texture_rect_region(texture,Rect2(-42,13+step_y,42,29),Rect2(0,84,64,44),tint)
 draw_texture_rect_region(texture,Rect2(0,13-step_y,42,29),Rect2(64,84,64,44),tint)
 draw_set_transform(Vector2(0,bob-25),velocity.x*.000035,Vector2(sx,1))
 draw_texture_rect_region(texture,Rect2(-42,-42,84,56),Rect2(0,0,128,85),tint);draw_set_transform(Vector2.ZERO)
 var a=facing.angle();var kind=String(equipment[Loadout.WEAPONS[maxi(0,combo-1)]].weapon_type)
 var extension=0.0
 if attack_time>0:a+=lerpf(TAU,0,attack_time/.2) if equipment[Loadout.WEAPONS[maxi(0,combo-1)]].weapon_type=="scythe" else lerpf(1.2,-1.1,attack_time/.3)
 if attack_time>0:
  if kind in ["spear","staff","fist"]:
   a=facing.angle();extension=sin(clampf(1-attack_time/.3,0,1)*PI)*(28 if kind=="spear" else 17)
  elif kind=="mace":a=facing.angle()+lerpf(1.7,-1.4,clampf(attack_time/.3,0,1))
  elif kind=="spellblade":extension=sin(attack_time*18)*9
 draw_set_transform(Vector2.from_angle(a)*(29+extension)+Vector2(0,-24),a+PI*.25,Vector2(.67,.67))
 draw_texture_rect(weapon_art.get(equipment[Loadout.WEAPONS[maxi(0,combo-1)]].weapon_type,sword),Rect2(-26,-78,64,64),false,tint);draw_set_transform(Vector2.ZERO)
 if barrier>0:draw_arc(Vector2.ZERO,40,0,TAU,48,Color("c9b5ff"),3,true)
 if counter_time>0:draw_arc(Vector2.ZERO,30,0,TAU,48,Color("eeecad"),2,true)
 if dash_time>0:draw_arc(Vector2.ZERO,35,0,TAU,40,Color("94e8db"),2,true)
