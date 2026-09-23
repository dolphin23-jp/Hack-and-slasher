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
 game.profile.path="user://phase6-isolated.json";game.profile.run={};game.start_run();game.set_physics_process(false)
 var item=game.player.equipment.weapon.duplicate(true)
 item.art_id="example_sword"
 check("manifest resolves installed art",ItemArt.path(item)=="res://assets/items/example_sword_default.svg")
 var tex=ItemArt.texture(item)
 var drop=game.spawn_drop(Vector2.ZERO,item)
 check("loot and UI share texture",drop.icon==game.ui.reliquary.art_texture(item) and drop.icon==tex)
 item.art_variant="missing"
 check("unknown variant falls back to default",ItemArt.texture(item)==tex)
 item.art_id="../../actors/player";check("invalid art id stays within icon fallback",ItemArt.path(item).begins_with("res://assets/icons/"))
 for kind in WeaponDB.TYPES:
  item.weapon_type=kind;item.art_id="missing"
  check("typed placeholder "+kind,ItemArt.path(item)=="res://assets/icons/"+kind+".svg")
  game.fx.weapon(Vector2.ZERO,Vector2.RIGHT,kind,180,"art")
 check("seven distinct weapon effects",game.fx.weapon_trails.size()==7)
 for i in range(1000):
  game.fx.weapon(Vector2.ZERO,Vector2.RIGHT,"sword",150)
  game.fx.recipe(Vector2.ZERO,["armor_cut"],true)
  game.fx.ring(Vector2.ZERO,100,Color.WHITE)
 check("effects bounded under sustained spam",game.fx.weapon_trails.size()==48 and game.fx.sigils.size()==16 and game.fx.rings.size()==64)
 game.fx.tick(2)
 check("all short effects expire",game.fx.weapon_trails.is_empty() and game.fx.sigils.is_empty() and game.fx.rings.is_empty())
 var original=game.player.equipment.duplicate(true)
 for kind in WeaponDB.TYPES:
  for slot in Loadout.WEAPONS:game.player.equipment[slot].weapon_type=kind
  game.player.rebuild_stats();game.player.attack_cd=0;game.player.dash_cd=0;game.player.dash_time=0;game.player.cooldowns=[0.0,0.0,0.0];game.player.skill_actions=[]
  check("normal attack "+kind,game.player.attack())
  check("art "+kind,game.player.cast(0))
  check("dash cancel "+kind,game.player.dash())
 game.player.equipment=original
 print("PHASE6 checks=%d failures=%d"%[checks,failures.size()])
 ItemArt.clear();game.shutdown(0 if failures.is_empty() else 1)
