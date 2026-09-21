class_name OathKnight
extends Node2D
var game
var velocity=Vector2.ZERO
var facing=Vector2.RIGHT
var last_move=Vector2.RIGHT
var dash_direction=Vector2.RIGHT
var stats={}
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
var anim=0.0
var dead=false
var touch_move=Vector2.ZERO
var touch_attack=false
var test_move=Vector2.ZERO
var controlled_by_test=false
var texture=preload("res://assets/characters/player.svg")
var sword=preload("res://assets/icons/sword.svg")
func setup(g)->void:game=g;rebuild_stats();hp=stats.hp
func calculated(loadout:Dictionary=equipment)->Dictionary:
 var s={"attack":13.0+(level-1)*2.1,"hp":146.0+(level-1)*14,"armor":0.0,"haste":0.0,"crit":.06,"crit_damage":.55,"speed":0.0,"cdr":0.0,"skill":0.0}
 for slot in ItemDB.SLOTS:
  for table in [loadout[slot].base,loadout[slot].affixes]:
   for k in table:s[k]=s.get(k,0)+float(table[k])
 for k in upgrades:
  if s.has(k):s[k]+=upgrades[k]
 s.haste=clampf(s.haste,0,1.8);s.crit=clampf(s.crit,0,.8);s.speed=clampf(s.speed,0,.65);s.cdr=clampf(s.cdr,0,.55)
 return s
func build_score(loadout:Dictionary=equipment)->float:
 var s:Dictionary=calculated(loadout)
 var dps:float=float(s.attack)*(1.0+float(s.haste))
 dps*=1.0+float(s.crit)*float(s.crit_damage)
 var score:float=dps+float(s.hp)*.018+float(s.armor)*.10+float(s.speed)*5.0
 for slot in ItemDB.SLOTS:
  match String(loadout[slot].effect):
   "echo":score+=dps*.28
   "crit_blast":score+=dps*.16
   "chain":score+=dps*.12
 return score
func item_upgrade_ratio(item:Dictionary)->float:
 if not ItemDB.valid(item):return 0.0
 var slot:String=String(item.slot)
 if slot not in ItemDB.SLOTS:return 0.0
 var current:float=build_score(equipment)
 if current<=0.001:return 0.0
 var loadout:Dictionary=equipment.duplicate(true)
 loadout[slot]=item
 return build_score(loadout)/current-1.0
func rebuild_stats()->void:stats=calculated();hp=minf(hp,stats.hp)
func has_effect(effect:String)->bool:
 for slot in ItemDB.SLOTS:
  if equipment[slot].effect==effect:return true
 return false
func tick(dt:float)->void:
 if dead:return
 for i in range(3):cooldowns[i]=maxf(0,cooldowns[i]-dt)
 dash_cd=maxf(0,dash_cd-dt);attack_cd=maxf(0,attack_cd-dt);invulnerable=maxf(0,invulnerable-dt);flash=maxf(0,flash-dt)
 crit_blast_cd=maxf(0,crit_blast_cd-dt);attack_time=maxf(0,attack_time-dt);combo_expire=maxf(0,combo_expire-dt)
 if combo_expire<=0:combo=0
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
  dash_time-=dt;velocity=dash_direction*850;fire_tick-=dt
  if fire_tick<=0:
   game.fx.burst(position,Color("85e3d4"),4,32)
   if has_effect("fire_dash"):game.add_hazard(position,47,3.0,stats.attack*1.1,true,0)
   fire_tick=.045
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
 combo=combo%3+1;combo_expire=1.25;swing_count+=1
 attack_cd=(.41 if combo<3 else .54)/(1+stats.haste);attack_time=.22
 game.melee(position,facing,117 if combo<3 else 137,1.16,stats.attack*(1 if combo<3 else 1.55),180 if combo<3 else 300)
 game.fx.slash(position,facing,101 if combo<3 else 121,Color("b4ecdf") if combo<3 else Color("eed6a7"),combo==3)
 game.sound.play("slash" if combo<3 else "heavy",.8)
 if has_effect("echo") and swing_count%2==0:
  for a in [-.12,.12]:
   var echo=game.fire(position+facing*26,facing.rotated(a)*610,stats.attack*.55,true,2,Color("b7dffb"));echo.secondary_effect=true
 return true
func dash()->bool:
 if dead or dash_cd>0:return false
 dash_time=.19;invulnerable=maxf(invulnerable,.29);dash_cd=1.1*(1-stats.cdr*.55)
 dash_direction=last_move if velocity.length()>20 else facing;fire_tick=0
 game.fx.ring(position,45,Color("a4ebe0"),.3);game.sound.play("dash");return true
func skill_duration(i:int)->float:return [5.0,10.0,6.0][i]*(1-stats.cdr)
func cast(i:int)->bool:
 if dead or cooldowns[i]>0 or dash_time>0:return false
 cooldowns[i]=skill_duration(i)
 var dmg=stats.attack*(1+stats.skill)
 match i:
  0:
   attack_time=.3;game.melee(position,facing,200,1.28,dmg*3.5,480)
   game.fx.slash(position,facing,190,Color("ffdaa0"),true);game.fx.ring(position+facing*100,95,Color("cda373"));game.sound.play("heavy");game.shake(6)
  1:
   var radius=225+upgrades.get("nova_radius",0)
   game.area_damage(position,radius,dmg*2.7,false,true)
   for e in game.enemies:
    if e.position.distance_to(position)<radius:e.slow_time=3
   game.fx.ring(position,radius,Color("85edda"),.65);game.fx.ring(position,radius*.8,Color("d4fff0"),.45)
   game.fx.burst(position,Color("85dace"),45,370);game.sound.play("nova");game.shake(7)
  2:
   game.fire(position+facing*25,facing*730,dmg*2.8,true,9,Color("9ce7ff"))
   if upgrades.get("spear_count",0)>0:
    for a in [-.15,.15]:game.fire(position+facing*25,facing.rotated(a)*680,dmg*1.25,true,5,Color("9ce7ff"))
   game.sound.play("bolt")
 return true
func take_damage(amount:float,knock:Vector2=Vector2.ZERO)->bool:
 if dead or invulnerable>0:return false
 var damage=amount*100/(100+stats.armor)
 hp=maxf(0,hp-damage);invulnerable=.52;flash=.16;velocity+=knock
 position=game.dungeon.move_body(position,knock*.06,18)
 game.fx.number(position,str(ceili(damage)),Color("ef8d84"),true);game.fx.burst(position,Color("d4716f"),10,120)
 game.shake(8);game.sound.play("hurt");game.metrics.hits_taken+=1
 if hp<=0:dead=true;game.player_died()
 return true
func heal(amount:float)->void:hp=minf(stats.hp,hp+amount)
func drink()->bool:
 if dead or potions<=0 or hp>=stats.hp:return false
 potions-=1;heal(stats.hp*.48);game.fx.ring(position,82,Color("a4d5a0"),.7);game.fx.number(position,"回復",Color("b5dfa9"));game.sound.play("heal");return true
func equip(index:int)->bool:
 if index<0 or index>=inventory.size():return false
 var item=inventory[index];var old=equipment[item.slot];equipment[item.slot]=item;inventory[index]=old
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
 if attack_time>0:a+=lerpf(1.2,-1.1,attack_time/.3)
 draw_set_transform(Vector2.from_angle(a)*29+Vector2(0,-24),a+PI*.25,Vector2(.67,.67))
 draw_texture_rect(sword,Rect2(-26,-78,64,64),false,tint);draw_set_transform(Vector2.ZERO)
 if dash_time>0:draw_arc(Vector2.ZERO,35,0,TAU,40,Color("94e8db"),2,true)
