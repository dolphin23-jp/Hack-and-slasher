class_name ChapelEnemy
extends Node2D
var game
var chain_marks={}
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
var stagger_time=0.0
var stagger_guard=0.0
var shield_break=0.0
var burn_time=0.0
var burn_damage=0.0
var burn_tick=0.0
var summoner_id=0
var spawned_minion=false
var charge_chain=0
var ring_gap=0.0
const ELITE_AFFIXES={
 "frenzied":{"name":"狂乱","hint":"移動高速化 / 予備動作短縮","color":Color("df756f")},
 "bulwark":{"name":"城塞","hint":"重装甲 / ノックバック耐性","color":Color("d3b06f")},
 "volatile":{"name":"爆裂","hint":"死亡後に爆発","color":Color("c98bd8")}}
func setup(g,type:String,p:Vector2,tier:int,room:int,forced_affix:String="")->void:
 game=g;kind=type;position=p;room_id=room;spec=game.enemy_data[kind];radius=spec.radius
 max_hp=spec.hp*(1+maxi(0,tier-1)*.25+game.ascension*.45);hp=max_hp
 damage=spec.damage*(1+maxi(0,tier-1)*.085+game.ascension*.15);speed=spec.speed;xp=int(spec.xp*(1+maxi(0,tier-1)*.12))
 texture=load("res://assets/characters/"+("cantor" if kind=="summoner" else kind)+".svg");windup=spec.windup
 if kind=="elite":
  max_hp*=game.ascension_elite_hp_mult();hp=max_hp;damage*=game.ascension_elite_damage_mult()
  affix=forced_affix if forced_affix in ELITE_AFFIXES else ELITE_AFFIXES.keys()[game.rng.randi_range(0,ELITE_AFFIXES.size()-1)]
  apply_elite_affix()
 if kind=="boss":max_hp=spec.hp*(1+game.ascension*.55);hp=max_hp;timer=1.5
 damage*=game.risk_damage_multiplier()
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
 stagger_guard=maxf(0,stagger_guard-dt);shield_break=maxf(0,shield_break-dt)
 if burn_time>0:
  burn_time-=dt;burn_tick-=dt
  if burn_tick<=0:
   burn_tick=.5;take_damage(burn_damage*.5,Vector2.ZERO,false,true)
   if dead:return
 if stagger_time>0:
  stagger_time-=dt;position=game.dungeon.move_body(position,velocity*dt,radius);velocity=velocity.move_toward(Vector2.ZERO,dt*1400);queue_redraw();return
 if kind=="boss" and hp<max_hp*.5 and phase==1:
  phase=2;state="transform";timer=1.6;charge_chain=0;velocity=Vector2.ZERO
  game.hazards=game.hazards.filter(func(h):return h.friendly)
  for bolt in game.projectiles.duplicate():
   if not bolt.friendly:bolt.remove()
  game.banner("最後の鐘 / 灰冠の王","連続突進のあとが反撃の好機。");game.toast("灰冠が砕ける / 攻撃後の青緑の輪を狙え")
  game.sound.set_music("boss_awakened");game.sound.play("boss");game.fx.ring(position,300,Color("e5ad76"),1)
 if kind=="boss" and phase==2 and state!="transform":
  summon_timer-=dt
  if summon_timer<=0:
   summon_timer=20
   for j in range(2):
    var minion=game.spawn_enemy("hollow",position+Vector2.from_angle(j*PI)*130,5,room_id);minion.spawned_minion=true
 match state:
  "spawn":
   if timer<=0:state="approach";timer=0
  "approach":
   aim=dir;var motion=dir
   if kind in ["cantor","summoner"]:
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
   if timer<=0 or position.distance_to(before)<dt*90:
    if kind=="boss" and charge_chain>0:
     charge_chain-=1;state="chain_windup";timer=.7;windup=.7;aim=dir
    else:state="recover";timer=2.4 if kind=="boss" else 1.2
   if int(age*30)%3==0:game.fx.burst(position,Color("ad796a"),2,30)
  "transform":
   if timer<=0:state="approach";timer=.5;pattern=3
  "chain_windup":
   if timer<=0:state="charge";timer=.65;charge_hit=false
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
 if kind=="boss":
  windup=[1.1,1.35,1.5,1.35][pattern%4]*(.92 if phase==2 else 1)
  ring_gap=aim.angle()+PI*.5
 if kind=="summoner":game.fx.ring(position,72,Color("cf9eff"),windup)
 timer=windup
 if kind=="boss" and pattern%4==1:
  game.add_hazard(target,95,.15,damage,false,windup)
  game.add_hazard(target+Vector2(150,0),85,.15,damage,false,windup+.28)
  game.add_hazard(target-Vector2(150,0),85,.15,damage,false,windup+.56)
  if phase==2:
   game.add_hazard(target+Vector2(0,160),85,.15,damage,false,windup+.4)
   game.add_hazard(target-Vector2(0,160),85,.15,damage,false,windup+.7)
func release_attack()->void:
 state="recover";timer=2.1 if kind=="boss" else spec.recovery
 match kind:
  "hollow":hit_cone(74,1.1,damage);game.fx.slash(position,aim,60,Color("dd9680"))
  "cantor":
   for a in [-.21,0.0,.21]:game.fire(position+aim*24,aim.rotated(a)*235,damage,false,0,Color("e2a8ff"))
   game.sound.play("bolt",.35)
  "summoner":
   var count=0
   for e in game.enemies:
    if e.summoner_id==get_instance_id():count+=1
   for j in range(mini(2,4-count)):
    var spawn_at=game.dungeon.spawn_point(room_id,j)
    var child=game.spawn_enemy("hollow" if j==0 else "hound",spawn_at,maxi(1,game.dungeon.rooms[room_id].tier-1),room_id)
    child.summoner_id=get_instance_id();child.spawned_minion=true
   game.sound.play("boss",.3)
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
      var a=j*TAU/18+ring_gap
      if absf(wrapf(a-ring_gap,-PI,PI))<.5:continue
      game.fire(position+Vector2.from_angle(a)*63,Vector2.from_angle(a)*(200 if phase==1 else 245),damage*.65,false,0,Color("f1c28f"))
     game.fx.ring(position,190,Color("edbc88"),.6);game.sound.play("boss",.45)
    3:state="charge";timer=.7;charge_hit=false;charge_chain=1 if phase==2 else 0
   pattern+=1;game.metrics.boss_patterns+=1
func hit_cone(reach:float,angle:float,amount:float)->void:
 var to=game.player.position-position
 if to.length()<reach and absf(aim.angle_to(to))<angle and game.dungeon.line_clear(position,game.player.position):game.player.take_damage(amount,aim*170,kind in ["elite","boss"])
func ignite(amount:float,duration:float)->void:
 burn_damage=maxf(burn_damage,amount);burn_time=maxf(burn_time,duration)
func take_damage(amount:float,knock:Vector2,crit:bool=false,proc:bool=false)->void:
 if dead or state in ["spawn","transform"]:return
 if kind=="warden" and shield_break<=0 and state!="recover" and knock.length()>1 and aim.dot(-knock.normalized())>.35:
  if knock.length()>=300:
   shield_break=3;state="recover";timer=1.5;game.fx.number(position,"盾崩し",Color("ffdaa1"),true);game.sound.play("heavy",.6)
  else:
   amount*=.25+clampf(game.player.stats.get("penetration",0),0,.6);game.fx.number(position,"防御",Color("b8d8e0"));knock*=.15
 if kind=="boss" and state=="recover":amount*=1.35
 if burn_time>0 and game.player.synergy("cinder") and not proc:amount*=1.3
 if not proc and stagger_guard<=0 and kind in ["hollow","cantor","hound","summoner"] and state!="charge":
  stagger_time=.16 if knock.length()<300 else .38;stagger_guard=.9
  if state=="windup":state="recover";timer=.55
 hp-=amount;flash=.12
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
   game.toast("爆裂の誓い / 爆発範囲から離れろ")
  game.enemy_died(self,proc);queue_free()
func _draw()->void:
 var size=145 if kind=="boss" else (104 if kind in ["elite","warden"] else (77 if kind=="hound" else 79))
 draw_set_transform(Vector2(0,8),0,Vector2(1,.4));draw_circle(Vector2.ZERO,radius*1.3,Color(0,0,0,.4));draw_set_transform(Vector2.ZERO)
 if kind=="boss":
  draw_arc(Vector2.ZERO,radius+8,0,TAU,48,Color("8cf3d2") if state=="recover" else Color("e9b171"),3,true)
  if phase==2:
   for side in [-1,1]:
    var wing=PackedVector2Array([Vector2(side*28,-24),Vector2(side*123,-104),Vector2(side*91,-10),Vector2(side*54,12)])
    draw_colored_polygon(wing,Color(.93,.35,.18,.36));draw_polyline(wing,Color("ffc489"),2,true)
   draw_arc(Vector2(0,-83),39,PI,TAU,32,Color("ffcc87"),4,true)
 elif kind=="elite":
  draw_arc(Vector2.ZERO,radius+9,0,TAU,48,Color(affix_color(),.72),3,true)
  draw_arc(Vector2.ZERO,radius+14,age*.7,age*.7+PI*1.15,32,Color(affix_color(),.34),2,true)
 var tint=Color(2.7,2.7,2.7) if flash>0 else Color.WHITE
 if kind=="boss" and phase==2 and flash<=0:tint=Color(1.3,.75,.56)
 if kind=="summoner" and flash<=0:tint=Color(.85,.7,1.3)
 if state=="spawn":tint.a=clampf(1-timer/(1.5 if kind=="boss" else .65),.15,1)
 if slow_time>0 and flash<=0:tint=Color(.65,1,1.12)
 draw_set_transform(Vector2(0,sin(age*7)*(2.2 if state=="approach" else .5)),sin(age*7)*.025 if state=="approach" else 0,Vector2(1 if aim.x>=0 else -1,1))
 draw_texture_rect(texture,Rect2(-size*.5,-size*.76,size,size),false,tint);draw_set_transform(Vector2.ZERO)
 if kind=="warden" and shield_break<=0:
  draw_arc(Vector2(0,-10),36,aim.angle()-1.05,aim.angle()+1.05,28,Color("b4e3f2"),7,true)
 if kind=="summoner":draw_arc(Vector2(0,-57),25,age,age+TAU*.8,32,Color("dfa8ff"),3,true)
 if burn_time>0:draw_arc(Vector2.ZERO,radius+4,0,TAU,32,Color("ffa45e"),3,true)
 if hp<max_hp and kind!="boss":
  var w=62 if kind=="elite" else 42
  draw_rect(Rect2(-w/2.0,-size*.81,w,5),Color("131824"));draw_rect(Rect2(-w/2.0,-size*.81,w*maxf(0,hp/max_hp),5),Color("d3a281") if kind=="elite" else Color("ab6b65"))
