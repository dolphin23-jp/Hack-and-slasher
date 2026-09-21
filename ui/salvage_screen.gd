class_name SalvageScreen
extends RefCounted
var opened=false
var bulk=false
var preview=[]
var page=0
func open(p,is_bulk:bool)->void:
 opened=true;bulk=is_bulk;preview=SalvagePolicy.junk_preview(p) if bulk else [];page=0
func act(u,action:String)->bool:
 var g=u.game
 if action=="salvage_rules:close":opened=false;preview=[];return true
 if action=="salvage_rules:confirm":
  g.toast(SalvagePolicy.confirm_junk(g.player,preview));opened=false;preview=[];u.selected=mini(u.selected,g.player.inventory.size()-1);return true
 if action.begins_with("salvage_rules:page:"):page=maxi(0,page+int(action.get_slice(":",2)));return true
 if action=="salvage_rules:toggle":g.profile.settings.auto_salvage_rare=not g.profile.settings.get("auto_salvage_rare",false);g.profile.write_save();return true
 if action.begins_with("salvage_rules:edit:"):
  var key=action.get_slice(":",2);var r=SalvagePolicy.sanitize(g.profile.settings.get("salvage_rules",{}))
  match key:
   "rarity":r.rarity=1-int(r.rarity)
   "quality":
    var values=[.5,.7,.9,1.01];var index=values.find(r.quality);r.quality=values[(index+1)%values.size()]
   "tier":r.tier=int(r.tier)%5+1
   "grade":r.grade=int(r.grade)%6+1
   "keep_weapon":
    var kinds=[""];kinds.append_array(WeaponDB.TYPES.keys());r.keep_weapon=kinds[(kinds.find(r.keep_weapon)+1)%kinds.size()]
  g.profile.settings.salvage_rules=r;g.profile.write_save();return true
 return true
func draw(u)->void:
 var g=u.game;var p=g.player
 u.dim();u.text("ジャンク一括分解の確認" if bulk else "自動分解ルール",Vector2(70,70),30)
 u.button(Rect2(1160,30,230,50),"戻る","salvage_rules:close")
 if bulk:
  var total=0
  for it in preview:total+=Forge.yield_for(it,p.stats)
  u.text("消費予定 %d個 / 獲得素材 %d / 保護中の品は除外"%[preview.size(),total],Vector2(70,125),21,u.GOLD)
  var max_page=maxi(0,ceili(preview.size()/8.0)-1);page=mini(page,max_page)
  for i in range(page*8,mini(page*8+8,preview.size())):
   var it=preview[i];var y=180+(i%8)*63
   u.panel(Rect2(70,y-30,1300,55),u.PANEL,ItemDB.COLORS[int(it.rarity)])
   u.text(it.name,Vector2(90,y),19,ItemDB.COLORS[int(it.rarity)])
   u.text("%s / 階%d / T%d / +%d / ロール %.0f%% / 素材 +%d"%[ItemDB.RARITIES[int(it.rarity)],it.grade,it.tier,it.enhance,SalvagePolicy.quality(it)*100,Forge.yield_for(it,p.stats)],Vector2(640,y),16,u.TEXT)
  u.button(Rect2(70,720,145,45),"◀","salvage_rules:page:-1",page>0)
  u.button(Rect2(235,720,210,45),"%d / %d ▶"%[page+1,max_page+1],"salvage_rules:page:1",page<max_page)
  if not preview.is_empty():u.button(Rect2(780,775,590,65),"表示したジャンク %d個を分解"%preview.size(),"salvage_rules:confirm")
  return
 var r=SalvagePolicy.sanitize(g.profile.settings.get("salvage_rules",{}))
 u.text("拾った時に、以下の条件をすべて満たす装備を分解します。",Vector2(70,125),19,u.MUTED)
 u.button(Rect2(70,165,570,60),"自動分解 "+("ON" if g.profile.settings.get("auto_salvage_rare",false) else "OFF"),"salvage_rules:toggle")
 var labels=["レアリティ: "+ItemDB.RARITIES[r.rarity]+"以下","最高ロール: "+("条件なし" if r.quality>1 else "%.0f%%未満"%[r.quality*100]),"Tier: T%d以下"%r.tier,"階級: %d以下"%r.grade,"残す武器: "+(WeaponDB.TYPES[r.keep_weapon].name if not r.keep_weapon.is_empty() else "指定なし")]
 var keys=["rarity","quality","tier","grade","keep_weapon"]
 for i in range(5):u.button(Rect2(70,255+i*95,570,70),labels[i]+"  →","salvage_rules:edit:"+keys[i])
 u.panel(Rect2(700,165,670,550),u.PANEL,u.LINE)
 u.wrapped_text("ロック・お気に入り・Epic以上は自動分解しません。Affixのどれか1つでも指定品質以上なら保持します。Affixなしは基本性能のロールで判定。範囲不明の旧装備は100%として扱います。残す武器の指定は防具に影響しません。",Vector2(730,205),600,21,u.TEXT,36)
 var matching=p.inventory.filter(func(it):return SalvagePolicy.matches(it,r)).size()
 u.text("現在の所持品では %d個が条件に一致"%matching,Vector2(730,575),22,u.TEAL)
 u.wrapped_text("設定は次に拾う装備へ適用。所持品は変更しません。一括分解はジャンク指定品のみ、別の確認画面で実行します。",Vector2(730,625),590,17,u.MUTED,26)
