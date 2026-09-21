extends SceneTree
var game
var checks=0
var failures=[]
var serial=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 checks+=1;print("FORGE ","PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func item(q:float=.4)->Dictionary:
 serial+=1
 var it=ItemDB.generate(game.rng,1,1);it.id="forge-test-"+str(serial);it.slot="weapon";it.weapon_type="sword";it.grade=1;it.tier=1;it.enhance=0;it.fusion=0;it.locked=false;it.favorite=false
 it.base={"attack":10.0};it.affixes={"crit":q*.1};it.rolls={"attack":[5.0,15.0],"crit":[0.0,.1]};return it
func run()->void:
 game=load("res://scripts/game.gd").new();root.add_child(game);game.set_physics_process(false)
 game.profile.path="user://forge-isolated.json";game.profile.run={};game.start_run();await process_frame
 var p=game.player;p.equipment.weapon=item();p.rebuild_stats();p.inventory=[];p.materials=1000;var target=p.equipment.weapon
 var good=item(.99);var junk=item(.3);junk.junk=true;p.inventory=[good,junk]
 Forge.apply(p,target,"fuse")
 check("fusion without explicit donor never consumes inventory",p.inventory.size()==2 and target.fusion==0)
 var preview=Forge.fusion_preview(p,"weapon",junk)
 check("fusion preview snapshots exact target donor and gain",preview.donor==junk and preview.gain==2 and target.fusion==0)
 p.inventory.reverse();Forge.confirm_fusion(p,preview)
 check("sorting cannot redirect donor selection",p.inventory.size()==1 and p.inventory[0].id==good.id and target.fusion==2)
 Forge.confirm_fusion(p,preview)
 check("repeat confirm cannot double consume",p.inventory.size()==1 and target.fusion==2)
 preview=Forge.fusion_preview(p,"weapon",good);good.locked=true
 Forge.confirm_fusion(p,preview)
 check("protecting donor after preview blocks consumption",p.inventory.size()==1 and target.fusion==2)
 good.locked=false;preview=Forge.fusion_preview(p,"weapon",good);good.affixes.crit=.045;Forge.confirm_fusion(p,preview)
 check("changed roll requires fresh confirmation",p.inventory.size()==1 and target.fusion==2)
 preview=Forge.fusion_preview(p,"weapon",good);target.enhance+=1;Forge.confirm_fusion(p,preview)
 check("changed target requires fresh confirmation",p.inventory.size()==1 and target.fusion==2)
 preview=Forge.fusion_preview(p,"weapon",good);p.inventory=[];Forge.confirm_fusion(p,preview)
 check("moved donor cannot be consumed",target.fusion==2)
 p.inventory=[good,good.duplicate(true)];preview=Forge.fusion_preview(p,"weapon",good);Forge.confirm_fusion(p,preview)
 check("ambiguous duplicate IDs reject fusion",p.inventory.size()==2 and target.fusion==2)
 good.favorite=true
 check("favorite donor excluded from candidates",Forge.fusion_preview(p,"weapon",good).is_empty())
 good.favorite=false;var r=SalvagePolicy.defaults();var low=item(.4)
 check("default rules include low-roll Rare T1 grade1",SalvagePolicy.matches(low,r))
 var high=item(.99);check("99 percent affix is preserved",not SalvagePolicy.matches(high,r))
 high.affixes.hp=2.0;high.rolls.hp=[0.0,100.0]
 check("one good affix protects item even with poor average",not SalvagePolicy.matches(high,r))
 var threshold=item(.7);check("quality boundary is strictly below 70 percent",not SalvagePolicy.matches(threshold,r))
 low.locked=true;check("lock always overrides rules",not SalvagePolicy.matches(low,r));low.locked=false
 low.favorite=true;check("favorite always overrides rules",not SalvagePolicy.matches(low,r));low.favorite=false
 low.tier=3;check("high Tier retained",not SalvagePolicy.matches(low,r));low.tier=1
 low.grade=3;check("high grade retained",not SalvagePolicy.matches(low,r));low.grade=1
 low.rarity=2;check("Epic retained even with permissive settings",not SalvagePolicy.matches(low,{"rarity":100,"quality":1.01}));low.rarity=1
 r.keep_weapon="sword";check("chosen weapon family retained",not SalvagePolicy.matches(low,r));low.weapon_type="spear"
 check("other weapon family still follows rules",SalvagePolicy.matches(low,r));r.keep_weapon=""
 r.rarity=0;check("Common-only excludes Rare",not SalvagePolicy.matches(low,r));low.rarity=0
 check("Common-only includes Common",SalvagePolicy.matches(low,r))
 low.affixes={};check("no-affix equipment uses base roll quality",is_equal_approx(SalvagePolicy.quality(low),.5))
 low.rolls={};check("unknown legacy bounds preserved by default",not SalvagePolicy.matches(low,SalvagePolicy.defaults()))
 check("malformed rules revert to safe defaults",SalvagePolicy.sanitize({"quality":999,"tier":-1,"grade":"bad","rarity":10,"keep_weapon":"missing"})==SalvagePolicy.defaults())
 p.inventory=[];game.profile.settings.auto_salvage_rare=true;game.profile.settings.salvage_rules=SalvagePolicy.defaults();var before=p.materials
 var drop=game.spawn_drop(p.position,item(.3));game.collect(drop)
 check("matching pickup becomes materials",drop.taken and p.inventory.is_empty() and p.materials>before)
 drop=game.spawn_drop(p.position,item(.99));game.collect(drop)
 check("high-roll pickup enters inventory",drop.taken and p.inventory.size()==1)
 var protected_item=item(.2);protected_item.locked=true;drop=game.spawn_drop(p.position,protected_item);game.collect(drop)
 check("locked world drop never auto salvaged",p.inventory.size()==2)
 p.inventory=[item(),item(),item()];p.inventory[0].junk=true;p.inventory[1].junk=true;p.inventory[1].locked=true
 var batch=SalvagePolicy.junk_preview(p);check("batch contains only unprotected junk",batch.size()==1)
 before=p.materials;p.inventory.reverse();SalvagePolicy.confirm_junk(p,batch)
 check("batch confirmation follows identity after sort",p.inventory.size()==2 and p.materials>before)
 before=p.materials;SalvagePolicy.confirm_junk(p,batch)
 check("repeated batch confirm cannot grant materials",p.inventory.size()==2 and p.materials==before)
 p.inventory=[item(),item()]
 for it in p.inventory:it.junk=true
 batch=SalvagePolicy.junk_preview(p);p.inventory[1].favorite=true;before=p.materials;SalvagePolicy.confirm_junk(p,batch)
 check("batch validation is atomic when one item changes",p.inventory.size()==2 and p.materials==before)
 game.profile.settings.salvage_rules={"rarity":0,"quality":.9,"tier":4,"grade":3,"keep_weapon":"staff"};game.profile.write_save()
 var disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 check("rules and enabled state survive disk restart",disk.settings.auto_salvage_rare and disk.settings.salvage_rules==game.profile.settings.salvage_rules)
 var saved=JSON.parse_string(FileAccess.get_file_as_string(game.profile.path));saved.settings.erase("salvage_rules")
 FileAccess.open(game.profile.path,FileAccess.WRITE).store_string(JSON.stringify(saved));disk=ProfileStore.new();disk.path=game.profile.path;disk.read_save()
 check("legacy toggle gains conservative quality and tier limits",disk.settings.auto_salvage_rare and disk.settings.salvage_rules==SalvagePolicy.defaults())
 game.mode="inventory";p.inventory=[item()];game.ui.reliquary.forge_slot="weapon";game.ui.act("forge:fuse")
 check("forge UI opens selector without consuming",game.ui.reliquary.forge_screen.opened and p.inventory.size()==1)
 game.ui.act("fusion:select:0");game.ui.act("fusion:preview")
 check("forge UI requires separate confirm",not game.ui.reliquary.forge_screen.pending.is_empty() and p.inventory.size()==1)
 game.ui.act("fusion:cancel");check("cancel preserves item",p.inventory.size()==1 and not game.ui.reliquary.modal_active())
 game.ui.act("bulk");game.ui.pad_back();check("gamepad back cancels modal before leaving inventory",game.mode=="inventory" and not game.ui.reliquary.modal_active())
 game.ui.act("auto_salvage");game.mode="play";p.dash_cd=0;p.dash_time=0;game.ui.act("dash")
 check("leaving inventory clears modal and gameplay actions work",not game.ui.reliquary.modal_active() and p.dash_time>0)
 DirAccess.make_dir_recursive_absolute("res://test-artifacts")
 var summary="FORGE checks=%d failures=%d\n"%[checks,failures.size()]
 FileAccess.open("res://test-artifacts/forge_summary.txt",FileAccess.WRITE).store_string(summary+"\n".join(failures));print(summary)
 game.shutdown(0 if failures.is_empty() else 1)
