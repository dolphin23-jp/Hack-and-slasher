extends Node
# Behavioral coverage of the expansion: real actors, projectiles and JSON files.
var game
var checks=0
var failures=[]
func _ready()->void:call_deferred("run")
func expect(label:String,ok:bool)->void:
 checks+=1
 if not ok:failures.append(label);printerr("EXPANSION FAIL ",label)
 else:print("EXPANSION PASS ",label)
func clear_combat()->void:
 for list in [game.enemies,game.projectiles,game.drops]:
  for actor in list.duplicate():
   if is_instance_valid(actor):actor.queue_free()
  list.clear()
 game.hazards.clear();game.delayed_blasts.clear();game.pending_upgrades=0
 game.dungeon.active=-1;game.mode="play";game.player.position=Vector2.ZERO
 game.player.active_oaths=["dance"];game.player.equipment=ItemDB.initial_items();game.player.upgrades={};game.player.rebuild_stats()
 game.player.hp=game.player.stats.hp;game.player.dead=false;game.player.invulnerable=0;game.player.dash_time=0;game.player.dash_cd=0
 game.player.attack_cd=0;game.player.combo=0;game.player.cooldowns=[0.0,0.0,0.0];game.player.counter_time=0;game.player.echo_ready=false
func enemy(kind:String="hollow",p:Vector2=Vector2(90,0)):
 var e=game.spawn_enemy(kind,p,1,0);e.state="approach";e.timer=1;e.hp=10000;e.max_hp=10000;return e
func equip_legend(i:int)->void:
 var item=ItemDB.generate(game.rng,1,3,i);game.player.equipment[item.slot]=item;game.player.rebuild_stats()
func run()->void:
 game.set_physics_process(false);game.profile.run={};game.profile.chronicle=ChronicleDB.empty();game.start_run()
 game.player.controlled_by_test=true
 clear_combat()
 game.player.active_oaths=[]
 var e=enemy();game.player.facing=Vector2.RIGHT;game.player.stats.crit=0
 var first_hp=e.hp;game.player.attack();var first=first_hp-e.hp
 game.player.attack_cd=0;game.player.attack();game.player.attack_cd=0
 var third_hp=e.hp;game.player.attack()
 expect("third chain slot switches from melee to a real staff projectile",first>0 and third_hp==e.hp and not game.projectiles.is_empty() and game.projectiles.any(func(b):return b.damage_types==["magic"]))
 expect("light enemies visibly stagger",e.stagger_time>0 and e.velocity.length()>0)
 game.player.dash_cd=0
 expect("dash cancels swing recovery",game.player.dash() and game.player.attack_time==0 and game.player.attack_cd<=.12)
 var hp=game.player.hp
 expect("dash avoids a real incoming hit",not game.player.take_damage(30) and game.player.hp==hp and game.player.counter_time>0)
 var evades=game.metrics.perfect_evades;game.player.take_damage(30)
 expect("one reward per dodge",game.metrics.perfect_evades==evades)
 game.player.dash_time=0;game.player.attack_cd=0;game.player.attack()
 expect("counter consumed by next attack",game.player.counter_time==0)
 clear_combat();e=enemy("warden");e.aim=Vector2.LEFT
 hp=e.hp;e.take_damage(100,Vector2.RIGHT*175)
 expect("shield blocks frontal light attacks",is_equal_approx(hp-e.hp,25))
 hp=e.hp;e.take_damage(100,Vector2.LEFT*175)
 expect("flanking bypasses shield",is_equal_approx(hp-e.hp,100))
 hp=e.hp;e.take_damage(100,Vector2.RIGHT*370)
 expect("finisher breaks guard and opens recovery",is_equal_approx(hp-e.hp,100) and e.shield_break>0 and e.state=="recover")
 clear_combat();e=enemy("summoner");e.start_windup();e.take_damage(1,Vector2.RIGHT*200)
 expect("summoning chant can be interrupted",e.state=="recover")
 e.release_attack();var total=game.enemies.size()
 expect("summoner creates two marked minions",total==3 and game.enemies[1].spawned_minion)
 e.release_attack();e.release_attack()
 expect("summoner limits living minions",game.enemies.size()==5)
 var xp=game.player.xp;var drops=game.drops.size();game.enemies[1].state="approach";game.enemies[1].take_damage(99999,Vector2.ZERO)
 expect("summons cannot farm loot or XP",game.player.xp==xp and game.drops.size()==drops)
 clear_combat();game.player.level=2;game.pending_upgrades=1;game.prepare_upgrade()
 expect("first level offers three distinct lance paths",game.upgrade_choices.size()==3 and game.upgrade_choices[0].key=="lance_fan" and game.upgrade_choices[2].key=="lance_blast")
 game.choose_upgrade(0);game.choose_upgrade(1)
 expect("one irreversible branch per choice",game.player.upgrades.has("lance_fan") and not game.player.upgrades.has("lance_giant"))
 game.player.cast(2)
 expect("fan path changes projectile count",game.projectiles.size()==3)
 clear_combat();game.player.upgrades.lance_giant=1;game.player.cast(2)
 expect("giant path changes collision and damage",game.projectiles.size()==1 and game.projectiles[0].radius==24 and game.projectiles[0].damage>game.player.stats.attack*5)
 clear_combat();game.player.upgrades.lance_blast=1;e=enemy("hollow",Vector2(70,0));var neighbor=enemy("hollow",Vector2(120,65));hp=neighbor.hp
 game.player.cast(2);game.projectiles[0].tick(.06)
 expect("blast damages neighboring enemies",neighbor.hp<hp and game.projectiles.is_empty())
 clear_combat();equip_legend(4);game.player.upgrades.lance_giant=1;game.player.cast(2)
 expect("legendary side lances stack with giant branch",game.projectiles.size()==3 and game.projectiles[0].radius==24)
 clear_combat();equip_legend(13);game.player.cast(2);var bolt=game.projectiles[0];var original_damage=bolt.damage;bolt.life=.01;bolt.tick(.02)
 expect("return lance reverses once with reduced damage",bolt.returning and bolt.velocity.x<0 and is_equal_approx(bolt.damage,original_damage*.6))
 bolt.life=.01;bolt.tick(.02)
 expect("return lance expires instead of looping",bolt.dead)
 clear_combat();game.player.active_oaths=["flame"];equip_legend(6);equip_legend(1);game.player.equipment.weapon.weapon_type="sword";game.player.stats.crit=0;e=enemy();game.player.attack()
 expect("ash blade applies burn and cinder set activates",e.burn_time>0 and game.player.synergy("cinder"))
 hp=e.hp;e.take_damage(100,Vector2.ZERO)
 expect("cinder synergy changes actual damage",is_equal_approx(hp-e.hp,130))
 clear_combat();game.player.active_oaths=["storm"];equip_legend(0);equip_legend(7);e=enemy();neighbor=enemy("hollow",Vector2(170,30));hp=neighbor.hp;game.player.cast(2);game.projectiles[0].tick(.07)
 expect("storm pair adds lightning to lance impact",neighbor.hp<hp)
 clear_combat();equip_legend(5);equip_legend(8);game.player.cast(1);e=enemy();game.player.combo=2;game.player.attack()
 expect("echo pair stores then releases a finisher repeat",not game.player.echo_ready and game.delayed_blasts.size()==1)
 expect("echo armor grants a timed barrier",game.player.barrier>0 and game.player.barrier_time>0)
 hp=e.hp;game.tick_delayed_blasts(.3)
 expect("delayed echo causes real damage",e.hp<hp and game.delayed_blasts.is_empty())
 clear_combat();equip_legend(11);game.player.cast(0)
 expect("double bell leaves a delayed judgement",game.delayed_blasts.size()==1)
 clear_combat();game.player.active_oaths=["flame"];equip_legend(12);game.player.cast(1)
 expect("ember armor changes nova into a fire field",game.hazards.size()==1 and game.hazards[0].friendly)
 clear_combat();game.player.active_oaths=["flame"];equip_legend(9);game.player.hp*=.5;game.player.potions=3;e=enemy();hp=e.hp;game.player.drink()
 expect("phoenix flask damages and ignites enemies",e.hp<hp and e.burn_time>0)
 clear_combat();equip_legend(14);e=enemy();game.player.controlled_by_test=true;game.player.dash();game.player.tick(.20)
 expect("dash nova creates an endpoint impact",game.player.dash_nova_cd>0)
 clear_combat();game.player.active_oaths=["storm"];equip_legend(10);e=enemy("hollow",Vector2(260,0));hp=e.hp;game.player.cast(1)
 expect("conductor reaches beyond nova radius",e.hp<hp)
 clear_combat();equip_legend(15);game.player.equipment.weapon.weapon_type="sword";game.player.equipment.weapon3=game.player.equipment.weapon.duplicate(true);game.player.stats.crit=0;e=enemy();e.hp=2000;game.player.combo=2;hp=e.hp;game.player.attack()
 expect("execution blade rewards low-health finishers",hp-e.hp>game.player.stats.attack*2.7)
 clear_combat();e=enemy("boss",Vector2(180,0));e.hp=e.max_hp*.49;e.tick(.01)
 expect("boss transforms at half health",e.phase==2 and e.state=="transform" and game.sound.music_name=="boss_awakened")
 hp=e.hp;e.take_damage(100,Vector2.ZERO)
 expect("transformation is protected and readable",e.hp==hp)
 e.tick(1.7);e.pattern=3;e.start_windup();e.release_attack()
 expect("awakened boss starts a chained charge",e.state=="charge" and e.charge_chain==1)
 e.timer=0;e.tick(.01)
 expect("second charge has a fresh warning",e.state=="chain_windup" and e.timer>=.69)
 e.state="recover";e.timer=2;hp=e.hp;e.take_damage(100,Vector2.ZERO)
 expect("boss recovery grants a damage opportunity",is_equal_approx(hp-e.hp,135))
 clear_combat();var shape=game.dungeon.obstacles.duplicate();var seed=game.run_seed;game.save_run()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save();game.profile.run=disk.run;game.start_run(true)
 expect("seeded geometry survives a disk reload",game.run_seed==seed and game.dungeon.obstacles==shape)
 var legacy=game.profile.run.duplicate(true);legacy.erase("world_version");legacy.erase("event_choices");legacy.erase("loot_favor");game.profile.run=legacy;game.start_run(true)
 expect("legacy saves retain their ten-room geometry",game.dungeon.layout_version==1 and game.dungeon.rooms.size()==10)
 game.start_run();clear_combat();game.event_room=10;game.mode="event";game.player.hp=2;game.choose_contract("blood")
 expect("blood contract cannot kill an unready player",game.mode=="event" and game.event_choices.is_empty())
 game.player.hp=game.player.stats.hp;hp=game.player.hp;game.choose_contract("blood")
 expect("blood contract pays exactly one cost",game.mode=="play" and is_equal_approx(game.player.hp,hp*.75))
 game.save_run();disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save();game.profile.run=disk.run;game.start_run(true)
 expect("paid contract is preserved through disk restart",game.event_choices.get("10")=="blood")
 game.player.position=game.dungeon.rooms[10].center;game.check_rooms(.01)
 expect("returning to paid room starts combat without paying again",game.mode=="play" and game.dungeon.active==10)
 game.clear_encounter()
 expect("contract clear awards legendary and permanent option",game.profile.chronicle.contracts==1 and "risk" in game.profile.chronicle.achievements and game.drops.any(func(d):return d.kind=="item" and d.item.rarity==3))
 game.event_room=11;game.mode="event";var weapon_id=game.player.equipment.weapon.id;game.choose_contract("wager")
 expect("wager replaces equipped weapon",game.player.equipment.weapon.id!=weapon_id and game.player.equipment.weapon.id=="contract-loan")
 game.clear_encounter()
 expect("wager rewards a legendary weapon",game.drops.any(func(d):return d.kind=="item" and d.item.rarity==3 and d.item.slot=="weapon"))
 game.start_run();clear_combat();game.event_room=10;game.mode="event";game.choose_contract("danger");e=enemy()
 expect("danger pact strengthens enemies and improves loot",e.damage>e.spec.damage*1.19 and game.loot_favor==.15)
 for i in range(6):game.record_item(ItemDB.generate(game.rng,1,3,i))
 game.save_run();disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 expect("discovery and option unlocks persist",disk.chronicle.legends.size()>=6 and "collector" in disk.chronicle.achievements)
 var broken=game.profile.run.duplicate(true);broken.event_choices={"10":"free_legendary"}
 expect("malformed new fields reject the save",not game.profile.valid_run(broken))
 game.ui.reset_touch();game.player.touch_attack=true;game.player.touch_move=Vector2.ONE;game.ui.reset_touch()
 expect("touch reset releases movement and held attack",not game.player.touch_attack and game.player.touch_move==Vector2.ZERO)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-artifacts"))
 var summary="EXPANSION checks=%d failures=%d\n"%[checks,failures.size()]
 for failure in failures:summary+="FAIL: "+failure+"\n"
 var file=FileAccess.open("res://test-artifacts/expansion_summary.txt",FileAccess.WRITE);file.store_string(summary);file.close();print(summary)
 game.shutdown(0 if failures.is_empty() else 1)
