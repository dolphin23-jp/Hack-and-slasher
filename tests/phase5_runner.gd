extends SceneTree
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase5-isolated.json";game.profile.run={};game.set_physics_process(false);game.start_run()
 check("new runs use branching world",game.dungeon.layout_version==3)
 var signatures={};var kinds={}
 for seed_value in range(100):
  game.run_seed=seed_value;RunRoutes.configure(game.dungeon)
  signatures[JSON.stringify(game.dungeon.route_stages)+JSON.stringify(game.dungeon.rooms.map(func(r):return r.get("room_type","")))]=true
  for room in game.dungeon.rooms:
   if room.has("room_type"):kinds[room.room_type]=true
  check("all stages lead to king",game.dungeon.route_stages[-1]==[9])
 check("routes and rewards vary",signatures.size()>10)
 for kind in RunRoutes.TYPES:check("generated service "+kind,kinds.has(kind))
 game.start_run()
 var initial=RunRoutes.choices(game.dungeon)
 check("initial three route choices",initial.size()==3)
 check("cannot skip to king",not game.travel_route(9))
 check("can commit first room",game.travel_route(int(initial[0])))
 check("cannot travel while fighting",not game.travel_route(int(initial[1])))
 check("old sibling floor is sealed",not game.dungeon.floor_at(game.dungeon.rooms[int(initial[1])].center))
 var saved=game.run_snapshot()
 check("new checkpoint passes schema",game.profile.valid_run(saved))
 game.profile.run=saved;game.start_run(true)
 check("resume retains committed route",game.dungeon.route_path==saved.route_path)
 check("resume stays on current floor",game.dungeon.walkable(game.player.position,18,false))
 # Resolve each service twice to verify once-only dispatch through room entry.
 for kind in ["heal","treasure","forge","oath","event"]:
  game.start_run();var id=int(RunRoutes.choices(game.dungeon)[0]);var room=game.dungeon.rooms[id]
  room.room_type=kind;room.waves=0;room.optional=false
  game.player.hp=game.player.stats.hp*.5
  check("enter "+kind,game.travel_route(id))
  if kind=="event":game.choose_route_event(false)
  if kind=="oath":game.choose_upgrade(0)
  var mats=game.player.materials;var drops=game.drops.size();var hp=game.player.hp
  game.mode="play";game.last_room=-1;game.check_rooms(0)
  check("service not repeated "+kind,mats==game.player.materials and drops==game.drops.size() and hp==game.player.hp)
  check("service unlocks next stage "+kind,not RunRoutes.choices(game.dungeon).is_empty())
 game.start_run();saved=game.run_snapshot();saved.world_version=2;saved.erase("route_path")
 game.profile.run=saved;game.start_run(true)
 check("legacy resumes physical cathedral",game.dungeon.layout_version==2 and not game.dungeon.corridors.is_empty())
 var summary="PHASE5 checks=%d failures=%d"%[checks,failures.size()]
 print(summary);DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 FileAccess.open("res://test-artifacts/phase5_summary.txt",FileAccess.WRITE).store_string(summary+"\n"+"\n".join(failures))
 game.shutdown(0 if failures.is_empty() else 1)
