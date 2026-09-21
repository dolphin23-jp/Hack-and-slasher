class_name DamageModel
extends RefCounted
const MATCHUPS={"hollow":{"slash":1.15,"magic":.9},"hound":{"pierce":1.15},"warden":{"blunt":1.25,"slash":.9},"elite":{"pierce":1.15,"blunt":1.1},"cantor":{"magic":1.2,"blunt":.9},"summoner":{"magic":1.2},"boss":{"pierce":1.1}}
static func multiplier(kind:String,types:Array,stats:Dictionary)->float:
 var total=0.0
 for key in types:total+=float(MATCHUPS.get(kind,{}).get(key,1.0))*(1+float(stats.get(key,0)))
 return total/maxi(1,types.size())
static func hint(kind:String)->String:
 var out=[]
 for key in MATCHUPS.get(kind,{}):out.append("%s %+.0f%%"%[WeaponDB.ATTRIBUTES[key],(MATCHUPS[kind][key]-1)*100])
 return " / ".join(out)
