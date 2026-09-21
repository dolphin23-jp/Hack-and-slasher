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
var equipment=ItemDB.initial_items()
var inventory=[]
var upgrades={}
var level=1
var xp=0
var hp=150.0
var potions=3
var cooldowns=[0.0,0.0,0.0]
var dash_cd=0.0
var dash_time=0.0
var attack_cd=0.0
var attack_time=0.0
var combo=0
var combo_expire=0.0
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
var skip_next_weapon=false
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
 game=g;active_oaths=game.profile.oaths.active.duplicate();rebuild_stats();hp=stats.hp
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
 var oath_stats=OathBoard.stats(game.profile.oaths,active_oaths) if game!=null else {}
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
 var s:Dictionary=calculated(loadout);var avg_power=average_weapon_power(loadout);var offense=0.0
 for slot in Loadout.WEAPONS:
  var it:Dictionary=loadout[slot];var w:Dictionary=WeaponDB.get_weapon(it)
  var per_hit=(float(s.attack)-avg_power+weapon_power(it))*float(w.damage)
  var type_bonus=1.0
  for damage_type in w.types:type_bonus=maxf(type_bonus,1.0+float(s.get(damage_type,0)))
  var coverage=1.0+clampf((float(w.reach)-110.0)/520.0,0,.24)
  if String(w.shape)=="circle":coverage+=.12
  elif String(w.shape)=="line":coverage+=.07
  var tier_factor=1.0+maxi(0,int(it.tier)-1)*.025
  if int(it.tier)>=5:tier_factor+=.05
  offense+=per_hit*(1.0+float(s.haste))/maxf(.13,float(w.cooldown))*type_bonus*coverage*tier_factor/3.0
 offense*=1.0+float(s.crit)*float(s.crit_damage)
 offense*=1.0+WeaponDB.chain_synergy_score(loadout)*.045
 var special=0.0
 for slot in ItemDB.SLOTS:
  var it:Dictionary=loadout[slot];var unique=String(it.get("unique",""))
  match unique:
   "wide_chain":special+=.05
   "double_spin":special+=.22
   "split_lance":special+=.13
   "ricochet":special+=.13
   "fist_nova":special+=.12
   "shield_reach":special+=.06
   "chain_guard":special+=.05
   "full_shield_magic_double":special+=.10
   "shield_spend_power":special+=.09
   "transition_crit":special+=.07
   "dodge_skip":special+=.07
   "transition_echo":special+=.08
  if int(it.rarity)==4:special+=.025
  match String(it.effect):
   "echo":special+=.12
   "crit_blast":special+=.08
   "chain":special+=.06
 offense*=1.0+minf(.65,special)
 var defense=float(s.hp)*.020+float(s.armor)*.11+float(s.shield_max)*.05+float(s.shield_regen)*.45
 defense+=float(s.speed)*6.0+float(s.dodge_cdr)*8.0+float(s.fatal_resist)*12.0
 return offense+defense
func best_item_target(item:Dictionary)->String:
 if not ItemDB.valid(item):return ""
 var slot=String(item.slot)
 if slot not in ItemDB.SLOTS:return ""
 var targets:Array=Loadout.WEAPONS if slot=="weapon" else (["accessory","accessory2"] if slot=="accessory" else [slot])
 var best_target="";var best_score=-INF
 for target in targets:
  var loadout=equipment.duplicate(true);loadout[target]=item
  var score=build_score(loadout)
  if score>best_score:best_score=score;best_target=String(target)
 return best_target
func item_upgrade_ratio(item:Dictionary)->float:
 var target=best_item_target(item)
 if target.is_empty():return 0.0
 var current=build_score(equipment)
 if current<=.001:return 0.0
 var loadout=equipment.duplicate(true);loadout[target]=item
 return build_score(loadout)/current-1.0
func item_comparison(item:Dictionary)->Dictionary:
 var target=best_item_target(item)
 if target.is_empty():return {}
 var loadout=equipment.duplicate(true);loadout[target]=item
 var next=calculated(loadout)
 var current_item=equipment[target]
 var out={"target":target,"attack":next.attack-stats.attack,"hp":next.hp-stats.hp,"armor":next.armor-stats.armor,"range":0.0,"chain":0,"tier":int(item.tier)-int(current_item.tier),"unique":not String(item.get("unique","")).is_empty() and String(item.get("unique",""))!=String(current_item.get("unique","")),"mythic":int(item.rarity)==4 and int(current_item.rarity)<4}
 if target in Loadout.WEAPONS:
  var old_reach=float(WeaponDB.get_weapon(equipment[target]).reach);var new_reach=float(WeaponDB.get_weapon(item).reach)
  out.range=new_reach/maxf(1.0,old_reach)-1.0
  out.chain=WeaponDB.chain_synergy_score(loadout)-WeaponDB.chain_synergy_score(equipment)
 return out
func item_comparison_text(item:Dictionary)->String:
 var c=item_comparison(item)
 if c.is_empty():return "比較不可"
 var bits=[]
 if c.attack>1.0:bits.append("攻撃+")
 elif c.attack< -1.0:bits.append("攻撃-")
 if c.range>.08:bits.append("範囲+")
 elif c.range<-.08:bits.append("範囲-")
 if int(c.chain)>0:bits.append("連携+")
 elif int(c.chain)<0:bits.append("連携-")
 if bool(c.unique):bits.append("固有+")
 if bool(c.mythic):bits.append("神話")
 elif int(c.tier)>0:bits.append("Tier+")
 var durability=float(c.hp)*.02+float(c.armor)*.1
 if durability>1.0:bits.append("防御+")
 elif durability< -1.0:bits.append("防御-")
 if bits.is_empty():bits.append("横並び")
 return " / ".join(bits)+" → "+ItemDB.slot_text(String(c.target))
func rebuild_stats()->void:stats=calculated();hp=minf(hp,stats.hp)
func has_effect(effect:String)->bool:
 if OathBoard.has_effect(active_oaths,effect):return true
 for slot in ItemDB.SLOTS:
  if effect in ["echo","reaper","execution","judgement_echo","lance_fork","lance_return","echo_guard","dash_nova"] and equipment[slot].effect==effect:return true
 return false
func unique_rarity(key:String)->int:
 var best=-1
 for slot in ItemDB.SLOTS:
  if String(equipment[slot].get("unique",""))==key:best=maxi(best,int(equipment[slot].rarity))
 return best
func has_unique(key:String)->bool:return unique_rarity(key)>=0
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
 combo=combo%3+1
 if skip_next_weapon:
  combo=combo%3+1;skip_next_weapon=false
  game.fx.number(position+facing*38,"回避連環",Color("bfe9ff"))
 combo_expire=1.25;swing_count+=1
 CombatChain.strike(self)
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
 if has_unique("dodge_skip"):
  skip_next_weapon=true
  if unique_rarity("dodge_skip")==4:dash_cd=maxf(0,dash_cd-.12)
 game.fx.ring(position,45,Color("a4ebe0"),.3);game.sound.play("dash");return true
func skill_duration(i:int)->float:return [5.0,10.0,6.0][i]*(1-stats.cdr)*(.75 if i==2 and upgrades.get("giant_mastery",0)>0 else 1.0)
func cast(i:int)->bool:
 if dead or cooldowns[i]>0 or dash_time>0:return false
 cooldowns[i]=skill_duration(i)
 if synergy("echo"):echo_ready=true
 var dmg=stats.attack*(1+stats.skill)
 match i:
  0:
   attack_time=.3;game.melee(position,facing,200,1.28,dmg*3.5*(1.2 if upgrades.get("finisher_wave",0)>0 else 1.0),480)
   if has_effect("judgement_echo"):game.queue_blast(position+facing*110,145,dmg*2.45,.35,Color("dfd6ff"))
   game.fx.slash(position,facing,190,Color("ffdaa0"),true);game.fx.ring(position+facing*100,95,Color("cda373"));game.sound.play("heavy");game.shake(6)
  1:
   var radius=225+upgrades.get("nova_radius",0)
   game.area_damage(position,radius,dmg*2.7,false,true)
   for e in game.enemies:
    if e.position.distance_to(position)<radius:
     e.slow_time=3
     if upgrades.get("nova_pull",0)>0:e.velocity=(position-e.position).normalized()*650
   if upgrades.get("nova_echo",0)>0:game.queue_blast(position,radius,dmg*1.35,.6,Color("92e8d5"))
   if has_effect("echo_guard"):barrier=stats.hp*.12;barrier_time=5
   if has_effect("ember_nova"):game.add_hazard(position,150,3,dmg*.9,true,0)
   if has_effect("conductor"):game.chain_lightning(position,dmg*.9,null)
   game.fx.ring(position,radius,Color("85edda"),.65);game.fx.ring(position,radius*.8,Color("d4fff0"),.45)
   game.fx.burst(position,Color("85dace"),45,370);game.sound.play("nova");game.shake(7)
  2:
   cast_lance(dmg)
   game.sound.play("bolt")
 return true
func cast_lance(dmg:float)->void:
 var path=BuildDB.lance_key(upgrades)
 var angles=[0.0]
 if path=="lance_fan":angles=[-.24,0.0,.24] if upgrades.get("fan_mastery",0)<=0 else [-.40,-.20,0.0,.20,.40]
 elif upgrades.get("spear_count",0)>0:angles=[-.15,0.0,.15]
 for a in angles:
  var mult=.65 if path=="lance_fan" else (1.8+upgrades.get("giant_mastery",0)*.3 if path=="lance_giant" else 1.0)
  var bolt=game.fire(position+facing*25,facing.rotated(a)*(610 if path=="lance_giant" else 730),dmg*2.8*mult,true,0 if path=="lance_blast" else 9,Color("ffb26e") if path=="lance_blast" else Color("9ce7ff"))
  bolt.radius=24 if path=="lance_giant" else 8;bolt.slow_on_hit=2 if path=="lance_giant" else 0
  bolt.explosion_radius=140+upgrades.get("blast_mastery",0)*65 if path=="lance_blast" else 0
  bolt.explosion_damage=dmg*2.8*(.9+upgrades.get("blast_mastery",0)*.4)
  bolt.can_return=has_effect("lance_return");bolt.chain_on_hit=synergy("storm") and a==0.0
 if has_effect("lance_fork"):
  for a in [-.35,.35]:
   var bolt=game.fire(position+facing*25,facing.rotated(a)*680,dmg*1.26,true,5,Color("c7b8ff"));bolt.secondary_effect=true
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
 rebuild_stats();game.sound.play("equip");game.metrics.equips+=1;game.save_run();return true
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
 var a=facing.angle()
 if attack_time>0:a+=lerpf(TAU,0,attack_time/.2) if equipment[Loadout.WEAPONS[maxi(0,combo-1)]].weapon_type=="scythe" else lerpf(1.2,-1.1,attack_time/.3)
 draw_set_transform(Vector2.from_angle(a)*29+Vector2(0,-24),a+PI*.25,Vector2(.67,.67))
 draw_texture_rect(weapon_art.get(equipment[Loadout.WEAPONS[maxi(0,combo-1)]].weapon_type,sword),Rect2(-26,-78,64,64),false,tint);draw_set_transform(Vector2.ZERO)
 if barrier>0:draw_arc(Vector2.ZERO,40,0,TAU,48,Color("c9b5ff"),3,true)
 if counter_time>0:draw_arc(Vector2.ZERO,30,0,TAU,48,Color("eeecad"),2,true)
 if dash_time>0:draw_arc(Vector2.ZERO,35,0,TAU,40,Color("94e8db"),2,true)
