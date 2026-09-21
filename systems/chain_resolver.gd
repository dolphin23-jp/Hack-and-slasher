class_name ChainResolver
extends RefCounted
# A dual attribute weapon can match several recipes. Multipliers use the best
# matching value (never an exponential product); distinct utility effects coexist.
const RECIPES=[
 {"id":"armor_cut","name":"断甲","from":"slash","to":"blunt","damage":1.10,"knock":1.45},
 {"id":"shatter","name":"破砕貫通","from":"blunt","to":"pierce","damage":1.18},
 {"id":"imbue","name":"魔力纏刃","from":"magic","to":"slash","damage":1.15,"reach":1.08},
 {"id":"harvest","name":"収束魔撃","previous":"scythe","current":"staff","damage":1.12,"reach":1.18},
 {"id":"seek","name":"穿孔追魔","from":"pierce","to":"magic","homing":true},
 {"id":"cleave","name":"崩し薙ぎ","from":"blunt","to":"slash","reach":1.22},
 {"id":"open_wound","name":"裂傷貫通","from":"slash","to":"pierce","wound":true},
 {"id":"reap","name":"魔痕収穫","previous":"staff","current":"scythe","pull":true},
 {"id":"rush","name":"連拳加速","previous":"fist","current":"fist","haste":1.22},
 {"id":"impact","name":"震源魔撃","previous":"mace","current":"staff","impact":true}
]
static func matches(previous:String,current:String)->Array:
 var out=[]
 if not WeaponDB.TYPES.has(previous) or not WeaponDB.TYPES.has(current):return out
 for r in RECIPES:
  if r.has("previous"):
   if r.previous==previous and r.current==current:out.append(r)
  elif r.from in WeaponDB.TYPES[previous].types and r.to in WeaponDB.TYPES[current].types:out.append(r)
 return out
static func triune(kinds:Array)->bool:
 if kinds.size()!=3:return false
 for kind in kinds:
  if not WeaponDB.TYPES.has(kind):return false
 for a in WeaponDB.TYPES[kinds[0]].types:
  for b in WeaponDB.TYPES[kinds[1]].types:
   for c in WeaponDB.TYPES[kinds[2]].types:
    if a!=b and b!=c and a!=c:return true
 return false
static func profile(previous:String,current:String,kinds:Array,streak:int,linked:bool)->Dictionary:
 var out={"damage":1.0,"reach":1.0,"knock":1.0,"haste":1.0,"label":"","recipes":[],"homing":false,"wound":false,"pull":false,"impact":false}
 var labels=[]
 if linked:
  for r in matches(previous,current):
   out.recipes.append(r.id);labels.append(r.name)
   for key in ["damage","reach","knock","haste"]:out[key]=maxf(out[key],r.get(key,1.0))
   for key in ["homing","wound","pull","impact"]:out[key]=out[key] or r.get(key,false)
 if linked and streak>=3 and streak%3==0 and kinds.size()==3:
  if kinds[0]==kinds[1] and kinds[1]==kinds[2]:out.damage*=1.28;labels.append("同型極撃")
  elif triune(kinds):out.damage*=1.16;labels.append("三相連環")
 out.label="・".join(labels)
 return out
static func marked(enemy,key:String)->bool:return float(enemy.chain_marks.get(key,-1))>=enemy.game.elapsed
static func mark(enemy,kind:String)->void:
 for attr in WeaponDB.TYPES[kind].types:enemy.chain_marks[attr]=enemy.game.elapsed+1.5
 enemy.chain_marks[kind]=enemy.game.elapsed+1.5
static func seek_target(p):
 var target=null;var distance=640.0
 for e in p.game.enemies:
  if e.dead or e.state in ["spawn","transform"] or not marked(e,"pierce"):continue
  var d=p.position.distance_to(e.position)
  if d<distance and p.game.dungeon.line_clear(p.position,e.position):target=e;distance=d
 return target
