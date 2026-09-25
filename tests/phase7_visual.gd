extends SceneTree
var game
var failures=[]
var shots=0
func _initialize():call_deferred("run")
func run()->void:
 root.size=Vector2i(1180,820)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts/ui")
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase7-visual.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 game.mode="play";game.profile.settings.touch=true;game.camera.position=Vector2.ZERO;game.player.position=Vector2.ZERO
 game.banner_time=0;game.toast_time=0
 for drop in game.drops:drop.queue_free()
 game.drops.clear()
 await shot("70_player_idle_ipad")
 game.player.velocity=Vector2(230,0);game.player.anim=1.2;await shot("71_player_move_ipad")
 game.player.velocity=Vector2.ZERO
 for kind in WeaponDB.TYPES:
  for slot in Loadout.WEAPONS:game.player.equipment[slot].weapon_type=kind
  game.player.combo=1;game.player.attack_time=.11;game.player.facing=Vector2.RIGHT
  await shot("72_player_"+kind+"_impact_ipad")
 game.player.attack_time=0;game.player.dash_time=.12;await shot("73_player_dodge_ipad")
 game.player.dash_time=0;game.player.flash=.15;await shot("74_player_hit_ipad")
 game.player.flash=0;game.player.dead=true;await shot("75_player_death_ipad")
 game.player.dead=false;game.player.combo=0;game.player.reset_chain()
 for i in range(3):game.player.equipment[Loadout.WEAPONS[i]].weapon_type=["sword","scythe","spear"][i]
 for i in range(3):
  game.player.attack_cd=0;game.player.attack_time=0
  if not game.player.attack():failures.append("chain attack "+str(i));continue
  game.player.attack_time=.11
  await shot("76_player_chain_"+str(i+1)+"_ipad")
 print("PHASE7_VISUAL shots=%d failures=%d"%[shots,failures.size()])
 game.shutdown(0 if failures.is_empty() else 1)
func shot(label:String)->void:
 game.player.queue_redraw();game.ui.queue_redraw()
 for _frame in range(3):await process_frame
 var img=root.get_texture().get_image()
 if img==null:
  failures.append("render unavailable: "+label)
  return
 var path=ProjectSettings.globalize_path("res://test-artifacts/ui/%s.png"%label)
 if img.save_png(path)!=OK:failures.append(label)
 else:shots+=1;print("SHOT ",label," ",img.get_width(),"x",img.get_height())
