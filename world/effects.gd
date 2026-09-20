class_name Effects
extends Node2D
var particles=[]
var rings=[]
var numbers=[]
var slashes=[]
var arcs=[]
var font=preload("res://assets/fonts/Body.ttf")
func burst(p:Vector2,c:Color,count:int=12,force:float=140)->void:
 for i in range(count):
  if particles.size()>=450:particles.pop_front()
  particles.append({"p":p,"v":Vector2.from_angle(randf()*TAU)*randf_range(force*.3,force),"life":randf_range(.2,.65),"c":c,"size":randf_range(1.5,4.5)})
func ring(p:Vector2,r:float,c:Color,duration:float=.45)->void:rings.append({"p":p,"r":r,"c":c,"life":duration,"max":duration})
func number(p:Vector2,t:String,c:Color,big:bool=false)->void:
 if numbers.size()>65:numbers.pop_front()
 numbers.append({"p":p+Vector2(randf_range(-20,20),-48),"text":t,"c":c,"life":.85,"big":big})
func slash(p:Vector2,dir:Vector2,r:float,c:Color,heavy:bool=false)->void:
 slashes.append({"p":p,"angle":dir.angle(),"r":r,"c":c,"life":.22 if heavy else .16,"max":.22 if heavy else .16})
func lightning(a:Vector2,b:Vector2)->void:
 var points=PackedVector2Array([a])
 for i in range(1,6):points.append(a.lerp(b,i/6.0)+Vector2(randf_range(-14,14),randf_range(-14,14)))
 points.append(b);arcs.append({"points":points,"life":.22})
func tick(dt:float)->void:
 for i in range(particles.size()-1,-1,-1):
  var p=particles[i];p.life-=dt;p.p+=p.v*dt;p.v*=maxf(0,1-dt*4)
  if p.life<=0:particles.remove_at(i)
 for list in [rings,numbers,slashes,arcs]:
  for i in range(list.size()-1,-1,-1):
   list[i].life-=dt
   if list[i].has("text"):list[i].p.y-=dt*31
   if list[i].life<=0:list.remove_at(i)
 queue_redraw()
func _draw()->void:
 for p in particles:draw_line(p.p,p.p-p.v.normalized()*p.size*2,Color(p.c,clampf(p.life*3,0,1)),p.size,true)
 for r in rings:
  var t=1-r.life/r.max;draw_arc(r.p,r.r*(.3+.7*t),0,TAU,70,Color(r.c,(1-t)*.9),3*(1-t)+1,true)
 for s in slashes:
  var t=1-s.life/s.max
  draw_arc(s.p,s.r*(.72+t*.28),s.angle-1.2+t*.6,s.angle+.8+t*.6,28,Color(s.c,1-t),13*(1-t)+1,true)
  draw_arc(s.p,s.r*.88,s.angle-1.05+t*.6,s.angle+.7+t*.6,24,Color(1,1,.92,(1-t)*.9),2,true)
 for a in arcs:
  draw_polyline(a.points,Color(.3,.75,1,a.life*2.7),9,true);draw_polyline(a.points,Color(.8,1,1,a.life*4),2,true)
 for n in numbers:
  var size=27 if n.big else 19;var pos=n.p-font.get_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size)*Vector2(.5,0)
  draw_string_outline(font,pos,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0,0,0,minf(1,n.life*4)))
  draw_string(font,pos,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(n.c,minf(1,n.life*4)))
