#!/usr/bin/env python3
"""Original SVG illustration and deterministic PCM synthesis. Python standard library only."""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[1]/'assets'
random.seed(804)
def svg(path,body,w=128,h=128):
 (ROOT/path).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>')
def knight(name,metal,light,cloth,glow,boss=False):
 s=f'''<defs><linearGradient id="m" x2="1" y2="1"><stop stop-color="{light}"/><stop offset=".45" stop-color="{metal}"/><stop offset="1" stop-color="#162329"/></linearGradient><linearGradient id="c" x2="1" y2="1"><stop stop-color="{cloth}"/><stop offset="1" stop-color="#101822"/></linearGradient></defs>
 <path d="M37 40 Q17 62 23 109 L39 103 49 119 65 101 82 119 105 106 Q96 64 90 41Z" fill="url(#c)" stroke="#0d171e" stroke-width="3"/>
 <path d="M38 57 L34 98 44 91 M83 50 L98 103 79 91 M65 67 L65 101" fill="none" stroke="{cloth}" stroke-width="2"/>
 <path d="M45 83 L43 111 54 116 62 105 60 81 M68 82 L68 109 77 116 88 109 81 80" fill="#18252b" stroke="#111a23" stroke-width="3"/>
 <path d="M45 88 L43 106 54 109 57 87 M71 88 L73 110 85 106 81 86" fill="url(#m)"/>
 <path d="M42 108 L34 118 Q43 124 57 118 L57 110 M73 110 L72 120 Q89 124 94 117 L84 108" fill="#26393e" stroke="#101c22" stroke-width="2"/>
 <path d="M37 44 L31 73 42 85 87 85 99 74 92 42 78 37 49 37Z" fill="url(#m)" stroke="#101b23" stroke-width="3"/>
 <path d="M41 54 L63 45 86 54 79 76 64 87 49 74Z" fill="{metal}" stroke="{light}" stroke-width="1.5"/>
 <path d="M63 47 L63 77 M48 60 L62 64 78 59" stroke="{light}" stroke-width="2" fill="none"/><path d="M62 54 L68 63 63 73 57 63Z" fill="{glow}"/>
 <path d="M31 43 L46 37 51 52 40 60 23 57 20 50Z M81 38 L95 39 109 53 104 63 87 58 77 51Z" fill="url(#m)" stroke="#101c24" stroke-width="3"/>
 <path d="M28 48 L42 44 M88 45 L99 51" stroke="{light}" stroke-width="2"/>
 <path d="M28 62 L24 82 32 94 42 85 39 62 M92 64 L91 87 101 96 111 86 103 63" fill="url(#m)" stroke="#13232a" stroke-width="3"/>
 <path d="M42 81 L85 81 86 89 43 89Z" fill="#372f2a" stroke="#d2b77b"/><path d="M58 81 L71 81 71 90 58 90Z" fill="#b59862"/>
 <path d="M47 20 L61 13 78 20 82 39 73 50 56 50 44 38Z" fill="url(#m)" stroke="#111e26" stroke-width="3"/>
 <path d="M49 30 L77 30 75 39 66 38 64 44 60 38 48 37Z" fill="#08191f"/><path d="M50 33 L60 34 M68 34 L75 33" stroke="{glow}" stroke-width="3"/>
 <path d="M63 18 L63 29 M50 24 L61 20 74 25" stroke="{light}" fill="none" stroke-width="2"/>
 <path d="M61 12 Q49 -2 64 2 Q83 4 78 21 L69 17Z" fill="{cloth}" stroke="{light}"/>'''
 if boss:s+='<path d="M41 23 L33 0 53 12 64 0 75 12 94 0 83 26Z" fill="#bfa171" stroke="#ffdc91" stroke-width="2"/><path d="M15 46 L3 25 26 37 M106 42 L126 26 116 58" fill="#c6b88d" stroke="#f6dfaa" stroke-width="2"/>'
 svg('characters/'+name+'.svg',s)
for args in [('player','#52838b','#b7d6cf','#215f6c','#a7fff4'),('hollow','#605e60','#afa18c','#503035','#ee895d'),('warden','#6c6557','#c3ac7d','#3c3935','#ffa650'),('elite','#776078','#d5b0b4','#57284d','#ffb3b1'),('boss','#786956','#efe0b8','#702d3a','#fff0b6',True)]:knight(*args)
svg('characters/cantor.svg','''<path d="M48 37 Q20 54 29 108 L43 99 54 121 68 104 80 116 96 99 Q106 66 80 35Z" fill="#605373" stroke="#171a29" stroke-width="3"/><path d="M46 61 L38 103 M72 58 L82 101 M61 62 L58 106" fill="none" stroke="#a58fba" stroke-width="2"/><path d="M42 29 Q46 1 64 4 Q89 6 87 37 L70 51 48 47Z" fill="#4b3b62" stroke="#ad8fbc" stroke-width="2"/><path d="M53 22 Q65 14 77 24 L73 43 58 43Z" fill="#101b29"/><path d="M55 29 L61 30 M69 30 L74 28" stroke="#f2aaf7" stroke-width="3"/><path d="M44 48 L62 61 83 45 M53 49 L64 85 73 49" fill="none" stroke="#ad9565" stroke-width="3"/><path d="M61 58 L70 68 62 80 55 68Z" fill="#eec9fa"/><path d="M92 32 L100 116" stroke="#c0a87f" stroke-width="4"/><path d="M83 18 L90 3 104 14 99 33 89 35Z" fill="#332b45" stroke="#ac92c0" stroke-width="3"/><path d="M92 13 L99 19 94 28 88 23Z" fill="#d6a1fd"/><path d="M32 53 L17 71 24 82 42 65 M86 53 L102 65 107 79 95 87 88 71" fill="#625073" stroke="#202337" stroke-width="3"/>''')
svg('characters/hound.svg','''<path d="M24 62 L11 48 9 28 18 36 23 46 39 51Z" fill="#8d8077" stroke="#24232b" stroke-width="3"/><path d="M36 67 L23 87 18 108 33 108 39 90 53 81 M73 76 L68 103 82 108 88 88 95 83" fill="#9f978e" stroke="#252731" stroke-width="4"/><path d="M33 48 L69 38 94 53 97 79 67 88 38 76 26 62Z" fill="#49444b" stroke="#1f242c" stroke-width="3"/><path d="M42 49 L44 70 52 77 M53 47 L54 70 62 79 M65 43 L66 67 73 75 M77 48 L78 63" fill="none" stroke="#d0b69d" stroke-width="5"/><path d="M83 50 L81 28 88 13 96 29 104 25 113 11 119 35 118 57 106 74 90 67Z" fill="#938e89" stroke="#272831" stroke-width="3"/><path d="M88 43 L100 46 95 52 87 49 M107 45 L116 41 115 50 106 53" fill="#ff885a"/><path d="M96 58 L105 57 109 66 98 68Z" fill="#171c27"/><path d="M94 69 L94 76 99 69 M108 69 L107 77 112 68" fill="#ede2c1"/><path d="M51 36 L49 22 60 34 67 20 75 35 82 28 84 43" fill="#c5b299" stroke="#403b41" stroke-width="2"/>''')
icons={
'sword':'<path d="M26 101 L48 76 40 68 45 62 51 67 96 17 106 12 103 29 58 75 65 81 59 87 51 80 30 107Z" fill="#aacdcc" stroke="#e3eee0" stroke-width="2"/><path d="M57 69 L99 22" stroke="#438b95" stroke-width="3"/><path d="M31 94 L39 102" stroke="#bba06b" stroke-width="8"/>',
'armor':'<path d="M31 27 L50 17 56 28 72 28 79 17 100 28 115 52 91 63 86 107 40 107 36 63 13 52Z" fill="#3b6470" stroke="#b5c7ba" stroke-width="3"/><path d="M44 40 L64 48 84 40 78 81 64 95 49 81Z" fill="#5d8c94" stroke="#cab786" stroke-width="2"/><path d="M64 50 L64 80 M40 97 L86 97" stroke="#c2d6c7" stroke-width="3"/>',
'accessory':'<path d="M34 18 Q20 75 62 97 Q110 80 95 18" fill="none" stroke="#b99967" stroke-width="5"/><path d="M63 61 L88 81 63 114 37 81Z" fill="#306f78" stroke="#e0bd7d" stroke-width="4"/><path d="M63 72 L74 82 63 97 51 82Z" fill="#9feadc"/>',
'cleave':'<path d="M18 92 Q49 7 111 20 Q69 40 38 113Z" fill="#e6c18a"/><path d="M39 97 Q65 48 103 32" fill="none" stroke="#fffae1" stroke-width="5"/>',
'nova':'<circle cx="64" cy="64" r="34" fill="#163e49" stroke="#81dccd" stroke-width="5"/><path d="M64 5 L72 45 113 18 84 53 122 64 85 72 111 110 75 85 64 123 53 85 17 111 43 76 6 64 42 53 18 18 53 43Z" fill="none" stroke="#c6f9ec" stroke-width="3"/><circle cx="64" cy="64" r="13" fill="#c6fff0"/>',
'bolt':'<path d="M18 105 L52 46 47 67 81 30 110 12 96 44 72 74 74 52Z" fill="#b5f0ec" stroke="#5bb9c4" stroke-width="3"/>',
'dash':'<path d="M38 28 L78 63 38 100 M65 28 L105 63 65 100" fill="none" stroke="#bce7dc" stroke-width="10"/><path d="M11 45 L37 45 M5 64 L46 64 M11 83 L35 83" stroke="#538c96" stroke-width="5"/>',
'potion':'<path d="M49 16 L80 16 80 31 76 35 77 49 Q105 66 94 101 Q63 124 33 101 Q22 68 52 49 L53 35 49 31Z" fill="#254640" stroke="#aad1ab" stroke-width="3"/><path d="M41 73 Q62 63 88 75 L87 96 Q65 110 41 96Z" fill="#80bf8b"/><path d="M49 18 L80 18" stroke="#b7926c" stroke-width="8"/>',
'crest':'<path d="M64 5 L76 38 106 22 96 58 122 71 88 83 86 111 64 99 40 117 39 88 8 73 34 55 21 23 52 37Z" fill="#305962" stroke="#b4a06f" stroke-width="3"/><path d="M64 20 L68 66 85 70 67 75 64 112 59 75 42 70 60 66Z" fill="#c0f1dd"/>',
'chest':'<path d="M16 57 Q16 24 64 24 Q111 24 112 57 L112 99 16 99Z" fill="#483e34" stroke="#c2a369" stroke-width="4"/><path d="M18 61 L110 61 M36 29 L36 98 M92 29 L92 98" stroke="#bf9a55" stroke-width="7"/><path d="M55 55 L73 55 73 78 55 78Z" fill="#f3d390"/>',
'flame':'<path d="M64 8 Q82 47 96 56 Q116 98 69 117 Q12 113 30 65 Q41 82 46 62 Q55 50 64 8Z" fill="#da7541" stroke="#f3c080" stroke-width="2"/><path d="M61 58 Q97 96 64 108 Q39 95 61 58Z" fill="#ffe7ad"/>',
'chain':'<path d="M81 7 L29 73 62 69 44 121 104 51 72 55Z" fill="#bcece5" stroke="#5d9eab" stroke-width="3"/>',
'crit':'<path d="M64 10 L74 47 114 33 84 63 119 85 78 82 67 118 56 82 15 96 42 66 9 44 50 49Z" fill="#ebaf83"/>'}
for n,s in icons.items():svg('icons/'+n+'.svg',s)
s=['<defs><radialGradient id="f"><stop stop-color="#28505c"/><stop offset="1" stop-color="#080e18"/></radialGradient></defs><rect width="1440" height="900" fill="url(#f)"/>']
for i in range(6):
 x=820+i*62;y=90+i*15;s.append(f'<path d="M{x-145} 780 V{y+200} Q{x} {y-90} {x+145} {y+200} V780" fill="none" stroke="#101c28" stroke-width="24"/>')
s+=['<circle cx="1010" cy="328" r="167" fill="#293e4c" stroke="#9a926f" stroke-width="3"/><circle cx="1010" cy="328" r="148" fill="#36515b" stroke="#768982" stroke-width="2"/>']
for i in range(12):
 a=i*math.tau/12;s.append(f'<path d="M1010 328 L{1010+145*math.cos(a):.2f} {328+145*math.sin(a):.2f}" stroke="#192b36" stroke-width="9"/>')
s+=['<path d="M-80 900 L440 550 1240 550 1600 900" fill="#111c27"/>']
for i in range(16):s.append(f'<path d="M{600+i*37} 557 L{120+i*97} 900" stroke="#2a3940"/>')
for y in [590,629,680,751,847]:s.append(f'<path d="M350 {y} H1440" stroke="#2a3940"/>')
for x in [746,1253]:s.append(f'<path d="M{x-35} 720 L{x-30} 216 {x} 163 {x+30} 216 {x+35} 720Z" fill="#1a2935" stroke="#40505b" stroke-width="3"/><path d="M{x-12} 235 V691 M{x+12} 235 V691" stroke="#52616a" stroke-width="4"/>')
s+=['<ellipse cx="1010" cy="735" rx="143" ry="34" fill="#0a121d"/><path d="M938 728 L948 656 1071 656 1084 728Z" fill="#39424a" stroke="#879087" stroke-width="2"/><path d="M919 654 L1101 654 1114 677 911 677Z" fill="#576365" stroke="#a2a791" stroke-width="2"/><path d="M998 454 L1023 442 1020 625 1010 657 998 625Z" fill="#b1ccc3" stroke="#e0dfbc" stroke-width="2"/><path d="M980 460 H1040" stroke="#ba9f6a" stroke-width="9"/><path d="M1009 416 V455" stroke="#6b5850" stroke-width="11"/><circle cx="1009" cy="409" r="10" fill="#b7ab81"/>']
for x in [899,920,1105,1134]:s.append(f'<path d="M{x} 717 v-36" stroke="#dbc7a2" stroke-width="5"/><ellipse cx="{x}" cy="675" rx="4" ry="10" fill="#ffe6a1"/>')
for i in range(85):s.append(f'<circle cx="{random.randrange(700,1370)}" cy="{random.randrange(300,840)}" r="1.5" fill="#bcd2b9" opacity=".3"/>')
svg('title.svg',''.join(s),1440,900)
RATE=22050
def wav(name,a):
 peak=max(1,max(abs(v) for v in a))
 with wave.open(str(ROOT/'audio'/f'{name}.wav'),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(struct.pack('<%dh'%len(a),*(int(v/peak*29000) for v in a)))
for name,dur,freq,end,noise in [('slash',.15,340,90,.7),('heavy',.28,190,44,.6),('hit',.14,135,42,.55),('crit',.27,960,120,.35),('dash',.26,250,530,.8),('hurt',.32,180,65,.45),('death',.55,150,28,.3),('enemy_death',.18,90,31,.6),('loot',.35,840,1210,.02),('rare',.7,550,1100,0),('legendary',1.5,380,1520,0),('equip',.27,440,760,.1),('ui',.08,660,550,0),('nova',.8,220,47,.45),('bolt',.29,790,290,.15),('level',1.1,392,1000,0),('boss',1.7,98,40,.15),('heal',.8,420,840,.05),('chest',.6,300,1000,.2)]:
 a=[];phase=0
 for n in range(int(RATE*dur)):
  t=n/RATE;z=t/dur;phase+=math.tau*(freq+(end-freq)*z)/RATE
  a.append(.7*(1-z)**2*min(1,t/.005)*((math.sin(phase)+.23*math.sin(phase*2.01))*(1-noise)+random.uniform(-1,1)*noise))
 wav(name,a)
for name,bpm,root in [('menu',60,110),('dungeon',75,82.4069),('boss_music',110,73.4162)]:
 beat=60/bpm;dur=beat*32;length=int(RATE*dur);f0=round(root*dur)/dur
 a=[.085*(math.sin(math.tau*f0*n/RATE)+.48*math.sin(math.tau*f0*1.5*n/RATE)) for n in range(length)]
 seq=[0,7,12,15,7,3,10,7,0,7,14,15,10,7,3,7]
 for j in range(32):
  freq=root*2**(seq[j%16]/12)*2;start=int(j*beat*RATE)
  for k in range(int(beat*2.8*RATE)):
   t=k/RATE;a[(start+k)%length]+=.16*math.exp(-t*3/beat)*min(1,t/.009)*(math.sin(math.tau*freq*t)+.25*math.sin(math.tau*freq*2.01*t))
  if name!='menu':
   for k in range(int(.17*RATE)):
    t=k/RATE;a[(start+k)%length]+=.22*math.exp(-t*32)*math.sin(math.tau*(65*t-85*t*t))
  if name=='boss_music':
   for k in range(int(.07*RATE)):
    t=k/RATE;a[(start+int(beat*RATE/2)+k)%length]+=.065*random.uniform(-1,1)*math.exp(-t*60)
 for i in range(100):a[i]*=i/100;a[-i-1]*=i/100
 wav(name,a)
print('Original art and audio rebuilt.')
