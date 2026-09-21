class_name CombatChain
extends RefCounted
static func strike(p)->void:
 var it=p.equipment[Loadout.WEAPONS[p.combo-1]]
 var w=WeaponDB.get_weapon(it);var g=p.game
 var amount=(p.stats.attack-p.average_weapon_power()+p.weapon_power(it))*w.damage
 var transition={"id":"","name":"","damage":1.0,"guard":1.0,"knock":1.0}
 if p.swing_count>1:
  var previous=p.equipment[Loadout.WEAPONS[(p.combo+1)%3]]
  transition=WeaponDB.transition(previous,it)
  amount*=float(transition.damage)*(1+float(p.upgrades.get("transition_power",0)))
  if p.has_unique("transition_echo"):amount*=1.12
  if int(p.equipment.accessory.tier)>=5:amount*=1.08
 var reach=w.reach*(1.15 if int(it.tier)>=2 else 1.0)*(1.15 if p.combo==3 else 1.0)
 if p.combo==2:reach*=1+float(p.upgrades.get("slot2_range",0))
 if p.combo==3:
  amount*=1+float(p.upgrades.get("slot3_power",0))
  if p.has_unique("shield_spend_power") and p.barrier>=10:
   p.barrier-=10;amount*=1.25
  if WeaponDB.same_family_chain(p.equipment):amount*=1+float(p.upgrades.get("family_finisher",0))
  if WeaponDB.distinct_primary_chain(p.equipment):amount*=1+float(p.upgrades.get("triad_finisher",0))
  if transition.id=="reap_cast":amount*=1+float(p.upgrades.get("reap_cast_power",0))
 if transition.id=="spell_edge":reach*=1.12
 if transition.id=="reap_cast":
  var focus=p.position+p.facing*minf(reach*.45,180.0)
  for enemy in g.enemies:
   if not enemy.dead and enemy.position.distance_to(focus)<190:enemy.velocity+=(focus-enemy.position).normalized()*150
 if p.dash_attack_time>0 and p.upgrades.get("dash_hunter",0)>0:reach+=35
 var unique=String(it.get("unique",""));var kind=String(it.get("weapon_type","sword"))
 if unique=="shield_reach" and p.barrier>=5:p.barrier-=5;reach*=1.3
 if unique=="wide_chain" and p.combo==3:reach*=1.2
 if p.counter_time>0:
  amount*=1.75 if p.upgrades.get("riposte",0)>0 else 1.35
  if p.upgrades.get("storm_counter",0)>0:g.chain_lightning(p.position,p.stats.attack*.8,null,2)
  p.counter_time=0
 p.attack_cd=w.cooldown/(1+p.stats.haste);p.attack_time=.2
 var mythic_round=int(it.rarity)==4 and p.combo==3 and kind in ["sword","scythe","fist"]
 var rounds=1+(1 if mythic_round else 0)+(1 if ((int(it.tier)>=5 and p.combo==3 and kind in ["sword","scythe"]) or (unique=="double_spin" and w.shape=="circle")) else 0)
 if p.combo==3 and WeaponDB.same_family_chain(p.equipment):rounds+=1
 if p.combo==3 and WeaponDB.distinct_primary_chain(p.equipment):rounds+=1
 if p.has_unique("full_shield_magic_double") and "magic" in w.types and p.stats.shield_max>0 and p.barrier>=p.stats.shield_max*.9:rounds+=1
 var landed=0
 for repeat in range(rounds):
  if w.shape in ["bolt","wave"]:
   var angles=[0.0]
   if (int(it.rarity)==4 and kind=="staff") or (int(it.tier)>=5 and p.combo==3 and kind=="staff"):angles=[-.13,0.0,.13]
   for a in angles:
    var bolt=g.fire(p.position+p.facing*20,p.facing.rotated(a)*780,amount/(1.7 if angles.size()>1 else 1),true,6 if (int(it.tier)>=4 and kind in ["staff","spellblade"]) else (4 if int(it.tier)>=4 else 2),Color("bfabff"))
    bolt.tier_shield=int(it.tier)>=3 and kind in ["spellblade"];bolt.damage_types=w.types;bolt.life=reach/780;bolt.radius=22 if w.shape=="wave" else 9
    bolt.bounces=2 if unique=="ricochet" else (1 if int(it.tier)>=3 and kind=="staff" else 0)
  else:
   for hit in range(w.hits):
    for e in g.enemies.duplicate():
     if e.dead or e.state in ["spawn","transform"]:continue
     var delta=e.position-p.position
     var inside=delta.length()<reach and (w.shape=="circle" or absf(p.facing.angle_to(delta))<w.arc)
     if w.shape=="line":inside=delta.dot(p.facing)>0 and delta.dot(p.facing)<reach and absf(delta.cross(p.facing))<22+e.radius
     if not inside or not g.dungeon.line_clear(p.position,e.position):continue
     var crit_chance=float(p.stats.crit)+(.08 if not String(transition.id).is_empty() and p.has_unique("transition_crit") else 0.0)
     var crit=g.rng.randf()<minf(.95,crit_chance)
     var damage=(amount+p.stats.attack if p.combo==3 and p.has_effect("execution") and e.hp/e.max_hp<.3 else amount)*DamageModel.multiplier(e.kind,w.types,p.stats)*(1+p.stats.crit_damage if crit else 1)
     if int(it.tier)>=3 and kind=="spear" and landed>0:damage*=1.2
     if transition.id=="sunder" and e.kind in ["warden","elite","boss"]:damage*=float(transition.guard)
     if "blunt" in w.types and e.kind=="warden":e.shield_break=maxf(e.shield_break,2.0 if int(it.tier)>=4 and kind=="mace" else 1.2)
     var knock=maxf(w.knock,350 if int(it.tier)>=4 and w.shape!="circle" else 0)*(1+p.stats.stagger)*float(transition.knock)
     e.take_damage(damage,delta.normalized()*knock,crit)
     if not e.dead and p.has_effect("ash_edge"):e.ignite(p.stats.attack*.35,2.5)
     if int(it.tier)>=4 and w.shape=="circle" and not e.dead:e.velocity=-delta.normalized()*160
     if crit:g.critical_effect(e.position)
     landed+=1
   if unique=="split_lance" and w.shape=="line":
    for a in [-.18,.18]:
     var bolt=g.fire(p.position,p.facing.rotated(a)*720,amount*.4,true,3);bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=.5
 if landed>=2 and int(it.tier)>=3 and kind in ["sword","fist","mace","spellblade"]:
  p.barrier=minf(p.barrier+(12 if kind=="mace" else 8),maxf(20,p.stats.shield_max));p.barrier_time=5
 if landed>=3 and int(it.tier)>=3 and kind=="scythe":
  g.area_damage(p.position,reach*.8,amount*.35,true);g.fx.ring(p.position,reach*.8,Color("c7efe1"),.2)
 if p.combo==3:
  if unique=="chain_guard":p.barrier+=12;p.barrier_time=5
  if unique=="fist_nova" or (int(it.tier)>=5 and kind=="fist"):g.area_damage(p.position,155,amount*.8,true);g.fx.ring(p.position,155,Color("ffcc8a"),.3)
  if int(it.tier)>=5 and kind=="mace":g.area_damage(p.position,190,amount*.65,true);g.fx.ring(p.position,190,Color("ffd29b"),.3)
  if int(it.tier)>=5 and kind=="spear":
   for a in [-.18,.18]:
    var side=g.fire(p.position+p.facing*20,p.facing.rotated(a)*760,amount*.48,true,4,Color("d9e7ff"));side.damage_types=w.types;side.life=.55
  if int(it.tier)>=5 and kind=="spellblade":
   g.queue_blast(p.position+p.facing*minf(reach*.7,280.0),120,amount*.75,.25,Color("c9b5ff"))
  if int(p.equipment.head.tier)>=5 and "magic" in w.types:g.queue_blast(p.position+p.facing*85,105,amount*.35,.18,Color("d6c8ff"))
  if int(p.equipment.armor.tier)>=5:p.barrier=minf(p.barrier+8,maxf(25,p.stats.shield_max));p.barrier_time=5
  if int(p.equipment.hands.tier)>=5:g.area_damage(p.position,120,amount*.25,true)
  if int(p.equipment.feet.tier)>=5:p.dash_cd=maxf(0,p.dash_cd-.25)
  if int(p.equipment.accessory2.tier)>=5:p.heal(p.stats.hp*.015)
  for slot in ItemDB.SLOTS:
   if slot not in Loadout.WEAPONS and p.equipment[slot].get("unique","")=="chain_guard":p.barrier=minf(p.barrier+4,maxf(25,p.stats.shield_max));p.barrier_time=5
  if int(it.rarity)==4:
   if kind=="spear":
    for a in [-.27,.27]:
     var myth_lance=g.fire(p.position+p.facing*18,p.facing.rotated(a)*800,amount*.42,true,5,Color("f2d7ff"));myth_lance.damage_types=w.types;myth_lance.life=.55
   elif kind=="mace":g.area_damage(p.position,220,amount*.55,true)
   elif kind=="spellblade":g.queue_blast(p.position+p.facing*210,145,amount*.7,.18,Color("e0b8ff"))
 if w.shape=="circle":g.fx.ring(p.position,reach,Color("d4fff0"),.25);g.fx.slash(p.position,p.facing,reach,Color("b4ecdf"),true,true)
 elif w.shape=="line":g.fx.lightning(p.position,p.position+p.facing*reach)
 else:g.fx.slash(p.position,p.facing,minf(reach,160),Color("b4ecdf"),p.combo==3,true)
 g.sound.play("slash" if w.shape!="bolt" else "bolt",.8,1.2 if w.cooldown<.25 else .95)
 if landed>0:
  if not String(transition.name).is_empty():g.fx.number(p.position+p.facing*44,String(transition.name),Color("d9e7ff"))
  if g.profile.settings.hitstop:g.hitstop=.025
  g.sound.play("hit",.65);g.shake(2)
