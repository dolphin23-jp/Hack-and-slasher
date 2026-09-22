extends SceneTree
var game
var count=0
var failures=[]
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 count+=1
 print("V03 ","PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func foe(pos:Vector2,kind:String="hollow"):
 var e=game.spawn_enemy(kind,pos,1,0);e.state="approach";e.hp=10000;e.max_hp=10000;return e
func clear()->void:
 for list in [game.enemies,game.projectiles,game.drops]:
  for node in list.duplicate():node.queue_free()
  list.clear()
 game.hazards.clear();game.delayed_blasts.clear();game.pending_upgrades=0
 game.player.position=Vector2.ZERO;game.player.facing=Vector2.RIGHT;game.player.attack_cd=0;game.player.dash_time=0;game.player.combo=0;game.player.combo_expire=0;game.player.last_chain_weapon="";game.player.chain_streak=0;game.player.chain_history=[];game.player.active_oaths=[];game.player.stats.crit=0
func weapon(kind:String,slot:String="weapon")->Dictionary:
 var it=ItemDB.generate(game.rng,1,0);it.slot="weapon";it.weapon_type=kind;it.base={"attack":9.0};it.affixes={};game.player.equipment[slot]=it;return it
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://v03-isolated.json";game.profile.run={};game.profile.oaths=OathBoard.empty();game.set_physics_process(false);game.start_run();await process_frame
 clear();var p=game.player
 check("nine slots",p.equipment.size()==9)
 check("seven weapon families",WeaponDB.TYPES.size()==7)
 check("five rarities",ItemDB.RARITIES.size()==5)
 var order=[]
 for i in range(4):p.attack_cd=0;p.attack();order.append(p.combo)
 check("chain cycles 1 2 3 1",order==[1,2,3,1])
 p.combo=2;p.combo_expire=0;p.controlled_by_test=true;p.tick(.01)
 check("idle preserves next slot",p.combo==2)
 for slot in Loadout.WEAPONS:weapon("spear",slot)
 order=[]
 for i in range(4):p.attack_cd=0;p.attack();order.append(p.combo)
 check("three same families cycle",order==[3,1,2,3])
 for kind in WeaponDB.TYPES:
  clear();weapon(kind);p.rebuild_stats();p.stats.crit=0
  var front=foe(Vector2(75,0));var back=foe(Vector2(-80,0));var far=foe(Vector2(240,0))
  p.attack()
  for b in game.projectiles.duplicate():b.tick(.3)
  check("real contact "+kind,front.hp<10000 or (kind in ["staff","spellblade"] and far.hp<10000))
  if kind=="scythe":check("scythe hits behind",back.hp<10000)
  elif kind not in ["staff","spellblade"]:check("directional attack excludes behind "+kind,back.hp==10000)
  if kind=="spear":check("spear pierces distant target",far.hp<10000)
 check("blunt advantage",is_equal_approx(DamageModel.multiplier("warden",["blunt"],{}),1.25))
 check("slash disadvantage mild",is_equal_approx(DamageModel.multiplier("warden",["slash"],{}),.9))
 check("pierce advantage",DamageModel.multiplier("hound",["pierce"],{})>1)
 check("magic advantage",DamageModel.multiplier("cantor",["magic"],{})>1)
 p.dash_cd=0;check("dodge cancels any weapon",p.dash() and p.attack_time==0 and p.attack_cd<=.12)
 p.dash_time=0;p.attack_cd=0;check("attack resumes after dodge",p.attack())
 clear();var it=weapon("scythe");it.tier=3;p.rebuild_stats();p.stats.crit=0;var s1=foe(Vector2(70,0));var s2=foe(Vector2(-70,0));var s3=foe(Vector2(0,85));p.attack()
 var t3_scythe_damage=(10000-s1.hp)+(10000-s2.hp)+(10000-s3.hp)
 clear();it=weapon("scythe");it.tier=1;p.rebuild_stats();p.stats.crit=0;s1=foe(Vector2(70,0));s2=foe(Vector2(-70,0));s3=foe(Vector2(0,85));p.attack()
 var t1_scythe_damage=(10000-s1.hp)+(10000-s2.hp)+(10000-s3.hp)
 check("T3 scythe rewards crowd hits with bonus rotation",t3_scythe_damage>t1_scythe_damage*1.3)
 clear();it=weapon("scythe");it.tier=4;p.rebuild_stats();var e=foe(Vector2(90,0));p.attack()
 check("T4 scythe attracts",e.velocity.x<0)
 clear();it=weapon("staff");it.tier=4;p.rebuild_stats();p.attack()
 check("T4 staff gains a real wall bounce",not game.projectiles.is_empty() and game.projectiles[0].bounces==1)
 clear();it=weapon("scythe","weapon3");it.tier=5;p.rebuild_stats();p.stats.crit=0;p.combo=2;e=foe(Vector2(90,0));p.attack();var tier_damage=10000-e.hp
 clear();it.tier=1;p.stats.crit=0;p.combo=2;e=foe(Vector2(90,0));p.attack()
 check("T5 third slot adds a strike",tier_damage>(10000-e.hp)*1.8)
 clear();it=weapon("fist","weapon3");it.tier=5;p.rebuild_stats();p.combo=2;var rear=foe(Vector2(-90,0));p.attack()
 check("T5 fist finisher hits around the player",rear.hp<10000)
 var values=[]
 for r in range(5):
  var low=INF;var high=0.0
  for i in range(30):
   var item=ItemDB.generate(game.rng,1,r)
   check_roll(item)
   for key in item.base:low=minf(low,item.base[key]);high=maxf(high,item.base[key])
   values.append(item.base)
  check("rarity roll bounds "+str(r),low>0 and high>low)
 check("random roll diversity",values[0]!=values[1])
 var weighted_rng=RandomNumberGenerator.new();weighted_rng.seed=771;var spear_pierce=0;var spear_blunt=0;var head_crit=0;var head_material=0;var affix_keys=ItemDB.AFFIXES.keys()
 for i in range(2000):
  var wk=ItemDB.pick_affix(weighted_rng,affix_keys,"weapon","spear");spear_pierce+=1 if wk=="pierce" else 0;spear_blunt+=1 if wk=="blunt" else 0
  var hk=ItemDB.pick_affix(weighted_rng,affix_keys,"head","sword");head_crit+=1 if hk=="crit" else 0;head_material+=1 if hk=="material_find" else 0
 check("spear affixes strongly favor pierce over off-type blunt",spear_pierce>spear_blunt*8)
 check("head affixes favor combat identity over material find",head_crit>head_material*4)
 clear();it=weapon("sword");p.materials=100000;p.inventory=[]
 for i in range(10):Forge.apply(p,it,"enhance")
 check("enhance reaches +10",it.enhance==10)
 for grade in range(5):check("old max slightly exceeds next base "+str(grade),ItemDB.GRADES[grade]*1.3>ItemDB.GRADES[grade+1] and ItemDB.GRADES[grade]*1.3<ItemDB.GRADES[grade+1]*1.06)
 var donor=it.duplicate(true);donor.id="donor";donor.enhance=0;p.inventory.append(donor)
 Forge.apply(p,it,"fuse","",p.inventory[0].duplicate(true));check("fusion consumes compatible donor",p.inventory.is_empty() and it.fusion>0)
 Forge.apply(p,it,"tier");check("tier unlock consumes progress",it.tier==2 and it.fusion==0)
 it.affixes={"crit":.1,"hp":15.0};it.rolls.crit=[.08,.12];it.rolls.hp=[10.0,20.0];var grade_ratio=ItemDB.GRADES[1]/ItemDB.GRADES[0];Forge.apply(p,it,"evolve","crit")
 check("grade evolution resets enhancement",it.grade==2 and it.enhance==0)
 check("chosen affix inherited after grade remap",is_equal_approx(it.affixes.crit,.1*grade_ratio*1.08) and it.inherited=="crit")
 check("unchosen affix keeps roll percentile",is_equal_approx(it.affixes.hp,15.0*grade_ratio) and is_equal_approx(it.rolls.hp[0],10.0*grade_ratio) and is_equal_approx(it.rolls.hp[1],20.0*grade_ratio))
 var before=p.materials;donor.locked=true;p.inventory=[donor];game.salvage(0)
 check("lock protects salvage",p.inventory.size()==1 and p.materials==before)
 donor.locked=false;game.salvage(0)
 check("salvage grants materials",p.inventory.is_empty() and p.materials>before)
 clear();it=weapon("scythe");it.unique="double_spin";p.rebuild_stats();p.stats.crit=0;e=foe(Vector2(90,0));p.attack();var legendary_damage=10000-e.hp
 clear();it.unique="";p.stats.crit=0;e=foe(Vector2(90,0));p.attack()
 check("legendary double spin changes damage",legendary_damage>(10000-e.hp)*1.8)
 clear();it=weapon("staff");it.rarity=4;p.rebuild_stats();p.attack()
 check("mythic three real projectiles",game.projectiles.size()==3)
 clear();var repeat_glove=ItemDB.generate(game.rng,1,3,24);p.equipment.hands=repeat_glove;weapon("sword");p.rebuild_stats();p.stats.crit=1.0;e=foe(Vector2(75,0));p.attack()
 check("legendary gloves schedule one same-weapon repeat",p.repeat_next)
 p.attack_cd=0;var repeated_slot=p.combo;p.attack()
 check("repeat consumes without advancing the chain",p.combo==repeated_slot and not p.repeat_next)
 var interrupted_triune=CombatChain.transition_profile("sword","mace",["sword","sword","mace"],3,true)
 check("same-weapon repeat cannot fake a three-attribute finisher",not String(interrupted_triune.label).contains("三相"))
 clear();var skip_boots=ItemDB.generate(game.rng,1,3,25);p.equipment.feet=skip_boots;p.rebuild_stats();p.combo=0;p.dash_cd=0;p.dash()
 p.dash_time=0;p.attack_cd=0;p.attack()
 check("legendary boots skip one weapon after dodge",p.combo==2)
 var stale=CombatChain.transition_profile("sword","mace",["sword","mace","spear"],1,false)
 check("expired chain has no transition bonus",is_equal_approx(stale.damage,1.0) and is_equal_approx(stale.knock,1.0))
 var sunder=CombatChain.transition_profile("sword","mace",["sword","mace","spear"],2,true)
 check("slash to blunt creates armor-breaking transition",sunder.damage>1.0 and sunder.knock>1.0 and String(sunder.label).contains("断甲"))
 var breach=CombatChain.transition_profile("mace","spear",["sword","mace","spear"],2,true)
 check("blunt to pierce creates breach transition",breach.damage>1.1 and String(breach.label).contains("破砕"))
 var spell_edge=CombatChain.transition_profile("staff","sword",["staff","sword","mace"],2,true)
 check("magic to slash empowers reach and damage",spell_edge.damage>1.1 and spell_edge.reach>1.0)
 var harvest_cast=CombatChain.transition_profile("scythe","staff",["scythe","staff","mace"],2,true)
 check("scythe to staff creates focused cast",harvest_cast.damage>1.1 and harvest_cast.reach>1.1)
 var triune=CombatChain.transition_profile("mace","spear",["sword","mace","spear"],3,true)
 check("three distinct attributes earn triune finisher",triune.damage>1.3 and String(triune.label).contains("三相"))
 var same_finish=CombatChain.transition_profile("sword","sword",["sword","sword","sword"],3,true)
 check("three identical weapons earn family finisher",same_finish.damage>1.2 and String(same_finish.label).contains("同型"))
 for slot in Loadout.WEAPONS:weapon(["sword","mace","spear"][Loadout.WEAPONS.find(slot)],slot)
 var chain_choices=BuildDB.chain_choices(p.equipment,{})
 var choice_keys=chain_choices.map(func(c):return String(c.key))
 check("run blessings inspect the equipped three-weapon chain",choice_keys.has("transition_power") and choice_keys.has("triune_mastery") and choice_keys.has("master_sword"))
 var board=OathBoard.sanitize({"active":["dance","dance","storm","flame","seek"],"ranks":{},"points":4})
 check("main plus two unique secondary limit",board.active==["dance","storm","flame"])
 var fallback_board=OathBoard.sanitize({"active":[],"ranks":{},"points":0})
 check("oath board always keeps a primary oath",fallback_board.active==["dance"])
 var tree_board=OathBoard.sanitize({"active":["flame"],"ranks":{"flame":0},"points":30,"nodes":[]})
 check("oath tree root is initially available",OathBoard.node_available(tree_board,"flame","flame_ember"))
 var unlock_msg=OathBoard.unlock_node(tree_board,"flame","flame_ember")
 OathBoard.unlock_node(tree_board,"flame","flame_feed");OathBoard.unlock_node(tree_board,"flame","flame_long")
 check("oath nodes spend permanent points",unlock_msg.begins_with("解放") and tree_board.points==21)
 check("oath branch is mutually exclusive",not OathBoard.node_available(tree_board,"flame","flame_burst"))
 var legacy_tree=OathBoard.sanitize({"active":["storm"],"ranks":{"storm":3},"points":0})
 check("legacy oath ranks map into tree nodes",legacy_tree.nodes.has("storm_spark") and legacy_tree.nodes.has("storm_wire") and legacy_tree.nodes.has("storm_voltage"))
 p.active_oaths=["flame"];check("flame independent of equipment",p.has_effect("ash_edge") and p.has_effect("fire_dash"))
 p.active_oaths=["storm"];check("storm independent of equipment",p.has_effect("chain"))
 p.active_oaths=[];check("inactive elemental gear gives no elemental proc",not p.has_effect("chain"))
 var rare0=0;var rare1=0;var r0=RandomNumberGenerator.new();var r1=RandomNumberGenerator.new();r0.seed=88;r1.seed=88
 for i in range(10000):
  if ItemDB.roll_rarity(r0,0)>=3:rare0+=1
  if ItemDB.roll_rarity(r1,1)>=3:rare1+=1
 check("rarity find improves rarity independently",rare1>rare0*1.25)
 game.rng.seed=9137;var material_total=0
 for i in range(10000):material_total+=game.roll_material_yield(.3)
 check("fractional material find becomes probabilistic yield",material_total>12700 and material_total<13300)
 var legacy=game.run_snapshot();legacy.equipment={"weapon":legacy.equipment.weapon,"armor":legacy.equipment.armor,"accessory":legacy.equipment.accessory}
 for slot in legacy.equipment:
  for key in ["schema","weapon_type","grade","enhance","fusion","unique","rolls","locked","favorite","art_id","art_variant"]:legacy.equipment[slot].erase(key)
 var migrated=SaveMigration.migrate({"version":1,"run":legacy,"chronicle":{"legends":["chain","fire_dash"]}})
 check("legacy 3 slots become 9",migrated.run.equipment.size()==9)
 check("legacy IDs retained",migrated.run.equipment.weapon.id==legacy.equipment.weapon.id)
 check("legacy elemental achievements compensated",migrated.oaths.points==4)
 check("legacy run remains valid",game.profile.valid_run(migrated.run))
 check("migration idempotent",SaveMigration.migrate(migrated)==migrated)
 game.profile.oaths=board;p.active_oaths=board.active.duplicate();p.materials=765;p.combo=2;game.save_run()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 check("disk save restores board",disk.oaths==board)
 var vault_item=ItemDB.generate(game.rng,3,2);game.profile.vault=[vault_item];game.profile.write_save()
 var vault_disk=ProfileStore.new();vault_disk.path=game.profile.path;vault_disk.read_save()
 check("persistent vault survives disk reload",vault_disk.vault.size()==1 and vault_disk.vault[0].id==vault_item.id)
 check("disk save restores material and chain",disk.run.get("materials")==765 and disk.run.get("combo")==2)
 game.profile.run=disk.run;game.start_run(true)
 check("restart restores full equipment",game.player.equipment==disk.run.equipment)
 check("restart restores active build",game.player.active_oaths==board.active)
 var corrupt=disk.run.duplicate(true);corrupt.equipment.weapon.enhance="oops"
 check("malformed item rejected",not game.profile.valid_run(corrupt))
 corrupt=disk.run.duplicate(true);corrupt.active_oaths=["flame","flame"]
 check("duplicate active build rejected",not game.profile.valid_run(corrupt))
 var ids=[]
 for slot in Loadout.WEAPONS:ids.append(game.player.equipment[slot].id)
 Loadout.swap(game.player,0,1)
 check("touch reorder exchanges actual weapons",game.player.equipment.weapon.id==ids[1] and game.player.equipment.weapon2.id==ids[0])
 p=game.player
 p.equipment.weapon.base={"attack":30.0};p.equipment.weapon2.base={"attack":5.0};p.equipment.weapon3.base={"attack":8.0};p.rebuild_stats()
 var comparison=ItemDB.generate(game.rng,1,0);comparison.slot="weapon";comparison.weapon_type="sword";comparison.base={"attack":12.0};comparison.affixes={}
 check("weapon drop compares against best replacement slot",p.item_upgrade_target(comparison)=="weapon2")
 var compare_tags=p.item_comparison(comparison,"weapon2")
 check("item comparison exposes multidimensional signals",compare_tags.size()>0 and not compare_tags.any(func(v):return String(v).contains("%強い")))
 check("generated items expose stable art metadata",comparison.schema==4 and not String(comparison.art_id).is_empty() and String(comparison.art_variant)=="default")
 check("missing item art uses shared placeholder",ItemDB.art_path(comparison).ends_with("assets/icons/chest.svg") and not ItemDB.art_ready(comparison))
 var schema3_item=comparison.duplicate(true);schema3_item.schema=3;schema3_item.erase("art_id");schema3_item.erase("art_variant")
 var schema4_item=SaveMigration.item(schema3_item)
 check("schema 3 items migrate to art schema 4",schema4_item.schema==4 and not String(schema4_item.art_id).is_empty() and ItemDB.valid(schema4_item))
 p.equipment.weapon.weapon_type="sword";p.equipment.weapon2.weapon_type="mace";p.equipment.weapon3.weapon_type="spear";p.rebuild_stats()
 var chain_candidate=comparison.duplicate(true);chain_candidate.id="compare-staff";chain_candidate.weapon_type="staff";chain_candidate.art_id=ItemDB.default_art_id(chain_candidate)
 var compare_snapshot=EquipmentCompare.snapshot(p,chain_candidate,"weapon2")
 check("comparison snapshot exposes current after delta and contribution",not compare_snapshot.is_empty() and compare_snapshot.after_stats.attack>compare_snapshot.before_stats.attack and compare_snapshot.candidate_contribution.has("attack"))
 check("comparison snapshot exposes chain recipe gains or losses",compare_snapshot.before_order!=compare_snapshot.after_order and (not compare_snapshot.gained_build.is_empty() or not compare_snapshot.lost_build.is_empty()))
 check("comparison snapshot exposes tier and weapon-art ability changes",not EquipmentCompare.ability_tokens(chain_candidate).is_empty())
 var shield_plan=game.encounter_plan(game.dungeon.rooms[4],2,6)
 check("shield-line encounter has a real front line",shield_plan.size()==6 and shield_plan.slice(0,3).all(func(v):return v.kind in ["warden","brute","lancer"]) and shield_plan.slice(0,3).map(func(v):return String(v.kind)).has("warden"))
 check("shield-line encounter protects ranged backline",shield_plan.slice(3).any(func(v):return v.kind in ["cantor","summoner"]))
 var surround_plan=game.encounter_plan(game.dungeon.rooms[2],1,7)
 check("surround encounter forms a multi-angle problem",surround_plan.size()==7 and surround_plan[0].p!=surround_plan[1].p and surround_plan[1].p!=surround_plan[2].p)
 var v1_path="user://v03-legacy-fixture.json"
 var fixture=FileAccess.open(v1_path,FileAccess.WRITE)
 fixture.store_string(JSON.stringify({"version":1,"run":legacy,"chronicle":{"legends":["chain","fire_dash"]},"records":{"wins":7},"settings":{"touch":true}}));fixture.close()
 var old_disk=ProfileStore.new();old_disk.path=v1_path;old_disk.read_save()
 check("v1 disk migration retains run and records",not old_disk.run.is_empty() and old_disk.records.wins==7 and old_disk.settings.touch)
 check("v1 backup exists",FileAccess.file_exists(v1_path+".v1.bak"))
 old_disk.write_save();var second=ProfileStore.new();second.path=v1_path;second.read_save()
 check("migration reward cannot duplicate",second.oaths.points==4)
 p=game.player;p.hp=p.stats.hp;p.barrier=0;p.invulnerable=0;p.stats.armor=0;p.stats.fatal_resist=.25
 var hp=p.hp;p.take_damage(40,Vector2.ZERO,true)
 check("telegraphed fatal strike reduced",is_equal_approx(hp-p.hp,30))
 p.invulnerable=0;hp=p.hp;p.take_damage(40)
 check("ordinary attack never rolls enemy crit",is_equal_approx(hp-p.hp,40))
 var found_types=[]
 for index in range(16,ItemDB.LEGENDS.size()):
  var unique_item=ItemDB.generate(game.rng,1,3,index)
  if unique_item.weapon_type not in found_types:found_types.append(unique_item.weapon_type)
 check("all seven unique weapon behaviors are obtainable",found_types.size()==7)
 var legacy_build=legacy.duplicate(true);legacy_build.erase("active_oaths")
 legacy_build.equipment.weapon.effect="ash_edge";legacy_build.equipment.armor.effect="fire_dash"
 var old_build=SaveMigration.migrate({"version":1,"run":legacy_build})
 check("legacy current Run keeps elemental build",old_build.run.active_oaths[0]=="flame")
 var stat_item=ItemDB.initial_items().armor;stat_item.tier=4
 check("armor T4 grants functional fatal resistance",Loadout.equipped_stats(stat_item).get("fatal_resist",0)>0)
 var head_item=ItemDB.initial_items().head;head_item.tier=4;var head_stats=Loadout.equipped_stats(head_item)
 check("head tiers follow offensive utility path",head_stats.get("crit",0)>0 and head_stats.get("cdr",0)>0 and head_stats.get("fatal_resist",0)==0)
 var feet_item=ItemDB.initial_items().feet;feet_item.tier=4;var feet_stats=Loadout.equipped_stats(feet_item)
 check("feet tiers follow mobility path",feet_stats.get("speed",0)>0 and feet_stats.get("dodge_cdr",0)>0 and feet_stats.get("dodge_distance",0)>0)
 var drop_counts=[]
 for bonus in [0.0,2.0]:
  clear();p=game.player;p.stats.drop_rate=bonus;p.stats.material_find=0;p.level=99;p.xp=0;game.rng.seed=4401
  for i in range(100):
   var target=foe(Vector2(100,0));target.dead=true;game.enemy_died(target,true);target.queue_free()
  drop_counts.append(game.drops.filter(func(d):return d.kind=="item").size())
 check("Drop Rate increases actual dropped item count",drop_counts[1]>drop_counts[0]*1.5)
 check("Drop Rate has a finite chance cap",drop_counts[1]<100)
 clear();p=game.player;game.profile.settings.auto_salvage_rare=true;game.profile.settings.salvage_rules={"quality":1.01,"tier":5,"grade":6};p.materials=0
 var auto_item=ItemDB.generate(game.rng,1,1);var auto_drop=game.spawn_drop(p.position+Vector2(10,0),auto_item);var auto_before=p.inventory.size();game.collect(auto_drop)
 check("auto salvage consumes Rare-or-lower drops without filling inventory",p.inventory.size()==auto_before and p.materials>0 and auto_drop.taken)
 game.profile.settings.auto_salvage_rare=false
 var jp=load("res://assets/fonts/NotoSansJP-Regular.subset.ttf")
 var extra=load("res://assets/fonts/NotoSansJP-Extra.ttf") if ResourceLoader.exists("res://assets/fonts/NotoSansJP-Extra.ttf") else null
 var missing_glyphs=[]
 for folder in ["actors","data","scripts","systems","ui","world"]:
  for file in DirAccess.get_files_at("res://"+folder):
   if not file.ends_with(".gd") and not file.ends_with(".json"):continue
   var content=FileAccess.get_file_as_string("res://"+folder+"/"+file)
   for character in content:
    var code=character.unicode_at(0)
    var covered=jp.has_char(code) or (extra!=null and extra.has_char(code))
    if code>=0x3000 and code<=0x9fff and not covered and character not in missing_glyphs:missing_glyphs.append(character)
 check("bundled Japanese font covers every UI kanji",missing_glyphs.is_empty())
 if not missing_glyphs.is_empty():print("Missing glyphs: ",missing_glyphs)
 print("V03 checks=",count," failures=",failures.size())
 game.shutdown(0 if failures.is_empty() else 1)
func check_roll(it:Dictionary)->void:
 for table in [it.base,it.affixes]:
  for key in table:
   var r=it.rolls[key]
   if table[key]<r[0]-.001 or table[key]>r[1]+.001:failures.append("roll range "+key)
