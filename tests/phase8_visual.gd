extends SceneTree
var game
var failures=[]
var shots=0
func _initialize():call_deferred("run")
func run()->void:
 root.size=Vector2i(1180,820)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts/ui")
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase8-visual.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 game.mode="play";game.profile.settings.touch=true;game.banner_time=0;game.toast_time=0
 for drop in game.drops:drop.queue_free()
 game.drops.clear()
 for spec in [["forge_boss",4],["thorn_boss",8],["boss",9]]:
  for old in game.enemies:old.queue_free()
  game.enemies.clear();game.projectiles.clear();game.hazards.clear()
  var kind=String(spec[0]);var room=int(spec[1]);var center=game.dungeon.rooms[room].center
  game.player.position=center+Vector2(-210,0);game.camera.position=center;game.dungeon.active=room
  var e=game.spawn_enemy(kind,center+Vector2(90,0),5,room)
  e.state="approach";e.timer=0;e.pattern=0;e.aim=Vector2.LEFT
  await shot("80_"+kind+"_phase1")
  e.start_windup();e.timer=e.windup*.42
  await shot("81_"+kind+"_windup")
  e.state="recover";e.timer=1.6;game.hazards.clear()
  await shot("82_"+kind+"_recover")
  e.state="approach";e.hp=e.max_hp*e.phase_threshold()-.1;e.tick(.01)
  game.banner_time=0;game.toast_time=0;e.timer=.52
  await shot("83_"+kind+"_transition")
  e.state="approach";e.timer=0;e.pattern=2;e.start_windup();e.timer=e.windup*.5
  await shot("84_"+kind+"_phase2_windup")
  e.state="recover";e.timer=1.6;game.hazards.clear()
  await shot("85_"+kind+"_phase2_recover")
 print("PHASE8_VISUAL shots=%d failures=%d"%[shots,failures.size()])
 game.shutdown(0 if failures.is_empty() else 1)
func shot(label:String)->void:
 for e in game.enemies:e.queue_redraw()
 game.player.queue_redraw();game.ui.queue_redraw()
 for _frame in range(3):await process_frame
 var img=root.get_texture().get_image()
 if img==null or img.save_png(ProjectSettings.globalize_path("res://test-artifacts/ui/%s.png"%label))!=OK:failures.append(label)
 else:shots+=1;print("SHOT ",label," ",img.get_width(),"x",img.get_height())
