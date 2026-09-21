class_name OathBoard
extends RefCounted
const PATHS={
 "dance":{"name":"戦舞","stats":{"haste":.12,"crit":.04,"stagger":.2},"effects":["echo","reaper"],"text":"連撃と霊刃。主誓印で3段目に追撃。"},
 "arcane":{"name":"秘術","stats":{"magic":.2,"skill":.18,"cdr":.06},"effects":["lance_fork","lance_return"],"text":"貫通魔撃。主誓印で槍・杖の武技弾が帰還。"},
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
static func node_cost(id:String)->int:
 var node=node_info(id)
 return int(node.get("cost",0)) if not node.is_empty() else 0
static func spent_points(board:Dictionary)->int:
 var total=0
 for id in board.get("nodes",[]):total+=node_cost(String(id))
 return total
static func total_points(board:Dictionary)->int:return int(board.get("points",0))+spent_points(board)
static func path_nodes(board:Dictionary,path:String)->Array:
 var out=[]
 for id in board.get("nodes",[]):
  var node=node_info(String(id))
  if not node.is_empty() and String(node.path)==path:out.append(String(id))
 return out
static func respec_path(board:Dictionary,path:String)->int:
 if not TREES.has(path):return 0
 var removed=path_nodes(board,path);var refund=0
 for id in removed:refund+=node_cost(String(id))
 for id in removed:board.nodes.erase(id)
 board.points=int(board.get("points",0))+refund
 return refund
static func respec_all(board:Dictionary)->int:
 var refund=spent_points(board)
 board.nodes=[]
 board.points=int(board.get("points",0))+refund
 return refund
static func _prerequisites_met(board:Dictionary,node:Dictionary)->bool:
 for required in node.get("requires",[]):
  if required not in board.get("nodes",[]):return false
 if node.has("requires_any"):
  var ok=false
  for required in node.requires_any:
   if required in board.get("nodes",[]):ok=true
  if not ok:return false
 return true
static func branch_conflict(board:Dictionary,path:String,id:String)->Array:
 var node=node_info(id);var out=[]
 if node.is_empty() or String(node.path)!=path:return out
 var group=String(node.get("group",""))
 if group.is_empty():return out
 for owned in board.get("nodes",[]):
  var other=node_info(String(owned))
  if not other.is_empty() and String(other.get("group",""))==group and String(owned)!=id:out.append(String(owned))
 return out
static func switch_branch(board:Dictionary,path:String,id:String)->String:
 var node=node_info(id)
 if node.is_empty() or String(node.path)!=path or String(node.get("group","")).is_empty():return "切替対象ではありません"
 if id in board.get("nodes",[]):return "すでに選択中です"
 if not _prerequisites_met(board,node):return "分岐の前提ノードが不足しています"
 var removed=branch_conflict(board,path,id)
 if removed.is_empty():return unlock_node(board,path,id)
 var changed=true
 while changed:
  changed=false
  for owned_value in board.get("nodes",[]):
   var owned=String(owned_value)
   if owned in removed:continue
   var info=node_info(owned)
   if info.is_empty() or String(info.path)!=path:continue
   var depends=false
   for required in info.get("requires",[]):
    if required in removed:depends=true
   if info.has("requires_any"):
    var viable=false
    for required in info.requires_any:
     if required in board.get("nodes",[]) and required not in removed:viable=true
    if not viable:depends=true
   if depends:removed.append(owned);changed=true
 var refund=0
 for owned in removed:refund+=node_cost(String(owned))
 for owned in removed:board.nodes.erase(owned)
 board.points=int(board.get("points",0))+refund
 var result=unlock_node(board,path,id)
 if result.begins_with("解放"):return "分岐切替 / "+String(node.name)+" / 返還 %d"%refund
 return result
static func preset_cost(value:Dictionary)->int:
 var total=0
 for id in value.get("nodes",[]):total+=node_cost(String(id))
 return total
static func sanitize_node_ids(value:Variant)->Array:
 if not value is Array:return []
 var requested=[]
 for id in value:
  if id is String and not node_info(id).is_empty() and id not in requested:requested.append(id)
 var out=[]
 for path in TREES:
  for node in TREES[path]:
   if node.id not in requested:continue
   var temp={"nodes":out}
   if not _prerequisites_met(temp,node):continue
   var group=String(node.get("group",""))
   var conflict=false
   if not group.is_empty():
    for owned in out:
     var other=node_info(String(owned))
     if not other.is_empty() and String(other.get("group",""))==group:conflict=true
   if not conflict:out.append(String(node.id))
 return out
static func sanitize_preset(value:Variant)->Dictionary:
 if not value is Dictionary:return {}
 var active=[]
 if value.get("active") is Array:
  for key in value.active:
   if key is String and PATHS.has(key) and key not in active and active.size()<3:active.append(key)
 if active.is_empty():active=["dance"]
 var nodes=sanitize_node_ids(value.get("nodes",[]))
 var weapons=[]
 if value.get("weapon_types") is Array:
  for kind in value.weapon_types:
   if kind is String and WeaponDB.TYPES.has(kind) and weapons.size()<3:weapons.append(kind)
 while weapons.size()<3:weapons.append("sword")
 var starter=String(value.get("starter","blade"))
 if starter not in ["blade","lance","ember"]:starter="blade"
 var name=String(value.get("name","Build")).strip_edges()
 if name.is_empty():name="Build"
 if name.length()>32:name=name.substr(0,32)
 return {"name":name,"active":active,"nodes":nodes,"starter":starter,"weapon_types":weapons}
static func make_preset(board:Dictionary,name:String,starter:String,weapon_types:Array)->Dictionary:
 return sanitize_preset({"name":name,"active":board.get("active",["dance"]).duplicate(),"nodes":board.get("nodes",[]).duplicate(),"starter":starter,"weapon_types":weapon_types.duplicate()})
static func apply_preset(board:Dictionary,preset:Dictionary)->String:
 var clean=sanitize_preset(preset)
 if clean.is_empty():return "Presetが壊れています"
 var total=total_points(board);var needed=preset_cost(clean)
 if needed>total:return "誓片が不足しています / 必要 %d / 保有 %d"%[needed,total]
 board.active=clean.active.duplicate();board.nodes=clean.nodes.duplicate();board.points=total-needed
 return "Preset読込 / "+String(clean.name)
