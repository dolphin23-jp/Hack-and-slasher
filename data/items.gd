class_name ItemDB
extends RefCounted
const RARITIES=["COMMON","MAGIC","RARE","LEGENDARY"]
const COLORS=[Color("b6c5c8"),Color("78b5ed"),Color("dcacd9"),Color("f4be68")]
const SLOTS=["weapon","armor","accessory"]
const AFFIXES={"attack":["Attack",3.0,7.0],"haste":["Attack speed",.04,.09],"crit":["Critical chance",.025,.05],"crit_damage":["Critical damage",.12,.25],"hp":["Maximum life",13.0,27.0],"speed":["Movement speed",.025,.055],"cdr":["Cooldown reduction",.025,.055],"armor":["Armor",4.0,10.0],"skill":["Skill damage",.06,.12]}
const LEGENDS=[
 {"name":"THUNDER TESTAMENT","slot":"weapon","effect":"chain","text":"On kill, lightning strikes up to 3 nearby foes for 90% Attack. Lightning cannot trigger itself."},
 {"name":"CINDERWAKE","slot":"armor","effect":"fire_dash","text":"Dash leaves a burning trail for 3 seconds, dealing 110% Attack each second."},
 {"name":"THE GLASS CHOIR","slot":"accessory","effect":"echo","text":"Every second sword swing releases 2 piercing spirit blades, each dealing 55% Attack."},
 {"name":"HEART OF THE PYRE","slot":"accessory","effect":"crit_blast","text":"Critical hits erupt for 80% Attack in an area. 0.7 second internal cooldown."}]
static func generate(rng:RandomNumberGenerator,tier:int,rarity:int=-1,legend:int=-1)->Dictionary:
 tier=maxi(1,tier)
 if rarity<0:
  var roll=rng.randf();rarity=3 if roll<.018 else (2 if roll<.18 else (1 if roll<.59 else 0))
 var slot=SLOTS[rng.randi_range(0,2)];var effect="";var desc="";var item_name=""
 if rarity==3:
  var l=LEGENDS[legend if legend>=0 else rng.randi_range(0,3)]
  slot=l.slot;effect=l.effect;desc=l.text;item_name=l.name
 else:
  var bases={"weapon":["Pilgrim's Edge","Vigil Blade","Grave Sabre","Oathsteel"],"armor":["Vesper Mail","Warden Plate","Ashweave","Sepulchral Coat"],"accessory":["Cinder Seal","Moon Reliquary","Mourning Knot","Ivory Talisman"]}
  item_name=bases[slot][rng.randi_range(0,3)]
  if rarity>0:item_name=["Keen ","Hallowed ","Vengeful ","Resonant "][rng.randi_range(0,3)]+item_name
 var power=1.0+maxi(0,tier-1)*.18;var base={}
 if slot=="weapon":base.attack=round((10+rarity*3.8)*power*rng.randf_range(.9,1.12))
 if slot=="armor":base={"armor":round((9+rarity*4)*power),"hp":round((16+rarity*6)*power)}
 if slot=="accessory":base={"crit":.02+rarity*.01,"skill":.04+rarity*.025}
 var affixes={};var keys=AFFIXES.keys()
 for i in range([0,2,3,4][rarity]):
  var key=keys.pop_at(rng.randi_range(0,keys.size()-1));var def=AFFIXES[key]
  var value=rng.randf_range(def[1],def[2])*(power if key in ["attack","hp","armor"] else 1+(tier-1)*.035)
  affixes[key]=snapped(value,1.0 if key in ["attack","hp","armor"] else .001)
 return {"id":str(rng.randi())+"-"+str(rng.randi()),"name":item_name,"rarity":rarity,"slot":slot,"tier":tier,"base":base,"affixes":affixes,"effect":effect,"description":desc}
static func initial_items()->Dictionary:
 var out={}
 for i in range(3):
  out[SLOTS[i]]={"id":"starter-"+SLOTS[i],"name":["Weathered Oathblade","Pilgrim's Mantle","An Unbroken Promise"][i],"rarity":0,"slot":SLOTS[i],"tier":1,"base":[{"attack":9},{"armor":7,"hp":14},{"crit":.02}][i],"affixes":{},"effect":"","description":""}
 return out
static func stat_text(key:String,value:float)->String:
 return ("+%d %s"%[roundi(value),AFFIXES[key][0]]) if key in ["attack","hp","armor"] else ("+%d%% %s"%[roundi(value*100),AFFIXES[key][0]])
static func valid(item:Variant)->bool:
 if not item is Dictionary:return false
 for k in ["id","name","rarity","slot","base","affixes","effect","description","tier"]:
  if not item.has(k):return false
 for k in ["id","name","slot","effect","description"]:
  if not item[k] is String:return false
 if not item.slot in SLOTS:return false
 for k in ["tier","rarity"]:
  if not (item[k] is int or item[k] is float):return false
 if item.rarity<0 or item.rarity>3 or item.tier<1 or item.tier>300:return false
 for table in [item.base,item.affixes]:
  if not table is Dictionary:return false
  for k in table:
   if not k in AFFIXES or not (table[k] is float or table[k] is int):return false
   if not is_finite(float(table[k])) or table[k]<0 or table[k]>100000:return false
 return true
