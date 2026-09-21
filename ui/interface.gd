extends Control
const BASE=Vector2(1440,900)
const INK=Color("0d1722")
const PANEL=Color("13222e")
const LINE=Color("4e5a59")
const GOLD=Color("c6ad7d")
const TEXT=Color("e1e6da")
const MUTED=Color("95a8ac")
const TEAL=Color("8ecdc2")
const RED=Color("d8857a")
var game
var body=preload("res://assets/fonts/Body.ttf")
var heading=preload("res://assets/fonts/Title.ttf")
var title_art=preload("res://assets/title.svg")
var japanese_font:Font=null
var icons={}
var buttons=[]
var selected=0
var hover=Vector2(-10,-10)
var big_map=false
var salvage_confirm=-1
var settings_return="title"
var pad_focus=0
var pad_active=false
var pad_mode=""
var pad_axis_x_latched=false
var pad_axis_y_latched=false
var touch_id=-1
var touch_origin=Vector2.ZERO
var touch_point=Vector2.ZERO
var attack_touch_id=-1
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var jp_path="res://assets/fonts/NotoSansJP-Regular.subset.ttf"
 if ResourceLoader.exists(jp_path):
  japanese_font=load(jp_path)
  body.fallbacks=[japanese_font]
  heading.fallbacks=[japanese_font]
 for name in ["sword","armor","accessory","cleave","nova","bolt","dash","potion","crest","chest","flame","chain","crit"]:icons[name]=load("res://assets/icons/"+name+".svg")
func layout_scale()->float:
 var size=get_viewport_rect().size
 return minf(size.x/BASE.x,size.y/BASE.y)
func layout_offset()->Vector2:
 var s=layout_scale()
 return (get_viewport_rect().size-BASE*s)*.5
func point(p:Vector2)->Vector2:return (p-layout_offset())/layout_scale()
func screen_point(p:Vector2)->Vector2:return layout_offset()+p*layout_scale()
func _input(event:InputEvent)->void:
 if event is InputEventMouseMotion:
  pad_active=false;hover=point(event.position)
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  pad_active=false
  for b in buttons:
   if b.rect.has_point(point(event.position)):act(b.action);get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo:
  pad_active=false
  if event.keycode==KEY_F11:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  if event.is_action("inventory") and game.mode in ["play","inventory"]:game.toggle_inventory();salvage_confirm=-1;return
  if event.is_action("pause"):
   match game.mode:
    "play":game.mode="pause"
    "pause","inventory":game.mode="play";game.save_run()
    "settings","help":game.mode=settings_return
   return
  if event.is_action("map") and game.mode=="play":big_map=not big_map
  if game.mode=="upgrade" and event.keycode in [KEY_1,KEY_2,KEY_3]:game.choose_upgrade(event.keycode-KEY_1)
  if game.mode in ["inventory","victory_inventory"]:
   if event.keycode==KEY_ENTER:game.player.equip(selected);salvage_confirm=-1
   if event.keycode==KEY_DELETE:act("salvage")
   if event.keycode==KEY_RIGHT:selected=mini(game.player.inventory.size()-1,selected+1)
   if event.keycode==KEY_LEFT:selected=maxi(0,selected-1)
  if game.mode=="title" and event.keycode==KEY_ENTER:game.start_run()
 if event is InputEventJoypadMotion:
  if absf(event.axis_value)>.25:pad_active=true
  if game.mode!="play":
   if event.axis==JOY_AXIS_LEFT_X:
    if absf(event.axis_value)<.35:pad_axis_x_latched=false
    elif not pad_axis_x_latched:
     pad_active=true;pad_axis_x_latched=true;pad_move(Vector2(signf(event.axis_value),0));get_viewport().set_input_as_handled()
   if event.axis==JOY_AXIS_LEFT_Y:
    if absf(event.axis_value)<.35:pad_axis_y_latched=false
    elif not pad_axis_y_latched:
     pad_active=true;pad_axis_y_latched=true;pad_move(Vector2(0,signf(event.axis_value)));get_viewport().set_input_as_handled()
 if event is InputEventJoypadButton and event.pressed:
  pad_active=true
  if event.is_action("inventory") and game.mode in ["play","inventory"]:
   game.toggle_inventory();get_viewport().set_input_as_handled();return
  if event.is_action("pause"):
   if game.mode=="play":game.mode="pause"
   elif game.mode in ["pause","inventory"]:game.mode="play";game.save_run()
   get_viewport().set_input_as_handled();return
  if game.mode!="play":
   if event.button_index==JOY_BUTTON_B:
    if pad_back():get_viewport().set_input_as_handled()
    return
   if game.mode in ["inventory","victory_inventory"] and event.button_index==JOY_BUTTON_X:
    game.player.equip(selected);salvage_confirm=-1;get_viewport().set_input_as_handled();return
   if game.mode in ["inventory","victory_inventory"] and event.button_index==JOY_BUTTON_Y:
    act("salvage");get_viewport().set_input_as_handled();return
   var direction=Vector2.ZERO
   match event.button_index:
    JOY_BUTTON_DPAD_LEFT:direction=Vector2.LEFT
    JOY_BUTTON_DPAD_RIGHT:direction=Vector2.RIGHT
    JOY_BUTTON_DPAD_UP:direction=Vector2.UP
    JOY_BUTTON_DPAD_DOWN:direction=Vector2.DOWN
   if direction!=Vector2.ZERO:
    pad_move(direction);get_viewport().set_input_as_handled();return
   if event.button_index==JOY_BUTTON_A and not buttons.is_empty():
    pad_focus=clampi(pad_focus,0,buttons.size()-1);act(buttons[pad_focus].action);get_viewport().set_input_as_handled();return
 if event is InputEventScreenTouch:
  pad_active=false
  var p=point(event.position)
  if event.pressed:
   game.profile.settings.touch=true
   for b in buttons:
    if b.rect.has_point(p):
     if b.action=="attack":attack_touch_id=event.index;game.player.touch_attack=true
     else:act(b.action)
     return
   if game.mode=="play" and p.x<650 and p.y>400:touch_id=event.index;touch_origin=p;touch_point=p
  else:
   if event.index==touch_id:
    touch_id=-1
    if is_instance_valid(game.player):game.player.touch_move=Vector2.ZERO
   if event.index==attack_touch_id:
    attack_touch_id=-1
    if is_instance_valid(game.player):game.player.touch_attack=false
 if event is InputEventScreenDrag and event.index==touch_id and is_instance_valid(game.player):touch_point=point(event.position);game.player.touch_move=(touch_point-touch_origin).limit_length(68)/68

func pad_move(direction:Vector2)->void:
 if buttons.is_empty():return
 pad_active=true;pad_focus=clampi(pad_focus,0,buttons.size()-1)
 var from:Vector2=buttons[pad_focus].rect.get_center()
 var best=-1;var best_score=INF
 for i in range(buttons.size()):
  if i==pad_focus:continue
  var delta:Vector2=buttons[i].rect.get_center()-from
  if delta.length()<1:continue
  var alignment=delta.normalized().dot(direction)
  if alignment<.35:continue
  var score=delta.length()*(1.0+(1.0-alignment)*2.8)
  if score<best_score:best_score=score;best=i
 if best<0:
  var extreme=-INF
  for i in range(buttons.size()):
   if i==pad_focus:continue
   var projection=buttons[i].rect.get_center().dot(direction)
   if projection>extreme:extreme=projection;best=i
 if best>=0:
  pad_focus=best;hover=Vector2(-10,-10);game.sound.play("ui",.35);queue_redraw()

func pad_back()->bool:
 match game.mode:
  "pause":game.mode="play";game.save_run();return true
  "inventory":game.mode="play";game.save_run();salvage_confirm=-1;return true
  "victory_inventory":game.mode="victory";salvage_confirm=-1;return true
  "settings","help":game.mode=settings_return;return true
 return false

func pointer_blocked()->bool:
 for b in buttons:
  if b.rect.has_point(hover):return true
 return false
func act(action:String)->void:
 if action.begins_with("item:"):selected=int(action.split(":")[1]);salvage_confirm=-1;game.sound.play("ui");return
 if action.begins_with("upgrade:"):game.choose_upgrade(int(action.split(":")[1]));return
 if action.begins_with("skill:"):
  if game.mode=="play":game.player.cast(int(action.split(":")[1]))
  return
 if action.begins_with("setting:"):
  var k=action.split(":")[1]
  if game.profile.settings[k] is bool:game.profile.settings[k]=not game.profile.settings[k]
  else:
   var v=game.profile.settings[k]+.25;game.profile.settings[k]=0.0 if v>1.01 else minf(1,v)
  game.sound.update_volume();game.profile.write_save();return
 game.sound.play("ui")
 match action:
  "start":game.start_run()
  "continue":game.start_run(true)
  "resume":game.mode="play"
  "pause":game.mode="pause"
  "inventory":game.toggle_inventory()
  "map":big_map=not big_map
  "settings":settings_return=game.mode;game.mode="settings"
  "help":settings_return=game.mode;game.mode="help"
  "back":game.mode=settings_return
  "title":game.return_to_title()
  "equip":game.player.equip(selected);salvage_confirm=-1
  "sort":
   var selected_id:String=""
   if selected>=0 and selected<game.player.inventory.size():selected_id=String(game.player.inventory[selected].id)
   game.sort_inventory();selected=0;salvage_confirm=-1
   if not selected_id.is_empty():
    for i in range(game.player.inventory.size()):
     if String(game.player.inventory[i].id)==selected_id:selected=i;break
  "salvage":
   if selected<0 or selected>=game.player.inventory.size():return
   if int(game.player.inventory[selected].rarity)==3 and salvage_confirm!=selected:salvage_confirm=selected;game.toast("レジェンダリーです。もう一度「分解」を押すと確定します。")
   else:game.salvage(selected);salvage_confirm=-1
  "dash":game.player.dash()
  "heal":game.player.drink()
  "interact":game.interact()
  "attack":game.player.attack()
  "ascend":game.start_run(false,true)
  "inspect_victory":game.mode="victory_inventory"
  "return_victory":game.mode="victory"
func _draw()->void:
 if pad_mode!=game.mode:
  pad_mode=game.mode
  pad_focus=1 if game.mode in ["inventory","victory_inventory"] and is_instance_valid(game.player) and not game.player.inventory.is_empty() else 0
 buttons.clear()
 draw_set_transform(Vector2.ZERO)
 var s=layout_scale()
 draw_set_transform(layout_offset(),0,Vector2(s,s))
 if game.mode=="title":draw_title();return
 if is_instance_valid(game.player):draw_hud()
 match game.mode:
  "inventory","victory_inventory":draw_inventory()
  "upgrade":draw_upgrades()
  "pause":draw_pause()
  "dead":draw_end(false)
  "victory":draw_end(true)
  "settings":draw_settings()
  "help":draw_help()
  "play":
   if big_map:draw_map(Rect2(280,195,880,440),true)
 if game.toast_time>0:
  var w=body.get_string_size(game.toast_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+42
  panel(Rect2(720-w/2,108,w,36),Color(.06,.12,.17,.94),Color(.45,.58,.55,.5));text(game.toast_text,Vector2(720,132),16,TEXT,true)
func text(s:String,p:Vector2,size:int=18,c:Color=TEXT,center:bool=false,serif:bool=false)->void:
 var f=heading if serif else body;var at=p
 if center:at.x-=f.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2
 draw_string(f,at,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func wrapped_text(s:String,p:Vector2,w:float,size:int=16,c:Color=MUTED,line_height:int=25)->float:
 var line="";var y=p.y
 var use_character_wrap=false
 for i in range(s.length()):
  if s.unicode_at(i)>127:use_character_wrap=true;break
 if use_character_wrap:
  for i in range(s.length()):
   var ch=s.substr(i,1)
   var test=line+ch
   if body.get_string_size(test,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>w and not line.is_empty():
    text(line,Vector2(p.x,y),size,c);y+=line_height;line=ch
   else:line=test
 else:
  for word in s.split(" "):
   var test=line+(" " if not line.is_empty() else "")+word
   if body.get_string_size(test,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>w and not line.is_empty():
    text(line,Vector2(p.x,y),size,c);y+=line_height;line=word
   else:line=test
 if not line.is_empty():text(line,Vector2(p.x,y),size,c)
 return y+line_height
func panel(r:Rect2,bg:Color=PANEL,border:Color=LINE)->void:
 draw_rect(r,bg);draw_rect(r,border,false,1)
 for p in [r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)]:draw_circle(p,2,border)
func rule(x:float,y:float,w:float,c:Color=LINE)->void:draw_line(Vector2(x,y),Vector2(x+w,y),c,1,true)
func icon(name:String,r:Rect2)->void:
 if icons.has(name):draw_texture_rect(icons[name],r,false)
func button(r:Rect2,label:String,action:String,highlight:bool=false)->void:
 var over=r.has_point(hover) or (pad_active and buttons.size()==pad_focus)
 panel(r,Color("29434b") if over else (Color("344443") if highlight else Color("142630")),GOLD if over or highlight else Color("4c6266"))
 text(label,Vector2(r.get_center().x,r.position.y+r.size.y/2+6),17,TEXT,true);buttons.append({"rect":r,"action":action})
func dim()->void:draw_rect(Rect2(Vector2.ZERO,BASE),Color(.015,.028,.05,.95));buttons.clear()
func bar(r:Rect2,ratio:float,c:Color)->void:
 draw_rect(r,Color("0a141c"));draw_rect(Rect2(r.position,Vector2(r.size.x*clampf(ratio,0,1),r.size.y)),c)
func draw_title()->void:
 draw_texture_rect(title_art,Rect2(Vector2.ZERO,BASE),false)
 for i in range(32):draw_rect(Rect2(i*22,0,23,900),Color(.025,.044,.066,.9*(1-i/32.0)))
 icon("crest",Rect2(100,97,72,72));text("砕けた誓いの大聖堂",Vector2(105,217),14,GOLD)
 text("ASHEN",Vector2(97,306),79,TEXT,false,true);text("VOW",Vector2(98,390),92,TEXT,false,true);rule(105,425,377,GOLD)
 wrapped_text("古びた刃を手に入り、伝説を携えて帰れ。",Vector2(106,469),395,19,MUTED,28)
 var y=550
 if not game.profile.run.is_empty():
  var continue_label="勝利の記録へ戻る" if bool(game.profile.run.get("victory_ready",false)) else "誓いを続ける"
  button(Rect2(105,y,353,54),continue_label,"continue",true);y+=66
 button(Rect2(105,y,353,54),"探索を始める","start",game.profile.run.is_empty());y+=66
 button(Rect2(105,y,170,44),"設定","settings");button(Rect2(288,y,170,44),"遊び方","help")
 if game.profile.records.wins>0 or game.profile.records.total_kills>0 or game.profile.records.best_ascension>0:
  panel(Rect2(105,753,353,73),Color(.035,.065,.09,.86),Color(GOLD,.45))
  text("戦歴",Vector2(120,776),11,GOLD)
  text("踏破 %d  /  最高アセンション %02d"%[game.profile.records.wins,game.profile.records.best_ascension],Vector2(120,799),13,TEXT)
  text("最高LV %02d  /  討伐 %d"%[game.profile.records.best_level,game.profile.records.total_kills],Vector2(120,819),12,MUTED)
 text("オリジナルアクションRPG  /  プロトタイプ",Vector2(105,859),12,MUTED);text("GODOT 4.5.1",Vector2(1329,859),12,MUTED,true)
func draw_hud()->void:
 var p=game.player
 panel(Rect2(24,20,323,69),Color(.045,.08,.12,.94),LINE);icon("crest",Rect2(35,28,47,47))
 text("ASHEN VOW",Vector2(94,51),20,TEXT,false,true)
 var oath_line="誓約者 / LV %02d"%p.level
 if game.ascension>0:oath_line+=" / ASC %02d"%game.ascension
 text(oath_line,Vector2(94,74),12,GOLD)
 var id=game.dungeon.room_at(p.position);var room=game.dungeon.rooms[id] if id>=0 else null
 text(room.name if room!=null else "闇の回廊",Vector2(720,47),19,TEXT,true,true)
 var status="探索し、次の封印へ進め。"
 if game.dungeon.active>=0:
  var active_room=game.dungeon.rooms[game.dungeon.active];status="%s | ウェーブ %d / %d | 残り %d"%[active_room.encounter,game.wave,active_room.waves,game.enemies.size()]
 elif room!=null and id in game.dungeon.cleared:
  var next=game.next_passage(id);status=next.heading+" / "+next.name if not next.is_empty() else "大聖堂は静まり返っている"
  if id==1 and 3 not in game.dungeon.cleared:status+=" - 任意の秘宝: 北"
 text(status,Vector2(720,74),12,GOLD,true);draw_map(Rect2(1175,20,238,136),false);buttons.append({"rect":Rect2(1175,20,238,136),"action":"map"})
 var elite=null
 for e in game.enemies:
  if e.kind=="boss":
   text("鐘なき王",Vector2(720,173),23,Color("efd5a5"),true,true);bar(Rect2(400,185,640,10),e.hp/e.max_hp,Color("be756b"));text("フェーズ "+("II" if e.phase==2 else "I"),Vector2(720,216),12,GOLD,true);elite=null;break
  if e.kind=="elite" and elite==null:elite=e
 if elite!=null:
  var elite_color=elite.affix_color()
  text("誓いなき騎士 / "+elite.affix_name(),Vector2(720,160),16,elite_color,true,true)
  bar(Rect2(565,170,310,7),elite.hp/elite.max_hp,elite_color)
  text(elite.affix_hint(),Vector2(720,194),10,MUTED,true)
 if game.banner_time>0 and game.mode=="play" and game.enemies.is_empty():
  text(game.banner_title,Vector2(720,269),29,Color(TEXT,minf(1,game.banner_time)),true,true);text(game.banner_sub,Vector2(720,306),15,Color(MUTED,minf(1,game.banner_time)),true)
 panel(Rect2(24,768,1390,109),Color(.045,.085,.12,.95),LINE)
 text("生命",Vector2(44,793),11,GOLD);text("%d / %d"%[ceili(p.hp),roundi(p.stats.hp)],Vector2(190,793),13)
 bar(Rect2(44,805,286,17),p.hp/p.stats.hp,Color("91bda7") if p.hp/p.stats.hp>.3 else RED)
 text("XP",Vector2(44,848),11,MUTED);bar(Rect2(74,839,256,5),float(p.xp)/p.xp_required(),GOLD);text("%d / %d"%[p.xp,p.xp_required()],Vector2(185,865),11,MUTED,true)
 var names=["断罪","ソウルノヴァ","スピリットランス","回避","治癒"];var pictures=["cleave","nova","bolt","dash","potion"];var touch_mode=game.profile.settings.touch;var controller_mode=pad_active and not touch_mode
 var keys=["Y","LB","RB","A","B"] if controller_mode else ["Q / RMB","E","R","SPACE","F"]
 for i in range(5):
  var x=375+i*117;var r=Rect2(x,778,62,62);panel(r,Color("182d36"),Color("809184"));icon(pictures[i],r.grow(-6))
  var cd=p.cooldowns[i] if i<3 else (p.dash_cd if i==3 else 0.0)
  if cd>0:draw_rect(r,Color(.02,.04,.07,.67));text("%.1f"%cd,Vector2(x+31,817),19,TEXT,true)
  if i==4:text(str(p.potions),Vector2(x+53,834),20,TEXT,true)
  text("TAP" if touch_mode else keys[i],Vector2(x+31,853),11,GOLD,true);text(names[i],Vector2(x+31,869),10,MUTED,true)
  buttons.append({"rect":r,"action":"skill:"+str(i) if i<3 else ("dash" if i==3 else "heal")})
 if touch_mode:
  text("下のスキルをタップ",Vector2(1005,794),12,MUTED);text("移動 / 攻撃 / 回収",Vector2(1005,816),12,MUTED)
 elif controller_mode:
  text("X 長押しで攻撃",Vector2(1005,794),12,MUTED);text("左スティック 移動    十字上 回収",Vector2(1005,816),11,MUTED)
 else:
  text("LMB / J 長押しで攻撃",Vector2(1005,794),12,MUTED);text("WASD 移動    C 回収",Vector2(1005,816),12,MUTED)
 var inventory_label="聖遺物庫" if touch_mode else ("戻る / 聖遺物庫" if controller_mode else "I 聖遺物庫")
 var pause_label="一時停止" if touch_mode else ("START 一時停止" if controller_mode else "ESC 一時停止")
 button(Rect2(1003,831,183,32),inventory_label,"inventory");button(Rect2(1200,831,188,32),pause_label,"pause")
 if game.profile.settings.touch and game.mode=="play":
  var o=touch_origin if touch_id>=0 else Vector2(133,645)
  draw_circle(o,70,Color(.2,.4,.44,.2));draw_arc(o,70,0,TAU,48,Color(.55,.8,.77,.6),2,true)
  draw_circle(o+(touch_point-touch_origin).limit_length(55) if touch_id>=0 else o,25,Color(.65,.88,.81,.45))
  button(Rect2(1223,597,140,65),"攻撃","attack",true);button(Rect2(1060,671,136,55),"回避","dash");button(Rect2(1213,681,154,45),"回収","interact")
 if game.mode=="play":draw_critical_health(p)
func draw_critical_health(p)->void:
 var ratio:float=clampf(float(p.hp)/maxf(1.0,float(p.stats.hp)),0.0,1.0)
 if ratio>=.30:return
 var severity:float=1.0-ratio/.30
 var pulse:float=.5+.5*sin(game.elapsed*5.2)
 var alpha:float=.07+severity*.12+pulse*.035
 var danger:=Color(RED.r,RED.g,RED.b,alpha)
 var edge:float=18.0
 draw_rect(Rect2(0,0,BASE.x,edge),danger)
 draw_rect(Rect2(0,BASE.y-edge,BASE.x,edge),danger)
 draw_rect(Rect2(0,0,edge,BASE.y),danger)
 draw_rect(Rect2(BASE.x-edge,0,edge,BASE.y),danger)
 var label_color:=Color(RED.r,RED.g,RED.b,.78+pulse*.18)
 var warning:String="生命 CRITICAL"
 var warning_w:float=body.get_string_size(warning,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
 draw_rect(Rect2(720-warning_w/2-12,724,warning_w+24,28),Color(.035,.02,.025,.76))
 draw_rect(Rect2(720-warning_w/2-12,724,warning_w+24,28),Color(RED.r,RED.g,RED.b,.32),false,1)
 text(warning,Vector2(720,743),12,label_color,true,true)
func draw_map(r:Rect2,large:bool)->void:
 panel(r,Color(.04,.075,.11,.96),LINE)
 var world=Rect2(-560,-1670,9500,2590);var size=r.size-Vector2(28,42);var f=minf(size.x/world.size.x,size.y/world.size.y)
 var origin=r.get_center()-world.size*f/2-world.position*f+Vector2(0,9)
 for link in game.dungeon.connections:draw_line(game.dungeon.rooms[link[0]].center*f+origin,game.dungeon.rooms[link[1]].center*f+origin,Color("61746f"),2 if large else 1)
 for room in game.dungeon.rooms:
  var rect=Rect2(room.rect.position*f+origin,room.rect.size*f);var c=Color("385f60") if room.id in game.dungeon.cleared else Color("263541")
  if room.id==game.dungeon.active:c=Color("92594f")
  draw_rect(rect,c);draw_rect(rect,GOLD if room.id==9 else Color("788c88"),false,1)
  if large:text(str(room.id+1).pad_zeros(2),rect.get_center()+Vector2(0,5),14,TEXT,true)
 draw_circle(game.player.position*f+origin,5 if large else 3,Color("d0ffe9"));text("大聖堂" if large else "M / 大聖堂",r.position+Vector2(13,22),15 if large else 10,GOLD)
 if large:
  text("01 Threshold  02 Nave  03 Ossuary  04 Treasury (optional)  05 Forge",Vector2(r.get_center().x,r.end.y-47),13,MUTED,true)
  text("06 Archive  07 Cloister  08 Chapel  09 Procession  10 Throne",Vector2(r.get_center().x,r.end.y-24),13,MUTED,true)
func draw_inventory()->void:
 dim();text("THE 聖遺物庫",Vector2(42,62),33,TEXT,false,true);text("戦利品を比べ、戦い方を組み替えよう。",Vector2(43,94),15,MUTED)
 button(Rect2(1215,40,180,43),"戻る","return_victory" if game.mode=="victory_inventory" else "inventory")
 var p=game.player;panel(Rect2(40,128,284,701));text("装備中",Vector2(60,162),13,GOLD)
 for i in range(3):
  var item=p.equipment[ItemDB.SLOTS[i]];var y=179+i*97
  panel(Rect2(57,y,66,66),INK,ItemDB.COLORS[int(item.rarity)]);icon("sword" if item.slot=="weapon" else item.slot,Rect2(63,y+6,54,54))
  text(item.slot.to_upper(),Vector2(138,y+17),11,MUTED);wrapped_text(item.name,Vector2(138,y+38),165,13,ItemDB.COLORS[int(item.rarity)],19)
 rule(58,477,245);text("現在の装備",Vector2(60,507),13,GOLD)
 var s=p.stats;var rows=[["攻撃力","%.0f"%s.attack],["クリティカル率","%d%%"%roundi(s.crit*100)],["クリティカル威力","%d%%"%roundi((1+s.crit_damage)*100)],["攻撃力 speed","+%d%%"%roundi(s.haste*100)],["防御力","%.0f"%s.armor],["スキル威力","+%d%%"%roundi(s.skill*100)],["クールダウン","-%d%%"%roundi(s.cdr*100)],["移動速度","+%d%%"%roundi(s.speed*100)]]
 for i in range(rows.size()):text(rows[i][0],Vector2(60,540+i*30),14,MUTED);text(rows[i][1],Vector2(238,540+i*30),14)
 text("LV %d / 討伐 %d"%[p.level,game.kills],Vector2(60,808),12,GOLD);text("所持品 %d / 40"%p.inventory.size(),Vector2(351,154),14,GOLD);text("比較するアイテムを選択",Vector2(351,177),12,MUTED)
 for i in range(maxi(40,p.inventory.size())):
  var r=Rect2(349+(i%5)*72,195+floori(i/5.0)*(64 if p.inventory.size()>40 else 72),62,62)
  var c=ItemDB.COLORS[int(p.inventory[i].rarity)] if i<p.inventory.size() else Color("344a55")
  var pad_over=pad_active and buttons.size()==pad_focus
  panel(r,Color("1b313b") if i==selected or pad_over else INK,c)
  if i<p.inventory.size():
   var it=p.inventory[i];icon("sword" if it.slot=="weapon" else it.slot,r.grow(-7))
   if i==selected or pad_over:draw_rect(r.grow(3),GOLD if pad_over else Color("f0e3bb"),false,2)
   text(str(it.tier),r.position+Vector2(48,57),10,c);buttons.append({"rect":r,"action":"item:"+str(i)})
 button(Rect2(535,139,180,36),"並べ替え","sort")
 text("ENTER 装備 / DELETE 分解",Vector2(351,808),12,MUTED)
 if selected<0 or selected>=p.inventory.size():text("未回収の装備はありません。",Vector2(1059,400),27,GOLD,true,true);return
 var it=p.inventory[selected];item_card(it,Rect2(746,129,310,487),"所持品");item_card(p.equipment[it.slot],Rect2(1074,129,310,487),"CURRENTLY 装備中")
 var loadout=p.equipment.duplicate(true);loadout[it.slot]=it;var next=p.calculated(loadout)
 panel(Rect2(746,635,638,103),INK);text("IF 装備中",Vector2(762,657),11,GOLD)
 var comparisons=[["剣DPS",dps(next)/dps(s)-1],["実効耐久",next.hp*(1+next.armor/100)/(s.hp*(1+s.armor/100))-1],["スキル一撃",next.attack*(1+next.skill)/(s.attack*(1+s.skill))-1]]
 for i in range(3):
  var x=762+i*209;var v=comparisons[i][1]*100;text(comparisons[i][0],Vector2(x,682),11,MUTED);text("%+.1f%%"%v,Vector2(x,714),26,TEAL if v>0 else (RED if v<0 else TEXT))
 button(Rect2(746,761,310,54),"この装備に変更","equip",true);button(Rect2(1074,761,310,54),"分解を確定" if salvage_confirm==selected else "SALVAGE TO 治癒","salvage")
 text("比較値にはレジェンダリー効果を含みません。分解前に効果を確認してください。",Vector2(1065,850),12,MUTED,true)
func dps(s:Dictionary)->float:return s.attack*(1+s.haste)*(1+s.crit*s.crit_damage)
func item_card(it:Dictionary,r:Rect2,tag:String)->void:
 var c=ItemDB.COLORS[int(it.rarity)];panel(r,Color("13252f"),Color(c,.7));draw_rect(Rect2(r.position,Vector2(r.size.x,3)),c)
 var x=r.position.x+19;var y=r.position.y+30;text(tag,Vector2(x,y),11,MUTED);icon("sword" if it.slot=="weapon" else it.slot,Rect2(x,y+13,60,60))
 text(ItemDB.RARITIES[int(it.rarity)],Vector2(x+78,y+38),12,c);text("ティア %d / %s"%[it.tier,it.slot.to_upper()],Vector2(x+78,y+62),10,MUTED)
 y=wrapped_text(it.name,Vector2(x,y+105),r.size.x-38,20,c,26)+9;rule(x,y,r.size.x-38,Color(c,.3));y+=28
 for key in it.base:text(ItemDB.stat_text(key,it.base[key]),Vector2(x,y),15);y+=25
 if not it.affixes.is_empty():y+=9
 for key in it.affixes:text(ItemDB.stat_text(key,it.affixes[key]),Vector2(x,y),14,Color("9fc8cb"));y+=23
 if not it.effect.is_empty():
  y+=9;rule(x,y,r.size.x-38,Color(c,.3));y+=24;text("レジェンダリー",Vector2(x,y),11,c);y+=25;wrapped_text(it.description,Vector2(x,y),r.size.x-38,13,c,20)
func draw_upgrades()->void:
 dim();text("誓いが強くなる",Vector2(720,207),37,TEXT,true,true);text("LV %d / 祝福を1つ選択"%game.player.level,Vector2(720,244),15,GOLD,true)
 for i in range(3):
  var c=game.upgrade_choices[i];var r=Rect2(221+i*344,299,310,356);var focused=r.has_point(hover) or (pad_active and buttons.size()==pad_focus);panel(r,Color("19313a") if focused else PANEL,GOLD if focused else LINE)
  icon(c.icon,Rect2(r.get_center().x-49,r.position.y+31,98,98));text(c.name,Vector2(r.get_center().x,r.position.y+177),20,TEXT,true,true);wrapped_text(c.detail,r.position+Vector2(25,220),260,16,MUTED,25)
  text("[ %d ] この誓いを選ぶ"%(i+1),Vector2(r.get_center().x,r.end.y-25),13,GOLD,true);buttons.append({"rect":r,"action":"upgrade:"+str(i)})
 text("装備は残る。誓いだけが変わる。",Vector2(720,714),15,MUTED,true)
func draw_pause()->void:
 dim();icon("crest",Rect2(680,147,80,80));text("束の間の静寂",Vector2(720,280),32,TEXT,true,true)
 button(Rect2(535,333,370,53),"戻る TO 大聖堂","resume",true);button(Rect2(535,402,370,48),"設定","settings");button(Rect2(535,467,370,48),"遊び方","help");button(Rect2(535,532,370,48),"SAVE & 戻る TO TITLE","title")
 wrapped_text("装備と祝福は保存されます。戦闘中なら最後に解放した聖域から再開します。",Vector2(492,642),460,15,MUTED,25)
func draw_run_summary()->void:
 var m=game.metrics
 panel(Rect2(380,398,680,82),Color("101f2a"),LINE)
 text("今回の記録",Vector2(720,418),11,GOLD,true)
 var rows=[
  ["与ダメージ",str(roundi(float(m.get("damage_dealt",0))))],
  ["被弾",str(int(m.get("hits_taken",0)))],
  ["戦利品",str(int(m.get("pickups",0)))],
  ["装備変更",str(int(m.get("equips",0)))],
  ["誓い",str(int(m.get("level_ups",0)))]]
 for i in range(rows.size()):
  var x=428+i*146
  text(rows[i][0],Vector2(x,442),10,MUTED,true)
  text(rows[i][1],Vector2(x,467),19,TEXT,true,true)
func draw_end(won:bool)->void:
 dim();icon("crest" if won else "sword",Rect2(665,108,110,110));text("誓いは果たされた" if won else "誓いはまだ終わらない",Vector2(720,272),39,TEXT,true,true)
 text("鐘は沈黙した。あなたはまだ立っている。" if won else "大聖堂はその名を刻んだ。次の誓いへ挑もう。",Vector2(720,320),17,MUTED,true)
 var seconds=int(game.elapsed);text("LV %d / 討伐 %d / %02d:%02d"%[game.player.level,game.kills,seconds/60,seconds%60],Vector2(720,384),18,GOLD,true)
 draw_run_summary()
 if won:
  wrapped_text("4つのレジェンダリーが所持品に加わりました。確認するか、このビルドでアセンションへ進めます。",Vector2(454,505),535,14,MUTED,22)
  var next_asc=game.ascension+1
  var next_vow=game.ASCENSION_VOWS[(next_asc-1)%game.ASCENSION_VOWS.size()]
  button(Rect2(502,541,436,54),"王の戦利品を見る","inspect_victory",true)
  button(Rect2(502,610,436,54),"アセンション %02d / %s"%[next_asc,next_vow.name],"ascend")
  text(next_vow.detail,Vector2(720,687),12,GOLD,true)
  button(Rect2(502,720,436,48),"戻る TO TITLE","title")
 else:
  wrapped_text("予備動作を見て動き続け、隙が閉じる前に回復を使おう。",Vector2(454,505),535,14,MUTED,22)
  button(Rect2(502,557,436,54),"もう一度探索する","start",true)
  button(Rect2(502,689,436,48),"戻る TO TITLE","title")
func draw_settings()->void:
 dim();text("設定",Vector2(720,162),35,TEXT,true,true)
 var labels={"music":"BGM音量","sfx":"効果音量","shake":"画面揺れ","auto_aim":"自動照準","touch":"タッチ操作"};var i=0
 for k in labels:
  var v=game.profile.settings[k];var label=labels[k]+"  "+(("オン" if v else "オフ") if v is bool else "%d%%"%roundi(v*100))
  button(Rect2(470,227+i*78,500,50),label,"setting:"+k);i+=1
 text("クリックで切替。タッチ操作では照準補助も有効になります。",Vector2(720,655),14,MUTED,true);button(Rect2(566,711,308,52),"戻る","back",true)
func draw_help()->void:
 dim();text("操作方法",Vector2(720,145),36,TEXT,true,true)
 var rows=[["WASD / 矢印キー","8方向移動"],["マウス / 右スティック","攻撃方向とスピリットランスを照準"],["LMB / J 長押し","3連続の剣攻撃。3段目は高威力。"],["SPACE / SHIFT","短い無敵時間つきの回避。再使用まで1.1秒。"],["Q / RMB","断罪: 広範囲の強力な近接攻撃。CT 5秒。"],["E","ソウルノヴァ: 範囲攻撃＋鈍足。CT 10秒。"],["R","スピリットランス: 貫通する遠距離攻撃。CT 6秒。"],["F","治癒: 3本ある回復薬を1本使用"],["C","近くの宝箱を開く / 装備を回収"],["I / TAB","聖遺物庫で比較・装備・分解"],["M / ESC","マップ / 一時停止・設定"]]
 for i in range(rows.size()):text(rows[i][0],Vector2(299,221+i*39),14,GOLD);text(rows[i][1],Vector2(535,221+i*39),16)
 text("戦利品は触れると回収。聖遺物庫を開いている間は戦闘が止まります。",Vector2(720,687),14,MUTED,true);text("聖域を解放すると生命と回復薬を補充。宝物庫は任意です。",Vector2(720,715),14,MUTED,true)
 button(Rect2(566,763,308,50),"準備完了","back",true)
