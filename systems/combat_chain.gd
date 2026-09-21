class_name CombatChain
extends RefCounted
static func strike(p)->void:
 var it=p.equipment[Loadout.WEAPONS[p.combo-1]]
 var w=WeaponDB.get_weapon(it);var g=p.game
 var amount=(p.stats.attack-p.average_weapon_power()+p.weapon_power(it))*w.damage
 var reach=w.reach*(1.15 if int(it.tier)>=2 else 1.0)*(1.15 if p.combo==3 else 1.0)
 var unique=String(it.get("unique",""))
 if unique=="shield_reach" and p.barrier>=5:p.barrier-=5;reach*=1.3
 if unique=="wide_chain" and p.combo==3:reach*=1.2
 if p.counter_time>0:amount*=1.75 if p.upgrades.get("riposte",0)>0 else 1.35;p.counter_time=0
 p.attack_cd=w.cooldown/(1+p.stats.haste);p.attack_time=.2
 var rounds=1+(1 if int(it.rarity)==4 and p.combo==3 else 0)+(1 if (int(it.tier)>=5 and p.combo==3) or (unique=="double_spin" and w.shape=="circle") else 0)
 var landed=0
 for repeat in range(rounds):
  if w.shape in ["bolt","wave"]:
   var angles=[0.0]
   if int(it.rarity)==4:angles=[-.13,0.0,.13]
   for a in angles:
    var bolt=g.fire(p.position+p.facing*20,p.facing.rotated(a)*780,amount/(1.7 if angles.size()>1 else 1),true,4 if int(it.tier)>=4 else 2,Color("bfabff"))
    bolt.tier_shield=int(it.tier)>=3;bolt.damage_types=w.types;bolt.life=reach/780;bolt.radius=22 if w.shape=="wave" else 9;bolt.bounces=2 if unique=="ricochet" else 0
  else:
   for hit in range(w.hits):
    for e in g.enemies.duplicate():
     if e.dead or e.state in ["spawn","transform"]:continue
     var delta=e.position-p.position
     var inside=delta.length()<reach and (w.shape=="circle" or absf(p.facing.angle_to(delta))<w.arc)
     if w.shape=="line":inside=delta.dot(p.facing)>0 and delta.dot(p.facing)<reach and absf(delta.cross(p.facing))<22+e.radius
     if not inside or not g.dungeon.line_clear(p.position,e.position):continue
     var crit=g.rng.randf()<p.stats.crit
     var damage=(amount+p.stats.attack if p.combo==3 and p.has_effect("execution") and e.hp/e.max_hp<.3 else amount)*DamageModel.multiplier(e.kind,w.types,p.stats)*(1+p.stats.crit_damage if crit else 1)
     if "blunt" in w.types and e.kind=="warden":e.shield_break=maxf(e.shield_break,1.2)
     e.take_damage(damage,delta.normalized()*maxf(w.knock,350 if int(it.tier)>=4 and w.shape!="circle" else 0)*(1+p.stats.stagger),crit)
     if not e.dead and p.has_effect("ash_edge"):e.ignite(p.stats.attack*.35,2.5)
     if int(it.tier)>=4 and w.shape=="circle" and not e.dead:e.velocity=-delta.normalized()*160
     if crit:g.critical_effect(e.position)
     landed+=1
   if unique=="split_lance" and w.shape=="line":
    for a in [-.18,.18]:
     var bolt=g.fire(p.position,p.facing.rotated(a)*720,amount*.4,true,3);bolt.damage_types=w.types;bolt.secondary_effect=true;bolt.life=.5
 if landed>=2 and int(it.tier)>=3:p.barrier=minf(p.barrier+8, maxf(20,p.stats.shield_max));p.barrier_time=5
 if p.combo==3:
  if unique=="chain_guard":p.barrier+=12;p.barrier_time=5
  if unique=="fist_nova":g.area_damage(p.position,155,amount*.8,true);g.fx.ring(p.position,155,Color("ffcc8a"),.3)
  for slot in ItemDB.SLOTS:
   if slot not in Loadout.WEAPONS and (int(p.equipment[slot].tier)>=5 or p.equipment[slot].get("unique","")=="chain_guard"):p.barrier=minf(p.barrier+(8 if int(p.equipment[slot].rarity)==4 else 4),maxf(25,p.stats.shield_max));p.barrier_time=5
 if w.shape=="circle":g.fx.ring(p.position,reach,Color("d4fff0"),.25);g.fx.slash(p.position,p.facing,reach,Color("b4ecdf"),true,true)
 elif w.shape=="line":g.fx.lightning(p.position,p.position+p.facing*reach)
 else:g.fx.slash(p.position,p.facing,minf(reach,160),Color("b4ecdf"),p.combo==3,true)
 g.sound.play("slash" if w.shape!="bolt" else "bolt",.8,1.2 if w.cooldown<.25 else .95)
 if landed>0:
  if g.profile.settings.hitstop:g.hitstop=.025
  g.sound.play("hit",.65);g.shake(2)
