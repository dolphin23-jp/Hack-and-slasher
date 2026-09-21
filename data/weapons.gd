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
const TIERS=["基礎性能","系統別の間合い強化","系統固有の連撃能力","系統固有の戦場制御","系統固有フィニッシュ"]
const WEAPON_TIER_TEXT={
 "sword":["基礎性能","間合い +10%","連携中の斬撃 +12%","扇角拡大","3番目に追撃斬"],
 "scythe":["基礎性能","回転半径 +16%","3体以上命中で追撃回転","命中敵を引き寄せる","3番目に追加回転"],
 "spear":["基礎性能","射程 +18%","2体目以降 +20%","強ノックバックで盾陣を崩す","3番目に側方貫通波"],
 "staff":["基礎性能","射程 +10%","複数命中で障壁","壁で1回反射","3番目に追撃魔弾"],
 "fist":["基礎性能","間合い +8%","双撃命中で小障壁","ノックバック強化","3番目に周囲打撃"],
 "mace":["基礎性能","間合い +12%","盾崩し時間を延長","攻撃範囲をさらに拡大","3番目に衝撃波"],
 "spellblade":["基礎性能","波動射程 +12%","複数命中で障壁","波動の貫通数増加","3番目に障壁獲得"]
}
const ARMOR_TIER_TEXT={
 "head":["基礎性能","クリ率 +2%","スキル威力 +5%","CD短縮 +3%","3連携ごとに追撃魔撃"],
 "armor":["基礎性能","障壁回復 +1","最大生命 +20","致命撃耐性 +5%","3連携ごとに障壁"],
 "hands":["基礎性能","攻撃速度 +4%","クリ威力 +10%","怯ませ +8%","3連携後の次撃を強化"],
 "feet":["基礎性能","移動速度 +4%","回避短縮 +5%","回避距離 +8%","3連携で回避CT短縮"],
 "accessory":["基礎性能","希少品発見 +4%","スキル威力 +5%","CD短縮 +3%","3連携で全スキルCT短縮"],
 "accessory2":["基礎性能","希少品発見 +4%","スキル威力 +5%","CD短縮 +3%","3連携で全スキルCT短縮"]
}
static func get_weapon(item:Dictionary)->Dictionary:return TYPES.get(item.get("weapon_type","sword"),TYPES.sword)
static func type_name(item:Dictionary)->String:return get_weapon(item).name
static func attributes(item:Dictionary)->String:
 var names=[]
 for key in get_weapon(item).types:names.append(ATTRIBUTES[key])
 return "＋".join(names)
static func tier_text(item:Dictionary,tier:int)->String:
 var index=clampi(tier-1,0,4)
 if item.get("weapon_type","") in WEAPON_TIER_TEXT:return WEAPON_TIER_TEXT[item.weapon_type][index]
 return ARMOR_TIER_TEXT.get(String(item.get("slot","armor")),TIERS)[index]
