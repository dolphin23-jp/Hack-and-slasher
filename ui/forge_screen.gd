class_name ForgeScreen
extends RefCounted
var opened=false
var slot="weapon"
var selected={}
var pending={}
var page=0
func open(target:String)->void:
 opened=true;slot=target;selected={};pending={};page=0
func candidates(p)->Array:return p.inventory.filter(func(it):return Forge.compatible(p.equipment[slot],it))
func act(u,action:String)->bool:
 var p=u.game.player
 if action=="fusion:cancel":opened=false;pending={};selected={};return true
 if action=="fusion:back":pending={};return true
 if action.begins_with("fusion:page:"):page=maxi(0,page+int(action.get_slice(":",2)));return true
 if action.begins_with("fusion:select:"):
  var list=candidates(p);var index=int(action.get_slice(":",2))
  if index>=0 and index<list.size():selected=list[index].duplicate(true)
  return true
 if action=="fusion:preview":
  pending=Forge.fusion_preview(p,slot,selected)
  if pending.is_empty():u.game.toast("素材を選び直してください");selected={}
  return true
 if action=="fusion:confirm":
  u.game.toast(Forge.confirm_fusion(p,pending));pending={};selected={};opened=false;return true
 return true
func draw(u)->void:
 var p=u.game.player
 u.dim();u.text("合成 / 消費する素材を選択",Vector2(50,65),29)
 u.button(Rect2(1180,30,210,48),"キャンセル","fusion:cancel")
 if not pending.is_empty():
  u.text("この1個を消費します",Vector2(720,116),23,u.GOLD,true)
  u.reliquary.detail(u,pending.target,Rect2(45,150,655,535),"強化する装備 / 保持")
  u.reliquary.detail(u,pending.donor,Rect2(720,150,670,535),"合成素材 / 消費")
  u.text("合成進行 %d → %d"%[pending.target.fusion,pending.target.fusion+pending.gain],Vector2(720,735),23,u.TEAL,true)
  u.button(Rect2(340,785,330,60),"素材を選び直す","fusion:back")
  u.button(Rect2(720,785,420,60),"この素材を消費して合成","fusion:confirm")
  return
 var list=candidates(p);var max_page=maxi(0,ceili(list.size()/6.0)-1);page=mini(page,max_page)
 u.text("同系統・同階級の候補 %d個 / ロック・お気に入りは除外"%list.size(),Vector2(50,116),17,u.MUTED)
 for i in range(page*6,mini(page*6+6,list.size())):
  var it=list[i];var y=155+(i%6)*86
  u.button(Rect2(45,y,580,75),it.name+" / "+ItemDB.RARITIES[int(it.rarity)],"fusion:select:"+str(i),selected==it)
  u.text("階%d / T%d / +%d / ロール %.0f%% / 合成 +%d"%[it.grade,it.tier,it.enhance,SalvagePolicy.quality(it)*100,1+int(it.rarity)],Vector2(62,y+63),14,u.TEAL)
 u.button(Rect2(45,700,145,48),"◀","fusion:page:-1",page>0)
 u.button(Rect2(210,700,210,48),"%d / %d ▶"%[page+1,max_page+1],"fusion:page:1",page<max_page)
 if not selected.is_empty():
  u.reliquary.detail(u,selected,Rect2(660,155,730,530),"選択中の消費素材")
  u.button(Rect2(810,750,480,60),"消費内容を確認","fusion:preview")
 else:u.text("左から素材を選んでください",Vector2(1020,365),21,u.MUTED,true)
