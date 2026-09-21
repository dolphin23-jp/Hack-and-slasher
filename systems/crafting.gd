class_name Forge
extends RefCounted
static func protected(it:Dictionary)->bool:return it.get("locked",false) or it.get("favorite",false)
static func yield_for(it:Dictionary,stats:Dictionary)->int:return maxi(1,roundi((3+int(it.rarity)*3+int(it.get("grade",1))*2)*(1+clampf(stats.get("salvage",0),0,2))))
static func cost(it:Dictionary,action:String,active:Array)->int:
 var base={"enhance":8+int(it.get("enhance",0))*5,"tier":35*int(it.tier),"evolve":90*int(it.get("grade",1)),"fuse":0}.get(action,0)
 return maxi(0,ceili(base*(.75 if "seek" in active else 1.0)))
static func compatible(a:Dictionary,b:Dictionary)->bool:
 if a.id==b.id or protected(b):return false
 return (a.get("weapon_type","")==b.get("weapon_type","") if a.slot in Loadout.WEAPONS and b.slot in Loadout.WEAPONS else a.slot==b.slot) and int(a.get("grade",1))==int(b.get("grade",1))
static func remap_roll(value:float,limits:Array,ratio:float)->Dictionary:
 if limits.size()!=2:return {"value":value*ratio,"limits":[value*ratio,value*ratio]}
 var low=float(limits[0]);var high=float(limits[1])
 var quality=.5 if high<=low else clampf((value-low)/(high-low),0,1)
 var next_limits=[low*ratio,high*ratio]
 return {"value":lerpf(next_limits[0],next_limits[1],quality),"limits":next_limits}
static func apply(p,it:Dictionary,action:String,inherit:String="")->String:
 var price=cost(it,action,p.active_oaths)
 if p.materials<price:return "素材が足りません / 必要 %d"%price
 match action:
  "enhance":
   if int(it.enhance)>=10:return "最大強化です"
   it.enhance+=1
  "fuse":
   var donor=-1
   for i in range(p.inventory.size()):
    if compatible(it,p.inventory[i]) and (donor<0 or int(p.inventory[i].rarity)<int(p.inventory[donor].rarity)):donor=i
   if donor<0:return "同系統・同階級の未保護素材が必要です"
   it.fusion+=1+int(p.inventory[donor].rarity);p.inventory.remove_at(donor)
  "tier":
   if int(it.tier)>=5:return "最大Tierです"
   if int(it.fusion)<int(it.tier):return "合成進行が不足 / 必要 %d"%it.tier
   it.fusion-=int(it.tier);it.tier+=1
  "evolve":
   if int(it.grade)>=6:return "最高階級です"
   if int(it.enhance)<10:return "+10強化が必要です"
   if not it.affixes.is_empty() and not it.affixes.has(inherit):return "継承するAffixを選んでください"
   var ratio=ItemDB.GRADES[int(it.grade)]/ItemDB.GRADES[int(it.grade)-1]
   for key in it.base:
    var mapped=remap_roll(float(it.base[key]),it.rolls.get(key,[it.base[key],it.base[key]]),ratio)
    it.base[key]=mapped.value;it.rolls[key]=mapped.limits
   for key in it.affixes:
    var mapped_affix=remap_roll(float(it.affixes[key]),it.rolls.get(key,[it.affixes[key],it.affixes[key]]),ratio)
    it.affixes[key]=mapped_affix.value;it.rolls[key]=mapped_affix.limits
   # Preserve roll percentile across the whole item; the chosen heirloom affix gains an extra 8%.
   if it.affixes.has(inherit):
    it.affixes[inherit]*=1.08;it.rolls[inherit][1]*=1.08;it.inherited=inherit
   it.grade+=1;it.enhance=0
   if it.slot in Loadout.WEAPONS and int(it.rarity)<3:it.name=WeaponDB.NAMES[it.weapon_type][int(it.grade)-1]
  _:return "不明な操作"
 p.materials-=price;p.rebuild_stats();p.game.save_run();return "完了 / "+{"enhance":"強化","fuse":"合成","tier":"Tier上昇","evolve":"階級進化"}[action]
