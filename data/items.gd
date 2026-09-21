class_name ItemDB
extends RefCounted
const RARITIES=["コモン","マジック","レア","レジェンダリー"]
const COLORS=[Color("b6c5c8"),Color("78b5ed"),Color("dcacd9"),Color("f4be68")]
const SLOTS=["weapon","armor","accessory"]
const SLOT_LABELS={"weapon":"武器","armor":"防具","accessory":"装飾品"}
const AFFIXES={"attack":["攻撃力",3.0,7.0],"haste":["攻撃速度",.04,.09],"crit":["クリティカル率",.025,.05],"crit_damage":["クリティカル威力",.12,.25],"hp":["最大生命",13.0,27.0],"speed":["移動速度",.025,.055],"cdr":["クールダウン短縮",.025,.055],"armor":["防御力",4.0,10.0],"skill":["スキル威力",.06,.12]}
const LEGENDS=[
 {"name":"サンダー・テスタメント","slot":"weapon","effect":"chain","set":"storm","text":"撃破時に最大3体へ攻撃力90%の雷撃。雷撃は再連鎖しない。"},
 {"name":"シンダーウェイク","slot":"armor","effect":"fire_dash","set":"cinder","text":"回避に3秒の炎。毎秒攻撃力110%。同じ場所の炎は重複しない。"},
 {"name":"グラス・クワイア","slot":"accessory","effect":"echo","set":"echo","text":"剣攻撃2回ごとに55%威力の貫通霊刃を2本放つ。"},
 {"name":"ハート・オブ・パイア","slot":"accessory","effect":"crit_blast","set":"cinder","text":"クリティカルで周囲に80%威力の爆発。CT 0.7秒。"},
 {"name":"嵐を縫う針","slot":"weapon","effect":"lance_fork","set":"storm","text":"ランスに45%威力の側射を2本追加。多重・巨大・爆発の各分岐と併用できる。"},
 {"name":"三度鳴る弔鐘","slot":"weapon","effect":"reaper","set":"echo","text":"剣の3段目が周囲に75%威力のノヴァを起こす。"},
 {"name":"灰冠の刃","slot":"weapon","effect":"ash_edge","set":"cinder","text":"剣で敵を2.5秒炎上させる。毎秒35%威力。炎上は重複せず更新。"},
 {"name":"雷を抱く外套","slot":"armor","effect":"storm_guard","set":"storm","text":"直前回避で近くの敵へ140%威力の雷撃。回避に攻撃の役割を与える。"},
 {"name":"名残の聖衣","slot":"armor","effect":"echo_guard","set":"echo","text":"ノヴァ使用時、最大生命12%の障壁を5秒獲得。"},
 {"name":"不死鳥の印","slot":"accessory","effect":"phoenix","set":"cinder","text":"回復薬で炎のノヴァ。200%威力、炎上3秒。"},
 {"name":"避雷の環","slot":"accessory","effect":"conductor","set":"storm","text":"ノヴァに当たった敵を起点に最大3体へ雷撃。1回の詠唱につき1度。"},
 {"name":"双鐘の柄","slot":"weapon","effect":"judgement_echo","set":"echo","text":"断罪が0.35秒後に70%威力の追撃を残す。"},
 {"name":"巡礼の灰衣","slot":"armor","effect":"ember_nova","set":"cinder","text":"ノヴァの中心に3秒の炎を残す。毎秒90%威力。"},
 {"name":"帰還の聖針","slot":"accessory","effect":"lance_return","set":"echo","text":"ランスが壁か射程端に届くと60%威力で一度だけ帰還する。"},
 {"name":"夜明けの留め金","slot":"armor","effect":"dash_nova","set":"storm","text":"回避の終点に70%威力の小ノヴァ。CT 1.2秒。"},
 {"name":"処刑台の火種","slot":"weapon","effect":"execution","set":"cinder","text":"剣3段目が生命30%以下の敵へ追加100%威力。ボスにも有効。"}]
static func legend_info(effect:String)->Dictionary:
 for l in LEGENDS:
  if l.effect==effect:return l
 return {}
static func set_of(item:Dictionary)->String:
 return legend_info(item.get("effect", "")).get("set", "")
static func generate(rng:RandomNumberGenerator,tier:int,rarity:int=-1,legend:int=-1)->Dictionary:
 tier=maxi(1,tier)
 if rarity<0:
  var roll=rng.randf();rarity=3 if roll<.018 else (2 if roll<.18 else (1 if roll<.59 else 0))
 var slot=SLOTS[rng.randi_range(0,2)];var effect="";var desc="";var item_name=""
 if rarity==3:
  var l=LEGENDS[legend if legend>=0 else rng.randi_range(0,LEGENDS.size()-1)]
  slot=l.slot;effect=l.effect;desc=l.text;item_name=l.name
 else:
  var bases={"weapon":["ピルグリム・エッジ","ヴィジル・ブレード","グレイヴ・サーベル","オーススティール"],"armor":["ヴェスパー・メイル","ウォーデン・プレート","アッシュウィーヴ","セパルクラル・コート"],"accessory":["シンダー・シール","ムーン・レリクアリ","モーニング・ノット","アイボリー・タリスマン"]}
  item_name=bases[slot][rng.randi_range(0,3)]
  if rarity>0:item_name=["鋭利な","聖別された","復讐の","共鳴する"][rng.randi_range(0,3)]+item_name
 var power=1.0+maxi(0,tier-1)*.18;var base={}
 if slot=="weapon":base.attack=round((10+rarity*3.8)*power*rng.randf_range(.9,1.12))
 if slot=="armor":base={"armor":round((9+rarity*4)*power),"hp":round((16+rarity*6)*power)}
 if slot=="accessory":base={"crit":.02+rarity*.01,"skill":.04+rarity*.025}
 var affixes={};var keys=AFFIXES.keys()
 for i in range([0,2,3,4][rarity]):
  var key=keys.pop_at(rng.randi_range(0,keys.size()-1));var def=AFFIXES[key]
  var value=rng.randf_range(def[1],def[2])*(power if key in ["attack","hp","armor"] else 1+(tier-1)*.035)
  affixes[key]=snapped(value,1.0 if key in ["attack","hp","armor"] else .001)
 return {"id":str(rng.randi())+"-"+str(rng.randi()),"name":item_name,"rarity":rarity,"slot":slot,"tier":tier,"base":base,"affixes":affixes,"effect":effect,"description":desc}
static func initial_items()->Dictionary:
 var out={}
 for i in range(3):
  out[SLOTS[i]]={"id":"starter-"+SLOTS[i],"name":["古びたオースブレード","巡礼者のマント","破れぬ誓い"][i],"rarity":0,"slot":SLOTS[i],"tier":1,"base":[{"attack":9},{"armor":7,"hp":14},{"crit":.02}][i],"affixes":{},"effect":"","description":""}
 return out
static func slot_text(slot:String)->String:
 return SLOT_LABELS.get(slot,slot)
static func stat_text(key:String,value:float)->String:
 return ("+%d %s"%[roundi(value),AFFIXES[key][0]]) if key in ["attack","hp","armor"] else ("+%d%% %s"%[roundi(value*100),AFFIXES[key][0]])
static func valid(item:Variant)->bool:
 if not item is Dictionary:return false
 for k in ["id","name","rarity","slot","base","affixes","effect","description","tier"]:
  if not item.has(k):return false
 for k in ["id","name","slot","effect","description"]:
  if not item[k] is String:return false
 if not item.slot in SLOTS:return false
 for k in ["tier","rarity"]:
  if not (item[k] is int or item[k] is float):return false
 if item.rarity<0 or item.rarity>3 or item.tier<1 or item.tier>300:return false
 for table in [item.base,item.affixes]:
  if not table is Dictionary:return false
  for k in table:
   if not k in AFFIXES or not (table[k] is float or table[k] is int):return false
   if not is_finite(float(table[k])) or table[k]<0 or table[k]>100000:return false
 return true
