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
 game.player.position=Vector2.ZERO;game.player.facing=Vector2.RIGHT;game.player.attack_cd=0;game.player.dash_time=0;game.player.combo=0;game.player.active_oaths=[];game.player.stats.crit=0
func weapon(kind:String,slot:String="weapon")->Dictionary:
 var it=ItemDB.generate(game.rng,1,0);it.slot="weapon";it.weapon_type=kind;it.base={"attack":9.0};it.affixes={};game.player.equipment[slot]=it;return it
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game)
 game.profile.path="user://v03-isolated.json";game.profile.run={};game.profile.oaths=OathBoard.empty();game.set_physics_process(false);game.start_run();await process_frame
 clear();var p=game.player
 check("nine slots",p.equipment.size()==9)
 check("seven weapon families",WeaponDB.TYPES.size()==7)
 var tr=WeaponDB.transition({"weapon_type":"sword"},{"weapon_type":"mace"})
 check("slash to blunt has sunder transition",tr.id=="sunder" and tr.guard>1.0)
 tr=WeaponDB.transition({"weapon_type":"mace"},{"weapon_type":"spear"})
 check("blunt to pierce has breach transition",tr.id=="breach" and tr.damage>1.0)
 tr=WeaponDB.transition({"weapon_type":"staff"},{"weapon_type":"sword"})
 check("magic to slash has spell-edge transition",tr.id=="spell_edge" and tr.damage>1.0)
 tr=WeaponDB.transition({"weapon_type":"scythe"},{"weapon_type":"staff"})
 check("scythe to staff has gather transition",tr.id=="reap_cast")
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
 check("same weapon trio enables family finisher",WeaponDB.same_family_chain(p.equipment))
 weapon("sword","weapon");weapon("mace","weapon2");weapon("spear","weapon3")
 check("three primary attributes enable triad finisher",WeaponDB.distinct_primary_chain(p.equipment))
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
 clear();var it=weapon("scythe");it.tier=3;p.rebuild_stats();foe(Vector2(70,0));foe(Vector2(-70,0));p.attack()
 check("T3 multi hit grants shield",p.barrier>0)
 clear();it=weapon("scythe");it.tier=4;p.rebuild_stats();var e=foe(Vector2(90,0));p.attack()
 check("T4 scythe attracts",e.velocity.x<0)
 clear();it=weapon("scythe","weapon3");it.tier=5;p.rebuild_stats();p.combo=2;e=foe(Vector2(90,0));p.attack();var tier_damage=10000-e.hp
 clear();it.tier=1;p.combo=2;e=foe(Vector2(90,0));p.attack()
 check("T5 third slot adds a strike",tier_damage>(10000-e.hp)*1.8)
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
 clear();it=weapon("sword");p.materials=100000;p.inventory=[]
 for i in range(10):Forge.apply(p,it,"enhance")
 check("enhance reaches +10",it.enhance==10)
 for grade in range(5):check("old max slightly exceeds next base "+str(grade),ItemDB.GRADES[grade]*1.3>ItemDB.GRADES[grade+1] and ItemDB.GRADES[grade]*1.3<ItemDB.GRADES[grade+1]*1.06)
 var donor=it.duplicate(true);donor.id="donor";donor.enhance=0;p.inventory.append(donor)
 Forge.apply(p,it,"fuse");check("fusion consumes compatible donor",p.inventory.is_empty() and it.fusion>0)
 Forge.apply(p,it,"tier");check("tier unlock consumes progress",it.tier==2 and it.fusion==0)
 it.affixes={"crit":.1};Forge.apply(p,it,"evolve","crit")
 check("grade evolution resets enhancement",it.grade==2 and it.enhance==0)
 check("chosen affix inherited",is_equal_approx(it.affixes.crit,.108) and it.inherited=="crit")
 var before=p.materials;donor.locked=true;p.inventory=[donor];game.salvage(0)
 check("lock protects salvage",p.inventory.size()==1 and p.materials==before)
 donor.locked=false;game.salvage(0)
 check("salvage grants materials",p.inventory.is_empty() and p.materials>before)
 clear();it=weapon("scythe");it.unique="double_spin";p.rebuild_stats();e=foe(Vector2(90,0));p.attack();var legendary_damage=10000-e.hp
 clear();it.unique="";e=foe(Vector2(90,0));p.attack()
 check("legendary double spin changes damage",legendary_damage>(10000-e.hp)*1.8)
 clear();it=weapon("staff");it.rarity=4;p.rebuild_stats();p.attack()
 check("mythic three real projectiles",game.projectiles.size()==3)
 var board=OathBoard.sanitize({"active":["dance","dance","storm","flame","seek"],"ranks":{},"points":4})
 check("main plus two unique secondary limit",board.active==["dance","storm","flame"])
 check("oath board always keeps a main oath",OathBoard.sanitize({"active":[]}).active==["dance"])
 p.active_oaths=["flame"];check("flame independent of equipment",p.has_effect("ash_edge") and p.has_effect("fire_dash"))
 p.active_oaths=["storm"];check("storm independent of equipment",p.has_effect("chain"))
 p.active_oaths=[];check("inactive elemental gear gives no elemental proc",not p.has_effect("chain"))
 var rare0=0;var rare1=0;var r0=RandomNumberGenerator.new();var r1=RandomNumberGenerator.new();r0.seed=88;r1.seed=88
 for i in range(10000):
  if ItemDB.roll_rarity(r0,0)>=3:rare0+=1
  if ItemDB.roll_rarity(r1,1)>=3:rare1+=1
 check("rarity find improves rarity independently",rare1>rare0*1.25)
 var legacy=game.run_snapshot();legacy.equipment={"weapon":legacy.equipment.weapon,"armor":legacy.equipment.armor,"accessory":legacy.equipment.accessory}
 for slot in legacy.equipment:
  for key in ["schema","weapon_type","grade","enhance","fusion","unique","rolls","locked","favorite"]:legacy.equipment[slot].erase(key)
 var migrated=SaveMigration.migrate({"version":1,"run":legacy,"chronicle":{"legends":["chain","fire_dash"]}})
 check("legacy 3 slots become 9",migrated.run.equipment.size()==9)
 check("legacy IDs retained",migrated.run.equipment.weapon.id==legacy.equipment.weapon.id)
 check("legacy elemental achievements compensated",migrated.oaths.points==4)
 check("legacy run remains valid",game.profile.valid_run(migrated.run))
 check("migration idempotent",SaveMigration.migrate(migrated)==migrated)
 game.profile.oaths=board;p.active_oaths=board.active.duplicate();p.materials=765;p.combo=2;game.save_run()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 check("disk save restores board",disk.oaths==board)
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
 var drop_counts=[]
 for bonus in [0.0,2.0]:
  clear();p=game.player;p.stats.drop_rate=bonus;p.stats.material_find=0;p.level=99;p.xp=0;game.rng.seed=4401
  for i in range(100):
   var target=foe(Vector2(100,0));target.dead=true;game.enemy_died(target,true);target.queue_free()
  drop_counts.append(game.drops.filter(func(d):return d.kind=="item").size())
 check("Drop Rate increases actual dropped item count",drop_counts[1]>drop_counts[0]*1.5)
 check("Drop Rate has a finite chance cap",drop_counts[1]<100)
 clear();p=game.player;p.level=99;p.xp=0;p.materials=0;p.stats.drop_rate=0;p.stats.material_find=.3;game.rng.seed=9001
 for i in range(1000):
  var target=foe(Vector2(100,0));target.dead=true;game.enemy_died(target,true);target.queue_free()
 check("fractional Material Find grants stochastic extra materials",p.materials>1200 and p.materials<1400)
 var weakest=weapon("sword","weapon");weakest.base.attack=2.0
 var middle=weapon("sword","weapon2");middle.base.attack=8.0
 var strongest=weapon("sword","weapon3");strongest.base.attack=20.0
 p.rebuild_stats()
 var candidate=ItemDB.generate(game.rng,1,0);candidate.slot="weapon";candidate.weapon_type="sword";candidate.base={"attack":9.0};candidate.affixes={}
 check("field comparison considers all three weapon slots",p.item_upgrade_ratio(candidate)>0.0)
 var jp=load("res://assets/fonts/NotoSansJP-Regular.subset.ttf")
 var missing_glyphs=[]
 for folder in ["actors","data","scripts","systems","ui","world"]:
  for file in DirAccess.get_files_at("res://"+folder):
   if not file.ends_with(".gd") and not file.ends_with(".json"):continue
   var content=FileAccess.get_file_as_string("res://"+folder+"/"+file)
   for character in content:
    var code=character.unicode_at(0)
    if code>=0x3000 and code<=0x9fff and not jp.has_char(code) and character not in missing_glyphs:missing_glyphs.append(character)
 check("bundled Japanese font covers every UI kanji",missing_glyphs.is_empty())
 if not missing_glyphs.is_empty():print("Missing glyphs: ",missing_glyphs)
 print("V03 checks=",count," failures=",failures.size())
 game.shutdown(0 if failures.is_empty() else 1)
func check_roll(it:Dictionary)->void:
 for table in [it.base,it.affixes]:
  for key in table:
   var r=it.rolls[key]
   if table[key]<r[0]-.001 or table[key]>r[1]+.001:failures.append("roll range "+key)
