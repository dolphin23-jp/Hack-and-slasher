class_name EquipmentCompare
extends RefCounted

const PRIORITY_STATS=["attack","hp","armor","haste","crit","crit_damage","skill","cdr","slash","blunt","pierce","magic","penetration","stagger","shield_max","shield_regen","fatal_resist","speed","dodge_cdr","dodge_distance","drop_rate","rarity_find","material_find","salvage"]

static func item_contribution(item:Dictionary)->Dictionary:
 var out=Loadout.equipped_stats(item).duplicate(true)
 if String(item.get("slot","")) in Loadout.WEAPONS:
  out.attack=float(out.get("attack",0))/3.0
 return out

static func weapon_order(loadout:Dictionary)->String:
 var names=[]
 for slot in Loadout.WEAPONS:names.append(WeaponDB.type_name(loadout[slot]))
 return " → ".join(names)

static func chain_tokens(loadout:Dictionary)->Array:
 var kinds=[];var out=[]
 for slot in Loadout.WEAPONS:kinds.append(String(loadout[slot].get("weapon_type","sword")))
 for i in range(3):
  var previous=String(kinds[i]);var current=String(kinds[(i+1)%3])
  for recipe in ChainResolver.matches(previous,current):
   var label="%d→%d %s"%[i+1,(i+1)%3+1,recipe.name]
   if label not in out:out.append(label)
 if ChainResolver.triune(kinds):out.append("三相連環")
 if kinds[0]==kinds[1] and kinds[1]==kinds[2]:out.append("同型極撃")
 return out

static func set_tokens(loadout:Dictionary)->Array:
 var counts={};var out=[]
 for slot in ItemDB.SLOTS:
  var family=ItemDB.set_of(loadout[slot])
  if not family.is_empty():counts[family]=int(counts.get(family,0))+1
 for family in counts:
  if int(counts[family])>=2:out.append(BuildDB.SET_NAMES.get(family,family)+" 2部位")
 return out

static func build_tokens(loadout:Dictionary)->Array:
 var out=chain_tokens(loadout)
 for value in set_tokens(loadout):
  if value not in out:out.append(value)
 return out

static func ability_tokens(item:Dictionary)->Array:
 var out=[]
 if String(item.get("slot","")) in Loadout.WEAPONS:
  var kind=String(item.get("weapon_type","sword"))
  if WeaponActionResolver.ARTS.has(kind):out.append("武技: "+String(WeaponActionResolver.ARTS[kind].name))
 for tier in range(2,mini(5,int(item.get("tier",1)))+1):
  out.append("T%d: %s"%[tier,WeaponDB.tier_text(item,tier)])
 var unique=String(item.get("unique",""))
 if not unique.is_empty():out.append("固有: "+ItemDB.unique_text(item))
 var family=ItemDB.set_of(item)
 if not family.is_empty():out.append("Set: "+BuildDB.SET_NAMES.get(family,family))
 return out

static func _difference(after:Array,before:Array)->Array:
 var out=[]
 for value in after:
  if value not in before:out.append(value)
 return out

static func key_stats(snapshot:Dictionary,limit:int=6)->Array:
 if snapshot.is_empty():return []
 var out=[];var delta=snapshot.get("delta",{})
 for key in PRIORITY_STATS:
  if absf(float(delta.get(key,0)))>.0001 and key not in out:out.append(key)
 for source_name in ["candidate_contribution","current_contribution"]:
  var source=snapshot.get(source_name,{})
  for key in PRIORITY_STATS:
   if source.has(key) and key not in out:out.append(key)
 for key in PRIORITY_STATS:
  if key not in out:out.append(key)
 return out.slice(0,mini(limit,out.size()))

static func snapshot(p,item:Dictionary,target:String)->Dictionary:
 if not ItemDB.valid(item) or target.is_empty() or not p.equipment.has(target) or not Loadout.accepts(item,target):return {}
 var before_loadout=p.equipment.duplicate(true);var after_loadout=p.equipment.duplicate(true)
 var current=before_loadout[target].duplicate(true);after_loadout[target]=item.duplicate(true)
 var before_stats=p.calculated(before_loadout);var after_stats=p.calculated(after_loadout);var delta={}
 for key in ItemDB.AFFIXES.keys():
  delta[key]=float(after_stats.get(key,0))-float(before_stats.get(key,0))
 var before_build=build_tokens(before_loadout);var after_build=build_tokens(after_loadout)
 var current_abilities=ability_tokens(current);var candidate_abilities=ability_tokens(item)
 return {
  "target":target,
  "current":current,
  "candidate":item.duplicate(true),
  "before_stats":before_stats,
  "after_stats":after_stats,
  "delta":delta,
  "current_contribution":item_contribution(current),
  "candidate_contribution":item_contribution(item),
  "before_order":weapon_order(before_loadout),
  "after_order":weapon_order(after_loadout),
  "gained_build":_difference(after_build,before_build),
  "lost_build":_difference(before_build,after_build),
  "gained_abilities":_difference(candidate_abilities,current_abilities),
  "lost_abilities":_difference(current_abilities,candidate_abilities),
  "before_build":before_build,
  "after_build":after_build
 }
