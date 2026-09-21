class_name OathBoard
extends RefCounted
const PATHS={
 "dance":{"name":"戦舞","stats":{"haste":.12,"crit":.04,"stagger":.2},"effects":["echo","reaper"],"text":"連撃と霊刃。主誓印で3段目に追撃。"},
 "arcane":{"name":"秘術","stats":{"magic":.2,"skill":.18,"cdr":.06},"effects":["lance_fork","lance_return"],"text":"貫通魔撃。主誓印でランスが帰還。"},
 "fortress":{"name":"城塞","stats":{"hp":35,"armor":12,"shield_max":25,"shield_regen":3,"fatal_resist":.2},"effects":["echo_guard","dash_nova"],"text":"障壁と致命撃耐性。主誓印で回避衝撃。"},
 "flame":{"name":"紅蓮","stats":{"skill":.1,"healing":.1},"effects":["ash_edge","fire_dash","crit_blast","phoenix","ember_nova"],"text":"通常攻撃で炎上。主誓印で炎の回避・爆発。"},
 "storm":{"name":"雷霆","stats":{"haste":.08,"pierce":.12},"effects":["chain","storm_guard","conductor"],"text":"撃破で連鎖雷。主誓印で見切り雷撃。"},
 "seek":{"name":"探究","stats":{"drop_rate":.2,"rarity_find":.25,"material_find":.3,"salvage":.25},"effects":[],"text":"戦利品と素材の発見。鍛冶コスト軽減。"}}
static func empty()->Dictionary:return {"unlocked":PATHS.keys(),"ranks":{"dance":0,"arcane":0,"fortress":0,"flame":0,"storm":0,"seek":0},"active":["dance"],"points":0}
static func sanitize(value:Variant)->Dictionary:
 var out=empty()
 if not value is Dictionary:return out
 out.points=clampi(int(value.get("points",0)) if value.get("points",0) is float or value.get("points",0) is int else 0,0,1000000)
 if value.get("active") is Array:
  out.active=[]
  for key in value.active:
   if key is String and PATHS.has(key) and key not in out.active and out.active.size()<3:out.active.append(key)
 if value.get("ranks") is Dictionary:
  for key in PATHS:
   var rank=value.ranks.get(key,0)
   if rank is int or rank is float:out.ranks[key]=clampi(int(rank),0,3)
 if out.active.is_empty():out.active=["dance"]
 return out
static func stats(board:Dictionary,active:Array)->Dictionary:
 var out={}
 for i in range(active.size()):
  var key=active[i]
  if not PATHS.has(key):continue
  var factor=(1.0 if i==0 else .5)*(1+int(board.ranks.get(key,0))*.12)
  for stat in PATHS[key].stats:out[stat]=out.get(stat,0)+PATHS[key].stats[stat]*factor
 return out
static func has_effect(active:Array,effect:String)->bool:
 for i in range(active.size()):
  var list=PATHS.get(active[i],{}).get("effects",[])
  if effect in (list if i==0 else list.slice(0,1)):return true
 return false
