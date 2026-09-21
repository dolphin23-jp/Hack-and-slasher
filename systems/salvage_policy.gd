class_name SalvagePolicy
extends RefCounted
static func defaults()->Dictionary:
 return {"rarity":1,"quality":.7,"tier":2,"grade":2,"keep_weapon":""}
static func sanitize(value:Variant)->Dictionary:
 var out=defaults()
 if not value is Dictionary:return out
 for key in ["rarity","quality","tier","grade"]:
  var v=value.get(key)
  if not (v is int or v is float) or not is_finite(float(v)):continue
  match key:
   "rarity":
    if v==0 or v==1:out[key]=int(v)
   "quality":
    if v>=0 and v<=1.01:out[key]=float(v)
   "tier":
    if v>=1 and v<=5 and v==int(v):out[key]=int(v)
   "grade":
    if v>=1 and v<=6 and v==int(v):out[key]=int(v)
 if value.get("keep_weapon","") in WeaponDB.TYPES:out.keep_weapon=value.keep_weapon
 return out
# Preserve an item if ANY affix is valuable. Unknown/legacy roll bounds are
# treated conservatively as a perfect roll, never guessed from absolute stats.
static func quality(it:Dictionary)->float:
 var values=it.get("affixes",{})
 if values.is_empty():values=it.get("base",{})
 if values.is_empty():return 1.0
 var best=0.0
 for key in values:
  var limits=it.get("rolls",{}).get(key,[])
  if not limits is Array or limits.size()!=2:return 1.0
  if float(limits[1])<=float(limits[0]):return 1.0
  best=maxf(best,clampf((float(values[key])-float(limits[0]))/(float(limits[1])-float(limits[0])),0,1))
 return best
static func matches(it:Dictionary,rules:Dictionary)->bool:
 if Forge.protected(it) or int(it.rarity)>1:return false
 var r=sanitize(rules)
 if int(it.rarity)>r.rarity or int(it.get("tier",1))>r.tier or int(it.get("grade",1))>r.grade:return false
 if it.slot in Loadout.WEAPONS and not r.keep_weapon.is_empty() and it.get("weapon_type")==r.keep_weapon:return false
 var q=quality(it)
 return q<r.quality and not is_equal_approx(q,float(r.quality))
static func junk_preview(p)->Array:
 var out=[]
 for it in p.inventory:
  if it.get("junk",false) and not Forge.protected(it):out.append(it.duplicate(true))
 return out
static func confirm_junk(p,preview:Array)->String:
 if preview.is_empty():return "分解するジャンクがありません"
 var indices=[]
 for snapshot in preview:
  var index=-1
  for i in range(p.inventory.size()):
   if p.inventory[i].get("id")==snapshot.get("id"):
    if index>=0 or p.inventory[i]!=snapshot:return "所持品が変更されました。確認し直してください"
    index=i
  if index<0 or index in indices or Forge.protected(p.inventory[index]) or not p.inventory[index].get("junk",false):return "所持品が変更されました。確認し直してください"
  indices.append(index)
 # Validate the complete batch before removing anything. Sorting is harmless.
 indices.sort();indices.reverse();var gain=0
 for i in indices:
  gain+=Forge.yield_for(p.inventory[i],p.stats);p.inventory.remove_at(i)
 p.materials+=gain;p.game.save_run()
 return "分解完了 / %d個・素材 +%d"%[indices.size(),gain]
