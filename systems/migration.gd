class_name SaveMigration
extends RefCounted
static func item(value:Variant)->Variant:
 if not value is Dictionary:return value
 var it=value.duplicate(true)
 if not ItemDB.valid(it):return it
 if int(it.get("schema",0))>=3:return it
 it.schema=3;it.weapon_type="sword";it.grade=clampi(1+int((it.tier-1)/3.0),1,6);it.tier=clampi(int(it.tier),1,5)
 it.enhance=0;it.fusion=0;it.locked=false;it.favorite=false;it.rolls={};it.unique="wide_chain" if int(it.rarity)>=3 else ""
 it.legacy_effect=it.effect
 return it
static func migrate(data:Dictionary)->Dictionary:
 var out=data.duplicate(true)
 out.oaths=OathBoard.sanitize(out.get("oaths",{}))
 var run=out.get("run",{})
 if run is Dictionary and not run.is_empty():
  if run.get("equipment") is Dictionary:
   var starter=ItemDB.initial_items()
   for slot in ItemDB.SLOTS:
    run.equipment[slot]=item(run.equipment[slot]) if run.equipment.has(slot) else starter[slot]
  if run.get("inventory") is Array:
   for i in range(run.inventory.size()):run.inventory[i]=item(run.inventory[i])
  if run.get("drops") is Array:
   for drop in run.drops:
    if drop is Dictionary and drop.get("kind")=="item":drop.item=item(drop.get("item"))
  run.materials=run.get("materials",0);run.active_oaths=run.get("active_oaths",out.oaths.active.duplicate());run.combo=run.get("combo",0)
 if out.get("version",1)==1:
  var legends=out.get("chronicle",{}).get("legends",[]) if out.get("chronicle") is Dictionary else []
  if legends is Array:out.oaths.points+=legends.size()*2
 out.version=2
 return out
