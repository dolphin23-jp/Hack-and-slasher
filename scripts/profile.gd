class_name ProfileStore
extends RefCounted
const VERSION=2
const RUN_METRIC_KEYS=["hits_taken","damage_dealt","kills","drops","pickups","equips","level_ups","boss_patterns","perfect_evades","contracts"]
static func empty_run_metrics()->Dictionary:
 var out={}
 for key in RUN_METRIC_KEYS:out[key]=0.0 if key=="damage_dealt" else 0
 return out
var recovery_notice=""
# Set when the file on disk must not be overwritten (newer version or failed backup).
var write_blocked=false
var path="user://ashen_vow_v1.json"
var settings={"music":.65,"sfx":.8,"shake":.7,"auto_aim":false,"touch":false,"touch_size":.5,"touch_inset":.5,"hitstop":true,"auto_salvage_rare":false,"salvage_rules":SalvagePolicy.defaults()}
var records={"runs":0,"wins":0,"best_level":1,"best_ascension":0,"total_kills":0}
var run={}
var oaths=OathBoard.empty()
var build_presets=[]
var vault=[]
var chronicle=ChronicleDB.empty()
func read_save()->void:
 if not FileAccess.file_exists(path):return
 var content=FileAccess.get_file_as_string(path)
 if content.length()>2000000:preserve_unreadable("保存データを開けませんでした。新しいデータで開始します。");return
 var json=JSON.new()
 var data=json.data if json.parse(content)==OK else null
 if not data is Dictionary:preserve_unreadable("保存データを開けませんでした。新しいデータで開始します。");return
 var version=data.get("version",0)
 if (version is int or version is float) and float(version)>VERSION:
  write_blocked=true;preserve_unreadable("新しいバージョンの保存データです。上書きを防ぐため、このバージョンでは保存しません。");return
 if version!=1 and version!=VERSION:preserve_unreadable("保存データを開けませんでした。新しいデータで開始します。");return
 if data.get("version")==1 and not FileAccess.file_exists(path+".v1.bak"):
  DirAccess.copy_absolute(path,path+".v1.bak")
 data=SaveMigration.migrate(data)
 oaths=OathBoard.sanitize(data.oaths)
 build_presets=[]
 var incoming_presets=data.get("build_presets",[])
 if incoming_presets is Array:
  for value in incoming_presets:
   if build_presets.size()>=5:break
   var preset=OathBoard.sanitize_preset(value)
   if not preset.is_empty():build_presets.append(preset)
 var incoming=data.get("settings",{})
 if incoming is Dictionary:
  for k in settings:
   if not incoming.has(k):continue
   if settings[k] is bool and incoming[k] is bool:settings[k]=incoming[k]
   elif not settings[k] is bool and (incoming[k] is float or incoming[k] is int):settings[k]=clampf(incoming[k],0,1)
 settings.salvage_rules=SalvagePolicy.sanitize(incoming.get("salvage_rules",{}) if incoming is Dictionary else {})
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
 vault=[]
 var saved_vault=data.get("vault",[])
 if saved_vault is Array:
  for item in saved_vault:
   if vault.size()>=120:break
   if ItemDB.valid(item):vault.append(item.duplicate(true))
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
 if s is Dictionary and not s.is_empty() and run.is_empty():
  preserve_unreadable("保存データの一部を復元できません。")
# Keeps an unreadable save instead of letting the next write replace it with defaults.
func preserve_unreadable(reason:String)->void:
 var backup=path+".recovery.bak"
 if FileAccess.file_exists(backup):backup=path+".recovery.%d.bak"%int(Time.get_unix_time_from_system())
 if DirAccess.copy_absolute(path,backup)==OK:
  recovery_notice=reason+"元データは "+backup.get_file()+" に保護しました。"
 else:
  write_blocked=true;recovery_notice=reason+"元データを保護できないため、保存を停止しています。"
func valid_run(v:Variant)->bool:
 if not v is Dictionary or v.is_empty():return false
 for k in ["level","xp","hp","potions","seed","kills","elapsed","ascension","equipment","inventory","upgrades","cleared","position"]:
  if not v.has(k):return false
 for k in ["level","xp","hp","potions","seed","kills","elapsed","ascension"]:
  if not (v[k] is int or v[k] is float) or not is_finite(float(v[k])):return false
 if v.level<1 or v.level>99 or v.ascension<0 or v.ascension>100 or v.hp<=0 or v.xp<0 or v.xp>10000000 or v.potions<0 or v.potions>3:return false
 for key in ["materials","combo"]:
  if v.has(key):
   if not (v[key] is int or v[key] is float) or not is_finite(float(v[key])) or v[key]<0 or v[key]>10000000:return false
 if v.has("combo") and v.combo>3:return false
 if v.has("finisher_charge"):
  var charge=v.finisher_charge
  if not (charge is int or charge is float) or not is_finite(float(charge)) or charge!=int(charge) or charge<0 or charge>WeaponActionResolver.FINISHER_COST:return false
 if v.has("skill_cooldowns"):
  if not v.skill_cooldowns is Array or v.skill_cooldowns.size()!=3:return false
  for cd in v.skill_cooldowns:
   if not (cd is int or cd is float) or not is_finite(float(cd)) or cd<0 or cd>60:return false
 if v.has("active_oaths"):
  if not v.active_oaths is Array or v.active_oaths.size()>3:return false
  var seen=[]
  for key in v.active_oaths:
   if not key is String or not OathBoard.PATHS.has(key) or key in seen:return false
   seen.append(key)
 if v.has("oath_board"):
  if not v.oath_board is Dictionary:return false
  var board=OathBoard.sanitize(v.oath_board)
  if not v.oath_board.get("nodes",[]) is Array:return false
  var clean_nodes=OathBoard.sanitize_node_ids(v.oath_board.get("nodes",[]))
  var requested=[]
  for id in v.oath_board.get("nodes",[]):
   if not id is String or OathBoard.node_info(id).is_empty() or id in requested:return false
   requested.append(id)
  if clean_nodes.size()!=requested.size():return false
  for id in requested:
   if id not in clean_nodes:return false
 if not v.equipment is Dictionary or not v.inventory is Array or v.inventory.size()>84 or not v.upgrades is Dictionary:return false
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
  if not (v.world_version is int or v.world_version is float) or v.world_version!=int(v.world_version) or int(v.world_version) not in [1,2,3]:return false
 if int(v.get("world_version",1))>=3:
  var path=v.get("route_path",[])
  if not path is Array or path.is_empty() or path.size()>6 or path[0]!=0:return false
  var seen=[]
  for id in path:
   if not (id is int or id is float) or id!=int(id) or id<0 or id>11 or id in seen:return false
   seen.append(id)
 if v.has("loot_favor") and (not (v.loot_favor is float or v.loot_favor is int) or not is_finite(float(v.loot_favor)) or v.loot_favor<0 or v.loot_favor>.15):return false
 if v.has("event_choices"):
  if not v.event_choices is Dictionary:return false
  for key in v.event_choices:
   if int(v.get("world_version",1))>=3 and key in ["1","2","3","4","5","6","7","8"]:
    if v.event_choices[key] not in ["sacrifice","rest"]:return false
    continue
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
 if write_blocked:return false
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return false
 f.store_string(JSON.stringify({"version":VERSION,"settings":settings,"records":records,"run":run,"chronicle":chronicle,"oaths":oaths,"build_presets":build_presets,"vault":vault}));f.flush();f.close()
 return DirAccess.rename_absolute(path+".tmp",path)==OK
