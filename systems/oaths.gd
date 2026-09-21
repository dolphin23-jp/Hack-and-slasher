class_name OathBoard
extends RefCounted
const PATHS={
 "dance":{"name":"戦舞","stats":{"haste":.12,"crit":.04,"stagger":.2},"effects":["echo","reaper"],"text":"連撃と霊刃。主誓印で3段目に追撃。"},
 "arcane":{"name":"秘術","stats":{"magic":.2,"skill":.18,"cdr":.06},"effects":["lance_fork","lance_return"],"text":"貫通魔撃。主誓印でランスが帰還。"},
 "fortress":{"name":"城塞","stats":{"hp":35,"armor":12,"shield_max":25,"shield_regen":3,"fatal_resist":.2},"effects":["echo_guard","dash_nova"],"text":"障壁と致命撃耐性。主誓印で回避衝撃。"},
 "flame":{"name":"紅蓮","stats":{"skill":.1,"healing":.1},"effects":["ash_edge","fire_dash","crit_blast","phoenix","ember_nova"],"text":"通常攻撃で炎上。主誓印で炎の回避・爆発。"},
 "storm":{"name":"雷霆","stats":{"haste":.08,"pierce":.12},"effects":["chain","storm_guard","conductor"],"text":"撃破で連鎖雷。主誓印で見切り雷撃。"},
 "seek":{"name":"探究","stats":{"drop_rate":.2,"rarity_find":.25,"material_find":.3,"salvage":.25},"effects":[],"text":"戦利品と素材の発見。鍛冶コスト軽減。"}}
const CHOICES={
 "dance":{"flow":{"name":"流転","stats":{"haste":.08},"text":"速度を高めて連携回数を増す。"},"impact":{"name":"重撃","stats":{"crit_damage":.18},"text":"一撃ごとの威力を高める。"}},
 "arcane":{"focus":{"name":"収束","stats":{"magic":.12},"text":"魔撃そのものを強化する。"},"reserve":{"name":"循環","stats":{"cdr":.06},"text":"スキルの再使用を早める。"}},
 "fortress":{"bulwark":{"name":"不落","stats":{"shield_max":18.0},"text":"障壁最大値を高める。"},"plate":{"name":"重装","stats":{"armor":8.0},"text":"常時防御を高める。"}},
 "flame":{"smolder":{"name":"残火","stats":{"skill":.12},"text":"継続火力とスキルを高める。"},"burst":{"name":"爆炎","stats":{"crit_damage":.18},"text":"高火力へ寄せる。"}},
 "storm":{"voltage":{"name":"雷威","stats":{"pierce":.12},"text":"1体への貫撃を高める。"},"cascade":{"name":"連鎖","stats":{"haste":.08},"text":"手数を増して雷撃機会を作る。"}},
 "seek":{"hunter":{"name":"探索","stats":{"rarity_find":.18},"text":"高レア発見へ寄せる。"},"smith":{"name":"鍛冶","stats":{"material_find":.20,"salvage":.15},"text":"素材循環へ寄せる。"}}}
const CAPSTONES={
 "dance":{"crit":.05},"arcane":{"skill":.15},"fortress":{"hp":30.0,"shield_regen":2.0},
 "flame":{"skill":.15},"storm":{"pierce":.10,"crit":.04},"seek":{"drop_rate":.15,"rarity_find":.10}}
static func empty()->Dictionary:return {"unlocked":PATHS.keys(),"ranks":{"dance":0,"arcane":0,"fortress":0,"flame":0,"storm":0,"seek":0},"choices":{},"active":["dance"],"points":0}
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
 if value.get("choices") is Dictionary:
  for key in CHOICES:
   var picked=String(value.choices.get(key,""))
   if CHOICES[key].has(picked):out.choices[key]=picked
 if out.active.is_empty():out.active=["dance"]
 return out
static func stats(board:Dictionary,active:Array)->Dictionary:
 var out={}
 for i in range(active.size()):
  var key=active[i]
  if not PATHS.has(key):continue
  var rank=int(board.ranks.get(key,0))
  var factor=(1.0 if i==0 else .5)*(1+rank*.12)
  for stat in PATHS[key].stats:out[stat]=out.get(stat,0)+PATHS[key].stats[stat]*factor
  var picked=String(board.get("choices",{}).get(key,""))
  if rank>=2 and CHOICES[key].has(picked):
   for stat in CHOICES[key][picked].stats:out[stat]=out.get(stat,0)+CHOICES[key][picked].stats[stat]*factor
  if rank>=3 and i==0:
   for stat in CAPSTONES[key]:out[stat]=out.get(stat,0)+CAPSTONES[key][stat]
 return out
static func has_effect(active:Array,effect:String)->bool:
 for i in range(active.size()):
  var list=PATHS.get(active[i],{}).get("effects",[])
  if effect in (list if i==0 else list.slice(0,1)):return true
 return false

static func choice_keys(path:String)->Array:
 return CHOICES.get(path,{}).keys()
static func choice_name(path:String,key:String)->String:
 return String(CHOICES.get(path,{}).get(key,{}).get("name",key))
static func capstone_text(path:String)->String:
 var parts=[]
 for stat in CAPSTONES.get(path,{}):parts.append(ItemDB.stat_text(stat,CAPSTONES[path][stat]))
 return " / ".join(parts)
