extends SceneTree
var game
var checks=0
var failures=[]

func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1;print("EQUIPMENT_UI ",("PASS " if ok else "FAIL ")+label)
 if not ok:failures.append(label)

func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
 game.profile.path="user://equipment-ui-isolated.json";game.profile.run={};game.start_run();await process_frame
 var p=game.player
 var generated=ItemDB.generate(game.rng,5,2)
 check("new items use schema 4",generated.schema==4 and ItemDB.valid(generated))
 check("new items carry stable art fields",not String(generated.art_id).is_empty() and generated.art_variant=="default")
 check("missing art falls back to shared placeholder",ItemDB.art_path(generated)=="res://assets/icons/chest.svg" and not ItemDB.art_ready(generated))
 var same=generated.duplicate(true);same.id="different-id"
 check("art identity does not depend on random item id",same.art_id==generated.art_id)

 var legacy=generated.duplicate(true);legacy.schema=3;legacy.erase("art_id");legacy.erase("art_variant")
 check("schema 3 is rejected before migration",not ItemDB.valid(legacy))
 var migrated=SaveMigration.item(legacy)
 check("schema 3 migrates to valid schema 4",migrated.schema==4 and ItemDB.valid(migrated) and not migrated.art_id.is_empty())
 var migrated_data=SaveMigration.migrate({"version":2,"vault":[legacy],"run":{},"oaths":{}})
 check("vault items migrate with the run schema",migrated_data.vault.size()==1 and migrated_data.vault[0].schema==4 and ItemDB.valid(migrated_data.vault[0]))

 p.equipment=ItemDB.initial_items();p.rebuild_stats()
 var candidate=p.equipment.weapon2.duplicate(true)
 candidate.id="compare-mace";candidate.weapon_type="mace";candidate.name="比較用メイス";candidate.tier=5
 candidate.base={"attack":45.0};candidate.affixes={"blunt":.12,"stagger":.12}
 candidate.rolls={"attack":[20.0,50.0],"blunt":[.04,.15],"stagger":[.05,.15]}
 candidate.unique="shield_reach";candidate.art_id=ItemDB.default_art_id(candidate)
 var before_equipment=p.equipment.duplicate(true)
 var snap=EquipmentCompare.snapshot(p,candidate,"weapon2")
 check("comparison snapshot is non-empty",not snap.is_empty())
 check("comparison never mutates equipped items",p.equipment==before_equipment)
 check("comparison exposes current and after totals",snap.before_stats.has("attack") and snap.after_stats.has("attack") and float(snap.after_stats.attack)>float(snap.before_stats.attack))
 check("comparison exposes exact deltas",is_equal_approx(float(snap.delta.attack),float(snap.after_stats.attack)-float(snap.before_stats.attack)))
 check("weapon contribution uses one third of weapon power",is_equal_approx(float(snap.candidate_contribution.attack),Loadout.equipped_stats(candidate).attack/3.0))
 check("comparison exposes changed chain order",snap.before_order!=snap.after_order and String(snap.after_order).contains("メイス"))
 check("comparison records gained chain recipes",snap.gained_build.any(func(value):return String(value).contains("断甲") or String(value).contains("震源")))
 check("comparison records lost chain recipes",not snap.lost_build.is_empty())
 var abilities=EquipmentCompare.ability_tokens(candidate)
 check("ability list includes weapon art",abilities.any(func(value):return String(value).begins_with("武技:")))
 check("ability list includes Tier ability",abilities.any(func(value):return String(value).begins_with("T5:")))
 check("ability list includes unique ability",abilities.any(func(value):return String(value).begins_with("固有:")))
 var keys=EquipmentCompare.key_stats(snap,6)
 check("key stat table prioritizes real changes",keys.size()==6 and "attack" in keys)
 check("human-readable stat deltas preserve sign",ItemDB.stat_delta("attack",3.2).begins_with("+") and ItemDB.stat_delta("crit",-.02).begins_with("-"))

 var armor=ItemDB.generate(game.rng,5,2);armor.slot="armor";armor.art_id=ItemDB.default_art_id(armor)
 var armor_snap=EquipmentCompare.snapshot(p,armor,"armor")
 check("non-weapon replacement keeps chain order",armor_snap.before_order==armor_snap.after_order and armor_snap.gained_build==armor_snap.lost_build)

 p.inventory=[candidate,armor];game.mode="inventory";game.ui.selected=1
 game.ui.act("item:0")
 check("selecting inventory item auto-targets best compatible slot",game.ui.reliquary.target==p.item_upgrade_target(candidate))
 check("selected target is actually compatible",Loadout.accepts(candidate,game.ui.reliquary.target))

 var contribution=EquipmentCompare.item_contribution(p.equipment.armor)
 check("equipped armor contribution is independently inspectable",contribution.has("armor") or contribution.has("hp"))
 var initial=p.equipment.weapon.duplicate(true)
 check("starter art id follows current weapon family",String(initial.art_id).contains(String(initial.weapon_type)))

 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="EQUIPMENT_UI checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/equipment_ui_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures))
 print(summary)
 game.shutdown(0 if failures.is_empty() else 1)
