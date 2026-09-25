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
 game.profile.path="user://phase7-isolated.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 var player=game.player
 var atlas:Image=player.texture.get_image()
 check("production atlas imported",atlas.get_width()==1254 and atlas.get_height()==1254)
 check("upper body visible",atlas.get_pixel(620,250).a>.8)
 check("leg cutouts visible",atlas.get_pixel(300,1000).a>.8 and atlas.get_pixel(930,1000).a>.8)
 check("atlas corner transparent",atlas.get_pixel(0,0).a<.1)
 var loadout=player.equipment.duplicate(true)
 for kind in WeaponDB.TYPES:
  for slot in Loadout.WEAPONS:player.equipment[slot].weapon_type=kind
  player.rebuild_stats();player.attack_cd=0;player.dash_cd=0;player.dash_time=0
  check("strike "+kind,player.attack() and player.attack_time>0)
  check("dodge cancels "+kind,player.dash() and player.attack_time==0 and player.dash_time>0)
 player.equipment=loadout;player.dash_time=0;player.attack_cd=0;player.combo=0;player.reset_chain()
 for slot in Loadout.WEAPONS:player.equipment[slot].weapon_type=["sword","scythe","spear"][Loadout.WEAPONS.find(slot)]
 var sequence=[]
 for _i in range(6):
  player.attack_cd=0
  check("chain strike",player.attack())
  sequence.append(player.equipment[Loadout.WEAPONS[player.combo-1]].weapon_type)
 check("three weapon order",sequence==["sword","scythe","spear","sword","scythe","spear"])
 print("PHASE7 checks=%d failures=%d"%[checks,failures.size()])
 game.shutdown(0 if failures.is_empty() else 1)
