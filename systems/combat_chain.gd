class_name CombatChain
extends RefCounted

static func transition_profile(previous_kind:String,current_kind:String,chain_kinds:Array,chain_streak:int,linked:bool)->Dictionary:
 return ChainResolver.profile(previous_kind,current_kind,chain_kinds,chain_streak,linked)

static func strike(p,linked:bool=false)->void:
 var it=p.equipment[Loadout.WEAPONS[p.combo-1]]
 var w=WeaponDB.get_weapon(it);var g=p.game;var kind=String(it.get("weapon_type","sword"));var tier=int(it.tier)
 var chain_sequence=p.chain_history.duplicate()
 var transition=transition_profile(p.last_chain_weapon,kind,chain_sequence,p.chain_streak,linked)
 var amount=(p.stats.attack-p.average_weapon_power()+p.weapon_power(it))*w.damage*float(transition.damage)*(1+p.upgrades.get("master_"+kind,0))
 if linked:amount*=1+p.upgrades.get("transition_power",0)
 if String(transition.label).contains("三相"):amount*=1+p.upgrades.get("triune_mastery",0)
 if String(transition.label).contains("同型"):amount*=1+p.upgrades.get("same_family_mastery",0)
 if linked and p.last_chain_weapon=="scythe" and kind=="staff":amount*=1+p.upgrades.get("harvest_cast_mastery",0)
 if tier>=3 and kind=="sword" and linked:amount*=1.12
 # Primary-oath node behaviors: 無拍子, 破拍子 and 星界回路 only shape linked strikes.
 if linked and "magic" in w.types and p.has_effect("arcane_cap"):amount*=1.2
 var tier2_reach={"sword":1.10,"scythe":1.16,"spear":1.18,"staff":1.10,"fist":1.08,"mace":1.12,"spellblade":1.12}
 var reach=w.reach*(tier2_reach.get(kind,1.0) if tier>=2 else 1.0)*(1.15 if p.combo==3 else 1.0)*float(transition.reach)*(1+p.upgrades.get("slot2_reach",0) if p.combo==2 else 1.0)
 if linked and p.last_chain_weapon=="scythe" and kind=="staff":reach*=1+p.upgrades.get("harvest_cast_mastery",0)
 var arc=float(w.arc)*(1.25 if tier>=4 and kind=="sword" else 1.0)
 var strike_knock=w.knock*float(transition.knock)*(1.22 if tier>=4 and kind=="fist" else 1.0)
 if linked and p.has_effect("impact_chain"):strike_knock*=1.3
 if tier>=4 and kind=="mace":reach*=1.15
 if int(it.rarity)==4 and kind=="mace":reach*=1.18
 if p.dash_attack_time>0 and p.upgrades.get("dash_hunter",0)>0:reach+=35
 var unique=String(it.get("unique",""))
 if unique=="shield_reach" and p.barrier>=5:p.barrier-=5;reach*=1.3
 if unique=="wide_chain" and p.combo==3:reach*=1.2
 if p.counter_time>0:
  amount*=1.75 if p.upgrades.get("riposte",0)>0 else 1.35
  if p.upgrades.get("storm_counter",0)>0:g.chain_lightning(p.position,p.stats.attack*.8,null,2)
  p.counter_time=0
 p.attack_cd=w.cooldown/(1+p.stats.haste)/float(transition.haste);p.attack_time=.2
 if linked and p.has_effect("flow_chain"):p.attack_cd/=1.12
 var tier5_repeat=tier>=5 and p.combo==3 and kind in ["sword","scythe"]
 var mythic_repeat=int(it.rarity)==4 and p.combo==3 and kind in ["sword","scythe"]
 var shield_double=p.has_unique("full_shield_double_magic") and "magic" in w.types and p.stats.shield_max>0 and p.barrier>=p.stats.shield_max-.01
 var rounds=1+(1 if mythic_repeat else 0)+(1 if tier5_repeat or (unique=="double_spin" and w.shape=="circle") else 0)+(1 if shield_double else 0)
 var landed=0
 for repeat in range(rounds):
  if w.shape in ["bolt","wave"]:
   var angles=[0.0]
   if int(it.rarity)==4 and kind=="staff":angles=[-.13,0.0,.13]
   elif int(it.rarity)==4 and kind=="spellblade":angles=[-.17,.17]
   for a in angles:
    var pierce=(4 if tier>=4 and kind in ["staff","spellblade"] else 2)+(2 if "magic" in w.types and p.has_effect("arcane_pierce") else 0)
    var bolt=g.fire(p.position+p.facing*20,p.facing.rotated(a)*780,amount/(1.7 if angles.size()>1 else 1),true,pierce,Color("bfabff"))
    bolt.tier_shield=tier>=3 and kind in ["staff","spellblade"];bolt.damage_types=w.types;bolt.life=reach/780;bolt.radius=22 if w.shape=="wave" else 9
    bolt.normal_group=p.normal_group;bolt.normal_serial=p.normal_serial;bolt.chain_kind=kind
    bolt.can_return="magic" in w.types and p.has_effect("arcane_echo")
    if transition.homing:bolt.homing_target=ChainResolver.seek_target(p)
    bolt.bounces=2 if unique=="ricochet" else (1 if tier>=4 and kind=="staff" else 0)
  else:
   var hit_count=int(w.hits)+(1 if int(it.rarity)==4 and kind=="fist" else 0)
   for hit in range(hit_count):
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
     if transition.wound and ChainResolver.marked(e,"slash"):damage*=1.25
     var was_marked=ChainResolver.marked(e,"magic")
     e.take_damage(damage,delta.normalized()*maxf(strike_knock,350 if tier>=4 and w.shape!="circle" else 0)*(1+p.stats.stagger),crit)
     WeaponActionResolver.normal_hit(p,p.normal_group,p.normal_serial);ChainResolver.mark(e,kind)
     if kind=="mace":p.last_mace_impact=e.position;p.last_mace_time=g.elapsed
     if transition.pull and was_marked and not e.dead:
      e.position=g.dungeon.move_body(e.position,(p.position-e.position).limit_length(65),e.radius);e.velocity=(p.position-e.position).normalized()*230
     if not e.dead and p.has_effect("ash_edge"):e.ignite(p.stats.attack*(.45 if p.has_effect("flame_cap") else .35),4.2 if p.has_effect("burn_long") else 2.5)
     if crit and p.has_effect("burn_burst"):g.area_damage(e.position,72,p.stats.attack*.24,true)
     if tier>=4 and kind=="scythe" and not e.dead:e.velocity=-delta.normalized()*160
     if crit:
      g.critical_effect(e.position)
      if p.has_unique("crit_repeat") and not p.repeat_block:p.repeat_next=true
     landed+=1
   if unique=="split_lance" and w.shape=="line":
    for a in [-.18,.18]:
     var bolt=g.fire(p.position,p.facing.rotated(a)*720,amount*.4,true,3);bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=.5
 if transition.impact and g.elapsed-p.last_mace_time<1.5 and g.dungeon.line_clear(p.position,p.last_mace_impact):
  g.queue_blast(p.last_mace_impact,110,amount*.40,.16,Color("c4a1ff"));g.fx.ring(p.last_mace_impact,110,Color("c4a1ff"),.25)
 if tier>=3 and kind=="scythe" and landed>=3:
  g.area_damage(p.position,reach,amount*.45,true);g.fx.ring(p.position,reach*.75,Color("c8efe4"),.18)
 if tier>=3 and kind=="fist" and landed>=2:p.barrier=minf(p.barrier+4,maxf(12,p.stats.shield_max));p.barrier_time=4
 if p.combo==3 and int(it.rarity)==4:
  match kind:
   "spear":
    for a in [-.28,.28]:
     var mythic_bolt=g.fire(p.position+p.facing*16,p.facing.rotated(a)*800,amount*.62,true,5,Color("eef4ff"));mythic_bolt.damage_types=w.types;mythic_bolt.secondary_effect=true;mythic_bolt.life=reach/800
   "mace":
    g.area_damage(p.position,215,amount*.72,true);g.fx.ring(p.position,215,Color("ffd89a"),.28)
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
  if p.has_effect("weapon_echo"):g.queue_blast(p.position+p.facing*55,120,p.stats.attack*.55,.14,Color("d7ccff"))
  if p.has_effect("fortress_cap"):p.barrier=minf(p.barrier+6,maxf(20,p.stats.shield_max));p.barrier_time=5
  if p.has_effect("shield_burst") and p.barrier>=8:
   var spent=minf(p.barrier,12);p.barrier-=spent;g.area_damage(p.position,135,p.stats.attack*.35+spent*1.5,true);g.fx.ring(p.position,135,Color("c8e6ef"),.25)
  if p.has_unique("barrier_burst_armor") and p.barrier>=6:
   var gear_spent=minf(p.barrier,10);p.barrier-=gear_spent;g.area_damage(p.position,145,p.stats.attack*.30+gear_spent*1.8,true);g.fx.ring(p.position,145,Color("f0cfaa"),.25)
  if p.has_unique("chain_cooldown"):
   for i in range(3):p.cooldowns[i]=maxf(0,p.cooldowns[i]-1.2)
  for slot in ItemDB.SLOTS:
   if slot in Loadout.WEAPONS:continue
   var gear=p.equipment[slot]
   if gear.get("unique","")=="chain_aegis":p.grant_barrier(8 if int(gear.rarity)==4 else 4,25,5)
   if int(gear.tier)<5:continue
   match String(slot):
    "head":g.queue_blast(p.position,125,p.stats.attack*.45,.12,Color("cbbcff"))
    "armor":p.barrier=minf(p.barrier+8,maxf(25,p.stats.shield_max));p.barrier_time=5
    "hands":p.counter_time=maxf(p.counter_time,1.1)
    "feet":p.dash_cd=maxf(0,p.dash_cd-.35)
    "accessory","accessory2":
     for i in range(3):p.cooldowns[i]=maxf(0,p.cooldowns[i]-.65)
 g.fx.weapon(p.position,p.facing,kind,reach)
 if linked and not String(transition.label).is_empty():
  g.fx.recipe(p.position,transition.recipes)
  var recipe_color=WeaponActionResolver.ARTS[kind].color
  g.fx.number(p.position+p.facing*48,String(transition.label),recipe_color,true);g.sound.play("crit",.25,1.15)
 g.sound.play("slash" if w.shape!="bolt" else "bolt",.8,1.2 if w.cooldown<.25 else .95)
 if landed>0:
  if g.profile.settings.hitstop:g.hitstop=.025
  g.sound.play("hit",.65);g.shake(2)
 p.last_chain_weapon=kind
