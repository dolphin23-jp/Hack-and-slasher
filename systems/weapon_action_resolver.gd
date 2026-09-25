class_name WeaponActionResolver
extends RefCounted
const FINISHER_COST=4
const ARTS={
 "sword":{"name":"瞬歩斬","color":Color("a7eee4"),"cooldown":4.0},
 "scythe":{"name":"渦刈り","color":Color("79dfba"),"cooldown":5.0},
 "spear":{"name":"天穿ち","color":Color("a1d9ff"),"cooldown":4.5},
 "staff":{"name":"魔力砲","color":Color("c4a1ff"),"cooldown":5.0},
 "fist":{"name":"百裂拳","color":Color("ffc68f"),"cooldown":4.0},
 "mace":{"name":"地砕波","color":Color("e9b775"),"cooldown":5.0},
 "spellblade":{"name":"幻刃連波","color":Color("e5a5e9"),"cooldown":4.5}
}
static func current_slot(p)->String:return Loadout.WEAPONS[maxi(0,p.combo-1)]
static func kinds(p)->Array:
 var out=[]
 for slot in Loadout.WEAPONS:out.append(String(p.equipment[slot].weapon_type))
 return out
static func chain_name(p)->String:
 var names=[]
 for kind in kinds(p):names.append(WeaponDB.TYPES[kind].name)
 return " → ".join(names)
static func duration(p,i:int)->float:
 if i<0 or i>2:return 0
 return ([ARTS[p.equipment[current_slot(p)].weapon_type].cooldown,10.0,1.0][i])*(1-p.stats.cdr)
static func snapshot(p,slot:String,scale:float)->Dictionary:
 var item=p.equipment[slot]
 return {"kind":String(item.weapon_type),"damage":maxf(1,p.stats.attack-p.average_weapon_power()+p.weapon_power(item))*(1+p.stats.skill)*(1+p.upgrades.get("master_"+item.weapon_type,0))*scale,"types":WeaponDB.get_weapon(item).types.duplicate(),"tier":int(item.tier),"mythic":int(item.rarity)==4}
static func cast(p,i:int)->bool:
 if i<0 or i>2 or p.dead or p.cooldowns[i]>0 or p.dash_time>0 or not p.skill_actions.is_empty():return false
 if i==2 and p.finisher_charge<FINISHER_COST:return false
 var g=p.game;var origin=p.position;var aim=p.facing.normalized()
 p.cooldowns[i]=duration(p,i)
 if p.synergy("echo"):p.echo_ready=true
 if i==0:
  var action=snapshot(p,current_slot(p),3.1*(1+p.upgrades.get("art_power",0)))
  execute(p,action,origin,aim,false)
  if p.has_effect("judgement_echo"):g.queue_blast(origin+aim*110,145,action.damage*.7,.35,Color("dfd6ff"))
 else:
  # Snapshot equipment, damage, origin and aim once; switching gear cannot change
  # already queued stages. Player movement/dash remains available during stages.
  var center=g.dungeon.move_body(origin,aim*100,18)
  var previous=""
  for index in range(3):
   var action=snapshot(p,Loadout.WEAPONS[index],(3.2 if i==2 else 1.65)*(1+p.upgrades.get("finisher_power" if i==2 else "chain_skill_power",0)))
   var transition=ChainResolver.profile(previous,action.kind,[],0,index>0)
   action.damage*=transition.damage
   action.delay=index*.16;action.origin=center;action.aim=aim;action.chain=true;action.finisher=i==2
   p.skill_actions.append(action);previous=action.kind
  if p.has_effect("echo_guard"):p.barrier=maxf(p.barrier,p.stats.hp*.12);p.barrier_time=5
  if p.has_effect("ember_nova"):g.add_hazard(center,150,3,p.stats.attack*.9,true,0)
  if p.has_effect("conductor"):g.chain_lightning(center,p.stats.attack*.9,null)
  if p.upgrades.get("chain_echo",0)>0:g.queue_blast(center,180,p.stats.attack*1.3,.6,Color("92e8d5"))
  if i==2:
   p.finisher_charge=0;g.fx.recipe(center,[],true);g.fx.ring(center,260,Color("ffe4a3"),.5);g.sound.play("legendary",.65)
  g.fx.number(origin,"三連奥義" if i==2 else "連携技",Color("f2d790"),true)
  tick(p,0)
 return true
static func tick(p,dt:float)->void:
 if p.dead:p.skill_actions.clear();return
 for action in p.skill_actions.duplicate():
  action.delay-=dt
  if action.delay>0:continue
  p.skill_actions.erase(action)
  execute(p,action,action.origin,action.aim,true)
static func execute(p,action:Dictionary,origin:Vector2,aim:Vector2,chained:bool)->void:
 var g=p.game;var kind=String(action.kind);var color:Color=ARTS[kind].color
 var reach=220.0+p.upgrades.get("chain_radius",0) if chained else 220.0
 g.fx.weapon(origin,aim,kind,reach,"finisher" if action.get("finisher",false) else ("chain" if chained else "art"))
 var amount=float(action.damage)
 if chained and "magic" in action.types and p.has_effect("arcane_cap"):amount*=1.2
 var magic_pierce=2 if "magic" in action.types and p.has_effect("arcane_pierce") else 0
 match kind:
  "sword":
   if not chained:p.position=g.dungeon.move_body(p.position,aim*95,18);origin=p.position
   melee(p,origin,aim,190,1.25,amount,380,action.types)
   g.fx.slash(origin,aim,190,color,true,true)
  "scythe":
   for e in g.enemies.duplicate():
    if eligible(g,e,origin,reach):
     e.position=g.dungeon.move_body(e.position,(origin-e.position).limit_length(100),e.radius)
     e.velocity=(origin-e.position).normalized()*230
   melee(p,origin,aim,reach,PI,amount,0,action.types)
   g.fx.ring(origin,reach,color,.3);g.fx.slash(origin,aim,reach,color,true,true)
  "spear","staff":
   var start=origin-aim*90 if chained else origin+aim*20
   var bolt=g.fire(start,aim*1050,amount,true,12+magic_pierce,color)
   bolt.damage_types=action.types;bolt.radius=18 if kind=="spear" else 28;bolt.life=.65
   bolt.can_return=p.has_effect("lance_return");bolt.chain_on_hit=p.synergy("storm")
   if p.has_effect("lance_fork"):
    for angle in [-.24,.24]:
     var side=g.fire(start,aim.rotated(angle)*900,amount*.25,true,4,color);side.damage_types=action.types;side.secondary_effect=true;side.life=.65
   if kind=="staff" and int(action.tier)>=4:bolt.bounces=1
   g.fx.lightning(start,start+aim*300)
  "fist":
   # Several short hits are resolved in one action, with independent stagger.
   for n in range(4):
    melee(p,origin,aim,165,1.1,amount*.25,330,action.types)
    g.fx.slash(origin+aim*(n*13),aim.rotated((n-1.5)*.13),115,color,false,true)
  "mace":
   melee(p,origin,aim,reach,PI,amount,500,action.types)
   g.fx.ring(origin,reach,color,.32);g.fx.burst(origin,color,24,230)
  "spellblade":
   for angle in [-.16,0,.16]:
    var bolt=g.fire(origin-aim*60 if chained else origin+aim*20,aim.rotated(angle)*870,amount/3,true,6+magic_pierce,color)
    bolt.damage_types=action.types;bolt.radius=23;bolt.life=.6
   g.fx.slash(origin,aim,180,color,true,true)
 if action.mythic:g.fx.ring(origin,85,Color("ffe4a3"),.28)
 g.sound.play("bolt" if kind in ["staff","spellblade","spear"] else ("heavy" if kind=="mace" else "slash"),.7)
 g.shake(3)
static func eligible(g,e,origin:Vector2,reach:float)->bool:
 return not e.dead and e.state not in ["spawn","transform"] and origin.distance_to(e.position)<reach and g.dungeon.line_clear(origin,e.position)
static func melee(p,origin:Vector2,aim:Vector2,reach:float,arc:float,amount:float,knock:float,types:Array)->void:
 for e in p.game.enemies.duplicate():
  if not eligible(p.game,e,origin,reach):continue
  var delta=e.position-origin
  if arc<PI and absf(aim.angle_to(delta))>arc:continue
  e.take_damage(amount*DamageModel.multiplier(e.kind,types,p.stats),delta.normalized()*knock)
static func begin_strike(p,linked:bool)->void:
 p.normal_serial+=1
 if not linked or p.chain_streak%3==1:
  p.normal_group=p.normal_serial
  p.normal_groups[p.normal_group]={"ids":[],"hits":[],"expires":p.game.elapsed+4.0}
 p.normal_groups[p.normal_group].ids.append(p.normal_serial)
 for key in p.normal_groups.keys():
  if p.game.elapsed>p.normal_groups[key].expires or p.normal_group-key>12:p.normal_groups.erase(key)
static func normal_hit(p,group:int,serial:int)->void:
 if p.dead or not p.normal_groups.has(group):return
 var entry=p.normal_groups[group]
 if p.game.elapsed>entry.expires or serial not in entry.ids:return
 if serial not in entry.hits:entry.hits.append(serial)
 if entry.ids.size()!=3 or entry.hits.size()!=3:return
 p.normal_groups.erase(group)
 p.finisher_charge=mini(FINISHER_COST,p.finisher_charge+1)
 if p.finisher_charge==FINISHER_COST:p.game.fx.number(p.position,"奥義 READY",Color("ffe4a3"),true)
static func migrate_upgrades(old:Dictionary)->Dictionary:
 var out=old.duplicate(true)
 var mapping={"lance_fan":["chain_skill_power",.18],"lance_giant":["finisher_power",.25],"lance_blast":["chain_echo",1.0],"fan_mastery":["chain_skill_power",.15],"giant_mastery":["finisher_power",.2],"blast_mastery":["chain_radius",45.0],"spear_count":["art_power",.15],"nova_radius":["chain_radius",1.0],"nova_pull":["chain_skill_power",.15],"nova_echo":["chain_echo",1.0]}
 for key in mapping:
  if not out.has(key):continue
  var rule=mapping[key]
  out[rule[0]]=out.get(rule[0],0)+float(out[key])*rule[1];out.erase(key)
 return out
