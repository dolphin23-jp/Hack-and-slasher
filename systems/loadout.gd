class_name Loadout
extends RefCounted
const WEAPONS=["weapon","weapon2","weapon3"]
static func accepts(item:Dictionary,slot:String)->bool:
 return (item.slot in WEAPONS and slot in WEAPONS) or (item.slot in ["accessory","accessory2"] and slot in ["accessory","accessory2"]) or item.slot==slot
static func swap(p,a:int,b:int)->void:
 if a not in range(3) or b not in range(3):return
 var it=p.equipment[WEAPONS[a]];p.equipment[WEAPONS[a]]=p.equipment[WEAPONS[b]];p.equipment[WEAPONS[b]]=it;p.rebuild_stats();p.game.save_run()
static func equipped_stats(item:Dictionary)->Dictionary:
 var result={}
 for table in [item.base,item.affixes]:
  for key in table:result[key]=result.get(key,0)+float(table[key])*(1+int(item.get("enhance",0))*.03)
 var tier=int(item.get("tier",1));var slot=String(item.slot)
 if slot not in WEAPONS:
  match slot:
   "head":
    if tier>=2:result.crit=result.get("crit",0)+.015
    if tier>=3:result.skill=result.get("skill",0)+.05
    if tier>=4:result.cdr=result.get("cdr",0)+.03
   "armor":
    if tier>=2:result.shield_regen=result.get("shield_regen",0)+1
    if tier>=3:result.hp=result.get("hp",0)+15
    if tier>=4:result.fatal_resist=result.get("fatal_resist",0)+.05
   "hands":
    if tier>=2:result.haste=result.get("haste",0)+.03
    if tier>=3:result.crit=result.get("crit",0)+.02
    if tier>=4:result.stagger=result.get("stagger",0)+.08
   "feet":
    if tier>=2:result.speed=result.get("speed",0)+.03
    if tier>=3:result.dodge_cdr=result.get("dodge_cdr",0)+.04
    if tier>=4:result.knock_resist=result.get("knock_resist",0)+.08
   "accessory":
    if tier>=2:result.skill=result.get("skill",0)+.04
    if tier>=3:result.cdr=result.get("cdr",0)+.03
    if tier>=4:result.crit_damage=result.get("crit_damage",0)+.12
   "accessory2":
    if tier>=2:result.healing=result.get("healing",0)+.05
    if tier>=3:result.rarity_find=result.get("rarity_find",0)+.06
    if tier>=4:result.material_find=result.get("material_find",0)+.08
 return result
