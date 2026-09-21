class_name CombatChain
extends RefCounted

static func transition_profile(previous_kind:String,current_kind:String,chain_kinds:Array,chain_streak:int,linked:bool)->Dictionary:
 var result={"damage":1.0,"reach":1.0,"knock":1.0,"label":""}
 if linked and WeaponDB.TYPES.has(previous_kind) and WeaponDB.TYPES.has(current_kind):
  var from_type=String(WeaponDB.TYPES[previous_kind].types[0])
  var to_type=String(WeaponDB.TYPES[current_kind].types[0])
  match from_type+">"+to_type:
   "slash>blunt":
    result.damage=1.10;result.knock=1.45;result.label="断甲"
   "blunt>pierce":
    result.damage=1.18;result.label="破砕貫通"
   "magic>slash":
    result.damage=1.15;result.reach=1.08;result.label="魔力纏刃"
  if previous_kind=="scythe" and current_kind=="staff":
   result.damage*=1.12;result.reach*=1.18;result.label="収束魔撃"
 if linked and chain_streak>=3 and chain_streak%3==0 and chain_kinds.size()==3:
  if chain_kinds[0]==chain_kinds[1] and chain_kinds[1]==chain_kinds[2]:
   result.damage*=1.28
   result.label=(String(result.label)+"・" if not String(result.label).is_empty() else "")+"同型極撃"
  else:
   var attrs=[]
   for kind in chain_kinds:
    if not WeaponDB.TYPES.has(kind):continue
    var attr=String(WeaponDB.TYPES[kind].types[0])
    if attr not in attrs:attrs.append(attr)
   if attrs.size()==3:
    result.damage*=1.16
    result.label=(String(result.label)+"・" if not String(result.label).is_empty() else "")+"三相連環"
 return result

static func strike(p,linked:bool=false)->void:
 var it=p.equipment[Loadout.WEAPONS[p.combo-1]]
 var w=WeaponDB.get_weapon(it);var g=p.game;var kind=String(it.get("weapon_type","sword"));var tier=int(it.tier)
 var chain_kinds=[]
 for slot in Loadout.WEAPONS:chain_kinds.append(String(p.equipment[slot].get("weapon_type","sword")))
 var transition=transition_profile(p.last_chain_weapon,kind,chain_kinds,p.chain_streak,linked)
 var amount=(p.stats.attack-p.average_weapon_power()+p.weapon_power(it))*w.damage*float(transition.damage)
 if tier>=3 and kind=="sword" and linked:amount*=1.12
 var tier2_reach={"sword":1.10,"scythe":1.16,"spear":1.18,"staff":1.10,"fist":1.08,"mace":1.12,"spellblade":1.12}
 var reach=w.reach*(tier2_reach.get(kind,1.0) if tier>=2 else 1.0)*(1.15 if p.combo==3 else 1.0)*float(transition.reach)
 var arc=float(w.arc)*(1.25 if tier>=4 and kind=="sword" else 1.0)
 var strike_knock=w.knock*float(transition.knock)*(1.22 if tier>=4 and kind=="fist" else 1.0)
 if tier>=4 and kind=="mace":reach*=1.15
 if p.dash_attack_time>0 and p.upgrades.get("dash_hunter",0)>0:reach+=35
 var unique=String(it.get("unique",""))
 if unique=="shield_reach" and p.barrier>=5:p.barrier-=5;reach*=1.3
 if unique=="wide_chain" and p.combo==3:reach*=1.2
 if p.counter_time>0:
  amount*=1.75 if p.upgrades.get("riposte",0)>0 else 1.35
  if p.upgrades.get("storm_counter",0)>0:g.chain_lightning(p.position,p.stats.attack*.8,null,2)
  p.counter_time=0
 p.attack_cd=w.cooldown/(1+p.stats.haste);p.attack_time=.2
 var tier5_repeat=tier>=5 and p.combo==3 and kind in ["sword","scythe"]
 var rounds=1+(1 if int(it.rarity)==4 and p.combo==3 else 0)+(1 if tier5_repeat or (unique=="double_spin" and w.shape=="circle") else 0)
 var landed=0
 for repeat in range(rounds):
  if w.shape in ["bolt","wave"]:
   var angles=[0.0]
   if int(it.rarity)==4:angles=[-.13,0.0,.13]
   for a in angles:
    var pierce=4 if tier>=4 and kind in ["staff","spellblade"] else 2
    var bolt=g.fire(p.position+p.facing*20,p.facing.rotated(a)*780,amount/(1.7 if angles.size()>1 else 1),true,pierce,Color("bfabff"))
    bolt.tier_shield=tier>=3 and kind in ["staff","spellblade"];bolt.damage_types=w.types;bolt.life=reach/780;bolt.radius=22 if w.shape=="wave" else 9
    bolt.bounces=2 if unique=="ricochet" else (1 if tier>=4 and kind=="staff" else 0)
  else:
   for hit in range(w.hits):
    for e in g.enemies.duplicate():
     if e.dead or e.state in ["spawn","transform"]:continue
     var delta=e.position-p.position
     var inside=delta.length()<reach and (w.shape=="circle" or absf(p.facing.angle_to(delta))<arc)
     if w.shape=="line":inside=delta.dot(p.facing)>0 and delta.dot(p.facing)<reach and absf(delta.cross(p.facing))<22+e.radius
     if not inside or not g.dungeon.line_clear(p.position,e.position):continue
     var crit=g.rng.randf()<p.stats.crit
     var damage=(amount+p.stats.attack if p.combo==3 and p.has_effect("execution") and e.hp/e.max_hp<.3 else amount)*DamageModel.multiplier(e.kind,w.types,p.stats)*(1+p.stats.crit_damage if crit else 1)
     if tier>=3 and kind=="spear" and landed>0:damage*=1.20
     if "blunt" in w.types and e.kind=="warden":e.shield_break=maxf(e.shield_break,2.4 if tier>=3 and kind=="mace" else 1.2)
     e.take_damage(damage,delta.normalized()*maxf(strike_knock,350 if tier>=4 and w.shape!="circle" else 0)*(1+p.stats.stagger),crit)
     if not e.dead and p.has_effect("ash_edge"):e.ignite(p.stats.attack*.35,2.5)
     if tier>=4 and kind=="scythe" and not e.dead:e.velocity=-delta.normalized()*160
     if crit:g.critical_effect(e.position)
     landed+=1
   if unique=="split_lance" and w.shape=="line":
    for a in [-.18,.18]:
     var bolt=g.fire(p.position,p.facing.rotated(a)*720,amount*.4,true,3);bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=.5
 if tier>=3 and kind=="scythe" and landed>=3:
  g.area_damage(p.position,reach,amount*.45,true);g.fx.ring(p.position,reach*.75,Color("c8efe4"),.18)
 if tier>=3 and kind=="fist" and landed>=2:p.barrier=minf(p.barrier+4,maxf(12,p.stats.shield_max));p.barrier_time=4
 if p.combo==3 and tier>=5:
  match kind:
   "spear":
    for a in [-.20,.20]:
     var bolt=g.fire(p.position+p.facing*18,p.facing.rotated(a)*760,amount*.55,true,4,Color("d4e9ff"));bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=reach/760
   "staff":
    var bolt=g.fire(p.position+p.facing*20,p.facing*820,amount*.65,true,5,Color("d9c4ff"));bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=reach/820
   "fist":
    g.area_damage(p.position,150,amount*.65,true);g.fx.ring(p.position,150,Color("ffd69e"),.25)
   "mace":
    g.area_damage(p.position,185,amount*.80,true);g.fx.ring(p.position,185,Color("e6c995"),.3)
   "spellblade":
    p.barrier=minf(p.barrier+14,maxf(28,p.stats.shield_max));p.barrier_time=5
 if p.combo==3:
  if unique=="chain_guard":p.barrier+=12;p.barrier_time=5
  if unique=="fist_nova":g.area_damage(p.position,155,amount*.8,true);g.fx.ring(p.position,155,Color("ffcc8a"),.3)
 if p.chain_streak>=3 and p.chain_streak%3==0:
  for slot in ItemDB.SLOTS:
   if slot in Loadout.WEAPONS:continue
   var gear=p.equipment[slot]
   if gear.get("unique","")=="chain_guard":p.barrier=minf(p.barrier+(8 if int(gear.rarity)==4 else 4),maxf(25,p.stats.shield_max));p.barrier_time=5
   if int(gear.tier)<5:continue
   match String(slot):
    "head":g.queue_blast(p.position,125,p.stats.attack*.45,.12,Color("cbbcff"))
    "armor":p.barrier=minf(p.barrier+8,maxf(25,p.stats.shield_max));p.barrier_time=5
    "hands":p.counter_time=maxf(p.counter_time,1.1)
    "feet":p.dash_cd=maxf(0,p.dash_cd-.35)
    "accessory","accessory2":
     for i in range(3):p.cooldowns[i]=maxf(0,p.cooldowns[i]-.65)
 if w.shape=="circle":g.fx.ring(p.position,reach,Color("d4fff0"),.25);g.fx.slash(p.position,p.facing,reach,Color("b4ecdf"),true,true)
 elif w.shape=="line":g.fx.lightning(p.position,p.position+p.facing*reach)
 else:g.fx.slash(p.position,p.facing,minf(reach,160),Color("b4ecdf"),p.combo==3,true)
 if linked and not String(transition.label).is_empty():g.fx.number(p.position+p.facing*48,String(transition.label),Color("f2d790"),true)
 g.sound.play("slash" if w.shape!="bolt" else "bolt",.8,1.2 if w.cooldown<.25 else .95)
 if landed>0:
  if g.profile.settings.hitstop:g.hitstop=.025
  g.sound.play("hit",.65);g.shake(2)
 p.last_chain_weapon=kind
