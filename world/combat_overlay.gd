class_name CombatOverlay
extends Node2D
var game
func _draw()->void:
 if not is_instance_valid(game.player):return
 for e in game.enemies:
  if e.dead or e.state!="windup":continue
  var c=Color("f3c184") if e.kind=="boss" else (Color("c79de7") if e.kind=="cantor" else Color("e09082"))
  var t=clampf(1-e.timer/e.windup,0,1);var p=e.position
  if e.kind=="hound" or (e.kind=="boss" and e.pattern%4==3):
   var side=e.aim.orthogonal()*(e.radius+5);var end=p+e.aim*(480 if e.kind=="boss" else 300)
   draw_colored_polygon(PackedVector2Array([p-side,p+side,end+side,end-side]),Color(c,.12+t*.13))
   draw_line(p-side,end-side,c,2,true);draw_line(p+side,end+side,c,2,true);draw_line(p,end,Color(c,.5),3,true)
  elif e.kind=="cantor":draw_line(p,p+e.aim*450,Color(c,.15+t*.35),2,true);draw_arc(p,30,0,TAU*t,32,c,3,true)
  elif e.kind=="warden" or (e.kind=="boss" and e.pattern%4==2):
   var r=115 if e.kind=="warden" else 210
   draw_circle(p,r,Color(c,.055+t*.09));draw_arc(p,r,0,TAU,64,c,2,true);draw_arc(p,r*t,0,TAU,64,Color(c,.45),3,true)
  elif e.kind=="boss" and e.pattern%4==1:draw_arc(p,62,0,TAU*t,40,c,4,true)
  else:
   var r=220 if e.kind=="boss" else (178 if e.kind=="elite" else 76);var half=1.45 if e.kind in ["boss","elite"] else 1.12
   var points=PackedVector2Array([p])
   for i in range(29):points.append(p+e.aim.rotated(-half+2*half*i/28)*r)
   draw_colored_polygon(points,Color(c,.075+t*.17));draw_arc(p,r,e.aim.angle()-half,e.aim.angle()+half,32,c,2.5,true)
   draw_line(p,points[1],Color(c,.75),1.5,true);draw_line(p,points[-1],Color(c,.75),1.5,true)
 for h in game.hazards:
  var c=Color("efa65c") if h.friendly else Color("f5a58a")
  draw_circle(h.p,h.radius,Color(c,.075))
  if h.delay>0:
   draw_arc(h.p,h.radius,0,TAU,64,c,2.5,true);draw_arc(h.p,h.radius*(1-h.delay/h.max_delay),0,TAU,48,Color(c,.55),2,true)
   draw_line(h.p-Vector2(12,0),h.p+Vector2(12,0),c,2);draw_line(h.p-Vector2(0,12),h.p+Vector2(0,12),c,2)
  else:
   for j in range(6):
    var p=h.p+Vector2.from_angle(j*TAU/6+game.elapsed)*(h.radius*.55)
    draw_line(p,p-Vector2(0,12+sin(game.elapsed*9+j)*7),Color(c,.65),3,true)
 if game.dungeon.active>=0:
  var room=game.dungeon.rooms[game.dungeon.active]
  for edge in game.dungeon.connections:
   if room.id not in edge:continue
   var other=game.dungeon.rooms[edge[1] if room.id==edge[0] else edge[0]].center;var dir=(other-room.center).normalized()
   var p=room.center+dir*(room.rect.size.x/2-10 if absf(dir.x)>.5 else room.rect.size.y/2-10);var side=dir.orthogonal()*87
   draw_line(p-side,p+side,Color(.35,.81,.78,.16),17,true);draw_line(p-side,p+side,Color("7fccbf"),2,true)
   for j in range(6):draw_circle((p-side).lerp(p+side,j/5.0),3,Color("b1e8d5"))
