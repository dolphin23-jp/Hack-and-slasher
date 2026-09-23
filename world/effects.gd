class_name Effects
extends Node2D
var particles=[]
var rings=[]
var numbers=[]
var slashes=[]
var arcs=[]
var weapon_trails=[]
var sigils=[]
const TRAIL_LIMIT=48
const SIGIL_LIMIT=16
var font=preload("res://assets/fonts/Body.ttf")
func burst(p:Vector2,c:Color,count:int=12,force:float=140)->void:
 for i in range(count):
  if particles.size()>=450:particles.pop_front()
  particles.append({"p":p,"v":Vector2.from_angle(randf()*TAU)*randf_range(force*.3,force),"life":randf_range(.2,.65),"c":c,"size":randf_range(1.5,4.5)})
func ring(p:Vector2,r:float,c:Color,duration:float=.45)->void:
 if rings.size()>=64:rings.pop_front()
 rings.append({"p":p,"r":r,"c":c,"life":duration,"max":duration})
func number(p:Vector2,t:String,c:Color,big:bool=false)->void:
 if numbers.size()>65:numbers.pop_front()
 numbers.append({"p":p+Vector2(randf_range(-20,20),-48),"text":t,"c":c,"life":.85,"big":big})
func slash(p:Vector2,dir:Vector2,r:float,c:Color,heavy:bool=false,reverse:bool=false)->void:
 if slashes.size()>=64:slashes.pop_front()
 slashes.append({"p":p,"angle":dir.angle(),"reverse":reverse,"r":r,"c":c,"life":.22 if heavy else .16,"max":.22 if heavy else .16})
func lightning(a:Vector2,b:Vector2)->void:
 if arcs.size()>=48:arcs.pop_front()
 var points=PackedVector2Array([a])
 for i in range(1,6):points.append(a.lerp(b,i/6.0)+Vector2(randf_range(-14,14),randf_range(-14,14)))
 points.append(b);arcs.append({"points":points,"life":.22})
func tick(dt:float)->void:
 for i in range(particles.size()-1,-1,-1):
  var p=particles[i];p.life-=dt;p.p+=p.v*dt;p.v*=maxf(0,1-dt*4)
  if p.life<=0:particles.remove_at(i)
 for list in [rings,numbers,slashes,arcs,weapon_trails,sigils]:
  for i in range(list.size()-1,-1,-1):
   list[i].life-=dt
   if list[i].has("text"):list[i].p.y-=dt*31
   if list[i].life<=0:list.remove_at(i)
 queue_redraw()
func _draw()->void:
 draw_weapon_trails()
 draw_sigils()
 for p in particles:draw_line(p.p,p.p-p.v.normalized()*p.size*2,Color(p.c,clampf(p.life*3,0,1)),p.size,true)
 for r in rings:
  var t=1-r.life/r.max;draw_arc(r.p,r.r*(.3+.7*t),0,TAU,70,Color(r.c,(1-t)*.9),3*(1-t)+1,true)
 for s in slashes:
  var t=1-s.life/s.max
  var sweep=1-t if s.get("reverse",false) else t
  draw_arc(s.p,s.r*(.72+t*.28),s.angle-1.2+sweep*.6,s.angle+.8+sweep*.6,28,Color(s.c,1-t),13*(1-t)+1,true)
  draw_arc(s.p,s.r*.88,s.angle-1.05+sweep*.6,s.angle+.7+sweep*.6,24,Color(1,1,.92,(1-t)*.9),2,true)
 for a in arcs:
  draw_polyline(a.points,Color(.3,.75,1,a.life*2.7),9,true);draw_polyline(a.points,Color(.8,1,1,a.life*4),2,true)
 for n in numbers:
  var size=27 if n.big else 19;var pos=n.p-font.get_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size)*Vector2(.5,0)
  draw_string_outline(font,pos,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0,0,0,minf(1,n.life*4)))
  draw_string(font,pos,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(n.c,minf(1,n.life*4)))

func weapon(p:Vector2,aim:Vector2,kind:String,reach:float,style:String="normal")->void:
 if weapon_trails.size()>=TRAIL_LIMIT:weapon_trails.pop_front()
 var duration=.22 if style=="normal" else .38
 weapon_trails.append({"p":p,"angle":aim.angle(),"kind":kind,"r":reach,"style":style,"life":duration,"max":duration})
func recipe(p:Vector2,ids:Array,finisher:bool=false)->void:
 if ids.is_empty() and not finisher:return
 if sigils.size()>=SIGIL_LIMIT:sigils.pop_front()
 sigils.append({"p":p,"ids":ids.duplicate(),"finisher":finisher,"life":.5,"max":.5})
func draw_weapon_trails()->void:
 for w in weapon_trails:
  var t=1-w.life/w.max;var color=Color(WeaponActionResolver.ARTS[w.kind].color,1-t)
  var r=minf(w.r,340);var width=3.0 if w.style=="normal" else 6.0
  draw_set_transform(w.p,w.angle)
  match String(w.kind):
   "sword":draw_arc(Vector2.ZERO,r*(.72+.28*t),-1.25+t*.5,1.0+t*.5,28,color,width+4*(1-t),true)
   "scythe":
    draw_arc(Vector2.ZERO,r,-PI+t*TAU,PI+t*TAU,48,color,width,true)
    draw_line(Vector2.from_angle(t*TAU)*r*.45,Vector2.from_angle(t*TAU)*r,color,width,true)
   "spear":
    var tip=Vector2(r*(.35+.65*t),0)
    draw_line(Vector2(-20,0),tip,color,width,true)
    draw_polyline(PackedVector2Array([tip+Vector2(-28,-13),tip,tip+Vector2(-28,13)]),color,width,true)
   "staff":
    draw_arc(Vector2(30,0),24+12*t,0,TAU,24,color,width,true)
    for side in [-1,1]:draw_line(Vector2(35,side*12),Vector2(r*(.4+.6*t),side*12),color,width,true)
   "fist":
    for i in range(3):
     var at=Vector2(35+(i+1)*r*.18*(.5+t),(-1 if i%2==0 else 1)*18)
     draw_colored_polygon(PackedVector2Array([at+Vector2(-12,0),at+Vector2(0,-9),at+Vector2(20,0),at+Vector2(0,9)]),color)
   "mace":
    var at=Vector2(r*.5,0)
    draw_arc(at,r*.5*t,0,TAU,28,color,width,true)
    for i in range(6):
     var dir=Vector2.from_angle(i*TAU/6)
     draw_polyline(PackedVector2Array([at,at+dir*r*.25+dir.orthogonal()*10,at+dir*r*.55*t]),color,width,true)
   "spellblade":
    draw_arc(Vector2.ZERO,r*.65,-1.1+t*.5,.9+t*.5,24,color,width,true)
    for side in [-1,1]:draw_line(Vector2(35,side*18),Vector2(r*(.45+.55*t),side*40),color,width,true)
  if w.style!="normal":
   draw_arc(Vector2.ZERO,32,0,TAU,24,Color(color,.8*(1-t)),2,true)
   if w.style=="finisher":draw_arc(Vector2.ZERO,48,0,TAU,24,Color("ffe4a3",1-t),3,true)
  draw_set_transform(Vector2.ZERO)
func draw_sigils()->void:
 for s in sigils:
  var t=1-s.life/s.max;var count=3 if s.finisher else maxi(1,s.ids.size())
  for j in range(count):
   var index=j if s.finisher else 0
   if not s.finisher:
    for i in range(ChainResolver.RECIPES.size()):
     if ChainResolver.RECIPES[i].id==s.ids[j]:index=i
   var color=Color.from_hsv(float(index)/10,.42,1,1-t)
   var radius=(95 if s.finisher else 55)+t*50+j*12
   var points=PackedVector2Array()
   var sides=3+index%5
   for n in range(sides+1):points.append(s.p+Vector2.from_angle(n*TAU/sides+t+j)*radius)
   draw_polyline(points,color,3 if s.finisher else 2,true)
