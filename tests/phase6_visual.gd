extends SceneTree
const BASE=Vector2(1440,900)
var game
var failures:Array[String]=[]
var shots=0
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1180,820)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts/ui")
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase6-visual.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 game.profile.settings.touch=true
 game.player.equipment.weapon.art_id="example_sword"
 game.mode="inventory";await _shot("60_shared_item_art_ipad")
 game.mode="play";game.camera.position=Vector2.ZERO;game.player.position=Vector2.ZERO
 for kind in WeaponDB.TYPES:
  game.fx.weapon_trails.clear();game.fx.sigils.clear()
  game.fx.weapon(Vector2.ZERO,Vector2.RIGHT,kind,220,"art");game.fx.tick(.12)
  await _shot("61_weapon_"+kind)
 game.fx.recipe(Vector2.ZERO,["armor_cut","shatter"],true)
 await _shot("62_finisher_ipad")
 var item=ItemDB.generate(game.rng,4,4);item.art_id="example_sword"
 game.spawn_drop(Vector2(100,0),item)
 await _shot("63_mythic_loot_art_ipad")
 print("PHASE6_VISUAL shots=%d failures=%d"%[shots,failures.size()])
 ItemArt.clear();game.shutdown(0 if failures.is_empty() else 1)
func _frames(count: int = 2) -> void:
 for _i in range(count):
  await process_frame

func _click(base_position: Vector2) -> void:
 var window_size := Vector2(root.size)
 var scale := minf(window_size.x / BASE.x, window_size.y / BASE.y)
 var offset := (window_size - BASE * scale) * 0.5
 var screen_position := offset + base_position * scale
 var motion := InputEventMouseMotion.new()
 motion.position = screen_position
 motion.global_position = screen_position
 Input.parse_input_event(motion)
 await process_frame
 var down := InputEventMouseButton.new()
 down.button_index = MOUSE_BUTTON_LEFT
 down.pressed = true
 down.position = screen_position
 down.global_position = screen_position
 Input.parse_input_event(down)
 await process_frame
 var up := InputEventMouseButton.new()
 up.button_index = MOUSE_BUTTON_LEFT
 up.pressed = false
 up.position = screen_position
 up.global_position = screen_position
 Input.parse_input_event(up)
 await _frames(2)


func _joy(button_index: int) -> void:
 var down := InputEventJoypadButton.new()
 down.device = 0
 down.button_index = button_index
 down.pressed = true
 Input.parse_input_event(down)
 await _frames(2)
 var up := InputEventJoypadButton.new()
 up.device = 0
 up.button_index = button_index
 up.pressed = false
 Input.parse_input_event(up)
 await _frames(2)


func _joy_axis(axis: int, value: float) -> void:
 var motion := InputEventJoypadMotion.new()
 motion.device = 0
 motion.axis = axis
 motion.axis_value = value
 Input.parse_input_event(motion)
 await _frames(2)


func _touch(base_position: Vector2) -> void:
 var window_size := Vector2(root.size)
 var scale := minf(window_size.x / BASE.x, window_size.y / BASE.y)
 var offset := (window_size - BASE * scale) * 0.5
 var screen_position := offset + base_position * scale
 var down := InputEventScreenTouch.new()
 down.index = 0
 down.pressed = true
 down.position = screen_position
 Input.parse_input_event(down)
 await _frames(2)
 var up := InputEventScreenTouch.new()
 up.index = 0
 up.pressed = false
 up.position = screen_position
 Input.parse_input_event(up)
 await _frames(2)

func _shot(label: String) -> void:
 game.ui.queue_redraw()
 await _frames(3)
 var image := root.get_texture().get_image()
 var path := ProjectSettings.globalize_path("res://test-artifacts/ui/%s.png" % label)
 var err := image.save_png(path)
 if err != OK:
  failures.append("screenshot %s could not be saved: %s" % [label, error_string(err)])
 else:
  shots += 1
  print("SHOT ", label, " ", image.get_width(), "x", image.get_height())
  if label in ["04_gameplay", "04a_critical_health", "04c_gamepad_hud", "09b_touch_gameplay", "10b_elite_affix", "11_boss_hud", "13c_ascension_vow", "14_ipad_4x3_touch"]:
   _expect("world visible in " + label, _world_visible(image))

func _world_visible(image: Image) -> bool:
 var ink := Color("0d1722")
 var changed := 0
 var total := 0
 var x0 := int(image.get_width() * 0.24)
 var x1 := int(image.get_width() * 0.76)
 var y0 := int(image.get_height() * 0.28)
 var y1 := int(image.get_height() * 0.68)
 var step_x := maxi(1, int((x1 - x0) / 18.0))
 var step_y := maxi(1, int((y1 - y0) / 12.0))
 for y in range(y0, y1, step_y):
  for x in range(x0, x1, step_x):
   var pixel := image.get_pixel(x, y)
   var diff := absf(pixel.r - ink.r) + absf(pixel.g - ink.g) + absf(pixel.b - ink.b)
   if diff > 0.08:
    changed += 1
   total += 1
 return total > 0 and float(changed) / float(total) > 0.35

func _expect(label: String, condition: bool) -> void:
 if condition:
  print("PASS ", label)
 else:
  failures.append(label)
  printerr("FAIL ", label)

func _touch_position(p:Vector2)->Vector2:
 var window_size=Vector2(root.size)
 var scale=minf(window_size.x/BASE.x,window_size.y/BASE.y)
 return (window_size-BASE*scale)*.5+p*scale
