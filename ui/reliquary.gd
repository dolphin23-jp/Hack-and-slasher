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
var forge_screen=ForgeScreen.new()
var salvage_screen=SalvageScreen.new()
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
func modal_active()->bool:return forge_screen.opened or salvage_screen.opened
func close_modal()->void:
 forge_screen.opened=false;forge_screen.pending={};forge_screen.selected={}
 salvage_screen.opened=false;salvage_screen.preview=[]
func act(u,action:String)->bool:
 var g=u.game;var p=g.player
 if g.mode not in ["inventory","victory_inventory"]:close_modal()
 if forge_screen.opened:return forge_screen.act(u,action)
 if salvage_screen.opened:return salvage_screen.act(u,action)
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
  salvage_screen.open(p,false);return true
 if action=="vault_store":
  if u.selected<0 or u.selected>=p.inventory.size():return true
  if g.profile.vault.size()>=120:g.toast("保管庫が満杯です / 120");return true
  g.profile.vault.append(p.inventory[u.selected]);p.inventory.remove_at(u.selected);u.selected=clampi(u.selected,0,maxi(0,p.inventory.size()-1));focus_detail=false;g.save_run();g.toast("保管庫へ移動");return true
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
 if action=="bulk":salvage_screen.open(p,true);return true
 if action.begins_with("inherit:"):inheritance=action.get_slice(":",1);return true
 if action=="forge:fuse":forge_screen.open(forge_slot);return true
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
var art_cache={}
func art_texture(it:Dictionary):
 var path=ItemDB.art_path(it)
 if not art_cache.has(path):art_cache[path]=load(path)
 return art_cache[path]
func draw_item_art(u,it:Dictionary,r:Rect2)->void:
 u.panel(r,Color("0b1720"),ItemDB.COLORS[int(it.rarity)])
 var tex=art_texture(it)
 if tex!=null:u.draw_texture_rect(tex,r.grow(-5),false)
 if not ItemDB.art_ready(it):
  u.panel(Rect2(r.position+Vector2(5,r.size.y-25),Vector2(r.size.x-10,20)),Color(.03,.06,.08,.88),Color(.2,.3,.32,.5))
  u.text("ART PLACEHOLDER",Vector2(r.get_center().x,r.end.y-10),9,u.MUTED,true)
func draw_inventory_card(u,it:Dictionary,index:int,r:Rect2,selected:bool,action_prefix:String="item")->void:
 u.button(r,"",action_prefix+":"+str(index),selected)
 draw_item_art(u,it,Rect2(r.position+Vector2(6,6),Vector2(42,42)))
 var title=WeaponDB.type_name(it) if String(it.slot) in Loadout.WEAPONS else ItemDB.slot_text(String(it.slot))
 u.text(title,Vector2(r.position.x+53,r.position.y+21),11,ItemDB.COLORS[int(it.rarity)])
 u.text("階%d T%d +%d"%[it.grade,it.tier,it.enhance],Vector2(r.position.x+53,r.position.y+39),10,u.TEXT)
 var mark=(" F" if it.get("favorite",false) else "")+(" L" if it.get("locked",false) else "")+(" J" if it.get("junk",false) else "")
 if not mark.is_empty():u.text(mark,Vector2(r.position.x+53,r.position.y+57),9,u.GOLD)
func comparison_target(p,it:Dictionary)->String:
 if Loadout.accepts(it,target):return target
 return p.item_upgrade_target(it)
func delta_color(u,value:float)->Color:
 if value>.0001:return u.TEAL
 if value<-.0001:return u.RED
 return u.MUTED
func compact_tokens(values:Array,max_items:int=2,max_chars:int=48)->String:
 if values.is_empty():return "なし"
 var shown=values.slice(0,mini(max_items,values.size()));var value=" / ".join(shown)
 if values.size()>shown.size():value+=" / +%d"%[values.size()-shown.size()]
 if value.length()>max_chars:value=value.substr(0,max_chars-1)+"…"
 return value
func draw_compare_panel(u,p,it:Dictionary,target_slot:String,r:Rect2,title:String="交換比較",show_detail_button:bool=true)->void:
 var snap=EquipmentCompare.snapshot(p,it,target_slot)
 u.panel(r,u.PANEL,ItemDB.COLORS[int(it.rarity)])
 var x=r.position.x+18;var y=r.position.y+26
 u.text(title+" / "+ItemDB.slot_text(target_slot),Vector2(x,y),14,u.GOLD)
 if show_detail_button:u.button(Rect2(r.end.x-200,r.position.y+11,180,34),"詳細を拡大","detail_toggle")
 draw_item_art(u,it,Rect2(x,y+18,112,112))
 var current=p.equipment[target_slot]
 draw_item_art(u,current,Rect2(x+126,y+42,72,72))
 u.text("候補",Vector2(x,y+151),11,u.MUTED);u.text("現在",Vector2(x+126,y+132),10,u.MUTED)
 u.text(it.name,Vector2(x+216,y+44),20,ItemDB.COLORS[int(it.rarity)])
 u.text("%s / 階%d T%d +%d"%[ItemDB.RARITIES[int(it.rarity)],it.grade,it.tier,it.enhance],Vector2(x+216,y+69),13,u.GOLD)
 u.text("現在: "+String(current.name),Vector2(x+216,y+93),13,u.MUTED)
 if String(it.slot) in Loadout.WEAPONS:
  u.text("武器列  "+String(snap.before_order),Vector2(x+216,y+116),11,u.MUTED)
  if snap.before_order!=snap.after_order:u.text("交換後  "+String(snap.after_order),Vector2(x+216,y+135),11,u.TEAL)
 var table_y=y+178
 u.text("能力",Vector2(x,table_y),11,u.MUTED)
 u.text("現在",Vector2(x+195,table_y),11,u.MUTED,true)
 u.text("交換後",Vector2(x+282,table_y),11,u.MUTED,true)
 u.text("差分",Vector2(x+369,table_y),11,u.MUTED,true)
 u.text("装備寄与  現→新",Vector2(x+525,table_y),11,u.MUTED,true)
 var keys=EquipmentCompare.key_stats(snap,6)
 for i in range(keys.size()):
  var key=String(keys[i]);var row_y=table_y+24+i*22
  var before=float(snap.before_stats.get(key,0));var after=float(snap.after_stats.get(key,0));var delta=float(snap.delta.get(key,0))
  var old_con=float(snap.current_contribution.get(key,0));var new_con=float(snap.candidate_contribution.get(key,0))
  u.text(ItemDB.stat_name(key),Vector2(x,row_y),12,u.TEXT)
  u.text(ItemDB.stat_value(key,before),Vector2(x+195,row_y),12,u.TEXT,true)
  u.text(ItemDB.stat_value(key,after),Vector2(x+282,row_y),12,u.TEXT,true)
  u.text(ItemDB.stat_delta(key,delta),Vector2(x+369,row_y),12,delta_color(u,delta),true)
  u.text(ItemDB.stat_value(key,old_con)+" → "+ItemDB.stat_value(key,new_con),Vector2(x+525,row_y),11,u.MUTED,true)
 var build_y=table_y+164
 var gains=[];gains.append_array(snap.gained_abilities);gains.append_array(snap.gained_build)
 var losses=[];losses.append_array(snap.lost_abilities);losses.append_array(snap.lost_build)
 u.text("得る: "+compact_tokens(gains),Vector2(x,build_y),11,u.TEAL)
 u.text("失う: "+compact_tokens(losses),Vector2(x,build_y+20),11,u.RED if not losses.is_empty() else u.MUTED)
func draw_focus_compare(u,p,it:Dictionary,target_slot:String,r:Rect2)->void:
 var snap=EquipmentCompare.snapshot(p,it,target_slot)
 u.panel(r,u.PANEL,ItemDB.COLORS[int(it.rarity)])
 var x=r.position.x+18;var y=r.position.y+26
 u.text("交換後の変化 / "+ItemDB.slot_text(target_slot),Vector2(x,y),15,u.GOLD)
 var keys=EquipmentCompare.key_stats(snap,6);var cell_w=(r.size.x-36)/3
 for i in range(keys.size()):
  var key=String(keys[i]);var col=i%3;var row=int(i/3);var px=x+col*cell_w;var py=y+38+row*48
  var before=float(snap.before_stats.get(key,0));var after=float(snap.after_stats.get(key,0));var delta=float(snap.delta.get(key,0))
  u.text(ItemDB.stat_name(key),Vector2(px,py),11,u.MUTED)
  u.text(ItemDB.stat_value(key,before)+" → "+ItemDB.stat_value(key,after),Vector2(px,py+19),13,u.TEXT)
  u.text(ItemDB.stat_delta(key,delta),Vector2(px+cell_w-52,py+19),12,delta_color(u,delta))
 var chain_y=y+145
 u.text("Chain: "+String(snap.before_order),Vector2(x,chain_y),11,u.MUTED)
 u.text("交換後: "+String(snap.after_order),Vector2(x,chain_y+20),11,u.TEAL if snap.before_order!=snap.after_order else u.MUTED)
 var gains=[];gains.append_array(snap.gained_abilities);gains.append_array(snap.gained_build)
 var losses=[];losses.append_array(snap.lost_abilities);losses.append_array(snap.lost_build)
 u.wrapped_text("得る: "+compact_tokens(gains,5,88),Vector2(x,chain_y+50),r.size.x-36,12,u.TEAL,18)
 u.wrapped_text("失う: "+compact_tokens(losses,5,88),Vector2(x,chain_y+92),r.size.x-36,12,u.RED if not losses.is_empty() else u.MUTED,18)
func draw(u)->void:
 if forge_screen.opened:forge_screen.draw(u);return
 if salvage_screen.opened:salvage_screen.draw(u);return
 var p=u.game.player
 u.dim();u.text("聖遺物庫 / Equipment 2.0",Vector2(40,55),30)
 u.button(Rect2(790,24,140,48),"保管庫","tab:vault",tab=="vault")
 u.button(Rect2(940,24,140,48),"装備","tab:equipment",tab=="equipment")
 u.button(Rect2(1090,24,140,48),"鍛冶","tab:forge",tab=="forge")
 u.button(Rect2(1240,24,150,48),"戻る","return_victory" if u.game.mode=="victory_inventory" else "inventory")
 if focus_detail and tab=="equipment":draw_focus_detail(u);return
 for i in range(3):
  var slot=Loadout.WEAPONS[i];var it=p.equipment[slot];var x=40+i*455
  u.panel(Rect2(x,94,430,105),u.PANEL,ItemDB.COLORS[int(it.rarity)])
  u.button(Rect2(x+10,104,300,48),"      %d  %s / T%d +%d"%[i+1,WeaponDB.type_name(it),it.tier,it.enhance],"slot:"+slot,target==slot)
  draw_item_art(u,it,Rect2(x+15,109,38,38))
  u.button(Rect2(x+321,104,98,48),"順序→","swap:"+str(i))
  u.text(WeaponDB.attributes(it)+" / Q: "+WeaponActionResolver.ARTS[it.weapon_type].name,Vector2(x+18,169),12,u.TEAL)
  var next=p.equipment[Loadout.WEAPONS[(i+1)%3]].weapon_type
  var recipes=ChainResolver.matches(it.weapon_type,next).map(func(v):return v.name)
  u.text("→ %d: "%[(i+1)%3+1]+("・".join(recipes) if not recipes.is_empty() else "通常連携"),Vector2(x+18,189),12,u.GOLD)
 for i in range(6):
  var slot=ItemDB.SLOTS[i+3];var it=p.equipment[slot]
  u.button(Rect2(40+i*227,215,215,48),"%s / 階%d T%d +%d"%[ItemDB.slot_text(slot),it.grade,it.tier,it.enhance],"slot:"+slot,target==slot)
 if tab=="forge":draw_forge(u);return
 if tab=="vault":draw_vault(u);return
 var visible=filtered_inventory(p);var per_page=20;var max_page=maxi(0,ceili(visible.size()/float(per_page))-1);inventory_page=mini(inventory_page,max_page)
 u.text("所持品 %d / 80  ・ 表示 %d  ・ 選択すると右で交換後まで比較"%[p.inventory.size(),visible.size()],Vector2(40,303),15,u.GOLD)
 u.button(Rect2(40,274,150,42),"表示: "+filter_label(),"filter")
 u.button(Rect2(210,274,140,42),"並べ替え","sort")
 u.button(Rect2(365,274,240,42),"ジャンク一括分解","bulk")
 var start_index=inventory_page*per_page;var page_items=visible.slice(start_index,mini(start_index+per_page,visible.size()))
 for display_i in range(page_items.size()):
  var i=int(page_items[display_i]);var it=p.inventory[i];var rr=Rect2(40+(display_i%5)*112,331+int(display_i/5)*79,104,71)
  draw_inventory_card(u,it,i,rr,u.selected==i)
 u.button(Rect2(40,660,190,35),"自動分解ルール "+("ON" if u.game.profile.settings.get("auto_salvage_rare",false) else "OFF"),"auto_salvage",u.game.profile.settings.get("auto_salvage_rare",false))
 u.button(Rect2(245,660,90,35),"◀","page:-1",inventory_page>0)
 u.button(Rect2(345,660,160,35),"%d / %d ▶"%[inventory_page+1,max_page+1],"page:1",inventory_page<max_page)
 u.button(Rect2(40,703,255,48),"誓印盤","oaths")
 u.button(Rect2(310,703,295,48),["攻撃ステータス","防御ステータス","探索ステータス"][stats_group],"stats_group")
 var groups=[["attack","haste","crit","crit_damage","slash","blunt","pierce","magic","penetration","skill","cdr","stagger"],["hp","armor","shield_max","shield_regen","fatal_resist","knock_resist","healing"],["speed","dodge_cdr","dodge_distance","drop_rate","rarity_find","material_find","salvage"]]
 for i in range(groups[stats_group].size()):
  var key=groups[stats_group][i]
  u.text(ItemDB.stat_text(key,p.stats.get(key,0)),Vector2(40+(i%3)*196,780+int(i/3)*24),12,u.MUTED)
 if u.selected<0 or u.selected>=p.inventory.size():
  detail(u,p.equipment[target],Rect2(640,283,748,468),"装備中 / "+ItemDB.slot_text(target));return
 var it=p.inventory[u.selected];var compare_slot=comparison_target(p,it)
 if compare_slot.is_empty():
  detail(u,it,Rect2(640,283,748,410),"所持品");return
 draw_compare_panel(u,p,it,compare_slot,Rect2(640,283,748,410))
 u.button(Rect2(1188,336,180,34),"保管庫へ","vault_store")
 u.button(Rect2(1188,378,180,34),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))
 var valid=Loadout.accepts(it,target)
 var signals=p.item_comparison(it,compare_slot)
 u.text("比較要約: "+" / ".join(signals.slice(0,5)),Vector2(660,722),15,u.TEAL)
 u.button(Rect2(640,748,350,48),"この枠へ装備" if valid else "比較先の部位を上で選択","equip_target",valid)
 u.button(Rect2(1000,748,388,48),"分解して素材獲得","salvage")
 u.button(Rect2(640,813,350,48),"ロック / "+("有効" if it.locked else "無効"),"lock")
 u.button(Rect2(1000,813,388,48),"お気に入り / "+("有効" if it.favorite else "無効"),"favorite")
func draw_focus_detail(u)->void:
 var p=u.game.player
 if u.selected<0 or u.selected>=p.inventory.size():focus_detail=false;return
 var it=p.inventory[u.selected];var target_slot=comparison_target(p,it)
 detail(u,it,Rect2(60,95,610,650),"候補装備 / "+ItemDB.slot_text(String(it.slot)))
 if not target_slot.is_empty():
  detail(u,p.equipment[target_slot],Rect2(690,95,690,285),"現在装備 / "+ItemDB.slot_text(target_slot))
  draw_focus_compare(u,p,it,target_slot,Rect2(690,395,690,350))
 u.button(Rect2(1160,108,195,42),"一覧へ戻る","detail_toggle")
 u.button(Rect2(920,770,210,48),"保管庫へ","vault_store")
 u.button(Rect2(1150,770,210,48),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))
func draw_vault(u)->void:
 var g=u.game;var p=g.player;var list=g.profile.vault;var per_page=24
 var max_page=maxi(0,ceili(list.size()/float(per_page))-1);vault_page=mini(vault_page,max_page)
 u.text("保管庫 %d / 120  ・ アートと比較内容はInventoryと共通"%list.size(),Vector2(40,303),17,u.GOLD)
 var start_index=vault_page*per_page;var end_index=mini(start_index+per_page,list.size())
 for display_i in range(end_index-start_index):
  var i=start_index+display_i;var it=list[i];var rr=Rect2(40+(display_i%5)*112,335+int(display_i/5)*79,104,71)
  draw_inventory_card(u,it,i,rr,vault_selected==i,"vault_item")
 u.button(Rect2(40,750,110,38),"◀","vault_page:-1",vault_page>0)
 u.button(Rect2(165,750,160,38),"▶ %d / %d"%[vault_page+1,max_page+1],"vault_page:1",vault_page<max_page)
 if list.is_empty():
  u.text("保管庫は空です。装備画面の「保管庫へ」から移動できます。",Vector2(720,510),21,u.MUTED,true);return
 vault_selected=clampi(vault_selected,0,list.size()-1)
 if vault_selected<start_index or vault_selected>=end_index:vault_selected=start_index
 var it=list[vault_selected];var compare_slot=p.item_upgrade_target(it)
 if compare_slot.is_empty():detail(u,it,Rect2(640,300,748,455),"保管庫")
 else:draw_compare_panel(u,p,it,compare_slot,Rect2(640,300,748,455),"保管庫から比較",false)
 u.button(Rect2(940,785,448,52),"所持品へ取り出す","vault_take",p.inventory.size()<80)
func detail(u,it:Dictionary,r:Rect2,label:String)->void:
 u.panel(r,u.PANEL,ItemDB.COLORS[int(it.rarity)])
 var x=r.position.x+18;var y=r.position.y+27
 u.text(label,Vector2(x,y),14,u.MUTED)
 var art_size=minf(145,r.size.x*.26);draw_item_art(u,it,Rect2(x,y+14,art_size,art_size))
 var tx=x+art_size+18
 u.text(it.name,Vector2(tx,y+48),21,ItemDB.COLORS[int(it.rarity)])
 u.text("%s / 階級%d / T%d / +%d"%[ItemDB.RARITIES[int(it.rarity)],it.grade,it.tier,it.enhance],Vector2(tx,y+76),14,u.GOLD)
 u.text((WeaponDB.attributes(it)+" / "+WeaponDB.type_name(it)) if String(it.slot) in Loadout.WEAPONS else ItemDB.slot_text(String(it.slot)),Vector2(tx,y+100),13,u.TEAL)
 u.text("Art: "+String(it.get("art_id",""))+(" ✓" if ItemDB.art_ready(it) else " / placeholder"),Vector2(tx,y+124),10,u.MUTED)
 var contribution=EquipmentCompare.item_contribution(it);var contribution_parts=[]
 for key in EquipmentCompare.PRIORITY_STATS:
  if contribution.has(key) and absf(float(contribution[key]))>.0001:
   contribution_parts.append(ItemDB.stat_name(key)+" "+ItemDB.stat_value(key,float(contribution[key])))
   if contribution_parts.size()>=3:break
 u.text("装備寄与: "+(" / ".join(contribution_parts) if not contribution_parts.is_empty() else "基礎性能のみ"),Vector2(tx,y+146),11,u.TEAL)
 y+=art_size+38
 var rows=[]
 for table in [it.base,it.affixes]:
  for key in table:
   var limits=it.get("rolls",{}).get(key,[0,table[key]])
   rows.append(ItemDB.stat_text(key,table[key])+"   %.2f / %.2f"%[table[key],limits[1]])
 for i in range(rows.size()):u.text(rows[i],Vector2(x+(i%2)*(r.size.x/2),y+int(i/2)*22),13,u.TEXT)
 y+=ceilf(rows.size()/2.0)*22+8
 for tier in range(1,int(it.tier)+1):
  u.text("T%d %s"%[tier,WeaponDB.tier_text(it,tier)],Vector2(x,y),11,u.TEAL);y+=16
 if int(it.rarity)>=3:u.wrapped_text("固有: "+ItemDB.unique_text(it)+(" / 神話: 武器系統または固有能力のルールを追加変化" if int(it.rarity)==4 else ""),Vector2(x,y+5),r.size.x-36,13,ItemDB.COLORS[int(it.rarity)],19)
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
