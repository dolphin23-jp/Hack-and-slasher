class_name ItemArt
extends RefCounted
const ROOT="res://assets/items/"
const LIMIT=96
static var cache={}
static var manifest={}
static var resolved_paths={}
static var initialized=false
static func valid_id(id:String)->bool:
 if id.is_empty() or id.length()>96:return false
 for c in id:
  if not (c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"):return false
 return true
static func initialize()->void:
 if initialized:return
 initialized=true
 var data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
 if data is Dictionary and data.get("items") is Dictionary:manifest=data.items
static func path(it:Dictionary)->String:
 var key=JSON.stringify([it.get("art_id",""),it.get("art_variant","default"),it.get("weapon_type",""),it.get("slot","")])
 if not resolved_paths.has(key):
  if resolved_paths.size()>=256:resolved_paths.erase(resolved_paths.keys()[0])
  resolved_paths[key]=resolve(it)
 return resolved_paths[key]
static func resolve(it:Dictionary)->String:
 initialize()
 var id=String(it.get("art_id",""));var variant=String(it.get("art_variant","default"))
 if valid_id(id) and valid_id(variant):
  var entry=manifest.get(id,{})
  if entry is Dictionary:
   var filename=String(entry.get(variant,entry.get("default","")))
   if not filename.is_empty() and filename==filename.get_file() and filename.get_extension() in ["png","webp","svg"] and ResourceLoader.exists(ROOT+filename):return ROOT+filename
  for ext in ["png","webp","svg"]:
   for stem in [id+"_"+variant,id]:
    if ResourceLoader.exists(ROOT+stem+"."+ext):return ROOT+stem+"."+ext
 var kind=String(it.get("weapon_type",""))
 var icon=kind if String(it.get("slot","")).begins_with("weapon") and kind in ["sword","scythe","spear","staff","fist","mace","spellblade"] else ("accessory" if String(it.get("slot","")).begins_with("accessory") else "armor")
 return "res://assets/icons/"+icon+".svg"
static func texture(it:Dictionary)->Texture2D:
 var resolved=path(it)
 if not cache.has(resolved):
  if cache.size()>=LIMIT:cache.erase(cache.keys()[0])
  cache[resolved]=load(resolved)
 return cache[resolved]
static func fitted(tex:Texture2D,rect:Rect2)->Rect2:
 var size=tex.get_size();var scale=minf(rect.size.x/maxf(1,size.x),rect.size.y/maxf(1,size.y))
 return Rect2(rect.get_center()-size*scale*.5,size*scale)
static func clear()->void:cache.clear();resolved_paths.clear();manifest.clear();initialized=false
