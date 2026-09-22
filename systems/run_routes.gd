class_name RunRoutes
extends RefCounted
# Stable room IDs retain contract semantics; seeded stages determine their order.
const TYPES={
 "combat":["戦闘","装備と経験値","中"],
 "elite":["精鋭","Epic以上の装備","高"],
 "treasure":["宝物庫","装備3個 / 戦闘なし","低"],
 "heal":["泉","生命全回復・回復薬補充","低"],
 "forge":["鍛冶","素材80・鍛冶画面","低"],
 "oath":["誓印の祭壇","Run祝福を1つ選択","低"],
 "event":["残響の泉","生命25%と引換にEpic / 無料回復も選択可","選択"],
 "contract":["契約","条件を選択・達成でLegendary","高"],
 "boss":["守護者","固有Legendary","極高"],
 "final":["王座","最終Bossと報酬","極高"]}
static func configure(d)->void:
 var r=RandomNumberGenerator.new();r.seed=d.game.run_seed ^ 0x51a7
 var stages=[[1,2,3],[4,5,6],[8,10,11],[7],[9]]
 # Three distinct itineraries; each preserves the southern contracts as choices.
 if r.randi_range(0,1)==1:stages=[[1,2,3],[4,5,10],[6,8,11],[7],[9]]
 var services=["treasure","heal","forge","oath","event"]
 for i in range(services.size()-1,0,-1):
  var j=r.randi_range(0,i);var t=services[i];services[i]=services[j];services[j]=t
 for stage in range(stages.size()):
  for index in range(stages[stage].size()):
   var id=int(stages[stage][index]);var room=d.rooms[id]
   var kind="combat"
   if id in [10,11]:kind="contract"
   elif id==7:kind="heal"
   elif id==9:kind="final"
   elif index==0:kind="elite" if stage==0 else "boss"
   elif index==1:kind="combat" if stage==0 else services[(stage+1)%services.size()]
   else:kind=services[stage%services.size()]
   room.route_stage=stage;room.room_type=kind;room.tier=1+stage*2
   room.optional=kind=="contract"
   room.reward=TYPES[kind][1];room.danger=TYPES[kind][2]
   room.name=TYPES[kind][0]+" / "+room.name
   room.lore=room.reward+" ・ 危険度 "+room.danger
   room.waves=2 if kind in ["combat","elite","contract","boss"] else (1 if kind=="final" else 0)
   room.count=5+stage*2
   room.special=""
   if kind=="elite":room.special="champion"
   if kind=="boss":room.special="forge_boss" if r.randi_range(0,1)==0 else "thorn_boss"
 d.route_stages=stages;d.connections=[]
 var previous=[0]
 for stage in stages:
  for a in previous:
   for b in stage:d.connections.append([a,b])
  previous=stage
static func choices(d)->Array:
 if d.layout_version<3 or d.active>=0:return []
 var current=int(d.route_path[-1]);var stage=d.route_path.size()-1
 if current not in d.cleared or stage>=d.route_stages.size():return []
 return d.route_stages[stage].duplicate()
static func restore_path(d,value)->void:
 d.route_path=[0]
 if not value is Array:return
 for i in range(1,mini(value.size(),d.route_stages.size()+1)):
  var id=int(value[i])
  if id not in d.route_stages[i-1]:break
  d.route_path.append(id)
