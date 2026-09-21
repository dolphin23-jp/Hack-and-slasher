class_name WorldDrop
extends Node2D
var game
var item={}
var kind="item"
var age=0.0
var taken=false
var icon:Texture2D
var font=preload("res://assets/fonts/Body.ttf")
func setup(g,p:Vector2,value:Dictionary,type:String="item")->void:
 game=g;position=p;item=value;kind=type
 if font.fallbacks.is_empty():
  var jp_path="res://assets/fonts/NotoSansJP-Regular.subset.ttf"
  if ResourceLoader.exists(jp_path):font.fallbacks=[load(jp_path)]
 icon=load("res://assets/icons/"+("potion" if kind=="health" else ("chest" if kind=="chest" else ("sword" if item.slot=="weapon" else item.slot)))+".svg")
func tick(dt:float)->void:
 age+=dt
 if taken:return
 var d=position.distance_to(game.player.position)
 if kind=="health" and d<95:
  position=position.move_toward(game.player.position,dt*280)
  if d<24:game.player.heal(game.player.stats.hp*.07);take()
 elif kind=="item" and d<42 and age>.45:game.collect(self)
 queue_redraw()
func take()->void:
 if taken:return
 taken=true;game.drops.erase(self);queue_free()
func _draw()->void:
 var rarity=int(item.get("rarity",0));var c=Color("8fc499") if kind=="health" else ItemDB.COLORS[rarity]
 if kind=="chest":c=Color("e7c281")
 draw_set_transform(Vector2(0,7),0,Vector2(1,.35));draw_circle(Vector2.ZERO,23,Color(0,0,0,.5));draw_set_transform(Vector2.ZERO)
 if kind=="item" and rarity>0:
  draw_colored_polygon(PackedVector2Array([Vector2(-13,4),Vector2(13,4),Vector2(3,-120-rarity*14),Vector2(-3,-120-rarity*14)]),Color(c,.06+rarity*.024))
  draw_line(Vector2.ZERO,Vector2(0,-102-rarity*17),Color(c,.3),2,true);draw_arc(Vector2.ZERO,22+sin(age*2)*2,0,TAU,40,Color(c,.55),2,true)
 var size=52 if kind=="chest" else (29 if kind=="health" else 36)
 draw_texture_rect(icon,Rect2(-size/2.0,-size+12+sin(age*3)*3,size,size),false)
 if kind=="item" and rarity==3:
  var pulse=.65+.35*sin(age*3)
  draw_line(Vector2(0,4),Vector2(0,-205),Color(c,.5+pulse*.3),4,true)
  draw_arc(Vector2(0,-44),18+sin(age*2)*3,0,TAU,32,Color("fff0c1"),2,true)
  for side in [-1,1]:draw_line(Vector2(side*10,-195),Vector2(0,-205),Color("ffe4a3"),2,true)
 if kind=="item" and (game.player.position.distance_to(position)<170 or (rarity>=2 and game.enemies.is_empty())):
  var near:bool=game.player.position.distance_to(position)<210
  var detail:String="ティア %d / %s"%[int(item.tier),ItemDB.slot_text(String(item.slot))]
  var detail_color:=Color("9aabb0")
  if near and rarity<3:
   var delta:float=game.player.item_upgrade_ratio(item)
   if delta>.035:
    detail+="  /  ▲ 強化 +%d%%"%maxi(1,roundi(delta*100.0));detail_color=Color("91d7b8")
   elif delta<-.035:
    detail+="  /  ▼ 弱体 %d%%"%roundi(delta*100.0);detail_color=Color("dc8f84")
   else:
    detail+="  /  ≈ 同等";detail_color=Color("c9c3a5")
  if rarity==3:detail+=" / "+BuildDB.SET_NAMES.get(ItemDB.set_of(item),"固有効果")
  var name_w:float=font.get_string_size(item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
  var detail_w:float=font.get_string_size(detail,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
  var w:float=maxf(name_w,detail_w)
  draw_rect(Rect2(-w/2-9,18,w+18,43),Color("101b25"))
  draw_string(font,Vector2(-name_w/2,35),item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,c)
  draw_string(font,Vector2(-detail_w/2,53),detail,HORIZONTAL_ALIGNMENT_LEFT,-1,11,detail_color)
 if kind=="chest":
  var prompt="[C] 開く"
  if game.profile.settings.touch:prompt="「回収」で開く"
  elif is_instance_valid(game.ui) and game.ui.pad_active:prompt="十字上で開く"
  var prompt_w=font.get_string_size(prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
  draw_string(font,Vector2(-prompt_w/2,38),prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,13,c)
