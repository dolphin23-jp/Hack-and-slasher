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
 var tier=int(item.get("tier",1))
 if item.slot not in WEAPONS:
  match String(item.slot):
   "head":
    if tier>=2:result.crit=result.get("crit",0)+.02
    if tier>=3:result.skill=result.get("skill",0)+.05
    if tier>=4:result.cdr=result.get("cdr",0)+.03
   "armor":
    if tier>=2:result.shield_regen=result.get("shield_regen",0)+1
    if tier>=3:result.hp=result.get("hp",0)+20
    if tier>=4:result.fatal_resist=result.get("fatal_resist",0)+.05
   "hands":
    if tier>=2:result.haste=result.get("haste",0)+.04
    if tier>=3:result.crit_damage=result.get("crit_damage",0)+.10
    if tier>=4:result.stagger=result.get("stagger",0)+.08
   "feet":
    if tier>=2:result.speed=result.get("speed",0)+.04
    if tier>=3:result.dodge_cdr=result.get("dodge_cdr",0)+.05
    if tier>=4:result.dodge_distance=result.get("dodge_distance",0)+.08
   "accessory","accessory2":
    if tier>=2:result.rarity_find=result.get("rarity_find",0)+.04
    if tier>=3:result.skill=result.get("skill",0)+.05
    if tier>=4:result.cdr=result.get("cdr",0)+.03
 return result
