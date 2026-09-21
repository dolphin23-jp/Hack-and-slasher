extends SceneTree
var game
var checks=0
var failures=[]

func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1
 print("BUILD_MANAGER ",("PASS " if ok else "FAIL ")+label)
 if not ok:failures.append(label)

func run()->void:
 var board=OathBoard.empty()
 board.points=100
 check("fresh board total equals unspent",OathBoard.total_points(board)==100 and OathBoard.spent_points(board)==0)
 check("first node unlocks",OathBoard.unlock_node(board,"dance","dance_tempo").begins_with("解放"))
 check("unlock spends exact node cost",board.points==98 and OathBoard.spent_points(board)==2 and OathBoard.total_points(board)==100)
 OathBoard.unlock_node(board,"dance","dance_edge")
 OathBoard.unlock_node(board,"dance","dance_flow")
 OathBoard.unlock_node(board,"dance","dance_flow2")
 OathBoard.unlock_node(board,"dance","dance_cap")
 check("branch path and capstone unlock",["dance_flow","dance_flow2","dance_cap"].all(func(id):return id in board.nodes))
 var total_before_switch=OathBoard.total_points(board)
 var switch_msg=OathBoard.switch_branch(board,"dance","dance_impact")
 check("exclusive branch switch reports success",switch_msg.begins_with("分岐切替"))
 check("old branch dependent nodes refunded",not "dance_flow" in board.nodes and not "dance_flow2" in board.nodes and not "dance_cap" in board.nodes)
 check("new branch becomes owned","dance_impact" in board.nodes)
 check("branch switch conserves total oath points",OathBoard.total_points(board)==total_before_switch)
 OathBoard.unlock_node(board,"dance","dance_impact2")
 OathBoard.unlock_node(board,"dance","dance_cap")
 var total_before_path=OathBoard.total_points(board)
 var path_refund=OathBoard.respec_path(board,"dance")
 check("path respec clears only that tree",OathBoard.path_nodes(board,"dance").is_empty())
 check("path respec refunds node costs",path_refund>0 and OathBoard.total_points(board)==total_before_path)
 OathBoard.unlock_node(board,"arcane","arcane_focus")
 OathBoard.unlock_node(board,"arcane","arcane_thread")
 var total_before_all=OathBoard.total_points(board)
 var all_refund=OathBoard.respec_all(board)
 check("full respec clears all nodes",board.nodes.is_empty() and all_refund>0)
 check("full respec conserves total points",OathBoard.total_points(board)==total_before_all)

 board.active=["storm","fortress","seek"]
 OathBoard.unlock_node(board,"storm","storm_spark")
 OathBoard.unlock_node(board,"storm","storm_wire")
 var preset=OathBoard.make_preset(board,"Storm Test","lance",["spear","staff","scythe"])
 check("preset stores name active starter and weapon memo",preset.name=="Storm Test" and preset.active==board.active and preset.starter=="lance" and preset.weapon_types==["spear","staff","scythe"])
 var preset_cost=OathBoard.preset_cost(preset)
 OathBoard.respec_all(board);board.active=["dance"]
 var total_before_load=OathBoard.total_points(board)
 var load_result=OathBoard.apply_preset(board,preset)
 check("preset load succeeds with sufficient total points",load_result.begins_with("Preset LOAD"))
 check("preset load restores active oath order",board.active==["storm","fortress","seek"])
 check("preset load restores node allocation",board.nodes==preset.nodes)
 check("preset load recalculates unspent points",board.points==total_before_load-preset_cost and OathBoard.total_points(board)==total_before_load)
 var corrupt=OathBoard.sanitize_preset({"name":"","active":["nope","dance","dance"],"nodes":["bad","dance_cap"],"starter":"bad","weapon_types":["nope"]})
 check("preset sanitizer repairs identity fields",corrupt.name=="Build" and corrupt.active==["dance"] and corrupt.starter=="blade")
 check("preset sanitizer rejects invalid node ids",corrupt.nodes==[])
 check("preset sanitizer normalizes weapon memo",corrupt.weapon_types==["sword","sword","sword"])
 var poor=OathBoard.empty();poor.points=1
 check("preset load refuses overspending",OathBoard.apply_preset(poor,preset).begins_with("誓片が不足"))

 game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
 game.profile.path="user://build-manager-isolated.json";game.profile.run={};game.profile.oaths=OathBoard.empty();game.profile.oaths.points=40
 game.profile.build_presets=[]
 game.profile.write_save()
 game.mode="title";game.ui.act("start")
 check("title start opens build confirmation",game.mode=="build_confirm")
 game.ui.act("cancel_start")
 check("build confirmation can return to title",game.mode=="title")
 game.ui.act("start");game.ui.reliquary.act(game.ui,"oaths")
 check("confirmation can open editable oath board",game.mode=="oaths" and game.ui.reliquary.back=="build_confirm" and game.ui.reliquary.oath_editable())
 game.ui.reliquary.act(game.ui,"node:dance:dance_tempo")
 game.ui.reliquary.act(game.ui,"preset_new")
 check("pre-run preset save persists one preset",game.profile.build_presets.size()==1 and game.profile.build_presets[0].nodes.has("dance_tempo"))
 var saved_name=String(game.profile.build_presets[0].name)
 game.ui.reliquary.act(game.ui,"preset_rename")
 check("preset has a mutable display name",String(game.profile.build_presets[0].name)!=saved_name)
 game.ui.reliquary.act(game.ui,"respec_all")
 check("UI full respec clears purchased nodes",game.profile.oaths.nodes.is_empty())
 game.ui.reliquary.act(game.ui,"preset_load")
 check("UI preset load restores allocation","dance_tempo" in game.profile.oaths.nodes)
 game.ui.reliquary.act(game.ui,"oath_back")
 check("oath back returns to build confirmation",game.mode=="build_confirm")
 game.ui.act("confirm_start");await process_frame
 check("confirm start launches a run",game.mode=="play" and is_instance_valid(game.player))
 check("run freezes active oath selection",game.player.active_oaths==game.profile.oaths.active)
 var nodes_before=game.profile.oaths.nodes.duplicate()
 game.ui.reliquary.back="inventory"
 game.ui.reliquary.act(game.ui,"respec_all")
 check("respec is blocked during run",game.profile.oaths.nodes==nodes_before)

 game.profile.write_save()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 check("preset survives disk reload",disk.build_presets.size()==1 and String(disk.build_presets[0].name)==String(game.profile.build_presets[0].name))
 var old_path="user://build-manager-old.json"
 var file=FileAccess.open(old_path,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":2,"settings":{},"records":{},"run":{},"chronicle":{},"oaths":OathBoard.empty(),"vault":[]}));file.close()
 var old=ProfileStore.new();old.path=old_path;old.read_save()
 check("old version 2 save without presets remains valid",old.build_presets.is_empty())

 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="BUILD_MANAGER checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/build_manager_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures))
 print(summary.strip_edges())
 game.shutdown(0 if failures.is_empty() else 1)
