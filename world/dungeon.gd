class_name DungeonMap
extends Node2D
var game
var rooms=[]
var corridors:Array[Rect2]=[]
var obstacles:Array[Rect2]=[]
var connections=[[0,1],[1,2],[1,3],[2,4],[4,5],[5,6],[6,7],[7,8],[8,9]]
var cleared=[0]
var visited=[0]
var active=-1
var encounter_labels=["聖域","集会","骨の狩り","秘宝の試練","鉄の誓い","詠唱者の合唱","火の狩り","聖域","最後の行進","最後の鐘"]
var crest=preload("res://assets/icons/crest.svg")
func setup(g)->void:
 game=g
 var specs=[
 [Vector2(0,0),Vector2(940,660),"入口",0,0,0,"誓いは主が消えても残る。"],
 [Vector2(1240,0),Vector2(1050,760),"灰の大広間",1,3,8,"虚ろな群れを沈黙させろ。"],
 [Vector2(2510,0),Vector2(1070,780),"名を刻む納骨堂",2,3,10,"死者は武器を忘れない。"],
 [Vector2(1240,-1040),Vector2(1040,730),"隠された宝物庫",2,2,10,"任意の試練。その先に秘宝が待つ。"],
 [Vector2(3810,0),Vector2(1120,820),"誓いなき工房",3,3,10,"堕ちた騎士が最初の封印を守る。"],
 [Vector2(3810,-1090),Vector2(1120,790),"残り火の書庫",4,3,12,"詠唱者の歌う場所に立つな。"],
 [Vector2(5140,-1090),Vector2(1100,800),"壊れた回廊",5,4,11,"狩りは炎の中でしか終わらない。"],
 [Vector2(5140,0),Vector2(1030,780),"静かな礼拝堂",5,0,0,"十分に備えろ。この先に王がいる。"],
 [Vector2(6470,0),Vector2(1160,860),"いばらの行進",6,4,12,"誓いに縛られた最後の者を倒せ。"],
 [Vector2(7990,0),Vector2(1460,1090),"鐘なき王座",7,1,1,"彼のために鳴る鐘はない。"]]
 for i in range(specs.size()):
  var s=specs[i];rooms.append({"id":i,"center":s[0],"rect":Rect2(s[0]-s[1]/2,s[1]),"name":s[2],"tier":s[3],"waves":s[4],"count":s[5],"lore":s[6],"encounter":encounter_labels[i]})
 for link in connections:
  var a=rooms[link[0]].center;var b=rooms[link[1]].center
  if absf(a.x-b.x)>10:corridors.append(Rect2(Vector2(minf(a.x,b.x),a.y-96),Vector2(absf(a.x-b.x),192)))
  else:corridors.append(Rect2(Vector2(a.x-96,minf(a.y,b.y)),Vector2(192,absf(a.y-b.y))))
 for room in rooms:
  if room.id==0:continue
  for x in [room.rect.position.x+150,room.rect.end.x-150]:
   for y in [room.rect.position.y+155,room.rect.end.y-155]:obstacles.append(Rect2(x-28,y-28,56,56))
 queue_redraw()
func floor_at(p:Vector2)->bool:
 for room in rooms:
  if room.rect.has_point(p):return true
 for r in corridors:
  if r.has_point(p):return true
 return false
func walkable(p:Vector2,radius:float=16,sealed:bool=true)->bool:
 if sealed and active>=0 and not rooms[active].rect.grow(-radius).has_point(p):return false
 for off in [Vector2.ZERO,Vector2(radius,0),Vector2(-radius,0),Vector2(0,radius),Vector2(0,-radius),Vector2(radius*.7,radius*.7),Vector2(-radius*.7,radius*.7),Vector2(radius*.7,-radius*.7),Vector2(-radius*.7,-radius*.7)]:
  if not floor_at(p+off):return false
 for obs in obstacles:
  if obs.grow(radius).has_point(p):return false
 return true
func move_body(p:Vector2,motion:Vector2,radius:float)->Vector2:
 var steps=maxi(1,ceili(motion.length()/12));var delta=motion/steps
 for i in range(steps):
  if walkable(p+delta,radius):p+=delta
  else:
   if walkable(p+Vector2(delta.x,0),radius):p.x+=delta.x
   if walkable(p+Vector2(0,delta.y),radius):p.y+=delta.y
 return p
func line_clear(a:Vector2,b:Vector2)->bool:
 var steps=maxi(1,ceili(a.distance_to(b)/24))
 for i in range(1,steps+1):
  if not walkable(a.lerp(b,float(i)/steps),3):return false
 return true
func room_at(p:Vector2)->int:
 for room in rooms:
  if room.rect.grow(-55).has_point(p):return room.id
 return -1
func spawn_point(id:int,index:int)->Vector2:
 var r=rooms[id].rect.grow(-115)
 for attempt in range(40):
  var p=Vector2(game.rng.randf_range(r.position.x,r.end.x),game.rng.randf_range(r.position.y,r.end.y))
  if walkable(p,35) and p.distance_to(game.player.position)>240:return p
 return rooms[id].center+Vector2(0,-190+index*4)
func _draw()->void:
 for r in corridors:
  draw_rect(r.grow(22),Color("0a111c"));draw_rect(r,Color("19232c"));draw_rect(r.grow(-10),Color("4a4840"),false,2)
 for room in rooms:draw_room(room)
 for obs in obstacles:
  draw_set_transform(obs.get_center()+Vector2(12,21),0,Vector2(1.2,.6));draw_circle(Vector2.ZERO,49,Color(0,0,0,.36));draw_set_transform(Vector2.ZERO)
  draw_rect(obs.grow(6),Color("131f28"));draw_rect(obs,Color("33424b"))
  draw_rect(Rect2(obs.position-Vector2(4,15),obs.size+Vector2(8,3)),Color("55616a"))
  draw_rect(Rect2(obs.position-Vector2(4,15),obs.size+Vector2(8,3)),Color("858a7b"),false,2)
  draw_rect(Rect2(obs.position+Vector2(7,-8),obs.size-Vector2(14,6)),Color("3c4c56"))
  draw_line(obs.position+Vector2(12,7),obs.position+Vector2(12,51),Color("677780"),3)
  draw_line(obs.position+Vector2(42,7),obs.position+Vector2(42,51),Color("172831"),3)
func draw_room(room:Dictionary)->void:
 var r=room.rect;var p=r.position;var center=room.center
 draw_rect(r.grow(35),Color("060e17"));draw_rect(Rect2(p-Vector2(30,47),r.size+Vector2(60,30)),Color("202e39"))
 draw_rect(r.grow(15),Color("445059"),false,3);draw_rect(r,Color("202d36"))
 for y in range(ceili(r.size.y/80)):
  for x in range(ceili(r.size.x/80)):
   var tile=Rect2(p+Vector2(x*80,y*80),Vector2(minf(79,r.size.x-x*80),minf(79,r.size.y-y*80)))
   var v=sin(x*23+y*7+room.id*31)*.016
   draw_rect(tile,Color(.127+v,.166+v,.197+v))
   draw_line(tile.position+Vector2(1,1),tile.position+Vector2(tile.size.x,1),Color(.24,.3,.34,.28),1)
   if (x*11+y*3+room.id)%13==0:
    var a=tile.position+Vector2(12,31);draw_polyline(PackedVector2Array([a,a+Vector2(18,-12),a+Vector2(22,7),a+Vector2(43,14)]),Color(.045,.073,.1,.65),1,true)
 if room.id in [1,4,8,9]:
  var rug=Rect2(p.x+70,center.y-53,r.size.x-140,106)
  draw_rect(rug,Color("493137") if room.id in [1,9] else Color("374440"));draw_rect(rug.grow(-6),Color("947b59"),false,1)
  for j in range(int(rug.size.x/75)):
   var cp=rug.position+Vector2(35+j*75,53)
   draw_polyline(PackedVector2Array([cp+Vector2(0,-13),cp+Vector2(12,0),cp+Vector2(0,13),cp+Vector2(-12,0),cp+Vector2(0,-13)]),Color(.66,.51,.32,.35),1,true)
 if room.id in [2,3,5,6]:
  for signum in [-1,1]:
   for j in range(4):
    var cp=center+Vector2((j-1.5)*130,signum*(r.size.y/2-99))
    draw_rect(Rect2(cp-Vector2(40,24),Vector2(80,48)),Color("131f29"))
    draw_rect(Rect2(cp-Vector2(36,32),Vector2(72,48)),Color("505657") if room.id in [2,6] else Color("50423b"))
    if room.id in [2,6]:
     draw_line(cp-Vector2(0,25),cp+Vector2(0,6),Color("b3a486"),3);draw_line(cp-Vector2(12,13),cp+Vector2(12,-13),Color("b3a486"),3)
    else:
     for k in range(8):draw_rect(Rect2(cp+Vector2(-32+k*8,-26),Vector2(5, 30)),[Color("817758"),Color("536960"),Color("7a5351")][k%3])
 draw_rect(r.grow(-38),Color("736d55"),false,2);draw_rect(r.grow(-45),Color("303f47"),false,2)
 var radius=239 if room.id==9 else 137
 draw_circle(center,radius,Color(.08,.14,.17,.35))
 for rr in [radius,radius-8,radius-27]:draw_arc(center,rr,0,TAU,88,Color(.36,.4,.35,.62),2,true)
 for i in range(12):
  var a=i*TAU/12;draw_line(center+Vector2.from_angle(a)*(radius-27),center+Vector2.from_angle(a)*radius,Color("646753"),2,true)
 draw_texture_rect(crest,Rect2(center-Vector2(63,63),Vector2(126,126)),false,Color(1,1,1,.27))
 for dx in [-260,260]:
  var wp=Vector2(center.x+dx,p.y-22)
  draw_rect(Rect2(wp-Vector2(35,22),Vector2(70,37)),Color("0a1623"));draw_rect(Rect2(wp-Vector2(28,20),Vector2(56,31)),Color("587c83"))
  for sx in [-16,0,16]:draw_line(wp+Vector2(sx,-20),wp+Vector2(sx,10),Color("1d303d"),4)
  draw_colored_polygon(PackedVector2Array([wp+Vector2(-27,0),wp+Vector2(27,0),wp+Vector2(174,350),wp+Vector2(16,350)]),Color(.52,.79,.82,.035))
 for off in [Vector2(72,77),Vector2(r.size.x-78,77),Vector2(72,r.size.y-75),r.size-Vector2(78,75)]:
  for j in range(3):
   var c=p+off+Vector2(j*10,j%2*6)
   for rad in [32,22,12]:draw_circle(c-Vector2(0,12),rad,Color(1,.68,.29,.026))
   draw_line(c,c-Vector2(0,12+j*3),Color("c6b699"),4);draw_circle(c-Vector2(0,14+j*3),2,Color("ffdead"))
 for link in connections:
  if room.id not in link:continue
  var other=rooms[link[1] if room.id==link[0] else link[0]].center;var dir=(other-center).normalized()
  var door=center+dir*(r.size.x/2 if absf(dir.x)>.5 else r.size.y/2)
  var size=Vector2(76,183) if absf(dir.x)>.5 else Vector2(183,76)
  draw_rect(Rect2(door-size/2,size),Color("26333b"))
  for signum in [-1,1]:
   var v=door+dir.orthogonal()*99*signum;draw_circle(v,16,Color("14242e"));draw_circle(v,9,Color("65706b"));draw_circle(v,3,Color("94bdb6"))
