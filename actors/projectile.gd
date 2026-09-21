class_name SpiritProjectile
extends Node2D
var game
var normal_group=-1
var normal_serial=-1
var chain_kind=""
var homing_target=null
var velocity=Vector2.ZERO
var damage_types=[]
var bounces=0
var tier_shield=false
var damage=10.0
var friendly=false
var pierce=0
var life=3.0
var radius=9.0
var color=Color("c188e6")
var hit_ids=[]
var dead=false
var secondary_effect=false
var explosion_radius=0.0
var explosion_damage=0.0
var slow_on_hit=0.0
var can_return=false
var returning=false
var chain_on_hit=false
var tail:Array[Vector2]=[]
func tick(dt:float)->void:
 life-=dt
 if life<=0:
  if try_return():return
  remove();return
 if is_instance_valid(homing_target) and not homing_target.dead and game.dungeon.line_clear(position,homing_target.position):
  velocity=velocity.lerp((homing_target.position-position).normalized()*velocity.length(),minf(1,dt*10)).normalized()*velocity.length()
 var next=position+velocity*dt
 if not game.dungeon.line_clear(position,next):
  game.fx.burst(position,color,5,65)
  if bounces>0:
   bounces-=1;velocity=-velocity;return
  if try_return():return
  remove();return
 var previous=position
 position=next;tail.push_front(position)
 if tail.size()>7:tail.pop_back()
 if friendly:
  for e in game.enemies.duplicate():
   if e.dead or e.state in ["spawn","transform"] or e.get_instance_id() in hit_ids:continue
   if e.position.distance_to(Geometry2D.get_closest_point_to_segment(e.position,previous,position))<e.radius+radius:
    hit_ids.append(e.get_instance_id())
    if tier_shield and hit_ids.size()>=2:
     tier_shield=false;game.player.barrier=minf(game.player.barrier+8,maxf(20,game.player.stats.shield_max));game.player.barrier_time=5
    var crit=not secondary_effect and game.rng.randf()<game.player.stats.crit
    e.take_damage((damage*DamageModel.multiplier(e.kind,damage_types,game.player.stats) if not damage_types.is_empty() else damage)*(1+game.player.stats.crit_damage if crit else 1),velocity.normalized()*100,crit,secondary_effect)
    if normal_group>=0:
     WeaponActionResolver.normal_hit(game.player,normal_group,normal_serial)
     if not chain_kind.is_empty():ChainResolver.mark(e,chain_kind)
    if crit:game.critical_effect(position)
    if slow_on_hit>0:e.slow_time=maxf(e.slow_time,slow_on_hit)
    if chain_on_hit:
     chain_on_hit=false;game.chain_lightning(position,damage*.35,e)
    if explosion_radius>0:
     game.area_damage(position,explosion_radius,explosion_damage,true);game.fx.ring(position,explosion_radius,Color("ffcb85"),.45);game.sound.play("nova",.5)
     explosion_radius=0
    game.fx.burst(position,color,9,120)
    if pierce<=0:
     if try_return():return
     remove();return
    pierce-=1
 elif game.player.position.distance_to(Geometry2D.get_closest_point_to_segment(game.player.position,previous,position))<19+radius:game.player.take_damage(damage,velocity.normalized()*80);remove();return
 queue_redraw()
func try_return()->bool:
 if not friendly or not can_return or returning:return false
 returning=true;life=2;damage*=.6;pierce=9;hit_ids.clear();secondary_effect=true
 velocity=(game.player.position-position).normalized()*maxf(400,velocity.length());return true
func remove()->void:
 if dead:return
 dead=true;game.projectiles.erase(self);queue_free()
func _draw()->void:
 for i in range(1,tail.size()):draw_line(tail[i]-position,tail[i-1]-position,Color(color,(1-float(i)/tail.size())*.45),radius*1.5,true)
 if not friendly:draw_circle(Vector2.ZERO,radius+3,Color("1d1229"));draw_arc(Vector2.ZERO,radius+2,0,TAU,24,Color("fff5d4"),2,true)
 draw_circle(Vector2.ZERO,radius*2.1,Color(color,.12));draw_circle(Vector2.ZERO,radius,color);draw_circle(Vector2.ZERO,radius*.43,Color("f4f8dc"))
