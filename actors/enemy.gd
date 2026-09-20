class_name ChapelEnemy
extends Node2D
var game
var kind="hollow"
var spec={}
var hp=50.0
var max_hp=50.0
var radius=18.0
var damage=10.0
var speed=100.0
var xp=8
var velocity=Vector2.ZERO
var aim=Vector2.RIGHT
var target=Vector2.ZERO
var state="spawn"
var timer=.65
var windup=1.0
var flash=0.0
var slow_time=0.0
var dead=false
var age=0.0
var pattern=0
var phase=1
var room_id=0
var texture:Texture2D
var charge_hit=false
var spawn_fx=false
var summon_timer=12.0
var affix=""
const ELITE_AFFIXES={
 "frenzied":{"name":"FRENZIED","hint":"FASTER MOVEMENT / SHORTER WINDUPS","color":Color("df756f")},
 "bulwark":{"name":"BULWARK","hint":"HEAVY ARMOR / RESISTS KNOCKBACK","color":Color("d3b06f")},
 "volatile":{"name":"VOLATILE","hint":"EXPLODES AFTER DEATH","color":Color("c98bd8")}}
func setup(g,type:String,p:Vector2,tier:int,room:int,forced_affix:String="")->void:
 game=g;kind=type;position=p;room_id=room;spec=game.enemy_data[kind];radius=spec.radius
 max_hp=spec.hp*(1+maxi(0,tier-1)*.25+game.ascension*.45);hp=max_hp
 damage=spec.damage*(1+maxi(0,tier-1)*.085+game.ascension*.15);speed=spec.speed;xp=int(spec.xp*(1+maxi(0,tier-1)*.12))
 texture=load("res://assets/characters/"+kind+".svg");windup=spec.windup
 if kind=="elite":
  max_hp*=game.ascension_elite_hp_mult();hp=max_hp;damage*=game.ascension_elite_damage_mult()
  affix=forced_affix if forced_affix in ELITE_AFFIXES else ELITE_AFFIXES.keys()[game.rng.randi_range(0,ELITE_AFFIXES.size()-1)]
  apply_elite_affix()
 if kind=="boss":max_hp=spec.hp*(1+game.ascension*.55);hp=max_hp;timer=1.5
func apply_elite_affix()->void:
 match affix:
  "frenzied":
   speed*=1.18
   damage*=1.05
  "bulwark":
   max_hp*=1.32
   hp=max_hp
   speed*=.88
   radius+=2
  "volatile":
   damage*=1.08
func affix_name()->String:
 return ELITE_AFFIXES.get(affix,{}).get("name","")
func affix_hint()->String:
 return ELITE_AFFIXES.get(affix,{}).get("hint","")
func affix_color()->Color:
 return ELITE_AFFIXES.get(affix,{}).get("color",Color("d3a281"))
func tick(dt:float)->void:
 if dead:return
 age+=dt;flash=maxf(0,flash-dt);slow_time=maxf(0,slow_time-dt);timer-=dt
 var to=game.player.position-position;var distance=to.length();var dir=to.normalized()
 if not spawn_fx:spawn_fx=true;game.fx.ring(position,48,Color("b48d83"),.5)
 if kind=="boss" and hp<max_hp*.5 and phase==1:
  phase=2;game.banner("THE LAST TOLL","The king's oath is broken.");game.sound.play("boss");game.fx.ring(position,300,Color("e5ad76"),1)
 if kind=="boss" and phase==2:
  summon_timer-=dt
  if summon_timer<=0:
   summon_timer=17
   for j in range(3):game.spawn_enemy("hollow",position+Vector2.from_angle(j*TAU/3)*130,5,room_id)
 match state:
  "spawn":
   if timer<=0:state="approach";timer=0
  "approach":
   aim=dir;var motion=dir
   if kind=="cantor":
    if distance<230:motion=-dir
    elif distance<365:motion=dir.orthogonal()*sin(age*.9)*.65
   var separation=Vector2.ZERO
   for e in game.enemies:
    if e==self or e.dead:continue
    var diff=position-e.position
    if diff.length_squared()<pow(radius+e.radius+7,2):separation+=diff.normalized()*50
   move_with_steering((motion*speed*(.53 if slow_time>0 else 1)+separation)*dt)
   var reach=spec.reach
   if kind=="boss":reach=650 if pattern%4 in [1,2,3] else 175
   if timer<=0 and distance<reach and game.dungeon.line_clear(position,game.player.position):start_windup()
  "windup":
   if timer<=0:release_attack()
  "charge":
   var before=position;position=game.dungeon.move_body(position,aim*(610 if kind=="boss" else 550)*dt,radius)
   if not charge_hit and position.distance_to(game.player.position)<radius+23:game.player.take_damage(damage*1.2,aim*190);charge_hit=true
   if timer<=0 or position.distance_to(before)<dt*90:state="recover";timer=1.1
   if int(age*30)%3==0:game.fx.burst(position,Color("ad796a"),2,30)
  "recover":
   if timer<=0:state="approach";timer=.18
 if velocity.length()>1:position=game.dungeon.move_body(position,velocity*dt,radius);velocity=velocity.move_toward(Vector2.ZERO,dt*1400)
 z_index=clampi(int(position.y/10),-400,400)+500;queue_redraw()
func move_with_steering(motion:Vector2)->void:
 var next=game.dungeon.move_body(position,motion,radius)
 if next.distance_to(position)<motion.length()*.35:
  for a in [.85,-.85,1.5,-1.5]:
   var alt=game.dungeon.move_body(position,motion.rotated(a),radius)
   if alt.distance_to(position)>next.distance_to(position):next=alt
 position=next
func start_windup()->void:
 state="windup";aim=(game.player.position-position).normalized();target=game.player.position;windup=spec.windup
 if kind=="elite" and affix=="frenzied":windup*=.78
 if kind=="boss":windup=[1.1,1.35,1.3,1.35][pattern%4]*(.85 if phase==2 else 1)
 timer=windup
 if kind=="boss" and pattern%4==1:
  game.add_hazard(target,95,.15,damage,false,windup)
  game.add_hazard(target+Vector2(150,0),85,.15,damage,false,windup+.28)
  game.add_hazard(target-Vector2(150,0),85,.15,damage,false,windup+.56)
  if phase==2:
   game.add_hazard(target+Vector2(0,160),85,.15,damage,false,windup+.4)
   game.add_hazard(target-Vector2(0,160),85,.15,damage,false,windup+.7)
func release_attack()->void:
 state="recover";timer=spec.recovery
 match kind:
  "hollow":hit_cone(74,1.1,damage);game.fx.slash(position,aim,60,Color("dd9680"))
  "cantor":game.fire(position+aim*24,aim*235,damage,false,0,Color("d7a6ee"));game.sound.play("bolt",.35)
  "hound":state="charge";timer=.48;charge_hit=false
  "warden":
   if position.distance_to(game.player.position)<118:game.player.take_damage(damage,aim*230)
   game.fx.ring(position,112,Color("e4ab76"),.35);game.fx.burst(position,Color("b69677"),16,170);game.sound.play("heavy",.4)
  "elite":
   hit_cone(180,1.45,damage);game.fx.slash(position,aim,173,Color("df99be"),true)
   for j in range(8):game.fire(position+Vector2.from_angle(j*TAU/8)*35,Vector2.from_angle(j*TAU/8)*180,damage*.65,false,0,Color("dea2c5"))
  "boss":
   match pattern%4:
    0:hit_cone(220,1.48,damage*1.2);game.fx.slash(position,aim,214,Color("ffd899"),true);game.sound.play("heavy",.8)
    1:game.sound.play("nova",.55)
    2:
     for j in range(18):
      var a=j*TAU/18+age*.13;game.fire(position+Vector2.from_angle(a)*63,Vector2.from_angle(a)*(200 if phase==1 else 245),damage*.65,false,0,Color("f1c28f"))
     game.fx.ring(position,190,Color("edbc88"),.6);game.sound.play("boss",.45)
    3:state="charge";timer=.8;charge_hit=false
   pattern+=1;game.metrics.boss_patterns+=1
func hit_cone(reach:float,angle:float,amount:float)->void:
 var to=game.player.position-position
 if to.length()<reach and absf(aim.angle_to(to))<angle and game.dungeon.line_clear(position,game.player.position):game.player.take_damage(amount,aim*170)
func take_damage(amount:float,knock:Vector2,crit:bool=false,proc:bool=false)->void:
 if dead or state=="spawn":return
 hp-=amount;flash=.095
 var knock_scale=.13 if kind=="boss" else (.35 if kind=="warden" else (.28 if kind=="elite" and affix=="bulwark" else .8))
 velocity+=knock*knock_scale
 game.fx.number(position,str(ceili(amount)),Color("ffe6a0") if crit else Color("e1e7db"),crit)
 game.fx.burst(position,Color("edaf84") if crit else Color("a0d1c7"),14 if crit else 6,180 if crit else 100)
 game.metrics.damage_dealt+=amount
 if hp<=0:
  dead=true
  if kind=="elite" and affix=="volatile":
   game.add_hazard(position,118,.12,damage*.9,false,.9)
   game.fx.ring(position,118,affix_color(),.9)
   game.toast("VOLATILE OATH / CLEAR THE BLAST")
  game.enemy_died(self,proc);queue_free()
func _draw()->void:
 var size=145 if kind=="boss" else (104 if kind in ["elite","warden"] else (77 if kind=="hound" else 79))
 draw_set_transform(Vector2(0,8),0,Vector2(1,.4));draw_circle(Vector2.ZERO,radius*1.3,Color(0,0,0,.4));draw_set_transform(Vector2.ZERO)
 if kind=="boss":draw_arc(Vector2.ZERO,radius+8,0,TAU,48,Color(.9,.62,.35,.45),2,true)
 elif kind=="elite":
  draw_arc(Vector2.ZERO,radius+9,0,TAU,48,Color(affix_color(),.72),3,true)
  draw_arc(Vector2.ZERO,radius+14,age*.7,age*.7+PI*1.15,32,Color(affix_color(),.34),2,true)
 var tint=Color(2.7,2.7,2.7) if flash>0 else Color.WHITE
 if state=="spawn":tint.a=clampf(1-timer/(1.5 if kind=="boss" else .65),.15,1)
 if slow_time>0 and flash<=0:tint=Color(.65,1,1.12)
 draw_set_transform(Vector2(0,sin(age*7)*(2.2 if state=="approach" else .5)),sin(age*7)*.025 if state=="approach" else 0,Vector2(1 if aim.x>=0 else -1,1))
 draw_texture_rect(texture,Rect2(-size*.5,-size*.76,size,size),false,tint);draw_set_transform(Vector2.ZERO)
 if hp<max_hp and kind!="boss":
  var w=62 if kind=="elite" else 42
  draw_rect(Rect2(-w/2.0,-size*.81,w,5),Color("131824"));draw_rect(Rect2(-w/2.0,-size*.81,w*maxf(0,hp/max_hp),5),Color("d3a281") if kind=="elite" else Color("ab6b65"))
