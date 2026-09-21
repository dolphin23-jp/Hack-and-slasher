class_name ReliquaryUI
extends RefCounted
const UNIQUE_TEXT=WeaponDB.UNIQUE_TEXT
var tab="equipment"
var target="weapon"
var forge_slot="weapon"
var inheritance=""
var stats_group=0
var filter_mode=0
var inventory_page=0
var vault_page=0
var vault_selected=0
var back="title"
const FILTERS=["すべて","武器","防具","Epic+","T4+"]
func inventory_indices(p)->Array:
 var out=[]
 for i in range(p.inventory.size()):
  var it=p.inventory[i];var keep=true
  match filter_mode:
   1:keep=it.slot in Loadout.WEAPONS
   2:keep=it.slot not in Loadout.WEAPONS
   3:keep=int(it.rarity)>=2
   4:keep=int(it.tier)>=4
  if keep:out.append(i)
 return out
func auto_salvage_label(g)->String:
 var mode=float(g.profile.settings.get("auto_salvage",0.0))
 return "自動分解 OFF" if mode<.24 else ("自動 Common" if mode<.49 else "自動 Rare以下")
func act(u,action:String)->bool:
 var g=u.game;var p=g.player
 if action=="oaths":back=g.mode;g.mode="oaths";return true
 if action=="oath_back":g.mode=back;return true
 if action.begins_with("oath:"):
  if back!="title":g.toast("誓印の選択は次の探索の出発前に行えます");return true
  var key=action.get_slice(":",1);var active=g.profile.oaths.active
  if key in active:
   if active.size()<=1:g.toast("主誓印は1つ以上必要です")
   else:active.erase(key)
  elif active.size()<3:active.append(key)
  else:g.toast("主誓印1・副誓印2までです")
  g.profile.write_save();return true
 if action.begins_with("rank:"):
  if back!="title":g.toast("刻印の強化は出発前に行えます");return true
  var key=action.get_slice(":",1);var rank=int(g.profile.oaths.ranks.get(key,0));var price=(rank+1)*3
  if rank<3 and g.profile.oaths.points>=price:g.profile.oaths.points-=price;g.profile.oaths.ranks[key]=rank+1;g.profile.write_save()
  else:g.toast("誓片が不足、または解放済みです")
  return true
 if action.begins_with("choice:"):
  if back!="title":g.toast("分岐の選択は次の探索の出発前に行えます");return true
  var path=action.get_slice(":",1);var picked=action.get_slice(":",2)
  if int(g.profile.oaths.ranks.get(path,0))<2:g.toast("ランク2で分岐を解放できます");return true
  if not OathBoard.CHOICES.get(path,{}).has(picked):return true
  g.profile.oaths.choices[path]=picked;g.profile.write_save();return true
 if action.begins_with("tab:"):tab=action.get_slice(":",1);inventory_page=0;vault_page=0;return true
 if action=="filter":
  filter_mode=(filter_mode+1)%FILTERS.size();inventory_page=0
  var ids=inventory_indices(p)
  if not ids.is_empty():u.selected=ids[0]
  return true
 if action=="page_prev":inventory_page=maxi(0,inventory_page-1);return true
 if action=="page_next":
  var pages=maxi(1,ceili(inventory_indices(p).size()/24.0));inventory_page=mini(pages-1,inventory_page+1);return true
 if action=="vault_prev":vault_page=maxi(0,vault_page-1);return true
 if action=="vault_next":
  var pages=maxi(1,ceili(g.profile.vault.size()/24.0));vault_page=mini(pages-1,vault_page+1);return true
 if action=="auto_salvage":
  var mode=float(g.profile.settings.get("auto_salvage",0.0))
  g.profile.settings.auto_salvage=.25 if mode<.24 else (.5 if mode<.49 else 0.0)
  g.profile.write_save();return true
 if action.begins_with("vault_item:"):vault_selected=int(action.get_slice(":",1));return true
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
   if p.inventory[i].get("junk",false) and not Forge.protected(p.inventory[i]):g.salvage(i)
  return true
 if action=="junk":
  if u.selected>=0 and u.selected<p.inventory.size():
   p.inventory[u.selected].junk=not p.inventory[u.selected].get("junk",false);g.save_run()
  return true
 if action=="store":
  if u.selected<0 or u.selected>=p.inventory.size():return true
  if g.profile.vault.size()>=120:g.toast("VAULTが満杯です");return true
  g.profile.vault.append(p.inventory[u.selected]);p.inventory.remove_at(u.selected)
  u.selected=clampi(u.selected,0,maxi(0,p.inventory.size()-1));g.save_run();return true
 if action=="retrieve":
  if vault_selected<0 or vault_selected>=g.profile.vault.size():return true
  if p.inventory.size()>=60:g.toast("所持品が満杯です");return true
  p.inventory.append(g.profile.vault[vault_selected]);g.record_item(p.inventory[-1]);g.profile.vault.remove_at(vault_selected)
  vault_selected=clampi(vault_selected,0,maxi(0,g.profile.vault.size()-1));g.save_run();return true
 if action.begins_with("inherit:"):inheritance=action.get_slice(":",1);return true
 if action.begins_with("forge:"):
  g.toast(Forge.apply(p,p.equipment[forge_slot],action.get_slice(":",1),inheritance));return true
 if action=="stats_group":stats_group=(stats_group+1)%3;return true
 return false
func draw(u)->void:
 var p=u.game.player
 u.dim();u.text("聖遺物庫 / 三連の誓い",Vector2(40,55),30)
 u.button(Rect2(780,24,150,48),"VAULT","tab:storage",tab=="storage")
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
 if tab=="storage":draw_storage(u);return
 var ids=inventory_indices(p);var pages=maxi(1,ceili(ids.size()/24.0));inventory_page=clampi(inventory_page,0,pages-1)
 u.text("所持品 %d / 60"%p.inventory.size(),Vector2(40,303),16,u.GOLD)
 u.button(Rect2(185,274,112,42),"並べ替え","sort")
 u.button(Rect2(307,274,138,42),FILTERS[filter_mode],"filter")
 u.button(Rect2(455,274,150,42),auto_salvage_label(u.game),"auto_salvage")
 var start=inventory_page*24
 for cell in range(24):
  if start+cell>=ids.size():break
  var i=int(ids[start+cell]);var it=p.inventory[i];var r=Rect2(40+(cell%6)*92,331+int(cell/6)*72,84,64)
  var mark=("保" if Forge.protected(it) else "")+("J" if it.get("junk",false) else "")
  u.button(r,mark+str(i+1),"item:"+str(i),u.selected==i)
  u.text(WeaponDB.type_name(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot),r.position+Vector2(7,56),12,ItemDB.COLORS[int(it.rarity)])
  u.draw_rect(r,ItemDB.COLORS[int(it.rarity)],false,2)
 u.button(Rect2(40,630,120,40),"前頁","page_prev")
 u.text("%d / %d"%[inventory_page+1,pages],Vector2(202,657),14,u.MUTED,true)
 u.button(Rect2(245,630,120,40),"次頁","page_next")
 u.button(Rect2(380,630,225,40),"JUNK一括分解","bulk")
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
  u.text("比較: "+p.item_comparison_text(it),Vector2(660,722),17,u.TEAL)
 u.button(Rect2(640,748,350,48),"この枠へ装備" if valid else "上で適合する部位を選択","equip_target",valid)
 u.button(Rect2(1000,748,185,48),"分解","salvage")
 u.button(Rect2(1195,748,193,48),"VAULTへ","store")
 u.button(Rect2(640,813,235,48),"ロック / "+("有効" if it.locked else "無効"),"lock")
 u.button(Rect2(885,813,235,48),"お気に入り / "+("有効" if it.favorite else "無効"),"favorite")
 u.button(Rect2(1130,813,258,48),"JUNK / "+("ON" if it.get("junk",false) else "OFF"),"junk")
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
 if int(it.rarity)>=3:u.wrapped_text("固有: "+ItemDB.unique_text(it)+(" / 神話: 固有能力が強化される" if int(it.rarity)==4 else ""),Vector2(x,y+5),r.size.x-36,14,ItemDB.COLORS[int(it.rarity)])
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
  var d=OathBoard.PATHS[key];var x=60+(i%3)*450;var y=155+int(i/3)*350;var index=b.active.find(key);var rank=int(b.ranks.get(key,0))
  u.panel(Rect2(x,y,420,330),u.PANEL,u.GOLD if index>=0 else u.LINE)
  u.text(d.name+" / "+("主誓印" if index==0 else ("副誓印" if index>0 else "未選択")),Vector2(x+20,y+36),22,u.TEAL)
  u.wrapped_text(d.text,Vector2(x+20,y+72),380,16,u.TEXT,24)
  var choices=OathBoard.choice_keys(key);var picked=String(b.get("choices",{}).get(key,""))
  for j in range(choices.size()):
   var ck=String(choices[j])
   u.button(Rect2(x+20+j*195,y+137,185,38),OathBoard.choice_name(key,ck),"choice:"+key+":"+ck,picked==ck and rank>=2)
  u.button(Rect2(x+20,y+188,380,42),"選択を解除" if index>=0 else "主/副に選択","oath:"+key,index>=0)
  u.button(Rect2(x+20,y+239,380,42),"刻印 %d/3 / 誓片%d"%[rank,(rank+1)*3],"rank:"+key)
  var cap="Capstone: "+OathBoard.capstone_text(key) if rank>=3 else "ランク3の主誓印でCapstone解放"
  u.text(cap,Vector2(x+20,y+307),12,u.GOLD if rank>=3 and index==0 else u.MUTED)
  i+=1

func draw_storage(u)->void:
 var p=u.game.player;var vault=u.game.profile.vault;var pages=maxi(1,ceili(vault.size()/24.0));vault_page=clampi(vault_page,0,pages-1)
 u.text("VAULT %d / 120"%vault.size(),Vector2(40,303),18,u.GOLD)
 u.text("装備を保存できます。",Vector2(240,303),14,u.MUTED)
 var start=vault_page*24
 for cell in range(24):
  var i=start+cell
  if i>=vault.size():break
  var it=vault[i];var r=Rect2(40+(cell%6)*92,331+int(cell/6)*72,84,64)
  u.button(r,str(i+1),"vault_item:"+str(i),vault_selected==i)
  u.text(WeaponDB.type_name(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot),r.position+Vector2(7,56),12,ItemDB.COLORS[int(it.rarity)])
  u.draw_rect(r,ItemDB.COLORS[int(it.rarity)],false,2)
 u.button(Rect2(40,630,120,40),"前頁","vault_prev")
 u.text("%d / %d"%[vault_page+1,pages],Vector2(202,657),14,u.MUTED,true)
 u.button(Rect2(245,630,120,40),"次頁","vault_next")
 u.button(Rect2(40,703,255,48),"誓印盤","oaths")
 if vault.is_empty():u.text("VAULTに装備はありません。",Vector2(1014,500),23,u.MUTED,true);return
 vault_selected=clampi(vault_selected,0,vault.size()-1)
 var it=vault[vault_selected]
 detail(u,it,Rect2(640,283,748,410),"VAULT / "+ItemDB.slot_text(it.slot))
 u.button(Rect2(640,748,748,50),"所持品へ戻す","retrieve",p.inventory.size()<60)
