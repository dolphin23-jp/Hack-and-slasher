class_name ItemDB
extends RefCounted
const RARITIES=["Common","Rare","Epic","Legendary","Mythic"]
const COLORS=[Color("b6c5c8"),Color("78b5ed"),Color("dcacd9"),Color("f4be68"),Color("ff80bd")]
const SLOTS=["weapon","weapon2","weapon3","head","armor","hands","feet","accessory","accessory2"]
const SLOT_LABELS={"weapon":"武器1","weapon2":"武器2","weapon3":"武器3","head":"頭","armor":"胴","hands":"手","feet":"足","accessory":"装飾1","accessory2":"装飾2"}
const AFFIXES={"attack":["攻撃力",3.0,7.0],"haste":["攻撃速度",.04,.09],"crit":["クリティカル率",.025,.05],"crit_damage":["クリティカル威力",.12,.25],"hp":["最大生命",13.0,27.0],"speed":["移動速度",.025,.055],"cdr":["クールダウン短縮",.025,.055],"armor":["防御力",4.0,10.0],"skill":["スキル威力",.06,.12],"slash":["斬撃威力",.04,.12],"blunt":["打撃威力",.04,.12],"pierce":["貫撃威力",.04,.12],"magic":["魔撃威力",.04,.12],"penetration":["防御貫通",.03,.1],"stagger":["怯ませ性能",.05,.15],"shield_max":["障壁最大値",5,15],"shield_regen":["障壁回復",1,3],"fatal_resist":["致命撃耐性",.03,.1],"knock_resist":["押出耐性",.05,.15],"healing":["回復補正",.04,.12],"dodge_cdr":["回避短縮",.03,.09],"dodge_distance":["回避距離",.04,.12],"drop_rate":["ドロップ率",.05,.15],"rarity_find":["希少品発見",.05,.15],"material_find":["素材発見",.05,.15],"salvage":["分解効率",.05,.15]}
const AFFIX_PROFILES={
 "sword":{"slash":6.0,"crit":4.0,"crit_damage":3.0,"haste":2.5,"attack":2.0},
 "scythe":{"slash":6.0,"haste":3.0,"stagger":3.0,"crit":2.5,"attack":2.0},
 "spear":{"pierce":7.0,"penetration":4.5,"crit":3.0,"attack":2.0,"stagger":2.0},
 "staff":{"magic":7.0,"skill":4.5,"cdr":3.5,"crit":2.5},
 "fist":{"blunt":7.0,"haste":5.0,"crit":3.5,"stagger":3.0},
 "mace":{"blunt":7.0,"stagger":5.0,"penetration":3.0,"armor":2.0},
 "spellblade":{"magic":5.0,"slash":5.0,"skill":3.5,"crit":3.0},
 "head":{"crit":5.0,"crit_damage":4.0,"skill":3.5,"cdr":2.5,"hp":2.0},
 "armor":{"hp":6.0,"armor":6.0,"shield_max":4.5,"shield_regen":3.5,"fatal_resist":3.0},
 "hands":{"haste":6.0,"crit":4.5,"blunt":2.5,"slash":2.5,"pierce":2.5,"magic":2.5},
 "feet":{"speed":6.0,"dodge_cdr":5.0,"dodge_distance":5.0,"knock_resist":2.5},
 "accessory":{"skill":4.0,"crit":3.5,"cdr":3.0,"rarity_find":2.5,"drop_rate":2.5,"material_find":2.0},
 "accessory2":{"skill":4.0,"crit":3.5,"cdr":3.0,"rarity_find":2.5,"drop_rate":2.5,"material_find":2.0}}
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
 {"name":"処刑台の火種","slot":"weapon","effect":"execution","set":"cinder","text":"剣3段目が生命30%以下の敵へ追加100%威力。ボスにも有効。"},
 {"name":"巡礼の三日月","slot":"weapon","effect":"weapon_sword","set":"","weapon_type":"sword","text":"3番目の範囲拡大"},
 {"name":"二重の月蝕","slot":"weapon","effect":"weapon_scythe","set":"","weapon_type":"scythe","text":"鎌の二重回転"},
 {"name":"天穿つ三叉","slot":"weapon","effect":"weapon_spear","set":"","weapon_type":"spear","text":"槍の側方へ貫通波"},
 {"name":"反響の水晶杖","slot":"weapon","effect":"weapon_staff","set":"","weapon_type":"staff","text":"魔力弾が壁で反射"},
 {"name":"轟く拳誓","slot":"weapon","effect":"weapon_fist","set":"","weapon_type":"fist","text":"3番目に周囲打撃"},
 {"name":"城塞を拓く槌","slot":"weapon","effect":"weapon_mace","set":"","weapon_type":"mace","text":"障壁消費で範囲拡大"},
 {"name":"巡る守護の魔刃","slot":"weapon","effect":"weapon_spellblade","set":"","weapon_type":"spellblade","text":"チェイン完了で障壁"},
 {"name":"満ちる星冠","slot":"head","effect":"threefold_crown","set":"","text":"障壁最大時、魔撃武器が二重化する。"},
 {"name":"不落の城壁","slot":"armor","effect":"threefold_armor","set":"","text":"3番目の攻撃で障壁を消費して威力へ変える。"},
 {"name":"反撃の籠手","slot":"hands","effect":"threefold_hands","set":"","text":"武器連携中のクリティカル率を高める。"},
 {"name":"回避の足甲","slot":"feet","effect":"threefold_feet","set":"","text":"回避後、次の武器を1つ先へ進めて順番を変える。"},
 {"name":"連環の環","slot":"accessory","effect":"threefold_ring","set":"","text":"武器連携攻撃の威力を増幅する。"}]
static func legend_info(effect:String)->Dictionary:
 for l in LEGENDS:
  if l.effect==effect:return l
 return {}
static func set_of(item:Dictionary)->String:
 return legend_info(item.get("effect", "")).get("set", "")
const GRADES=[1.0,1.24,1.54,1.91,2.37,2.94]
const ROLLS=[[.88,1.12],[1.05,1.25],[1.20,1.45],[1.40,1.70],[1.70,2.05]]
const UNIQUE=["wide_chain","double_spin","split_lance","ricochet","fist_nova","shield_reach","chain_guard"]
const NONWEAPON_UNIQUES={"head":"full_shield_magic_double","armor":"shield_spend_power","hands":"transition_crit","feet":"dodge_skip","accessory":"transition_echo","accessory2":"transition_echo"}
const UNIQUE_TEXT={
 "full_shield_magic_double":"障壁が最大なら魔撃武器の攻撃回数 +1",
 "shield_spend_power":"3番目で障壁10を消費し威力 +25%",
 "transition_crit":"武器連携中のクリティカル率 +8%",
 "dodge_skip":"回避後の次攻撃は武器を1枠先へ進める",
 "transition_echo":"武器連携攻撃の威力 +12%"}
static func unique_text(item:Dictionary)->String:
 var key=String(item.get("unique",""))
 return WeaponDB.UNIQUE_TEXT.get(key,UNIQUE_TEXT.get(key,"継承された固有能力"))
static func generate(rng:RandomNumberGenerator,depth:int,rarity:int=-1,legend:int=-1)->Dictionary:
 if rarity<0:rarity=roll_rarity(rng,0)
 rarity=clampi(rarity,0,4)
 var slots=["weapon","head","armor","hands","feet","accessory"]
 var slot=slots[rng.randi_range(0,slots.size()-1)]
 var kind=WeaponDB.TYPES.keys()[rng.randi_range(0,6)]
 var grade=clampi(1+int((depth-1)/3.0),1,6)
 var tier=clampi(1+int((depth-1)/2.0),1,5)
 var name=WeaponDB.NAMES[kind][grade-1] if slot=="weapon" else ["巡礼","青銅","黒鉄","聖鋼","月銀","星冠"][grade-1]+SLOT_LABELS[slot]
 var effect="";var description=""
 if rarity>=3:
  var legend_index=legend if legend>=0 and legend<LEGENDS.size() else rng.randi_range(0,LEGENDS.size()-1)
  var l=LEGENDS[legend_index]
  kind=l.get("weapon_type",WeaponDB.TYPES.keys()[legend_index%7])
  slot=l.slot;name=l.name;effect=l.effect
  var preview_unique=UNIQUE[WeaponDB.TYPES.keys().find(kind)] if slot=="weapon" else NONWEAPON_UNIQUES.get(slot,"transition_echo")
  description=WeaponDB.UNIQUE_TEXT.get(preview_unique,UNIQUE_TEXT.get(preview_unique,"固有能力"))
 var ranges={};var base={};var power=GRADES[grade-1]
 var templates={"weapon":{"attack":10.0},"armor":{"armor":9.0,"hp":16.0},"head":{"hp":10.0},"hands":{"haste":.035},"feet":{"speed":.03},"accessory":{"crit":.02,"skill":.04}}
 for key in templates[slot]:
  var unit=templates[slot][key]*power
  ranges[key]=[unit*ROLLS[rarity][0],unit*ROLLS[rarity][1]]
  base[key]=snappedf(rng.randf_range(ranges[key][0],ranges[key][1]),.001)
 var affixes={};var keys=AFFIXES.keys().filter(func(k):return not base.has(k))
 if tier<4:keys=keys.filter(func(k):return k not in ["penetration","fatal_resist","shield_regen"])
 for i in range([0,1,2,3,4][rarity]):
  var key=weighted_affix(rng,keys,slot,kind);keys.erase(key)
  ranges[key]=affix_range(key,grade,rarity)
  affixes[key]=snappedf(rng.randf_range(ranges[key][0],ranges[key][1]),.001)
 var unique=(UNIQUE[WeaponDB.TYPES.keys().find(kind)] if slot=="weapon" else NONWEAPON_UNIQUES.get(slot,"transition_echo")) if rarity>=3 else ""
 return {"schema":3,"id":str(rng.randi())+"-"+str(rng.randi()),"name":name,"rarity":rarity,"slot":slot,"weapon_type":kind,"grade":grade,"tier":tier,"enhance":0,"fusion":0,"base":base,"affixes":affixes,"rolls":ranges,"effect":effect,"unique":unique,"description":description,"locked":false,"favorite":false}
static func affix_range(key:String,grade:int,rarity:int)->Array:
 var def=AFFIXES[key]
 var scale=GRADES[clampi(grade,1,6)-1] if key in ["attack","hp","armor","shield_max","shield_regen"] else 1.0
 return [def[1]*scale*ROLLS[clampi(rarity,0,4)][0],def[2]*scale*ROLLS[clampi(rarity,0,4)][1]]
static func weighted_affix(rng:RandomNumberGenerator,keys:Array,slot:String,kind:String)->String:
 var profile_key=kind if slot=="weapon" else slot
 var profile:Dictionary=AFFIX_PROFILES.get(profile_key,{})
 var total=0.0
 for key in keys:total+=float(profile.get(key,.35))
 var roll=rng.randf()*total
 for key in keys:
  roll-=float(profile.get(key,.35))
  if roll<=0:return String(key)
 return String(keys[-1])
static func roll_rarity(rng:RandomNumberGenerator,find:float)->int:
 var weights=[55.0,28.0,13.0,3.6,.4];var bonus=1+clampf(find,0,2)
 var total=weights[0]
 for i in range(1,5):weights[i]*=bonus;total+=weights[i]
 var roll=rng.randf()*total
 for i in range(5):
  roll-=weights[i]
  if roll<=0:return i
 return 4
static func initial_items()->Dictionary:
 var out={};var rng=RandomNumberGenerator.new();rng.seed=314159
 for slot in SLOTS:
  var it=generate(rng,1,0);it.slot=slot;it.id="starter-"+slot;it.base={};it.affixes={}
  if slot in Loadout.WEAPONS:
   it.weapon_type=["sword","scythe","staff"][Loadout.WEAPONS.find(slot)];it.base={"attack":9.0};it.name=WeaponDB.NAMES[it.weapon_type][0]
  else:it.name="巡礼者の"+SLOT_LABELS[slot]
  if slot=="armor":it.base={"armor":7.0,"hp":14.0}
  if slot=="accessory":it.base={"crit":.02}
  it.rolls={}
  out[slot]=it
 return out
static func slot_text(slot:String)->String:
 return SLOT_LABELS.get(slot,slot)
static func stat_text(key:String,value:float)->String:
 return ("+%d %s"%[roundi(value),AFFIXES.get(key,[key])[0]]) if key in ["attack","hp","armor","shield_max","shield_regen"] else ("+%d%% %s"%[roundi(value*100),AFFIXES.get(key,[key])[0]])
static func valid(item:Variant)->bool:
 if not item is Dictionary:return false
 for k in ["id","name","rarity","slot","base","affixes","effect","description","tier"]:
  if not item.has(k):return false
 for k in ["id","name","slot","effect","description"]:
  if not item[k] is String:return false
 if not item.slot in SLOTS:return false
 for k in ["tier","rarity"]:
  if not (item[k] is int or item[k] is float):return false
  if not is_finite(float(item[k])) or item[k]!=int(item[k]):return false
 if item.rarity<0 or item.rarity>4 or item.tier<1 or item.tier>300:return false
 for table in [item.base,item.affixes]:
  if not table is Dictionary:return false
  for k in table:
   if not k in AFFIXES or not (table[k] is float or table[k] is int):return false
   if not is_finite(float(table[k])) or table[k]<0 or table[k]>100000:return false
 if item.has("schema"):
  for key in ["schema","grade","enhance","fusion"]:
   if not (item.get(key) is int or item.get(key) is float):return false
   if not is_finite(float(item[key])) or item[key]!=int(item[key]):return false
  if item.schema!=3 or item.grade<1 or item.grade>6 or item.enhance<0 or item.enhance>10 or item.fusion<0 or item.fusion>100000 or item.tier>5:return false
  if not item.get("weapon_type") is String or not WeaponDB.TYPES.has(item.weapon_type):return false
  if not item.get("locked") is bool or not item.get("favorite") is bool:return false
  if not item.get("unique") is String or not item.get("rolls") is Dictionary:return false
  for key in item.rolls:
   var limits=item.rolls[key]
   if not limits is Array or limits.size()!=2:return false
   for n in limits:
    if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>1000000:return false
 return true
