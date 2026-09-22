extends SceneTree
const BASE=Vector2(1440,900)
var game
var failures:Array[String]=[]
var shots=0
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1440,900)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts/ui")
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase5-visual.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 game.ui.act("route_open");await _frames(5)
 await _shot("50_routes_desktop")
 root.size=Vector2i(1180,820);game.profile.settings.touch=true
 await _frames(5);await _shot("51_routes_ipad")
 await _touch(Vector2(240,780))
 _expect("tap commits route",game.dungeon.route_path.size()==2)
 _expect("tap starts encounter",game.dungeon.active>=0)
 game.start_run();game.ui.act("route_open");await _frames(5)
 await _touch(Vector2(1230,60))
 _expect("tap returns without commitment",game.mode=="play" and game.dungeon.route_path==[0])
 await _shot("52_route_hud_ipad")
 game.mode="route_event";await _frames(5);await _shot("53_route_event_ipad")
 print("PHASE5_VISUAL shots=%d failures=%d"%[shots,failures.size()])
 game.shutdown(0 if failures.is_empty() else 1)
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
