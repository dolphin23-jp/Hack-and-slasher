extends SceneTree
var game
var checks=0
var failures=[]

func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1
 print("PHASE4 ",("PASS " if ok else "FAIL ")+label)
 if not ok:failures.append(label)

func clear_combat()->void:
 for list in [game.enemies,game.projectiles,game.drops]:
  for node in list.duplicate():
   if is_instance_valid(node):node.queue_free()
  list.clear()
 game.hazards.clear();game.delayed_blasts.clear();game.victory_pending=false
 game.dungeon.active=-1;game.wave=0;game.wave_delay=0
 game.player.position=Vector2.ZERO;game.player.hp=game.player.stats.hp;game.player.dead=false
 game.player.invulnerable=0;game.player.dash_time=0;game.player.attack_cd=0

func foe(kind:String,p:Vector2=Vector2(180,0),room:int=1,tier:int=3):
 var e=game.spawn_enemy(kind,p,tier,room)
 e.state="approach";e.timer=0
 return e

func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://phase4-isolated.json";game.profile.run={};game.set_physics_process(false);game.start_run();await process_frame
 clear_combat()

 for kind in ["lancer","weaver","brute","champion","miniboss","forge_boss","thorn_boss"]:
  check("enemy data "+kind,game.enemy_data.has(kind))
 check("expanded bestiary contains phase4 kinds",["lancer","weaver","brute","champion","miniboss","forge_boss","thorn_boss"].all(func(k):return ChronicleDB.ENEMIES.has(k)))
 check("lancer prefers blunt",DamageModel.multiplier("lancer",["blunt"],{})>DamageModel.multiplier("lancer",["magic"],{}))
 check("weaver prefers slash",DamageModel.multiplier("weaver",["slash"],{})>DamageModel.multiplier("weaver",["magic"],{}))
 check("brute rewards pierce",DamageModel.multiplier("brute",["pierce"],{})>1.2)
 check("forge boss rewards magic over blunt",DamageModel.multiplier("forge_boss",["magic"],{})>DamageModel.multiplier("forge_boss",["blunt"],{}))
 check("thorn boss rewards slash",DamageModel.multiplier("thorn_boss",["slash"],{})>1.1)

 var e=foe("lancer")
 e.start_windup();e.timer=0;e.tick(.01)
 check("lancer converts telegraph into charge",e.state=="charge" and e.timer>.3)
 clear_combat();e=foe("weaver")
 e.start_windup()
 check("weaver marks current position and retreat line",game.hazards.size()==2)
 var projectile_before=game.projectiles.size();e.release_attack()
 check("weaver follows delayed floor control with projectile",game.projectiles.size()==projectile_before+1)
 clear_combat();e=foe("brute",Vector2(100,0))
 var hp_before=game.player.hp;e.release_attack()
 check("brute owns close space with radial slam",game.player.hp<hp_before and game.projectiles.size()==8)

 clear_combat();e=foe("elite",Vector2(150,0),3,3);e.affix="echoing";e.release_attack()
 check("new elite echoing affix adds followup projectiles",game.projectiles.size()>=12)
 clear_combat();e=foe("champion",Vector2(150,0),3,4);e.affix="frenzied";e.pattern=0;e.release_attack()
 check("champion has hybrid cone and projectile opener",e.pattern==1 and game.projectiles.size()>=3)
 e.pattern=2;e.release_attack()
 check("champion cycles into a charge pattern",e.state=="charge")

 clear_combat();e=foe("miniboss",Vector2(190,0),6,5);e.hp=e.max_hp*.49;e.tick(.01)
 check("mini boss has second phase",e.phase==2 and e.state=="transform")
 hp_before=e.hp;e.take_damage(100,Vector2.ZERO)
 check("mini boss transform cannot be burst through",is_equal_approx(e.hp,hp_before))
 e.tick(1.6);e.pattern=2;e.start_windup();e.release_attack()
 check("mini boss phase2 charge chains once",e.state=="charge" and e.charge_chain==1)

 clear_combat();e=foe("forge_boss",Vector2(200,0),4,4);e.pattern=1;e.start_windup()
 check("forge boss telegraphs a five-cell furnace wall",game.hazards.size()==5)
 e.pattern=2;projectile_before=game.projectiles.size();e.release_attack()
 check("forge boss fires readable five-shot fan",game.projectiles.size()==projectile_before+5)
 e.hp=e.max_hp*.57;e.state="approach";e.tick(.01)
 check("forge boss phase changes before half health",e.phase==2 and e.state=="transform")
 e.tick(1.7);e.state="recover";hp_before=e.hp;e.take_damage(100,Vector2.ZERO)
 check("forge boss recovery is a real damage window",is_equal_approx(hp_before-e.hp,130.0))

 clear_combat();e=foe("thorn_boss",Vector2(210,0),8,6);e.pattern=0;e.start_windup();projectile_before=game.projectiles.size();e.release_attack()
 check("thorn boss ring leaves a safe angular gap",game.projectiles.size()>10 and game.projectiles.size()<20)
 for p in game.projectiles.duplicate():p.remove()
 e.pattern=2;e.release_attack()
 check("thorn boss summons mixed pressure units",game.enemies.any(func(v):return v!=e and v.spawned_minion and v.kind=="hound") and game.enemies.any(func(v):return v!=e and v.spawned_minion and v.kind=="weaver"))

 clear_combat()
 for spec in [[3,"champion"],[4,"forge_boss"],[6,"miniboss"],[8,"thorn_boss"],[11,"champion"]]:
  var room=int(spec[0]);game.dungeon.active=room;game.wave=int(game.dungeon.rooms[room].waves)-1
  game.spawn_wave()
  check("final wave special "+str(room),game.enemies.size()==1 and game.enemies[0].kind==String(spec[1]))
  clear_combat()
 game.dungeon.active=5;game.wave=int(game.dungeon.rooms[5].waves)-1;game.spawn_wave()
 check("main route retains a normal Elite tier",game.enemies.any(func(v):return v.kind=="elite"))
 clear_combat()

 game.dungeon.active=4;game.wave=game.dungeon.rooms[4].waves
 e=foe("forge_boss",Vector2(180,0),4,4);e.hp=1;e.take_damage(9999,Vector2.ZERO)
 check("forge boss guarantees mace legendary",game.drops.any(func(d):return d.kind=="item" and d.item.get("effect","")=="weapon_mace"))
 check("mid boss death does not trigger final victory",not game.victory_pending)

 clear_combat();game.dungeon.active=8;game.wave=game.dungeon.rooms[8].waves
 e=foe("thorn_boss",Vector2(180,0),8,6);e.hp=1;e.take_damage(9999,Vector2.ZERO)
 check("thorn boss guarantees scythe legendary",game.drops.any(func(d):return d.kind=="item" and d.item.get("effect","")=="weapon_scythe"))

 clear_combat();game.dungeon.active=9
 e=foe("boss",Vector2(180,0),9,7);e.hp=1;e.take_damage(999999,Vector2.ZERO)
 check("final king still owns victory transition",game.victory_pending)
 check("final king still drops four boss rewards",game.drops.filter(func(d):return d.kind=="item" and d.item.get("boss_reward",false)).size()==4)

 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="PHASE4 checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/phase4_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures))
 print(summary.strip_edges())
 game.shutdown(0 if failures.is_empty() else 1)
