extends SceneTree
var game
var checks=0
var failures=[]
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1;print("SKILL ","PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func clear()->void:
 for list in [game.enemies,game.projectiles,game.drops]:
  for node in list.duplicate():node.queue_free()
  list.clear()
 game.hazards.clear();game.delayed_blasts.clear();game.pending_upgrades=0;game.mode="play";game.elapsed=0
 var p=game.player
 p.skill_actions.clear();p.finisher_charge=0;p.reset_chain();p.combo=0;p.attack_cd=0;p.dash_time=0;p.dash_cd=0;p.dead=false;p.cooldowns=[0.0,0.0,0.0]
 p.upgrades={};p.active_oaths=[];p.equipment=ItemDB.initial_items();p.rebuild_stats();p.position=Vector2.ZERO;p.facing=Vector2.RIGHT;p.stats.crit=0
func equip(kinds:Array)->void:
 for i in range(3):game.player.equipment[Loadout.WEAPONS[i]].weapon_type=kinds[i]
 game.player.rebuild_stats();game.player.stats.crit=0
func foe(pos:Vector2):
 var e=game.spawn_enemy("hollow",pos,1,0);e.state="approach";e.hp=10000;e.max_hp=10000;return e
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
 game.profile.path="user://skill-isolated.json";game.profile.run={};game.profile.oaths=OathBoard.empty();game.start_run();await process_frame
 clear();var p=game.player
 check("ten chain recipes",ChainResolver.RECIPES.size()==10)
 var composite=ChainResolver.matches("spellblade","spellblade").map(func(r):return r.id)
 check("dual attributes participate on both sides",composite.has("imbue") and ChainResolver.matches("spellblade","mace").size()==1 and ChainResolver.matches("spear","spellblade").any(func(r):return r.id=="seek"))
 check("triune can assign a different attribute to each weapon",ChainResolver.triune(["sword","spellblade","spear"]))
 check("triune cannot count both attributes from only one weapon",not ChainResolver.triune(["sword","sword","spellblade"]))
 for kind in WeaponDB.TYPES:
  clear();equip([kind,kind,kind]);var e=foe(Vector2(100,0))
  check("Q activates "+kind,p.cast(0))
  for bolt in game.projectiles.duplicate():bolt.tick(.12)
  check("Q deals real damage "+kind,e.hp<10000)
  check("Q cooldown rejects repeat "+kind,not p.cast(0) and p.cooldowns[0]>0)
 clear();equip(["sword","scythe","spear"]);p.combo=2;p.cast(0)
 check("Q uses last swung slot, not always first",is_equal_approx(p.cooldowns[0],5.0*(1-p.stats.cdr)))
 clear();equip(["scythe","staff","spear"]);var e=foe(Vector2(230,60));var before=e.position
 p.cast(1)
 check("chain starts with real scythe pull",e.position.distance_to(Vector2(100,0))<before.distance_to(Vector2(100,0)) and game.projectiles.is_empty())
 p.equipment.weapon2.weapon_type="fist";WeaponActionResolver.tick(p,.17)
 check("queued chain snapshots gear and resolves staff second",game.projectiles.size()==1 and game.projectiles[0].damage_types==["magic"])
 WeaponActionResolver.tick(p,.16)
 check("chain resolves spear third",game.projectiles.size()==2 and game.projectiles[1].damage_types==["pierce"] and p.skill_actions.is_empty())
 clear();equip(["fist","fist","fist"]);foe(Vector2(65,0))
 p.attack();var first_cd=p.attack_cd;p.attack_cd=0;p.attack()
 check("fist recipe increases actual attack speed",p.attack_cd<first_cd*.9)
 p.attack_cd=0;p.attack()
 check("multi-hit attacks award only one completed chain",p.finisher_charge==1)
 for i in range(9):p.attack_cd=0;p.attack()
 check("four confirmed triples fill finisher",p.finisher_charge==4)
 check("R consumes gauge once",p.cast(2) and p.finisher_charge==0 and not p.cast(2))
 check("dash remains usable during queued finisher",p.dash())
 clear();equip(["sword","sword","sword"])
 for i in range(12):p.attack_cd=0;p.attack()
 check("empty swings cannot charge finisher",p.finisher_charge==0 and not p.cast(2) and p.cooldowns[2]==0)
 clear();equip(["sword","sword","sword"]);foe(Vector2(60,0))
 for i in range(2):p.attack_cd=0;p.attack()
 p.combo_expire=0;p.attack_cd=0;p.attack()
 check("expired combo cannot complete the prior charge group",p.finisher_charge==0)
 clear();equip(["staff","staff","staff"]);foe(Vector2(160,0))
 for i in range(3):p.attack_cd=0;p.attack()
 check("projectile launch alone cannot charge",p.finisher_charge==0)
 for bolt in game.projectiles.duplicate():bolt.tick(.2)
 check("late projectile hits complete one charge group",p.finisher_charge==1)
 clear();equip(["staff","staff","staff"]);foe(Vector2(160,0))
 for i in range(3):p.attack_cd=0;p.attack()
 Loadout.swap(p,0,1)
 for bolt in game.projectiles.duplicate():bolt.tick(.2)
 check("gear reorder invalidates in-flight charge groups",p.finisher_charge==0)
 clear();equip(["spear","staff","sword"]);e=foe(Vector2(180,12));p.attack();p.attack_cd=0;p.attack()
 check("pierce to magic tracks a pierced target",game.projectiles.size()==1 and game.projectiles[0].homing_target==e)
 var old_velocity=game.projectiles[0].velocity;game.projectiles[0].tick(.04)
 check("tracking changes actual projectile direction",game.projectiles[0].velocity.y>old_velocity.y)
 clear();equip(["sword","spear","sword"]);e=foe(Vector2(85,0));p.attack();var hp=e.hp;p.attack_cd=0;p.attack();var marked_damage=hp-e.hp
 clear();equip(["sword","spear","sword"]);e=foe(Vector2(220,0));p.attack();hp=e.hp;p.attack_cd=0;p.attack()
 check("slash to pierce rewards an actually marked enemy",marked_damage>(hp-e.hp)*1.2)
 clear();equip(["mace","staff","sword"]);e=foe(Vector2(90,0));p.attack();p.attack_cd=0;p.attack()
 check("mace to staff creates one blast at last real impact",game.delayed_blasts.size()==1)
 hp=e.hp;game.tick_delayed_blasts(.2)
 check("impact recipe blast deals damage",e.hp<hp)
 clear();equip(["staff","scythe","sword"]);e=foe(Vector2(145,0));p.attack();game.projectiles[0].tick(.16);before=e.position;p.attack_cd=0;p.attack()
 check("staff to scythe pulls marked enemies",e.position.x<before.x)
 var old={"lance_fan":1.0,"fan_mastery":1.0,"nova_radius":45.0,"lance_giant":1.0,"lance_blast":1.0}
 var migrated=WeaponActionResolver.migrate_upgrades(old)
 check("old branch investments map to functional skill bonuses",is_equal_approx(migrated.chain_skill_power,.33) and migrated.chain_radius==45 and migrated.finisher_power==.25 and migrated.chain_echo==1)
 check("upgrade migration is idempotent",WeaponActionResolver.migrate_upgrades(migrated)==migrated and old.has("lance_fan"))
 clear();p.finisher_charge=3;p.cooldowns=[2.0,7.0,.5];p.upgrades=old;game.save_run()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save();game.profile.run=disk.run;game.start_run(true);p=game.player
 check("disk restart restores gauge and cooldowns",p.finisher_charge==3 and p.cooldowns==[2.0,7.0,.5])
 check("disk restart migrates old skill choices",p.upgrades==migrated)
 var bad=game.run_snapshot();bad.finisher_charge=4.5
 check("invalid gauge is rejected",not game.profile.valid_run(bad))
 bad=game.run_snapshot();bad.skill_cooldowns=[0,"bad",0]
 check("invalid cooldowns are rejected",not game.profile.valid_run(bad))
 clear();p=game.player;p.cast(1);p.dead=true;WeaponActionResolver.tick(p,1)
 check("death cancels pending stages",p.skill_actions.is_empty() and game.projectiles.is_empty())
 check("out-of-range skill buttons are harmless",not p.cast(-1) and not p.cast(3))
 clear();p=game.player;equip(["fist","fist","fist"]);e=foe(Vector2(65,0));e.hp=1000000;e.max_hp=e.hp
 for i in range(150):p.attack_cd=0;p.attack()
 check("sustained combos beyond 99 retain bounded charge tracking",p.chain_streak==150 and p.finisher_charge==4 and p.normal_groups.size()<=4)
 clear();equip(["staff","staff","staff"]);e=foe(Vector2(160,0))
 for i in range(3):p.attack_cd=0;p.attack()
 p.dead=true
 for bolt in game.projectiles.duplicate():bolt.tick(.2)
 check("late projectiles cannot charge a dead player",p.finisher_charge==0)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="SKILL checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/skill_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures));print(summary)
 game.shutdown(0 if failures.is_empty() else 1)
