class_name SpiritProjectile
extends Node2D
var game
var velocity=Vector2.ZERO
var damage=10.0
var friendly=false
var pierce=0
var life=3.0
var radius=9.0
var color=Color("c188e6")
var hit_ids=[]
var dead=false
var secondary_effect=false
var tail:Array[Vector2]=[]
func tick(dt:float)->void:
 life-=dt
 if life<=0:remove();return
 var next=position+velocity*dt
 if not game.dungeon.line_clear(position,next):game.fx.burst(position,color,5,65);remove();return
 position=next;tail.push_front(position)
 if tail.size()>7:tail.pop_back()
 if friendly:
  for e in game.enemies.duplicate():
   if e.dead or e.get_instance_id() in hit_ids:continue
   if e.position.distance_to(position)<e.radius+radius:
    hit_ids.append(e.get_instance_id())
    var crit=not secondary_effect and game.rng.randf()<game.player.stats.crit
    e.take_damage(damage*(1+game.player.stats.crit_damage if crit else 1),velocity.normalized()*100,crit,secondary_effect)
    if crit:game.critical_effect(position)
    game.fx.burst(position,color,9,120)
    if pierce<=0:remove();return
    pierce-=1
 elif game.player.position.distance_to(position)<19+radius:game.player.take_damage(damage,velocity.normalized()*80);remove();return
 queue_redraw()
func remove()->void:
 if dead:return
 dead=true;game.projectiles.erase(self);queue_free()
func _draw()->void:
 for i in range(1,tail.size()):draw_line(tail[i]-position,tail[i-1]-position,Color(color,(1-float(i)/tail.size())*.45),radius*1.5,true)
 draw_circle(Vector2.ZERO,radius*2.1,Color(color,.12));draw_circle(Vector2.ZERO,radius,color);draw_circle(Vector2.ZERO,radius*.43,Color("f4f8dc"))
