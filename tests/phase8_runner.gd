extends SceneTree
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase8-isolated.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 for spec in [["forge_boss",4],["thorn_boss",8],["boss",9]]:
  var kind=String(spec[0]);var e=game.spawn_enemy(kind,Vector2(280,0),5,int(spec[1]))
  var path=String(ChapelEnemy.BOSS_ART[kind])
  check(kind+" loads unique atlas",e.texture.resource_path==path)
  var image=e.texture.get_image()
  check(kind+" transparent 2-phase atlas",image.get_width()==1536 and image.get_height()==1024 and image.get_pixel(0,0).a<.1)
  var left=image.get_pixel(384,384);var right=image.get_pixel(1152,384)
  check(kind+" both phases rendered",left.a>.1 and right.a>.1)
  e.state="approach";e.hp=e.max_hp*e.phase_threshold()-.1;e.tick(.01)
  check(kind+" reaches protected visual transition",e.phase==2 and e.state=="transform" and e.texture.resource_path==path)
  e.timer=.4;e.tick(.41)
  check(kind+" resumes attack after visual transition",e.state=="approach")
  e.state="recover";e.timer=1.4;var old=e.hp;e.take_damage(100,Vector2.ZERO)
  check(kind+" recovery damage window remains",e.hp<old-100)
  e.queue_free();game.enemies.clear();game.hazards.clear()
 print("PHASE8 checks=%d failures=%d"%[checks,failures.size()])
 game.shutdown(0 if failures.is_empty() else 1)
