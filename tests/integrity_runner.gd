extends SceneTree
# Effect integrity and review-fix regressions: every advertised effect id has live
# behavior, legendary relics work from equipment, and audio/save/boss/UI fixes hold.
var game
var checks=0
var failures=[]
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1;print("INTEGRITY ","PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func clear()->void:
 for list in [game.enemies,game.projectiles,game.drops]:
  for node in list.duplicate():node.queue_free()
  list.clear()
 game.hazards.clear();game.delayed_blasts.clear();game.pending_upgrades=0;game.mode="play";game.elapsed=0
 var p=game.player
 p.skill_actions.clear();p.finisher_charge=0;p.reset_chain();p.combo=0;p.attack_cd=0;p.dash_time=0;p.dash_cd=0;p.dead=false;p.cooldowns=[0.0,0.0,0.0]
 p.upgrades={};p.active_oaths=[];p.oath_board=OathBoard.empty();p.equipment=ItemDB.initial_items();p.barrier=0;p.barrier_time=0;p.counter_time=0
 p.rebuild_stats();p.hp=p.stats.hp;p.position=Vector2.ZERO;p.facing=Vector2.RIGHT;p.stats.crit=0
func weapons(kinds:Array)->void:
 for i in range(3):game.player.equipment[Loadout.WEAPONS[i]].weapon_type=kinds[i]
 game.player.rebuild_stats();game.player.stats.crit=0
func oath(path:String,nodes:Array)->void:
 var p=game.player
 p.oath_board=OathBoard.sanitize({"active":[path],"nodes":nodes});p.active_oaths=[path];p.rebuild_stats();p.stats.crit=0
func foe(pos:Vector2,kind:String="hollow"):
 var e=game.spawn_enemy(kind,pos,1,0);e.state="approach";e.hp=100000;e.max_hp=100000;return e
func legend(effect:String,rarity:int=3)->Dictionary:
 for i in range(ItemDB.LEGENDS.size()):
  if ItemDB.LEGENDS[i].effect==effect:
   var rng=RandomNumberGenerator.new();rng.seed=7+i
   return ItemDB.generate(rng,5,rarity,i)
 return {}
# Performs one unlinked and one linked strike; returns the linked strike's state.
func linked_strike()->Dictionary:
 var p=game.player
 p.attack_cd=0;p.attack();p.attack_cd=0
 var before=game.projectiles.size();p.attack()
 return {"cd":p.attack_cd,"bolt":game.projectiles[before] if game.projectiles.size()>before else null}
func write_text(path:String,text:String)->void:
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func source_text()->String:
 var out=""
 for dir in ["res://actors","res://systems","res://scripts","res://world","res://ui","res://data"]:
  for file in DirAccess.get_files_at(dir):
   if file.ends_with(".gd"):out+=FileAccess.get_file_as_string(dir+"/"+file)
 return out
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
 game.profile.path="user://integrity-isolated.json";game.profile.run={};game.profile.oaths=OathBoard.empty();game.start_run();await process_frame
 clear();var p=game.player

 # --- Every advertised effect and unique id has a gameplay handler ---
 var code=source_text()
 var missing=[]
 for path in OathBoard.TREES:
  for node in OathBoard.TREES[path]:
   for effect in node.get("effects",[]):
    if not code.contains("has_effect(\""+String(effect)+"\")"):missing.append(effect)
 for path in OathBoard.PATHS:
  for effect in OathBoard.PATHS[path].effects:
   if not code.contains("has_effect(\""+String(effect)+"\")"):missing.append(effect)
 for entry in ItemDB.LEGENDS:
  if not ItemDB.effect_text({"effect":entry.effect}).is_empty() and not code.contains("has_effect(\""+String(entry.effect)+"\")"):missing.append(entry.effect)
 check("every oath and relic effect id has a has_effect handler "+str(missing),missing.is_empty())
 var unhandled=[]
 for id in ItemDB.UNIQUE+ItemDB.ARMOR_UNIQUE_TEXT.keys():
  var handled=code.contains("==\""+String(id)+"\"") or code.contains("has_unique(\""+String(id)+"\")")
  if not handled:unhandled.append(id)
 check("every unique id has a gameplay handler "+str(unhandled),unhandled.is_empty())

 # --- Oath node effects (primary path only) ---
 clear();weapons(["sword","sword","sword"]);foe(Vector2(60,0))
 oath("dance",["dance_tempo","dance_edge","dance_flow"]);var base_cd=linked_strike().cd
 clear();weapons(["sword","sword","sword"]);foe(Vector2(60,0))
 oath("dance",["dance_tempo","dance_edge","dance_flow","dance_flow2"]);var flow_cd=linked_strike().cd
 check("無拍子 speeds linked strikes by 12%",is_equal_approx(base_cd/flow_cd,1.12))
 p.attack_cd=0;p.combo_expire=0;p.attack();var unlinked_cd=p.attack_cd
 check("無拍子 leaves the unlinked opener unchanged",is_equal_approx(unlinked_cd,base_cd))

 clear();weapons(["sword","sword","sword"]);oath("dance",["dance_tempo","dance_edge","dance_impact"]);var e=foe(Vector2(60,0))
 p.attack_cd=0;p.attack();e.velocity=Vector2.ZERO;e.stagger_guard=0;p.attack_cd=0;p.attack();var base_push=e.velocity.length()
 clear();weapons(["sword","sword","sword"]);oath("dance",["dance_tempo","dance_edge","dance_impact","dance_impact2"]);e=foe(Vector2(60,0))
 p.attack_cd=0;p.attack();e.velocity=Vector2.ZERO;e.stagger_guard=0;p.attack_cd=0;p.attack();var impact_push=e.velocity.length()
 check("破拍子 adds 30% knockback to linked strikes",base_push>0 and is_equal_approx(impact_push/base_push,1.3))

 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce"]);foe(Vector2(300,0))
 var plain=linked_strike().bolt
 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2"]);foe(Vector2(300,0))
 var piercing=linked_strike().bolt
 check("無窮穿ち adds two pierces to magic bolts",plain!=null and piercing!=null and piercing.pierce==plain.pierce+2)
 check("magic bolts do not return without 帰還律",not plain.can_return)
 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2"]);game.player.cast(0)
 check("無窮穿ち also extends the staff art bolt",game.projectiles.size()>=1 and game.projectiles[0].pierce==14)

 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_echo","arcane_echo2"]);foe(Vector2(900,0))
 var echo_bolt=linked_strike().bolt;var echo_damage=echo_bolt.damage
 echo_bolt.life=.01;echo_bolt.tick(.02)
 check("帰還律 returns normal magic bolts once at 60%",echo_bolt.returning and echo_bolt.velocity.x<0 and is_equal_approx(echo_bolt.damage,echo_damage*.6))
 clear();weapons(["sword","sword","sword"]);oath("arcane",["arcane_focus","arcane_thread","arcane_echo","arcane_echo2"]);foe(Vector2(60,0))
 check("帰還律 does not create projectiles for melee weapons",linked_strike().bolt==null)

 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2"]);foe(Vector2(300,0))
 var cap_base=linked_strike().bolt.damage
 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2","arcane_cap"]);foe(Vector2(300,0))
 var cap_bolt=linked_strike().bolt.damage
 check("星界回路 adds 20% to linked magic strikes",is_equal_approx(cap_bolt/cap_base,1.2))
 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2"]);game.player.cast(1)
 var chain_base=game.projectiles[0].damage
 clear();weapons(["staff","staff","staff"]);oath("arcane",["arcane_focus","arcane_thread","arcane_pierce","arcane_pierce2","arcane_cap"]);game.player.cast(1)
 check("星界回路 adds 20% to magic chain-skill stages",is_equal_approx(game.projectiles[0].damage/chain_base,1.2))

 clear();oath("fortress",["fortress_wall","fortress_aegis","fortress_sustain"]);p.barrier=0;p.tick(.5);var regen_base=p.barrier
 clear();oath("fortress",["fortress_wall","fortress_aegis","fortress_sustain","fortress_sustain2"]);p.barrier=0;p.tick(.5);var regen_sustain=p.barrier
 check("恒久障壁 raises barrier regeneration by 60%",regen_base>0 and is_equal_approx(regen_sustain/regen_base,1.6))
 clear();p.oath_board=OathBoard.sanitize({"active":["dance","fortress"],"nodes":["fortress_wall","fortress_aegis","fortress_sustain","fortress_sustain2"]});p.active_oaths=["dance","fortress"]
 check("node effects stay primary-path only",not p.has_effect("shield_sustain"))

 # --- Legendary relic effects from equipment ---
 for effect in ["fire_dash","crit_blast","storm_guard","phoenix","conductor","ember_nova","chain","ash_edge"]:
  clear();var relic=legend(effect);p.equipment[relic.slot]=relic;p.rebuild_stats()
  check("equipped relic grants "+effect+" without an oath",p.has_effect(effect) and not ItemDB.effect_text(relic).is_empty())
 clear()
 check("unequipped relics grant nothing",not p.has_effect("fire_dash") and not p.has_effect("chain"))
 clear();var cinder=legend("fire_dash");p.equipment.armor=cinder;p.rebuild_stats();p.controlled_by_test=true;p.dash();p.tick(.02)
 check("equipped シンダーウェイク leaves a real fire trail",game.hazards.any(func(h):return h.friendly))
 clear();var pyre=legend("crit_blast");p.equipment.accessory=pyre;p.rebuild_stats();var near=foe(Vector2(90,0));var hp_before=near.hp
 game.critical_effect(Vector2(60,0))
 check("equipped ハート・オブ・パイア explodes on critical hits",near.hp<hp_before)
 clear();var storm_cloak=legend("storm_guard");p.equipment.armor=storm_cloak;p.rebuild_stats();near=foe(Vector2(120,0));hp_before=near.hp
 p.dash_time=.1;p.invulnerable=.2;p.take_damage(10)
 check("equipped 雷を抱く外套 strikes on a perfect evade",near.hp<hp_before)
 clear();p.equipment.armor=legend("fire_dash");p.equipment.accessory=legend("crit_blast");p.rebuild_stats()
 check("two cinder relics activate the cinder set without the flame oath",p.synergy("cinder") and not p.synergy("storm"))
 clear();p.equipment.armor=legend("fire_dash");p.rebuild_stats()
 check("one relic does not complete a two-piece set",not p.synergy("cinder"))
 clear();p.active_oaths=["storm"]
 check("oath-granted synergy still works",p.synergy("storm"))

 # chain_aegis: non-weapon legendaries grant barrier on each completed three-chain.
 clear();weapons(["sword","sword","sword"]);var aegis=legend("fire_dash");p.equipment.armor=aegis;p.rebuild_stats();p.stats.crit=0;foe(Vector2(60,0))
 check("non-weapon relic carries the chain_aegis unique",aegis.unique=="chain_aegis")
 for i in range(3):p.attack_cd=0;p.attack()
 check("chain_aegis grants barrier on a completed chain",is_equal_approx(p.barrier,4.0) and p.barrier_time>0)
 for i in range(60):p.attack_cd=0;p.attack()
 check("chain_aegis barrier stays capped",p.barrier<=maxf(25,p.stats.shield_max)+.001)
 p.barrier=80;p.attack_cd=0;p.attack();p.attack_cd=0;p.attack();p.attack_cd=0;p.attack()
 check("chain_aegis never cuts a larger barrier",p.barrier>=80)
 clear();var mythic_aegis=legend("storm_guard",4);p.equipment.armor=mythic_aegis;weapons(["sword","sword","sword"]);foe(Vector2(60,0))
 for i in range(3):p.attack_cd=0;p.attack()
 check("mythic chain_aegis grants a larger barrier",is_equal_approx(p.barrier,8.0))

 # chain_guard (巡る守護の魔刃) barrier is bounded like every other barrier source.
 clear();var guard_blade=legend("weapon_spellblade");p.equipment.weapon3=guard_blade;p.rebuild_stats();p.stats.crit=0;foe(Vector2(60,0))
 for i in range(3):p.attack_cd=0;p.attack()
 check("chain_guard grants barrier on the third strike",guard_blade.unique=="chain_guard" and is_equal_approx(p.barrier,12.0))
 for i in range(120):p.attack_cd=0;p.attack();p.tick(0.0)
 check("chain_guard barrier is capped under sustained attacks",p.barrier<=maxf(36,p.stats.shield_max)+.001 and p.barrier>=36-.001)
 # Relic text is visible in details, journal and comparison tokens.
 var tokens=EquipmentCompare.ability_tokens(legend("phoenix"))
 check("comparison lists the relic effect",tokens.any(func(t):return String(t).begins_with("聖遺物: ")))
 check("chain-rule legendaries do not duplicate unique text as relic text",ItemDB.effect_text(legend("chain_hands")).is_empty() and ItemDB.effect_text(legend("weapon_scythe")).is_empty())

 # --- BGM loops over the whole track, not the first ~20% (QOA data size != frames) ---
 var rate=AudioServer.get_mix_rate()
 for key in ["menu","dungeon","elite_music","boss_music","boss_awakened","victory_music"]:
  game.sound.set_music(key);var stream:AudioStreamWAV=game.sound.music.stream;var length=stream.get_length()
  var playback=stream.instantiate_playback();playback.start(0.0)
  playback.mix_audio(1.0,int(rate*(length-1.0)))
  var near_end=playback.get_playback_position()
  playback.mix_audio(1.0,int(rate*1.5))
  var wrapped=playback.get_playback_position()
  check("BGM %s plays to its end before looping"%key,stream.loop_end==int(round(length*stream.mix_rate)) and absf(near_end-(length-1.0))<.1 and absf(wrapped-.5)<.1)
 game.sound.set_music("dungeon")

 # --- Unreadable or newer saves are preserved instead of silently replaced ---
 var save_dir="user://integrity-saves"
 DirAccess.make_dir_recursive_absolute(save_dir)
 for file in DirAccess.get_files_at(save_dir):DirAccess.remove_absolute(ProjectSettings.globalize_path(save_dir+"/"+file))
 var corrupt_path=save_dir+"/corrupt.json";var corrupt_text="{\"version\":2,\"records\":{\"wins\":7},"
 write_text(corrupt_path,corrupt_text)
 var store=ProfileStore.new();store.path=corrupt_path;store.read_save()
 check("corrupt save shows a recovery notice",not store.recovery_notice.is_empty() and not store.write_blocked)
 check("corrupt save is copied to a recovery backup",FileAccess.get_file_as_string(corrupt_path+".recovery.bak")==corrupt_text)
 check("play can continue and save after a corrupt file",store.write_save() and FileAccess.get_file_as_string(corrupt_path+".recovery.bak")==corrupt_text)
 write_text(corrupt_path,"not json at all")
 var again=ProfileStore.new();again.path=corrupt_path;again.read_save()
 var backups=Array(DirAccess.get_files_at(save_dir)).filter(func(f):return String(f).begins_with("corrupt.json.recovery"))
 check("a second corruption never overwrites the first backup",backups.size()==2 and FileAccess.get_file_as_string(corrupt_path+".recovery.bak")==corrupt_text)
 var future_path=save_dir+"/future.json";var future_text="{\"version\":3,\"records\":{\"wins\":7},\"run\":{}}"
 write_text(future_path,future_text)
 var future=ProfileStore.new();future.path=future_path;future.read_save()
 check("newer save version blocks writes",future.write_blocked and not future.write_save() and FileAccess.get_file_as_string(future_path)==future_text)
 check("newer save version is also backed up",FileAccess.get_file_as_string(future_path+".recovery.bak")==future_text and not future.recovery_notice.is_empty())
 var healthy=ProfileStore.new();healthy.path=save_dir+"/healthy.json";healthy.records.wins=3;healthy.write_save()
 var reread=ProfileStore.new();reread.path=healthy.path;reread.read_save()
 check("valid saves load without notice or backup",reread.records.wins==3 and reread.recovery_notice.is_empty() and not FileAccess.file_exists(healthy.path+".recovery.bak"))

 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="INTEGRITY checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/integrity_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures));print(summary)
 game.shutdown(0 if failures.is_empty() else 1)
