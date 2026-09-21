class_name BuildDB
extends RefCounted
# Choices are data-driven; mutually exclusive paths use numeric upgrade keys so
# pre-expansion profiles retain their original save format.
const LANCE_PATHS=[
 {"name":"三叉の誓い","detail":"ランスを3方向へ。1本65%威力。集団を扇状に貫く。後続の祝福で5本へ。","icon":"bolt","key":"lance_fan","value":1.0,"family":"lance"},
 {"name":"王を穿つ槍","detail":"ランスが巨大化。幅3倍、威力180%、鈍足2秒。後続の祝福で再使用を短縮。","icon":"bolt","key":"lance_giant","value":1.0,"family":"lance"},
 {"name":"弔いの流星","detail":"ランスが最初の敵で爆発。直撃100%＋周囲へ90%。後続の祝福で爆発が拡大。","icon":"flame","key":"lance_blast","value":1.0,"family":"lance"}]
const CHOICES=[
 {"name":"五重の合唱","detail":"三叉の誓いを5本へ進化。扇角も拡大。","icon":"bolt","key":"fan_mastery","value":1.0,"requires":"lance_fan","max":1},
 {"name":"終わらぬ貫通","detail":"巨大ランスのCTを25%短縮、さらに威力30%増加。","icon":"bolt","key":"giant_mastery","value":1.0,"requires":"lance_giant","max":1},
 {"name":"灰の超新星","detail":"流星の爆発半径 +65。爆発威力 +40%。","icon":"flame","key":"blast_mastery","value":1.0,"requires":"lance_blast","max":1},
 {"name":"断罪の余韻","detail":"剣の3段目が衝撃波を放つ。断罪は威力20%増加。","icon":"cleave","key":"finisher_wave","value":1.0,"max":1},
 {"name":"白夜の引力","detail":"ノヴァが敵を引き寄せる。3段目と範囲装備をつなぐ。","icon":"nova","key":"nova_pull","value":1.0,"max":1},
 {"name":"追憶の輪","detail":"ノヴァに遅れて50%威力の残響が発生する。","icon":"nova","key":"nova_echo","value":1.0,"max":1},
 {"name":"見切りの誓い","detail":"直前回避の反撃が75%強化に。回避の再使用もさらに短縮。","icon":"dash","key":"riposte","value":1.0,"max":1},
 {"name":"狩人の歩幅","detail":"回避CT -20%。回避直後の剣攻撃の射程 +35。","icon":"dash","key":"dash_hunter","value":1.0,"max":1},
 {"name":"雷鳴の継承","detail":"直前回避の反撃が近くの敵2体へ雷撃。見切り5回で解放。","icon":"chain","key":"storm_counter","value":1.0,"max":1,"unlock":"evader"},
 {"name":"残火の収穫","detail":"炎上中の敵を倒すと生命を4回復。契約達成で解放。","icon":"flame","key":"ember_harvest","value":1.0,"max":1,"unlock":"risk"}]
const SET_NAMES={"storm":"雷の遺産","cinder":"残り火","echo":"残響"}
const SET_TEXT={"storm":"2部位: 雷撃が最大5体へ。ランスの初撃にも雷撃が発生。","cinder":"2部位: 炎上中の敵への剣・直接スキルダメージ +30%。","echo":"2部位: スキル使用で次の剣3段目が2連撃になる。"}
static func lance_key(upgrades:Dictionary)->String:
 for c in LANCE_PATHS:
  if upgrades.get(c.key,0)>0:return c.key
 return ""
static func chain_choices(equipment:Dictionary,upgrades:Dictionary)->Array:
 var kinds=[];var attrs=[]
 for slot in Loadout.WEAPONS:
  var kind=String(equipment[slot].get("weapon_type","sword"));kinds.append(kind)
  var attr=String(WeaponDB.get_weapon(equipment[slot]).types[0])
  if attr not in attrs:attrs.append(attr)
 var out=[]
 for kind in kinds:
  var key="master_"+kind
  if out.any(func(c):return c.key==key) or upgrades.get(key,0)>0:continue
  out.append({"name":WeaponDB.TYPES[kind].name+"の研鑽","detail":WeaponDB.TYPES[kind].name+"の通常攻撃威力 +10%。現在の三連構成に直接効く。","icon":"sword","key":key,"value":.10,"max":1})
 if upgrades.get("transition_power",0)<=0:out.append({"name":"継ぎ目を断つ","detail":"時間内の武器遷移ボーナス威力 +10%。順番を組む価値を高める。","icon":"cleave","key":"transition_power","value":.10,"max":1})
 if upgrades.get("slot2_reach",0)<=0:out.append({"name":"第二歩の間合い","detail":"第2武器の攻撃範囲 +18%。中継武器を集団処理へ寄せる。","icon":"dash","key":"slot2_reach","value":.18,"max":1})
 if attrs.size()==3 and upgrades.get("triune_mastery",0)<=0:out.append({"name":"三相の誓い","detail":"3属性が異なる三連フィニッシュの威力 +18%。","icon":"crit","key":"triune_mastery","value":.18,"max":1})
 if kinds[0]==kinds[1] and kinds[1]==kinds[2] and upgrades.get("same_family_mastery",0)<=0:out.append({"name":"一器専心","detail":"同武器3連フィニッシュの威力 +22%。","icon":"crit","key":"same_family_mastery","value":.22,"max":1})
 for i in range(3):
  var next=(i+1)%3
  if kinds[i]=="scythe" and kinds[next]=="staff" and upgrades.get("harvest_cast_mastery",0)<=0:
   out.append({"name":"刈り集め、穿つ","detail":"鎌→杖の収束魔撃を強化。威力と射程をさらに +12%。","icon":"bolt","key":"harvest_cast_mastery","value":.12,"max":1})
   break
 return out
static func available(upgrades:Dictionary,unlocks:Array)->Array:
 var out=[]
 if lance_key(upgrades).is_empty():out.append_array(LANCE_PATHS.duplicate(true))
 for c in CHOICES:
  if upgrades.get(c.key,0)>=c.get("max",99):continue
  if c.has("requires") and upgrades.get(c.requires,0)<=0:continue
  if c.has("unlock") and c.unlock not in unlocks:continue
  out.append(c.duplicate(true))
 return out
