class_name CombatOverlay
extends Node2D
var game
func _draw()->void:
 if not is_instance_valid(game.player):return
 for e in game.enemies:
  if e.dead or e.state not in ["windup","chain_windup"]:continue
  var boss_color={"forge_boss":Color("ffb46f"),"thorn_boss":Color("e69bc5"),"miniboss":Color("d8bd8b"),"boss":Color("f3c184")}
  var c=boss_color.get(e.kind,Color("c79de7") if e.kind in ["cantor","weaver","summoner"] else Color("e09082"))
  var t=clampf(1-e.timer/maxf(.01,e.windup),0,1);var p=e.position
  var charge=e.kind in ["hound","lancer"] or e.state=="chain_windup"
  charge=charge or (e.kind=="champion" and e.pattern%3==2) or (e.kind=="miniboss" and e.pattern%3==2)
  charge=charge or (e.kind in ["boss","forge_boss"] and e.pattern%4==3)
  if charge:
   var side=e.aim.orthogonal()*(e.radius+7)
   var length=500 if e.is_boss_like() else (390 if e.kind in ["lancer","champion"] else 300)
   var finish=p+e.aim*length
   draw_colored_polygon(PackedVector2Array([p-side,p+side,finish+side,finish-side]),Color(c,.12+t*.15))
   draw_line(p-side,finish-side,c,2,true);draw_line(p+side,finish+side,c,2,true);draw_line(p,finish,Color(c,.55),3,true)
  elif e.kind in ["cantor","weaver"]:
   var angles=[-.21,0.0,.21] if e.kind=="cantor" else [0.0]
   for a in angles:draw_line(p,p+e.aim.rotated(a)*(470 if e.kind=="cantor" else 520),Color(c,.35+t*.45),2.5,true)
   draw_arc(p,30,0,TAU*t,32,c,3,true)
  elif e.kind=="summoner":
   draw_arc(p,80,0,TAU*t,48,Color("e5b1ff"),4,true);draw_circle(p,80,Color(.7,.3,1,.12))
  elif e.kind in ["warden","brute"] or (e.kind=="champion" and e.pattern%3==1) or (e.kind=="forge_boss" and e.pattern%4==0):
   var r=205 if e.kind=="forge_boss" else (165 if e.kind=="champion" else (132 if e.kind=="brute" else 115))
   draw_circle(p,r,Color(c,.055+t*.09));draw_arc(p,r,0,TAU,64,c,2,true);draw_arc(p,r*t,0,TAU,64,Color(c,.45),3,true)
  elif (e.kind=="boss" and e.pattern%4==2) or (e.kind=="miniboss" and e.pattern%3==1) or (e.kind=="thorn_boss" and e.pattern%4==0):
   var r=210 if e.kind=="boss" else (190 if e.kind=="miniboss" else 205)
   var safe=Vector2.from_angle(e.ring_gap)
   draw_colored_polygon(PackedVector2Array([p,p+safe.rotated(-.5)*330,p+safe.rotated(.5)*330]),Color(.3,1,.77,.18))
   draw_line(p+safe*80,p+safe*320,Color("8aefce"),4,true)
   draw_circle(p,r,Color(c,.055+t*.09));draw_arc(p,r,0,TAU,64,c,2,true);draw_arc(p,r*t,0,TAU,64,Color(c,.45),3,true)
  elif e.kind in ["boss","forge_boss","thorn_boss"] and e.pattern%4==1:
   draw_arc(p,72,0,TAU*t,40,c,4,true)
  else:
   var r=235 if e.is_boss_like() else (200 if e.kind=="champion" else 76)
   var half=1.45 if e.kind in ["boss","miniboss","champion"] else (0.78 if e.kind in ["forge_boss","thorn_boss"] else (1.45 if e.kind=="elite" else 1.12))
   var points=PackedVector2Array([p])
   for i in range(29):points.append(p+e.aim.rotated(-half+2*half*i/28)*r)
   draw_colored_polygon(points,Color(c,.075+t*.17));draw_arc(p,r,e.aim.angle()-half,e.aim.angle()+half,32,c,2.5,true)
   draw_line(p,points[1],Color(c,.75),1.5,true);draw_line(p,points[-1],Color(c,.75),1.5,true)
 for h in game.hazards:
  var c=Color("6df0c2") if h.friendly else Color("ff846b")
  draw_circle(h.p,h.radius,Color(c,.075))
  if h.delay>0:
   draw_arc(h.p,h.radius+3,0,TAU,64,Color("151321"),5,true);draw_arc(h.p,h.radius,0,TAU,64,c,3.5,true);draw_arc(h.p,h.radius*(1-h.delay/h.max_delay),0,TAU,48,Color(c,.55),2,true)
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
