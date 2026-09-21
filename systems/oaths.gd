class_name OathBoard
extends RefCounted
const PATHS={
 "dance":{"name":"戦舞","stats":{"haste":.12,"crit":.04,"stagger":.2},"effects":["echo","reaper"],"text":"連撃と霊刃。主誓印で3段目に追撃。"},
 "arcane":{"name":"秘術","stats":{"magic":.2,"skill":.18,"cdr":.06},"effects":["lance_fork","lance_return"],"text":"貫通魔撃。主誓印でランスが帰還。"},
 "fortress":{"name":"城塞","stats":{"hp":35,"armor":12,"shield_max":25,"shield_regen":3,"fatal_resist":.2},"effects":["echo_guard","dash_nova"],"text":"障壁と致命撃耐性。主誓印で回避衝撃。"},
 "flame":{"name":"紅蓮","stats":{"skill":.1,"healing":.1},"effects":["ash_edge","fire_dash","crit_blast","phoenix","ember_nova"],"text":"通常攻撃で炎上。主誓印で炎の回避・爆発。"},
 "storm":{"name":"雷霆","stats":{"haste":.08,"pierce":.12},"effects":["chain","storm_guard","conductor"],"text":"撃破で連鎖雷。主誓印で見切り雷撃。"},
 "seek":{"name":"探究","stats":{"drop_rate":.2,"rarity_find":.25,"material_find":.3,"salvage":.25},"effects":[],"text":"戦利品と素材の発見。鍛冶コスト軽減。"}}
const TREES={
 "dance":[
  {"id":"dance_tempo","name":"拍子","cost":2,"stats":{"haste":.04}},
  {"id":"dance_edge","name":"連刃","cost":3,"requires":["dance_tempo"],"stats":{"slash":.06}},
  {"id":"dance_flow","name":"流転","cost":4,"requires":["dance_edge"],"group":"dance_branch","stats":{"haste":.07}},
  {"id":"dance_impact","name":"重奏","cost":4,"requires":["dance_edge"],"group":"dance_branch","stats":{"stagger":.16}},
  {"id":"dance_flow2","name":"無拍子","cost":5,"requires":["dance_flow"],"effects":["flow_chain"]},
  {"id":"dance_impact2","name":"破拍子","cost":5,"requires":["dance_impact"],"effects":["impact_chain"]},
  {"id":"dance_cap","name":"千刃残響","cost":7,"requires_any":["dance_flow2","dance_impact2"],"effects":["weapon_echo"]}],
 "arcane":[
  {"id":"arcane_focus","name":"集束","cost":2,"stats":{"magic":.06}},
  {"id":"arcane_thread","name":"魔脈","cost":3,"requires":["arcane_focus"],"stats":{"cdr":.03}},
  {"id":"arcane_pierce","name":"穿光","cost":4,"requires":["arcane_thread"],"group":"arcane_branch","stats":{"pierce":.10}},
  {"id":"arcane_echo","name":"反響","cost":4,"requires":["arcane_thread"],"group":"arcane_branch","stats":{"skill":.10}},
  {"id":"arcane_pierce2","name":"無窮穿ち","cost":5,"requires":["arcane_pierce"],"effects":["arcane_pierce"]},
  {"id":"arcane_echo2","name":"帰還律","cost":5,"requires":["arcane_echo"],"effects":["arcane_echo"]},
  {"id":"arcane_cap","name":"星界回路","cost":7,"requires_any":["arcane_pierce2","arcane_echo2"],"effects":["arcane_cap"]}],
 "fortress":[
  {"id":"fortress_wall","name":"礎石","cost":2,"stats":{"armor":5.0}},
  {"id":"fortress_aegis","name":"障壁律","cost":3,"requires":["fortress_wall"],"stats":{"shield_max":10.0}},
  {"id":"fortress_sustain","name":"不落","cost":4,"requires":["fortress_aegis"],"group":"fortress_branch","stats":{"shield_regen":1.5}},
  {"id":"fortress_spend","name":"破城","cost":4,"requires":["fortress_aegis"],"group":"fortress_branch","stats":{"stagger":.12}},
  {"id":"fortress_sustain2","name":"恒久障壁","cost":5,"requires":["fortress_sustain"],"effects":["shield_sustain"]},
  {"id":"fortress_spend2","name":"障壁砲","cost":5,"requires":["fortress_spend"],"effects":["shield_burst"]},
  {"id":"fortress_cap","name":"動く城塞","cost":7,"requires_any":["fortress_sustain2","fortress_spend2"],"effects":["fortress_cap"]}],
 "flame":[
  {"id":"flame_ember","name":"火種","cost":2,"stats":{"skill":.05}},
  {"id":"flame_feed","name":"薪継ぎ","cost":3,"requires":["flame_ember"],"stats":{"healing":.05}},
  {"id":"flame_long","name":"燻焼","cost":4,"requires":["flame_feed"],"group":"flame_branch","effects":["burn_long"]},
  {"id":"flame_burst","name":"爆ぜ火","cost":4,"requires":["flame_feed"],"group":"flame_branch","effects":["burn_burst"]},
  {"id":"flame_long2","name":"永火","cost":5,"requires":["flame_long"],"stats":{"slash":.08}},
  {"id":"flame_burst2","name":"瞬火","cost":5,"requires":["flame_burst"],"stats":{"crit_damage":.16}},
  {"id":"flame_cap","name":"灰より再燃","cost":7,"requires_any":["flame_long2","flame_burst2"],"effects":["flame_cap"]}],
 "storm":[
  {"id":"storm_spark","name":"火花","cost":2,"stats":{"haste":.03}},
  {"id":"storm_wire","name":"導線","cost":3,"requires":["storm_spark"],"stats":{"pierce":.05}},
  {"id":"storm_voltage","name":"高電圧","cost":4,"requires":["storm_wire"],"group":"storm_branch","effects":["high_voltage"]},
  {"id":"storm_chain","name":"連鎖網","cost":4,"requires":["storm_wire"],"group":"storm_branch","effects":["wide_lightning"]},
  {"id":"storm_voltage2","name":"落雷芯","cost":5,"requires":["storm_voltage"],"stats":{"crit":.04}},
  {"id":"storm_chain2","name":"雷網","cost":5,"requires":["storm_chain"],"stats":{"haste":.05}},
  {"id":"storm_cap","name":"天雷循環","cost":7,"requires_any":["storm_voltage2","storm_chain2"],"effects":["storm_cap"]}],
 "seek":[
  {"id":"seek_eye","name":"鑑定眼","cost":2,"stats":{"rarity_find":.08}},
  {"id":"seek_hand","name":"拾い手","cost":3,"requires":["seek_eye"],"stats":{"drop_rate":.08}},
  {"id":"seek_loot","name":"秘宝狩り","cost":4,"requires":["seek_hand"],"group":"seek_branch","stats":{"rarity_find":.12}},
  {"id":"seek_forge","name":"鍛冶師","cost":4,"requires":["seek_hand"],"group":"seek_branch","stats":{"material_find":.18}},
  {"id":"seek_loot2","name":"黄金嗅覚","cost":5,"requires":["seek_loot"],"stats":{"drop_rate":.12}},
  {"id":"seek_forge2","name":"無駄なき手","cost":5,"requires":["seek_forge"],"stats":{"salvage":.18}},
  {"id":"seek_cap","name":"巡礼王の眼","cost":7,"requires_any":["seek_loot2","seek_forge2"],"stats":{"rarity_find":.12,"material_find":.12}}]}
static func empty()->Dictionary:return {"unlocked":PATHS.keys(),"ranks":{"dance":0,"arcane":0,"fortress":0,"flame":0,"storm":0,"seek":0},"active":["dance"],"points":0,"nodes":[]}
static func node_info(id:String)->Dictionary:
 for path in TREES:
  for node in TREES[path]:
   if node.id==id:
    var out=node.duplicate(true);out.path=path;return out
 return {}
static func legacy_nodes(path:String,rank:int)->Array:
 if rank<=0:return []
 var tree=TREES[path];var out=[tree[0].id]
 if rank>=2:out.append(tree[1].id)
 if rank>=3:out.append(tree[2].id)
 return out
static func sanitize(value:Variant)->Dictionary:
 var out=empty()
 if not value is Dictionary:return out
 out.points=clampi(int(value.get("points",0)) if value.get("points",0) is float or value.get("points",0) is int else 0,0,1000000)
 if value.get("active") is Array:
  out.active=[]
  for key in value.active:
   if key is String and PATHS.has(key) and key not in out.active and out.active.size()<3:out.active.append(key)
 if out.active.is_empty():out.active=["dance"]
 if value.get("ranks") is Dictionary:
  for key in PATHS:
   var rank=value.ranks.get(key,0)
   if rank is int or rank is float:out.ranks[key]=clampi(int(rank),0,3)
 if value.get("nodes") is Array:
  for id in value.nodes:
   if id is String and not node_info(id).is_empty() and id not in out.nodes:out.nodes.append(id)
 if out.nodes.is_empty():
  for path in PATHS:
   for id in legacy_nodes(path,int(out.ranks[path])):
    if id not in out.nodes:out.nodes.append(id)
 return out
static func node_available(board:Dictionary,path:String,id:String)->bool:
 var node=node_info(id)
 if node.is_empty() or node.path!=path or id in board.get("nodes",[]):return false
 for required in node.get("requires",[]):
  if required not in board.get("nodes",[]):return false
 if node.has("requires_any"):
  var ok=false
  for required in node.requires_any:
   if required in board.get("nodes",[]):ok=true
  if not ok:return false
 var group=String(node.get("group",""))
 if not group.is_empty():
  for owned in board.get("nodes",[]):
   var other=node_info(String(owned))
   if not other.is_empty() and other.get("group","")==group:return false
 return true
static func unlock_node(board:Dictionary,path:String,id:String)->String:
 if not node_available(board,path,id):return "前提ノードまたは分岐条件を満たしていません"
 var node=node_info(id);var cost=int(node.cost)
 if int(board.get("points",0))<cost:return "誓片が不足しています / 必要 %d"%cost
 board.points=int(board.points)-cost
 if not board.has("nodes") or not board.nodes is Array:board.nodes=[]
 board.nodes.append(id)
 return "解放 / "+String(node.name)
static func stats(board:Dictionary,active:Array)->Dictionary:
 var out={}
 for i in range(active.size()):
  var key=active[i]
  if not PATHS.has(key):continue
  var factor=1.0 if i==0 else .5
  for stat in PATHS[key].stats:out[stat]=out.get(stat,0)+PATHS[key].stats[stat]*factor
  for node in TREES[key]:
   if node.id not in board.get("nodes",[]):continue
   for stat in node.get("stats",{}):out[stat]=out.get(stat,0)+node.stats[stat]*factor
 return out
static func has_effect(board:Dictionary,active:Array,effect:String)->bool:
 for i in range(active.size()):
  var key=active[i]
  var list=PATHS.get(key,{}).get("effects",[])
  if effect in (list if i==0 else list.slice(0,1)):return true
  if i==0 and TREES.has(key):
   for node in TREES[key]:
    if node.id in board.get("nodes",[]) and effect in node.get("effects",[]):return true
 return false
static func has_node(board:Dictionary,id:String)->bool:return id in board.get("nodes",[])
