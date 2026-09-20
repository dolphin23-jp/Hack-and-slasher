class_name Soundscape
extends Node
var effects={}
var voices:Array[AudioStreamPlayer]=[]
var music:AudioStreamPlayer
var music_name=""
var settings={}
var last_sound={}
func _ready()->void:
 for key in ["slash","heavy","hit","crit","dash","hurt","death","enemy_death","loot","rare","legendary","equip","ui","nova","bolt","level","boss","heal","chest"]:effects[key]=load("res://assets/audio/"+key+".wav")
 for i in range(16):
  var v=AudioStreamPlayer.new();add_child(v);voices.append(v)
 music=AudioStreamPlayer.new();add_child(music)
func play(key:String,volume:float=1)->void:
 var now=Time.get_ticks_msec()
 if not effects.has(key) or now-last_sound.get(key,-1000)<40:return
 last_sound[key]=now
 for v in voices:
  if not v.playing:
   v.stream=effects[key];v.volume_db=linear_to_db(maxf(.001,settings.get("sfx",.8)*volume))-7
   v.pitch_scale=randf_range(.94,1.06) if key in ["hit","slash","enemy_death"] else 1
   v.play();return
func set_music(key:String)->void:
 if music_name==key:return
 music_name=key;music.stop()
 var stream=load("res://assets/audio/"+key+".wav")
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=stream.data.size()/2
 music.stream=stream;update_volume();music.play()
func update_volume()->void:music.volume_db=linear_to_db(maxf(.001,settings.get("music",.65)))-8
func silence()->void:
 if is_instance_valid(music):music.stop();music.stream=null
 for v in voices:
  if is_instance_valid(v):v.stop();v.stream=null
 effects.clear();last_sound.clear();music_name=""
func dispose()->void:
 silence()
 for v in voices.duplicate():
  if is_instance_valid(v):v.free()
 voices.clear()
 if is_instance_valid(music):music.free()
 music=null
func _exit_tree()->void:silence()
