class_name ChronicleDB
extends RefCounted
const ENEMIES={
 "hollow":["虚ろな巡礼者","群れで接近する。剣の2段目でまとめて怯ませよう。"],
 "cantor":["灰の詠唱者","3方向の射撃で位置を動かす。予告線の横へ移動。"],
 "hound":["残火の猟犬","向きを固定して突進。横へかわし、停止後に反撃。"],
 "warden":["鉄の守衛","正面は盾で軽減。背後、強い打撃、メイス武技で崩す。"],
 "summoner":["弔鐘の司祭","詠唱後に眷属を召喚。怯みで詠唱を中断できる。"],
 "elite":["誓いなき騎士","狂乱・城塞・爆裂の紋章を確認しよう。"],
 "boss":["鐘なき王","半分で覚醒。攻撃後の青緑の輪は反撃機会、被ダメージ35%増加。"]}
const ACHIEVEMENTS={
 "first_clear":["鐘を沈めた者","大聖堂を初めて踏破。次の探索で『槍の巡礼』を選択可能。"],
 "collector":["聖遺物の探求者","異なるレジェンダリーを6種回収。『残火の巡礼』を解放。"],
 "evader":["鐘を聞く前に","直前回避を累計5回成功。祝福『雷鳴の継承』を解放。"],
 "risk":["誓いの代価","危険な契約を達成。祝福『残火の収穫』を解放。"],
 "bestiary":["死者を知る者","全7種の敵を撃破。図鑑の記録を完成。"]}
const STARTS=[
 {"id":"blade","name":"刃の巡礼","text":"初期装備で開始。探索中の祝福を自由に選べる。","unlock":""},
 {"id":"lance","name":"槍の巡礼","text":"第1武器が槍。武技威力 +18%、攻撃速度 -10%。","unlock":"first_clear"},
 {"id":"ember","name":"残火の巡礼","text":"回避が小さな炎を残す。最大生命 -15。","unlock":"collector"}]
static func empty()->Dictionary:
 return {"legends":[],"enemies":{},"achievements":[],"evades":0,"contracts":0,"start":"blade"}
