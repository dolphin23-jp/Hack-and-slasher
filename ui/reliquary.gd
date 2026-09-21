class_name ReliquaryUI
extends RefCounted
const NODE_EFFECT_TEXT={
 "flow_chain":"連携速度を強化",
 "impact_chain":"連携の怯ませを強化",
 "weapon_echo":"3連携で追撃",
 "arcane_pierce":"魔撃の貫通を強化",
 "arcane_echo":"魔撃が帰還",
 "arcane_cap":"魔撃連携を強化",
 "shield_sustain":"障壁回復を強化",
 "shield_burst":"障壁を攻撃へ変換",
 "fortress_cap":"3連携で障壁",
 "burn_long":"炎上時間を延長",
 "burn_burst":"炎上クリティカルで爆発",
 "flame_cap":"炎上威力を強化",
 "high_voltage":"雷撃威力を強化",
 "wide_lightning":"連鎖数を強化",
 "storm_cap":"雷撃連携を強化"
}
var tab="equipment"
var target="weapon"
var forge_slot="weapon"
var inheritance=""
var stats_group=0
var back="title"
var oath_view="dance"
var filter_mode="all"
var inventory_page=0
var vault_selected=0
var vault_page=0
var focus_detail=false
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
 if action.begins_with("oath_view:"):
  oath_view=action.get_slice(":",1);return true
 if action.begins_with("oath_main:"):
  if back!="title":g.toast("誓印の選択は次の探索の出発前に行えます");return true
  var key=action.get_slice(":",1);var active=g.profile.oaths.active
  if key in active:active.erase(key)
  elif active.size()>=3:active.pop_back()
  active.insert(0,key);g.profile.write_save();return true
 if action.begins_with("node:"):
  if back!="title":g.toast("誓印盤の強化は出発前に行えます");return true
  var path=action.get_slice(":",1);var id=action.get_slice(":",2)
  g.toast(OathBoard.unlock_node(g.profile.oaths,path,id));g.profile.write_save();return true
 if action.begins_with("rank:"):
  if back!="title":g.toast("刻印の強化は出発前に行えます");return true
  var key=action.get_slice(":",1);var rank=int(g.profile.oaths.ranks.get(key,0));var price=(rank+1)*3
  if rank<3 and g.profile.oaths.points>=price:g.profile.oaths.points-=price;g.profile.oaths.ranks[key]=rank+1;g.profile.write_save()
  else:g.toast("誓片が不足、または解放済みです")
  return true
 if action.begins_with("tab:"):
  tab=action.get_slice(":",1);focus_detail=false;return true
 if action=="filter":
  var modes=["all","weapon","armor","legendary","junk"];filter_mode=modes[(modes.find(filter_mode)+1)%modes.size()];inventory_page=0
  var visible=filtered_inventory(p);u.selected=int(visible[0]) if not visible.is_empty() else -1
  return true
 if action.begins_with("page:"):
  inventory_page=maxi(0,inventory_page+int(action.get_slice(":",1)));return true
 if action.begins_with("vault_page:"):
  vault_page=maxi(0,vault_page+int(action.get_slice(":",1)));return true
 if action=="detail_toggle":focus_detail=not focus_detail;return true
 if action=="junk":
  if u.selected>=0 and u.selected<p.inventory.size():
   p.inventory[u.selected].junk=not p.inventory[u.selected].get("junk",false);g.save_run()
  return true
 if action=="auto_salvage":
  g.profile.settings.auto_salvage_rare=not g.profile.settings.get("auto_salvage_rare",false);g.profile.write_save();return true
 if action=="vault_store":
  if u.selected<0 or u.selected>=p.inventory.size():return true
  if g.profile.vault.size()>=120:g.toast("保管庫が満杯です / 120");return true
  g.profile.vault.append(p.inventory[u.selected]);p.inventory.remove_at(u.selected);u.selected=clampi(u.selected,0,maxi(0,p.inventory.size()-1));g.save_run();g.toast("保管庫へ移動");return true
 if action.begins_with("vault_item:"):vault_selected=int(action.get_slice(":",1));return true
 if action=="vault_take":
  if vault_selected<0 or vault_selected>=g.profile.vault.size():return true
  if p.inventory.size()>=80:g.toast("所持品が満杯です / 80");return true
  p.inventory.append(g.profile.vault[vault_selected]);g.profile.vault.remove_at(vault_selected);vault_selected=clampi(vault_selected,0,maxi(0,g.profile.vault.size()-1));g.save_run();g.toast("保管庫から取り出した");return true
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
   if (int(p.inventory[i].rarity)<=1 or p.inventory[i].get("junk",false)) and not Forge.protected(p.inventory[i]):g.salvage(i)
  return true
 if action.begins_with("inherit:"):inheritance=action.get_slice(":",1);return true
 if action.begins_with("forge:"):
  g.toast(Forge.apply(p,p.equipment[forge_slot],action.get_slice(":",1),inheritance));return true
 if action=="stats_group":stats_group=(stats_group+1)%3;return true
 return false
func filtered_inventory(p)->Array:
 var out=[]
 for i in range(p.inventory.size()):
  var it=p.inventory[i];var show=false
  match filter_mode:
   "all":show=true
   "weapon":show=String(it.slot) in Loadout.WEAPONS
   "armor":show=String(it.slot) not in Loadout.WEAPONS
   "legendary":show=int(it.rarity)>=3
   "junk":show=it.get("junk",false)
  if show:out.append(i)
 return out
func filter_label()->String:
 return {"all":"すべて","weapon":"武器","armor":"防具・装飾","legendary":"Legendary+","junk":"ジャンク"}.get(filter_mode,"すべて")
func draw(u)->void:
 var p=u.game.player
 u.dim();u.text("聖遺物庫 / 三連の誓い",Vector2(40,55),30)
 u.button(Rect2(790,24,140,48),"保管庫","tab:vault",tab=="vault")
 u.button(Rect2(940,24,140,48),"装備","tab:equipment",tab=="equipment")
 u.button(Rect2(1090,24,140,48),"鍛冶","tab:forge",tab=="forge")
 u.button(Rect2(1240,24,150,48),"戻る","return_victory" if u.game.mode=="victory_inventory" else "inventory")
 if focus_detail and tab=="equipment":draw_focus_detail(u);return
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
 if tab=="vault":draw_vault(u);return
 var visible=filtered_inventory(p);var max_page=maxi(0,ceili(visible.size()/40.0)-1);inventory_page=mini(inventory_page,max_page)
 u.text("所持品 %d / 80  ・ 表示 %d"%[p.inventory.size(),visible.size()],Vector2(40,303),16,u.GOLD)
 u.button(Rect2(40,274,150,42),"表示: "+filter_label(),"filter")
 u.button(Rect2(210,274,140,42),"並べ替え","sort")
 u.button(Rect2(365,274,240,42),"Rare以下/ジャンク分解","bulk")
 var start=inventory_page*40;var page_items=visible.slice(start,mini(start+40,visible.size()))
 for display_i in range(page_items.size()):
  var i=int(page_items[display_i]);var it=p.inventory[i];var r=Rect2(40+(display_i%8)*70,331+int(display_i/8)*66,62,58)
  var mark=("保" if Forge.protected(it) else "")+("J" if it.get("junk",false) else "")
  u.button(r,mark+str(i+1),"item:"+str(i),u.selected==i)
  u.text(WeaponDB.type_name(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot),r.position+Vector2(5,51),11,ItemDB.COLORS[int(it.rarity)])
  u.draw_rect(r,ItemDB.COLORS[int(it.rarity)],false,2)
 u.button(Rect2(40,660,190,35),"Rare以下自動分解 "+("ON" if u.game.profile.settings.get("auto_salvage_rare",false) else "OFF"),"auto_salvage",u.game.profile.settings.get("auto_salvage_rare",false))
 u.button(Rect2(245,660,90,35),"◀","page:-1",inventory_page>0)
 u.button(Rect2(345,660,160,35),"%d / %d"%[inventory_page+1,max_page+1],"page:1",inventory_page<max_page)
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
 u.button(Rect2(1188,294,180,34),"詳細を拡大","detail_toggle")
 u.button(Rect2(1188,336,180,34),"保管庫へ","vault_store")
 u.button(Rect2(1188,378,180,34),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))
 var valid=Loadout.accepts(it,target)
 if valid:
  var signals=p.item_comparison(it,target)
  u.text("比較: "+" / ".join(signals.slice(0,5)),Vector2(660,722),17,u.TEAL)
 u.button(Rect2(640,748,350,48),"この枠へ装備" if valid else "上で適合する部位を選択","equip_target",valid)
 u.button(Rect2(1000,748,388,48),"分解して素材獲得","salvage")
 u.button(Rect2(640,813,350,48),"ロック / "+("有効" if it.locked else "無効"),"lock")
 u.button(Rect2(1000,813,388,48),"お気に入り / "+("有効" if it.favorite else "無効"),"favorite")
func draw_focus_detail(u)->void:
 var p=u.game.player
 if u.selected<0 or u.selected>=p.inventory.size():focus_detail=false;return
 var it=p.inventory[u.selected]
 detail(u,it,Rect2(60,95,1320,650),"拡大詳細 / "+ItemDB.slot_text(String(it.slot)))
 u.button(Rect2(1160,108,195,42),"一覧へ戻る","detail_toggle")
 var target_slot=p.item_upgrade_target(it);var signals=p.item_comparison(it,target_slot)
 u.text("装備候補: "+ItemDB.slot_text(target_slot)+"   /   "+" / ".join(signals),Vector2(90,790),19,u.TEAL)
 u.button(Rect2(920,770,210,48),"保管庫へ","vault_store")
 u.button(Rect2(1150,770,210,48),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))
func draw_vault(u)->void:
 var g=u.game;var list=g.profile.vault;var per_page=48
 var max_page=maxi(0,ceili(list.size()/float(per_page))-1);vault_page=mini(vault_page,max_page)
 u.text("保管庫 %d / 120  ・ Runをまたいで保持"%list.size(),Vector2(40,303),18,u.GOLD)
 var start=vault_page*per_page;var end=mini(start+per_page,list.size())
 for display_i in range(end-start):
  var i=start+display_i;var it=list[i];var r=Rect2(40+(display_i%8)*70,335+int(display_i/8)*66,62,58)
  u.button(r,str(i+1),"vault_item:"+str(i),vault_selected==i)
  u.text(WeaponDB.type_name(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot),r.position+Vector2(5,51),11,ItemDB.COLORS[int(it.rarity)])
  u.draw_rect(r,ItemDB.COLORS[int(it.rarity)],false,2)
 u.button(Rect2(40,750,110,38),"◀","vault_page:-1",vault_page>0)
 u.button(Rect2(165,750,160,38),"▶ %d / %d"%[vault_page+1,max_page+1],"vault_page:1",vault_page<max_page)
 if list.is_empty():
  u.text("保管庫は空です。装備画面の「保管庫へ」から移動できます。",Vector2(720,510),21,u.MUTED,true);return
 vault_selected=clampi(vault_selected,0,list.size()-1)
 if vault_selected<start or vault_selected>=end:vault_selected=start
 detail(u,list[vault_selected],Rect2(640,300,748,455),"保管庫")
 u.button(Rect2(940,785,448,52),"所持品へ取り出す","vault_take",u.game.player.inventory.size()<80)
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
  u.text("T%d %s"%[i+1,WeaponDB.tier_text(it,i+1)],Vector2(x,y),12,u.TEAL);y+=17
 if int(it.rarity)>=3:u.wrapped_text("固有: "+ItemDB.unique_text(it)+(" / 神話: 武器系統または固有能力のルールを追加変化" if int(it.rarity)==4 else ""),Vector2(x,y+5),r.size.x-36,14,ItemDB.COLORS[int(it.rarity)])
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
 u.text("誓印盤 / 分岐する永続ビルド",Vector2(60,60),30)
 u.text("誓片 %d / 主誓印1・副誓印2。ノードは永続解放。"%b.points,Vector2(60,98),17,u.GOLD)
 u.button(Rect2(1160,35,230,50),"戻る","oath_back")
 var keys=OathBoard.PATHS.keys()
 for i in range(keys.size()):
  var key=String(keys[i]);var active_index=b.active.find(key)
  u.button(Rect2(55+i*220,125,205,48),OathBoard.PATHS[key].name+(" / 主" if active_index==0 else (" / 副" if active_index>0 else "")),"oath_view:"+key,oath_view==key)
 var path=oath_view
 if not OathBoard.PATHS.has(path):path="dance";oath_view=path
 var info=OathBoard.PATHS[path];var active_index=b.active.find(path)
 u.panel(Rect2(60,205,300,610),u.PANEL,u.GOLD if active_index>=0 else u.LINE)
 u.text(info.name,Vector2(85,252),30,u.TEAL)
 u.wrapped_text(info.text,Vector2(85,290),250,17,u.TEXT,27)
 u.text("状態: "+("主誓印" if active_index==0 else ("副誓印" if active_index>0 else "未選択")),Vector2(85,382),17,u.GOLD)
 u.button(Rect2(85,415,250,48),"選択を解除" if active_index>=0 else "副誓印として選択","oath:"+path,active_index>=0)
 u.button(Rect2(85,475,250,48),"主誓印にする","oath_main:"+path,active_index==0)
 u.text("解放済み %d / 7"%OathBoard.TREES[path].filter(func(n):return n.id in b.nodes).size(),Vector2(85,555),15,u.MUTED)
 u.wrapped_text("中央の枝は二者択一です。片方を選ぶと反対側はその探索者では解放できません。最下段がCapstone。",Vector2(85,600),250,14,u.MUTED,22)
 var positions=[
  Vector2(615,220),Vector2(615,310),
  Vector2(430,420),Vector2(800,420),
  Vector2(430,530),Vector2(800,530),
  Vector2(615,665)]
 var nodes=OathBoard.TREES[path]
 for pair in [[0,1],[1,2],[1,3],[2,4],[3,5],[4,6],[5,6]]:
  u.draw_line(positions[pair[0]]+Vector2(130,30),positions[pair[1]]+Vector2(130,30),u.LINE,3)
 for i in range(nodes.size()):
  var node=nodes[i];var owned=node.id in b.nodes;var available=OathBoard.node_available(b,path,node.id)
  var label=("✓ " if owned else ("◆ " if available else "◇ "))+node.name+" / "+str(node.cost)
  u.button(Rect2(positions[i],Vector2(260,60)),label,"node:"+path+":"+node.id,owned)
  var detail=[]
  for stat in node.get("stats",{}):detail.append(ItemDB.stat_text(stat,node.stats[stat]))
  for effect in node.get("effects",[]):detail.append(NODE_EFFECT_TEXT.get(String(effect),"固有効果"))
  if not detail.is_empty():u.text(" / ".join(detail),positions[i]+Vector2(130,82),11,u.TEAL if owned else u.MUTED,true)
 u.text("◆ 解放可能   ✓ 解放済み   ◇ 前提不足・排他",Vector2(850,820),14,u.MUTED,true)
