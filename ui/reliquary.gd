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
func compact_name(value:String,limit:int=12)->String:
 return value if value.length()<=limit else value.substr(0,limit-1)+"…"
func compact_contribution(it:Dictionary,limit:int=2)->String:
 var source=EquipmentCompare.item_contribution(it);var parts=[]
 for key in EquipmentCompare.PRIORITY_STATS:
  if source.has(key) and absf(float(source[key]))>.0001:
   parts.append(ItemDB.stat_name(key)+" "+ItemDB.stat_value(key,float(source[key])))
   if parts.size()>=limit:break
 return "基礎性能" if parts.is_empty() else " / ".join(parts)
func item_art(u,it:Dictionary,r:Rect2)->void:
 u.panel(r,Color("101a22"),ItemDB.COLORS[int(it.rarity)])
 var texture=load(ItemDB.art_path(it))
 if texture!=null:u.draw_texture_rect(texture,r.grow(-7),false,Color(1,1,1,.92))
 if not ItemDB.art_ready(it):
  u.panel(Rect2(r.position+Vector2(4,r.size.y-22),Vector2(r.size.x-8,18)),Color(0,0,0,.62),Color(0,0,0,0))
  u.text("アート準備中",r.position+Vector2(r.size.x/2,r.size.y-8),10,u.MUTED,true)
func draw_inventory_card(u,it:Dictionary,r:Rect2,action:String,selected:bool)->void:
 u.button(r,"",action,selected)
 item_art(u,it,Rect2(r.position+Vector2(5,5),Vector2(48,r.size.y-10)))
 u.text(compact_name(String(it.name),11),r.position+Vector2(60,21),13,ItemDB.COLORS[int(it.rarity)])
 u.text("%s / T%d / %s"%[ItemDB.RARITIES[int(it.rarity)],int(it.tier),compact_contribution(it,1)],r.position+Vector2(60,43),11,u.MUTED)
func draw_compare_item(u,it:Dictionary,r:Rect2,label:String,contribution:Dictionary)->void:
 u.panel(r,Color("111d26"),ItemDB.COLORS[int(it.rarity)])
 item_art(u,it,Rect2(r.position+Vector2(10,30),Vector2(84,84)))
 var x=r.position.x+106
 u.text(label,Vector2(x,r.position.y+23),12,u.MUTED)
 u.text(compact_name(String(it.name),16),Vector2(x,r.position.y+50),17,ItemDB.COLORS[int(it.rarity)])
 u.text("%s / 階%d / T%d / +%d"%[ItemDB.RARITIES[int(it.rarity)],int(it.grade),int(it.tier),int(it.enhance)],Vector2(x,r.position.y+73),12,u.GOLD)
 var parts=[]
 for key in EquipmentCompare.PRIORITY_STATS:
  if contribution.has(key) and absf(float(contribution[key]))>.0001:
   parts.append(ItemDB.stat_name(key)+" "+ItemDB.stat_value(key,float(contribution[key])))
   if parts.size()>=2:break
 u.text("寄与: "+(" / ".join(parts) if not parts.is_empty() else "基礎性能"),Vector2(x,r.position.y+97),11,u.TEAL)
 if String(it.get("unique",""))!="":u.text("固有: "+compact_name(ItemDB.unique_text(it),18),Vector2(x,r.position.y+119),11,u.MUTED)
func draw_compare_panel(u,it:Dictionary,target_slot:String,r:Rect2)->void:
 var p=u.game.player;var snap=EquipmentCompare.snapshot(p,it,target_slot)
 if snap.is_empty():detail(u,it,r,"比較対象を選択");return
 u.panel(r,u.PANEL,u.LINE)
 u.text("交換比較 / "+ItemDB.slot_text(target_slot),r.position+Vector2(18,25),17,u.GOLD)
 var card_y=r.position.y+42;var card_w=(r.size.x-46)/2
 draw_compare_item(u,snap.current,Rect2(r.position.x+14,card_y,card_w,130),"現在装備",snap.current_contribution)
 draw_compare_item(u,snap.candidate,Rect2(r.position.x+28+card_w,card_y,card_w,130),"交換候補",snap.candidate_contribution)
 u.text("全ステータス  現在 → 交換後  (差分)",r.position+Vector2(18,194),13,u.MUTED)
 var keys=EquipmentCompare.key_stats(snap,6);var cell_w=(r.size.x-36)/3
 for i in range(keys.size()):
  var key=String(keys[i]);var col=i%3;var row=int(i/3);var px=r.position.x+18+col*cell_w;var py=r.position.y+221+row*46
  var before=float(snap.before_stats.get(key,0));var after=float(snap.after_stats.get(key,0));var delta=float(snap.delta.get(key,0))
  u.text(ItemDB.stat_name(key),Vector2(px,py),11,u.MUTED)
  u.text("%s → %s"%[ItemDB.stat_value(key,before),ItemDB.stat_value(key,after)],Vector2(px,py+18),13,u.TEXT)
  u.text(ItemDB.stat_delta(key,delta),Vector2(px+cell_w-54,py+18),12,u.TEAL if delta>0 else (u.RED if delta<0 else u.MUTED))
 var build_y=r.position.y+319
 if target_slot in Loadout.WEAPONS:
  u.text("Chain: "+String(snap.before_order),Vector2(r.position.x+18,build_y),12,u.MUTED)
  u.text("  →  "+String(snap.after_order),Vector2(r.position.x+18,build_y+19),12,u.GOLD)
 else:u.text("Chain構成は変化しません",Vector2(r.position.x+18,build_y+10),12,u.MUTED)
 var gain=" / ".join(snap.gained_build.slice(0,3));var loss=" / ".join(snap.lost_build.slice(0,3))
 u.text("獲得: "+("なし" if gain.is_empty() else gain),Vector2(r.position.x+r.size.x/2,build_y),11,u.TEAL)
 u.text("失う: "+("なし" if loss.is_empty() else loss),Vector2(r.position.x+r.size.x/2,build_y+19),11,u.RED if not loss.is_empty() else u.MUTED)
 var ability_y=build_y+50
 var ability_gain=" / ".join(snap.gained_abilities.slice(0,2));var ability_loss=" / ".join(snap.lost_abilities.slice(0,2))
 u.text("能力 + "+("変化なし" if ability_gain.is_empty() else ability_gain),Vector2(r.position.x+18,ability_y),11,u.TEAL if not ability_gain.is_empty() else u.MUTED)
 u.text("能力 - "+("変化なし" if ability_loss.is_empty() else ability_loss),Vector2(r.position.x+18,ability_y+18),11,u.RED if not ability_loss.is_empty() else u.MUTED)
func draw(u)->void:
 if forge_screen.opened:forge_screen.draw(u);return
 if salvage_screen.opened:salvage_screen.draw(u);return
 var p=u.game.player
 u.dim();u.text("聖遺物庫 / Equipment UI 2.0",Vector2(40,55),30)
 u.button(Rect2(790,24,140,48),"保管庫","tab:vault",tab=="vault")
 u.button(Rect2(940,24,140,48),"装備","tab:equipment",tab=="equipment")
 u.button(Rect2(1090,24,140,48),"鍛冶","tab:forge",tab=="forge")
 u.button(Rect2(1240,24,150,48),"戻る","return_victory" if u.game.mode=="victory_inventory" else "inventory")
 if focus_detail and tab=="equipment":draw_focus_detail(u);return
 for i in range(3):
  var slot=Loadout.WEAPONS[i];var it=p.equipment[slot];var x=40+i*455
  u.panel(Rect2(x,94,430,105),u.PANEL,ItemDB.COLORS[int(it.rarity)])
  item_art(u,it,Rect2(x+10,104,52,52))
  u.button(Rect2(x+70,104,240,48),"%d %s / T%d +%d"%[i+1,WeaponDB.type_name(it),it.tier,it.enhance],"slot:"+slot,target==slot)
  u.button(Rect2(x+321,104,98,48),"順序→","swap:"+str(i))
  u.text("寄与 "+compact_contribution(it,2),Vector2(x+70,171),11,u.TEAL)
  var next=p.equipment[Loadout.WEAPONS[(i+1)%3]].weapon_type
  var recipes=ChainResolver.matches(it.weapon_type,next).map(func(recipe):return recipe.name)
  u.text("→ %d  "%[(i+1)%3+1]+("・".join(recipes) if not recipes.is_empty() else "通常連携"),Vector2(x+70,191),11,u.GOLD)
 for i in range(6):
  var slot=ItemDB.SLOTS[i+3];var it=p.equipment[slot];var x=40+i*227;var r=Rect2(x,215,215,52)
  u.button(r,"","slot:"+slot,target==slot);item_art(u,it,Rect2(x+5,220,42,42))
  u.text(ItemDB.slot_text(slot)+" / T%d +%d"%[it.tier,it.enhance],Vector2(x+54,236),12,ItemDB.COLORS[int(it.rarity)])
  u.text(compact_contribution(it,1),Vector2(x+54,256),10,u.MUTED)
 if tab=="forge":draw_forge(u);return
 if tab=="vault":draw_vault(u);return
 var visible=filtered_inventory(p);var per_page=15;var max_page=maxi(0,ceili(visible.size()/float(per_page))-1);inventory_page=mini(inventory_page,max_page)
 u.text("所持品 %d / 80  ・ 表示 %d  ・ 選択すると最適枠と自動比較"%[p.inventory.size(),visible.size()],Vector2(40,303),15,u.GOLD)
 u.button(Rect2(40,274,150,42),"表示: "+filter_label(),"filter")
 u.button(Rect2(210,274,140,42),"並べ替え","sort")
 u.button(Rect2(365,274,240,42),"ジャンク一括分解","bulk")
 var start=inventory_page*per_page;var page_items=visible.slice(start,mini(start+per_page,visible.size()))
 for display_i in range(page_items.size()):
  var index=int(page_items[display_i]);var it=p.inventory[index]
  var r=Rect2(40+(display_i%3)*195,331+int(display_i/3)*64,185,58)
  draw_inventory_card(u,it,r,"item:"+str(index),u.selected==index)
 u.button(Rect2(40,660,190,35),"自動分解ルール "+("ON" if u.game.profile.settings.get("auto_salvage_rare",false) else "OFF"),"auto_salvage",u.game.profile.settings.get("auto_salvage_rare",false))
 u.button(Rect2(245,660,90,35),"◀","page:-1",inventory_page>0)
 u.button(Rect2(345,660,160,35),"%d / %d ▶"%[inventory_page+1,max_page+1],"page:1",inventory_page<max_page)
 u.button(Rect2(40,703,255,48),"誓印盤","oaths")
 u.button(Rect2(310,703,295,48),["攻撃ステータス","防御ステータス","探索ステータス"][stats_group],"stats_group")
 if u.selected<0 or u.selected>=p.inventory.size():
  detail(u,p.equipment[target],Rect2(640,283,748,440),"装備中 / "+ItemDB.slot_text(target));return
 var it=p.inventory[u.selected]
 if not Loadout.accepts(it,target):
  var auto_target=p.item_upgrade_target(it)
  if not auto_target.is_empty():target=auto_target;forge_slot=auto_target
 draw_compare_panel(u,it,target,Rect2(640,283,748,440))
 u.button(Rect2(1190,294,178,32),"拡大比較","detail_toggle")
 u.button(Rect2(1000,294,178,32),"保管庫へ","vault_store")
 u.button(Rect2(810,294,178,32),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))
 var valid=Loadout.accepts(it,target)
 u.button(Rect2(640,748,350,48),"この枠へ装備" if valid else "適合する部位を選択","equip_target",valid)
 u.button(Rect2(1000,748,388,48),"分解して素材獲得","salvage")
 u.button(Rect2(640,813,350,48),"ロック / "+("有効" if it.locked else "無効"),"lock")
 u.button(Rect2(1000,813,388,48),"お気に入り / "+("有効" if it.favorite else "無効"),"favorite")

func draw_focus_detail(u)->void:
 var p=u.game.player
 if u.selected<0 or u.selected>=p.inventory.size():focus_detail=false;return
 var it=p.inventory[u.selected];var target_slot=target if Loadout.accepts(it,target) else p.item_upgrade_target(it)
 if target_slot.is_empty():target_slot=String(it.slot)
 var snap=EquipmentCompare.snapshot(p,it,target_slot)
 u.dim();u.text("拡大比較 / "+ItemDB.slot_text(target_slot),Vector2(55,60),29)
 u.button(Rect2(1160,35,220,48),"一覧へ戻る","detail_toggle")
 if snap.is_empty():
  detail(u,it,Rect2(60,100,1320,630),"交換候補");return
 detail(u,snap.current,Rect2(45,100,650,625),"現在装備 / "+ItemDB.slot_text(target_slot))
 detail(u,snap.candidate,Rect2(715,100,680,625),"交換候補")
 var gained=" / ".join(snap.gained_build);var lost=" / ".join(snap.lost_build)
 u.text("Build獲得: "+("なし" if gained.is_empty() else gained),Vector2(70,760),14,u.TEAL)
 u.text("Build失う: "+("なし" if lost.is_empty() else lost),Vector2(70,786),14,u.RED if not lost.is_empty() else u.MUTED)
 u.button(Rect2(920,770,210,48),"保管庫へ","vault_store")
 u.button(Rect2(1150,770,210,48),"ジャンク "+("ON" if it.get("junk",false) else "OFF"),"junk",it.get("junk",false))

func draw_vault(u)->void:
 var g=u.game;var p=g.player;var list=g.profile.vault;var per_page=15
 var max_page=maxi(0,ceili(list.size()/float(per_page))-1);vault_page=mini(vault_page,max_page)
 u.text("保管庫 %d / 120  ・ アート/比較データを保持してRunをまたいで保存"%list.size(),Vector2(40,303),16,u.GOLD)
 var start=vault_page*per_page;var end=mini(start+per_page,list.size())
 for display_i in range(end-start):
  var index=start+display_i;var it=list[index];var r=Rect2(40+(display_i%3)*195,331+int(display_i/3)*64,185,58)
  draw_inventory_card(u,it,r,"vault_item:"+str(index),vault_selected==index)
 u.button(Rect2(40,660,110,38),"◀","vault_page:-1",vault_page>0)
 u.button(Rect2(165,660,180,38),"▶ %d / %d"%[vault_page+1,max_page+1],"vault_page:1",vault_page<max_page)
 if list.is_empty():
  u.text("保管庫は空です。装備画面の「保管庫へ」から移動できます。",Vector2(1010,510),19,u.MUTED,true);return
 vault_selected=clampi(vault_selected,0,list.size()-1)
 if vault_selected<start or vault_selected>=end:vault_selected=start
 var it=list[vault_selected];var target_slot=p.item_upgrade_target(it)
 if target_slot.is_empty():target_slot=String(it.slot)
 draw_compare_panel(u,it,target_slot,Rect2(640,283,748,440))
 u.button(Rect2(940,785,448,52),"所持品へ取り出す","vault_take",p.inventory.size()<80)

func detail(u,it:Dictionary,r:Rect2,label:String)->void:
 u.panel(r,u.PANEL,ItemDB.COLORS[int(it.rarity)])
 var x=r.position.x+18;var y=r.position.y+26
 u.text(label,Vector2(x,y),14,u.MUTED)
 var art_size=minf(150.0,minf(r.size.x*.24,r.size.y*.31));var art_r=Rect2(x,y+18,art_size,art_size)
 item_art(u,it,art_r)
 u.text("ART "+String(it.get("art_id","legacy")),Vector2(x+art_size/2,art_r.end.y+18),9,u.MUTED,true)
 var tx=x+art_size+28;var tw=r.size.x-art_size-64
 u.text(it.name,Vector2(tx,y+34),22,ItemDB.COLORS[int(it.rarity)])
 u.text("%s / 階級%d / T%d / +%d / %s"%[ItemDB.RARITIES[int(it.rarity)],it.grade,it.tier,it.enhance,WeaponDB.attributes(it) if it.slot in Loadout.WEAPONS else ItemDB.slot_text(it.slot)],Vector2(tx,y+60),14,u.GOLD)
 u.text("装備寄与: "+compact_contribution(it,3),Vector2(tx,y+86),13,u.TEAL)
 var rows=[]
 for table in [it.base,it.affixes]:
  for key in table:
   var limits=it.get("rolls",{}).get(key,[0,table[key]])
   rows.append(ItemDB.stat_text(key,table[key])+"  / max "+ItemDB.stat_value(key,float(limits[1])))
 for i in range(rows.size()):
  u.text(rows[i],Vector2(tx+(i%2)*(tw/2),y+116+int(i/2)*22),12,u.TEXT)
 var content_y=maxf(art_r.end.y+42,y+130+ceilf(rows.size()/2.0)*22)
 if String(it.get("slot","")) in Loadout.WEAPONS:
  var kind=String(it.get("weapon_type","sword"))
  u.text("Weapon Art: "+String(WeaponActionResolver.ARTS[kind].name),Vector2(x,content_y),13,u.GOLD);content_y+=22
 for tier in range(2,mini(5,int(it.tier))+1):
  u.text("T%d  %s"%[tier,WeaponDB.tier_text(it,tier)],Vector2(x,content_y),12,u.TEAL);content_y+=19
 if String(it.get("unique",""))!="":
  u.wrapped_text("固有: "+ItemDB.unique_text(it),Vector2(x,content_y+4),r.size.x-36,13,ItemDB.COLORS[int(it.rarity)],20)

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
