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
const TIERS=["基礎性能","攻撃範囲 +15% / 防具は障壁回復","複数命中で障壁 / 防具は回復強化","集敵・貫通・防御崩し / 防具は致命撃耐性","3番目に追加攻撃 / 防具はチェイン障壁"]
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
