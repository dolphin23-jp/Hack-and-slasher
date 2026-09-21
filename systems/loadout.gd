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
 if int(item.get("tier",1))>=2 and item.slot not in WEAPONS:result.shield_regen=result.get("shield_regen",0)+1
 if int(item.get("tier",1))>=3 and item.slot not in WEAPONS:result.healing=result.get("healing",0)+.04
 if int(item.get("tier",1))>=4 and item.slot not in WEAPONS:result.fatal_resist=result.get("fatal_resist",0)+.03
 return result
