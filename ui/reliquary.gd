class_name ReliquaryUI
extends RefCounted
const UNIQUE_TEXT=WeaponDB.UNIQUE_TEXT
var tab="equipment"
var target="weapon"
var forge_slot="weapon"
var inheritance=""
var stats_group=0
var back="title"
func act(u,action:String)->bool:
 var g=u.game;var p=g.player
 if action=="oaths":back=g.mode;g.mode="oaths";return true
 if action=="oath_back":g.mode=back;return true
 if action.begins_with("oath:"):
  if back!="title":g.toast("誓印の選択は次の探索の出発前に行えます");return true
  var key=action.get_slice(":",1);var active=g.profile.oaths.active
  if key in active:
   if active.size()<=1:g.toast("主誓印は1つ以上必要です");return true
   active.erase(key)
  elif active.size()<3:active.append(key)
  else:g.toast("主誓印1・副誓印2までです")
  g.profile.write_save();return true
 if action.begins_with("rank:"):
  if back!="title":g.toast("刻印の強化は出発前に行えます");return true
  var key=action.get_slice(":",1);var rank=int(g.profile.oaths.ranks.get(key,0));var price=(rank+1)*3
  if rank<3 and g.profile.oaths.points>=price:g.profile.oaths.points-=price;g.profile.oaths.ranks[key]=rank+1;g.profile.write_save()
  else:g.toast("誓片が不足、または解放済みです")
  return true
 if action.begins_with("tab:"):tab=action.get_slice(":",1);return true
 if action.begins_with("slot:"):target=action.get_slice(":",1);forge_slot=target;inheritance="";return true
 if action.begins_with("swap:"):
  var a=int(action.get_slice(":",1));Loadout.swap(p,a,(a+1)%3);return true
 if action=="equip_target":p.equip(u.selected,target);return true
 if action=="lock" or action=="favorite":
  if u.selected>=0 and u.selected<p.inventory.size():
   var it=p.inventory[u.selected];var key="locked" if action=="lock" else "favorite";it[key]=not it.get(key,false);g.save_run()
  return true
 if action=="bulk":
  for i in range(p.inventory.size()-1,-1,-1):
   if int(p.inventory[i].rarity)<=1 and not Forge.protected(p.inventory[i]):g.salvage(i)
  return true
 if action.begins_with("inherit:"):inheritance=action.get_slice(":",1);return true
 if action.begins_with("forge:"):
  g.toast(Forge.apply(p,p.equipment[forge_slot],action.get_slice(":",1),inheritance));return true
 if action=="stats_group":stats_group=(stats_group+1)%3;return true
 return false
func draw(u)->void:
 var p=u.game.player
 u.dim();u.text("聖遺物庫 / 三連の誓い",Vector2(40,55),30)
 u.button(Rect2(940,24,140,48),"装備","tab:equipment",tab=="equipment")
 u.button(Rect2(1090,24,140,48),"鍛冶","tab:forge",tab=="forge")
 u.button(Rect2(1240,24,150,48),"戻る","return_victory" if u.game.mode=="victory_inventory" else "inventory")
 for i in range(3):
  var slot=Loadout.WEAPONS[i];var it=p.equipment[slot];var x=40+i*455
  u.panel(Rect2(x,94,430,105),u.PANEL,ItemDB.COLORS[int(it.rarity)])
  u.button(Rect2(x+10,104,300,48),"%d %s / T%d +%d"%[i+1,WeaponDB.type_name(it),it.tier,it.enhance],"slot:"+slot,target==slot)
  u.button(Rect2(x+321,104,98,48),"順序→","swap:"+str(i))
  u.text("→ %d   %s"%[(i+1)%3+1,WeaponDB.attributes(it)],Vector2(x+18,182),15,u.TEAL)
 for i in range(6):
  var slot=ItemDB.SLOTS[i+3];var it=p.equipment[slot]
  u.button(Rect2(40+i*227,215,215,48),"%s / 階%d T%d +%d"%[ItemDB.slot_text(slot),it.grade,it.tier,it.enhance],"slot:"+slot,target==slot)
 if tab=="forge":draw_forge(u);return
 u.text("所持品 %d / 40"%p.inventory.size(),Vector2(40,303),16,u.GOLD)
 u.button(Rect2(210,274,140,42),"並べ替え","sort")
 u.button(Rect2(365,274,240,42),"Rare以下を一括分解","bulk")
 for i in range(p.inventory.size()):
  var it=p.inventory[i];var r=Rect2(40+(i%8)*70,331+int(i/8)*66,62,58)
  u.button(r,("保" if Forge.protected(it) else "")+str(i+1),"item:"+str(i),u.selected==i)
  u.text(WeaponDB.type_name(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot),r.position+Vector2(5,51),11,ItemDB.COLORS[int(it.rarity)])
  u.draw_rect(r,ItemDB.COLORS[int(it.rarity)],false,2)
 u.button(Rect2(40,703,255,48),"誓印盤","oaths")
 u.button(Rect2(310,703,295,48),["攻撃ステータス","防御ステータス","探索ステータス"][stats_group],"stats_group")
 var groups=[["attack","haste","crit","crit_damage","slash","blunt","pierce","magic","penetration","skill","cdr","stagger"],["hp","armor","shield_max","shield_regen","fatal_resist","knock_resist","healing"],["speed","dodge_cdr","dodge_distance","drop_rate","rarity_find","material_find","salvage"]]
 for i in range(groups[stats_group].size()):
  var key=groups[stats_group][i]
  u.text(ItemDB.stat_text(key,p.stats.get(key,0)),Vector2(40+(i%3)*196,780+int(i/3)*24),12,u.MUTED)
 if u.selected<0 or u.selected>=p.inventory.size():
  detail(u,p.equipment[target],Rect2(640,283,748,468),"装備中 / "+ItemDB.slot_text(target));return
 var it=p.inventory[u.selected]
 detail(u,it,Rect2(640,283,748,410),"所持品 → "+ItemDB.slot_text(target))
 var valid=Loadout.accepts(it,target)
 if valid:
  var loadout=p.equipment.duplicate(true);loadout[target]=it
  var next=p.calculated(loadout)
  u.text("変更: 攻撃 %+.1f / HP %+.0f / 防御 %+.1f"%[p.weapon_power(it)-p.weapon_power(p.equipment[target]) if target in Loadout.WEAPONS else next.attack-p.stats.attack,next.hp-p.stats.hp,next.armor-p.stats.armor],Vector2(660,722),17,u.TEAL)
 u.button(Rect2(640,748,350,48),"この枠へ装備" if valid else "上で適合する部位を選択","equip_target",valid)
 u.button(Rect2(1000,748,388,48),"分解して素材獲得","salvage")
 u.button(Rect2(640,813,350,48),"ロック / "+("有効" if it.locked else "無効"),"lock")
 u.button(Rect2(1000,813,388,48),"お気に入り / "+("有効" if it.favorite else "無効"),"favorite")
func detail(u,it:Dictionary,r:Rect2,label:String)->void:
 u.panel(r,u.PANEL,ItemDB.COLORS[int(it.rarity)])
 var x=r.position.x+18;var y=r.position.y+27
 u.text(label,Vector2(x,y),14,u.MUTED);y+=32
 u.text(it.name,Vector2(x,y),23,ItemDB.COLORS[int(it.rarity)]);y+=28
 u.text("%s / 階級%d / T%d / +%d / %s"%[ItemDB.RARITIES[int(it.rarity)],it.grade,it.tier,it.enhance,WeaponDB.attributes(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot)],Vector2(x,y),16,u.GOLD);y+=30
 var rows=[]
 for table in [it.base,it.affixes]:
  for key in table:
   var limits=it.get("rolls",{}).get(key,[0,table[key]])
   rows.append(ItemDB.stat_text(key,table[key])+"   %.2f / %.2f"%[table[key],limits[1]])
 for i in range(rows.size()):u.text(rows[i],Vector2(x+(i%2)*(r.size.x/2),y+int(i/2)*22),14,u.TEXT)
 y+=ceilf(rows.size()/2.0)*22+8
 for i in range(int(it.tier)):
  u.text("T%d %s"%[i+1,WeaponDB.TIERS[i]],Vector2(x,y),12,u.TEAL);y+=17
 if int(it.rarity)>=3:u.wrapped_text("固有: "+UNIQUE_TEXT.get(it.get("unique",""),"継承された固有能力")+(" / 神話: 3番目に追撃・魔力弾3方向" if int(it.rarity)==4 else ""),Vector2(x,y+5),r.size.x-36,14,ItemDB.COLORS[int(it.rarity)])
func draw_forge(u)->void:
 var p=u.game.player;var it=p.equipment[forge_slot]
 detail(u,it,Rect2(40,290,780,535),"鍛冶対象 / "+ItemDB.slot_text(forge_slot))
 u.text("素材 %d / 合成進行 %d"%[p.materials,it.fusion],Vector2(860,317),23,u.GOLD)
 var actions=["enhance","fuse","tier","evolve"];var names=["強化 +1","同系統・同階級を合成","Tierアップ","階級進化 / +10が必要"]
 for i in range(4):u.button(Rect2(850,350+i*66,540,52),"%s / 素材%d"%[names[i],Forge.cost(it,actions[i],p.active_oaths)],"forge:"+actions[i])
 u.text("進化で継承強化するAffixを選択",Vector2(860,650),18,u.TEAL)
 var i=0
 for key in it.affixes:
  u.button(Rect2(850,670+i*45,540,40),ItemDB.stat_text(key,it.affixes[key]),"inherit:"+key,inheritance==key);i+=1
 u.text("全Affixを保持。選択した1つはさらに8%強化。",Vector2(45,859),15,u.MUTED)
func draw_oaths(u)->void:
 u.dim();var b=u.game.profile.oaths
 u.text("誓印盤 / 出発前に主1・副2を選択",Vector2(60,70),30)
 u.text("誓片 %d / 最初に選んだ系統が主誓印。Run中の選択変更不可。"%b.points,Vector2(60,111),18,u.GOLD)
 u.button(Rect2(1160,35,230,50),"戻る","oath_back")
 var i=0
 for key in OathBoard.PATHS:
  var d=OathBoard.PATHS[key];var x=60+(i%3)*450;var y=165+int(i/3)*340;var index=b.active.find(key);var rank=int(b.ranks.get(key,0))
  u.panel(Rect2(x,y,420,305),u.PANEL,u.GOLD if index>=0 else u.LINE)
  u.text(d.name+" / "+("主誓印" if index==0 else ("副誓印" if index>0 else "未選択")),Vector2(x+20,y+40),24,u.TEAL)
  u.wrapped_text(d.text,Vector2(x+20,y+85),380,18,u.TEXT,28)
  u.button(Rect2(x+20,y+165,380,48),"選択を解除" if index>=0 else "選択","oath:"+key,index>=0)
  u.button(Rect2(x+20,y+230,380,48),"刻印 %d/3 / 誓片%d"%[rank,(rank+1)*3],"rank:"+key)
  i+=1
