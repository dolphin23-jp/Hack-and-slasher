class_name ProfileStore
extends RefCounted
const VERSION=1
const RUN_METRIC_KEYS=["hits_taken","damage_dealt","kills","drops","pickups","equips","level_ups","boss_patterns","perfect_evades","contracts"]
static func empty_run_metrics()->Dictionary:
 var out={}
 for key in RUN_METRIC_KEYS:out[key]=0.0 if key=="damage_dealt" else 0
 return out
var path="user://ashen_vow_v1.json"
var settings={"music":.65,"sfx":.8,"shake":.7,"auto_aim":false,"touch":false,"touch_size":.5,"touch_inset":.5,"hitstop":true}
var records={"runs":0,"wins":0,"best_level":1,"best_ascension":0,"total_kills":0}
var run={}
var chronicle=ChronicleDB.empty()
func read_save()->void:
 if not FileAccess.file_exists(path):return
 var content=FileAccess.get_file_as_string(path)
 if content.length()>2000000:return
 var data=JSON.parse_string(content)
 if not data is Dictionary or data.get("version",0)!=VERSION:return
 var incoming=data.get("settings",{})
 if incoming is Dictionary:
  for k in settings:
   if not incoming.has(k):continue
   if settings[k] is bool and incoming[k] is bool:settings[k]=incoming[k]
   elif not settings[k] is bool and (incoming[k] is float or incoming[k] is int):settings[k]=clampf(incoming[k],0,1)
 var rec=data.get("records",{})
 if rec is Dictionary:
  for k in records:
   if rec.get(k) is float or rec.get(k) is int:records[k]=maxi(0,int(rec[k]))
 var history=data.get("chronicle",{})
 if history is Dictionary:
  for key in ["legends","achievements"]:
   if history.get(key) is Array:
    for value in history[key]:
     if not value is String:continue
     if key=="legends" and not ItemDB.legend_info(value).is_empty() and value not in chronicle.legends:chronicle.legends.append(value)
     if key=="achievements" and ChronicleDB.ACHIEVEMENTS.has(value) and value not in chronicle.achievements:chronicle.achievements.append(value)
  if history.get("enemies") is Dictionary:
   for key in history.enemies:
    if ChronicleDB.ENEMIES.has(key) and (history.enemies[key] is int or history.enemies[key] is float):chronicle.enemies[key]=clampi(int(history.enemies[key]),0,100000000)
  for key in ["evades","contracts"]:
   if history.get(key) is int or history.get(key) is float:chronicle[key]=clampi(int(history[key]),0,100000000)
  if history.get("start","") in ["blade","lance","ember"]:chronicle.start=history.start
 var s=data.get("run",{})
 if valid_run(s):
  run=s
  for k in ["level","xp","potions","seed","kills","ascension","pending_upgrades"]:
   if run.has(k):run[k]=int(run[k])
  for k in ["cleared","visited"]:
   if run.has(k):
    for i in range(run[k].size()):run[k][i]=int(run[k][i])
  for slot in ItemDB.SLOTS:run.equipment[slot].rarity=int(run.equipment[slot].rarity)
  for item in run.inventory:item.rarity=int(item.rarity)
func valid_run(v:Variant)->bool:
 if not v is Dictionary or v.is_empty():return false
 for k in ["level","xp","hp","potions","seed","kills","elapsed","ascension","equipment","inventory","upgrades","cleared","position"]:
  if not v.has(k):return false
 for k in ["level","xp","hp","potions","seed","kills","elapsed","ascension"]:
  if not (v[k] is int or v[k] is float) or not is_finite(float(v[k])):return false
 if v.level<1 or v.level>99 or v.ascension<0 or v.ascension>100 or v.hp<=0 or v.xp<0 or v.xp>10000000 or v.potions<0 or v.potions>3:return false
 if not v.equipment is Dictionary or not v.inventory is Array or v.inventory.size()>44 or not v.upgrades is Dictionary:return false
 for slot in ItemDB.SLOTS:
  if not ItemDB.valid(v.equipment.get(slot)):return false
 for item in v.inventory:
  if not ItemDB.valid(item):return false
 for key in v.upgrades:
  if not (v.upgrades[key] is int or v.upgrades[key] is float) or not is_finite(float(v.upgrades[key])) or absf(v.upgrades[key])>100000:return false
 for key in ["cleared","visited"]:
  if not v.get(key,[]) is Array:return false
  for id in v.get(key,[]):
   if not (id is int or id is float) or id<0 or id>11:return false
 if v.cleared.is_empty() or int(v.cleared[0])!=0:return false
 if not vector_valid(v.position):return false
 if v.has("pending_upgrades") and not (v.pending_upgrades is int or v.pending_upgrades is float):return false
 if v.has("victory_ready") and not v.victory_ready is bool:return false
 if v.has("world_version"):
  if not (v.world_version is int or v.world_version is float) or v.world_version!=int(v.world_version) or int(v.world_version) not in [1,2]:return false
 if v.has("loot_favor") and (not (v.loot_favor is float or v.loot_favor is int) or not is_finite(float(v.loot_favor)) or v.loot_favor<0 or v.loot_favor>.15):return false
 if v.has("event_choices"):
  if not v.event_choices is Dictionary:return false
  for key in v.event_choices:
   if key not in ["10","11"]:return false
   if key=="10" and v.event_choices[key] not in ["blood","danger","leave"]:return false
   if key=="11" and v.event_choices[key] not in ["wager","leave"]:return false
 if v.has("metrics"):
  if not v.metrics is Dictionary:return false
  for key in v.metrics:
   if key not in RUN_METRIC_KEYS:return false
   var value=v.metrics[key]
   if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0 or float(value)>1000000000:return false
 if not v.get("drops",[]) is Array or v.get("drops",[]).size()>1200:return false
 for d in v.get("drops",[]):
  if not d is Dictionary or not vector_valid(d.get("position")):return false
  if d.get("kind")=="item":
   if not ItemDB.valid(d.get("item")):return false
  elif d.get("kind")=="chest":
   if not d.get("item") is Dictionary or not (d.item.get("tier") is int or d.item.get("tier") is float) or not d.item.get("gilded") is bool:return false
  else:return false
 return true
func vector_valid(v:Variant)->bool:
 if not v is Array or v.size()!=2:return false
 for n in v:
  if not (n is int or n is float) or not is_finite(float(n)):return false
 return true
func write_save()->bool:
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return false
 f.store_string(JSON.stringify({"version":VERSION,"settings":settings,"records":records,"run":run,"chronicle":chronicle}));f.flush();f.close()
 return DirAccess.rename_absolute(path+".tmp",path)==OK
