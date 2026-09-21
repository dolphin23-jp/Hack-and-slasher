class_name WeaponDB
extends RefCounted
const UNIQUE_TEXT={"wide_chain":"3番目の範囲がさらに20%拡大","double_spin":"鎌が二重に回転","split_lance":"槍から側方へ貫通波2本","ricochet":"魔力弾が壁で2回反射","fist_nova":"3番目に周囲打撃","shield_reach":"障壁5消費で範囲30%増加","chain_guard":"3連携完了で障壁を獲得"}
const TYPES={
 "sword":{"name":"剣","shape":"fan","types":["slash"],"reach":132.0,"arc":1.15,"damage":1.15,"knock":185.0,"cooldown":.24,"hits":1},
 "scythe":{"name":"鎌","shape":"circle","types":["slash"],"reach":178.0,"arc":3.15,"damage":1.2,"knock":210.0,"cooldown":.29,"hits":1},
 "spear":{"name":"槍","shape":"line","types":["pierce"],"reach":310.0,"arc":.14,"damage":1.3,"knock":230.0,"cooldown":.26,"hits":1},
 "staff":{"name":"杖","shape":"bolt","types":["magic"],"reach":640.0,"arc":.1,"damage":1.25,"knock":120.0,"cooldown":.27,"hits":1},
 "fist":{"name":"籠手","shape":"fan","types":["blunt"],"reach":110.0,"arc":.95,"damage":.52,"knock":320.0,"cooldown":.18,"hits":2},
 "mace":{"name":"メイス","shape":"fan","types":["blunt"],"reach":148.0,"arc":1.4,"damage":1.35,"knock":390.0,"cooldown":.28,"hits":1},
 "spellblade":{"name":"魔刃","shape":"wave","types":["slash","magic"],"reach":380.0,"arc":1.1,"damage":1.3,"knock":190.0,"cooldown":.25,"hits":1}}
const NAMES={"sword":["ボロの剣","青銅の剣","鉄の剣","鋼の剣","ミスリルの剣","星銀の剣"],"scythe":["欠けた鎌","墓守の鎌","黒鉄の鎌","月弧の鎌","霊樹の大鎌","星を刈る鎌"],"spear":["折れた槍","狩人の槍","鉄翼の槍","城塞の槍","白金の槍","天穿つ槍"],"staff":["枯枝の杖","巡礼の杖","水晶の杖","賢者の杖","月樹の杖","星詠みの杖"],"fist":["古い籠手","革巻の拳","鉄拳","鋼拳","聖銀の拳","流星の拳"],"mace":["朽ちた棍","青銅の棍","鉄のメイス","破城の槌","聖堂の槌","星砕き"],"spellblade":["鈍い魔刃","刻印の魔刃","霊鉄の魔刃","月影の魔刃","虚空の魔刃","黎明の魔刃"]}
const ATTRIBUTES={"slash":"斬撃","blunt":"打撃","pierce":"貫撃","magic":"魔撃"}
const TIERS=["基礎性能","攻撃範囲 +15% / 防具は障壁回復","武器固有の中核能力 / 防具は回復強化","武器固有の制圧能力 / 防具は致命撃耐性","武器固有フィニッシュ / 防具はチェイン障壁"]
const TIER_TEXT_BY_WEAPON={
 "sword":["基礎性能","間合い +15%","複数命中で障壁","強ノックバックで前線維持","3番目に追い斬り"],
 "scythe":["基礎性能","回転半径 +15%","3体以上を巻き込むと追い薙ぎ","命中敵を中心へ引き寄せ","3番目に追加回転"],
 "spear":["基礎性能","刺突距離 +15%","2体目以降への威力 +20%","直線制圧と強ノックバック","3番目に側方貫通波"],
 "staff":["基礎性能","射程 +15%","魔力弾が壁で1回反射","貫通数増加","3番目に三方向魔撃"],
 "fist":["基礎性能","踏み込み間合い +15%","連打命中で障壁","怯ませ性能を強化","3番目に周囲打撃"],
 "mace":["基礎性能","打撃範囲 +15%","複数命中で強障壁","盾持ちを強く崩す","3番目に震撃波"],
 "spellblade":["基礎性能","魔刃射程 +15%","貫通命中で障壁","貫通数増加","3番目に遅延魔爆"]}
static func get_weapon(item:Dictionary)->Dictionary:return TYPES.get(item.get("weapon_type","sword"),TYPES.sword)
static func type_name(item:Dictionary)->String:return get_weapon(item).name
static func attributes(item:Dictionary)->String:
 var names=[]
 for key in get_weapon(item).types:names.append(ATTRIBUTES[key])
 return "＋".join(names)

static func primary_type(item:Dictionary)->String:
 var types:Array=get_weapon(item).types
 return String(types[0]) if not types.is_empty() else ""
static func transition(from_item:Dictionary,to_item:Dictionary)->Dictionary:
 var a=primary_type(from_item);var b=primary_type(to_item)
 if a=="slash" and b=="blunt":return {"id":"sunder","name":"断甲","damage":1.08,"guard":1.28,"knock":1.18}
 if a=="blunt" and b=="pierce":return {"id":"breach","name":"砕穿","damage":1.20,"guard":1.12,"knock":1.0}
 if a=="magic" and b=="slash":return {"id":"spell_edge","name":"魔纏斬","damage":1.16,"guard":1.0,"knock":1.0}
 if from_item.get("weapon_type","")== "scythe" and to_item.get("weapon_type","")=="staff":return {"id":"reap_cast","name":"収束魔撃","damage":1.12,"guard":1.0,"knock":1.0}
 return {"id":"","name":"","damage":1.0,"guard":1.0,"knock":1.0}
static func same_family_chain(equipment:Dictionary)->bool:
 var kind=String(equipment[Loadout.WEAPONS[0]].get("weapon_type",""))
 return not kind.is_empty() and Loadout.WEAPONS.all(func(slot):return equipment[slot].get("weapon_type","")==kind)
static func distinct_primary_chain(equipment:Dictionary)->bool:
 var seen=[]
 for slot in Loadout.WEAPONS:
  var key=primary_type(equipment[slot])
  if key.is_empty() or key in seen:return false
  seen.append(key)
 return seen.size()==3

static func chain_synergy_score(equipment:Dictionary)->int:
 var score=0
 for i in range(3):
  var from_item=equipment[Loadout.WEAPONS[i]]
  var to_item=equipment[Loadout.WEAPONS[(i+1)%3]]
  if not String(transition(from_item,to_item).id).is_empty():score+=1
 if same_family_chain(equipment):score+=2
 if distinct_primary_chain(equipment):score+=2
 return score

static func tier_text(item:Dictionary,tier:int)->String:
 if item.slot not in Loadout.WEAPONS:return TIERS[clampi(tier,1,5)-1]
 var kind=String(item.get("weapon_type","sword"))
 return TIER_TEXT_BY_WEAPON.get(kind,TIERS)[clampi(tier,1,5)-1]
