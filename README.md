# XAUUSD арилжааны хэрэгслүүд

Энэ репозитор нь **XAUUSD** (алт)-д зориулсан арилжааны хэрэгслүүдийг агуулна.

- **TradingView Pine Script v5 индикатор** (`tradingview/XAU_Footprint_Pro.pine`): footprint-ийн ойролцоо тооцоо, volume profile (**POC / VAH / VAL**), Доугийн онолын трэнд, Фибоначчийн бүс, buy/sell дохио.
- **TradingView Pine Script v6 all-in-one** (`tradingview/Orochi_Style_AllInOne.pine`) болон доод цонхны дельта (`tradingview/Orochi_Style_Delta_Pane.pine`). Тайлбар доор, англи + монгол.
- **MT5 Expert Advisor** (`mt5/VP_Dow_EA.mq5`): volume profile болон Доугийн трэнд ашиглан оролт хийнэ. Суулгалт, компайл, Strategy Tester болон тохиргооны тайлбар `mt5/README_mn.md` файлд байна.
- **Algo-breeder стратеги** (`tradingview/strategies/`, `mt5/experts/`): XAU Bred #1, #2, #3. Товч тайлбар `tradingview/strategies/README.md`, судалгааны тайлан `research/algo-breeder/REPORT.md`.
- **Quantum AI (TradingView, Pine v6, нэг скрипт)**: `tradingview/QuantumAI_XAU.pine`. Суулгалт, үе, пресет: `tradingview/QuantumAI_README.md` (монгол + англи). Cloud Chamber бүтээгдэхүүн биш.
- **Quantum AI XAU (өөрийн хувилбар, MT5)**: `mt5/indicators/`. Тайлбар доор. Cloud Chamber бүтээгдэхүүн биш.

## Хавтасны бүтэц

```
.
├── README.md
├── tradingview/
│   ├── XAU_Footprint_Pro.pine         # Pine v5 индикатор
│   ├── Orochi_Style_AllInOne.pine     # Pine v6 all-in-one
│   ├── Orochi_Style_Delta_Pane.pine   # Pine v6 дельта цонх
│   ├── QuantumAI_XAU.pine             # Pine v6 Quantum AI (chart + oscillator)
│   ├── QuantumAI_README.md            # Quantum AI суулгалт, монгол + англи
│   └── strategies/                    # XAU Bred #1–#3 (Pine v5)
├── mt5/
│   ├── VP_Dow_EA.mq5             # Expert Advisor
│   ├── experts/                  # XAU Bred #1–#3 (MQL5)
│   ├── indicators/
│   │   ├── QuantumAI_XAU.mq5         # chart overlay
│   │   ├── QuantumAI_Oscillator.mq5  # resonance subwindow
│   │   └── QuantumAI_Math.mqh        # shared formulas
│   └── README_mn.md              # EA-ийн монгол тайлбар
└── research/
    └── algo-breeder/REPORT.md    # breeder-ийн судалгааны тайлан
```

## Quantum AI on TradingView

The chart script is **`tradingview/QuantumAI_XAU.pine`**. Paste it in the Pine Editor, **Save**, **Add to chart**. The oscillator opens under the price; labels, zones, the profile, and the tables are drawn on the chart. Install steps, the four candle phases, symbol presets, and the non-repaint rules are in **`tradingview/QuantumAI_README.md`** (Mongolian and English).

## Quantum AI XAU (original MT5 build)

This is an original indicator pair. It follows the public module list, panel names, and the 30-page dual-module guide from [cloudchamber.zhtde.com](https://cloudchamber.zhtde.com/features). It is not the vendor's invite-only script, and it does not place orders.

| File | Role |
|---|---|
| `mt5/indicators/QuantumAI_XAU.mq5` | Chart overlay: labels, SMC, profile, risk lines, both panels, thermometer |
| `mt5/indicators/QuantumAI_Oscillator.mq5` | Subwindow: cyan/violet structural cloud and green/dark-red momentum bars |
| `mt5/indicators/QuantumAI_Math.mqh` | Shared closed-bar formulas |

### Install on MT5 (Mac, Wine, or Windows)

1. In MetaTrader 5 choose **File → Open Data Folder**.
2. Copy the three files into `MQL5/Indicators/`. Keep them in the same folder so the `.mqh` include resolves.
3. Open MetaEditor (**F4**), open `QuantumAI_XAU.mq5`, press **F7**. Repeat for `QuantumAI_Oscillator.mq5`. Both should report **0 errors**.
4. On an **XAUUSD** chart: Navigator → Indicators → **Quantum AI XAU**. Then add **QAI Resonance** in a subwindow under the price. MT5 draws subwindows below the chart; the vendor's TradingView layout puts that pane on top.
5. Alerts: right-click the chart → **Expert list / Alerts**, or rely on the indicator's `Alert`, mobile push, and optional email. For Telegram, set **Webhook URL** to `https://api.telegram.org/bot<token>/sendMessage`, set **Chat id**, and add that URL under **Tools → Options → Expert Advisors → Allow WebRequest**. Some builds only allow `WebRequest` from Expert Advisors; push and `Alert` still work from the indicator.
6. Demo first. This is not financial advice.

### What the panels mean

**Resonance Engine** (top right). Independent signals are the volume-profile location (percent of profile volume at or below price) and RSI(14). **Core Resonance** is their average. **Market Bias** is `Resonance Bull` or `Resonance Bear` only when both factors sit on the same side of 45/55. Otherwise it says `Waiting`. A confirmed Buy/Sell is allowed only when this bias matches the trigger.

**Scalp / Swing / Range panel.** The mode renames the header. Ultra-short is **Scalp Mode**.

- **AI Stance** is the Wyckoff phase plus the local direction: `Bear Distribution - Sell Rallies`, `Bull Accumulation - Buy Dips`, `Strong Bullish - Look For Longs`, `Strong Bearish - Look For Shorts`, `Coiling - Wait For Break`, `Neutral Bias - Cash is King`.
- **Multi-TF Radar** reads the last **closed** bar of M15, M30, H1, H4, and D1 (the rows are inputs). Trend bias is an EMA(21)/EMA(55) stack. A tight coil near the slow EMA is `Tight Consolidation` and counts as no sign, so it breaks a unanimous **HTF Resonance**. Momentum strength is `|RSI-50| * 2`, bucketed at 32 and 22.
- **Core Analytics**: HTF resonance (all five signs agree), Kaufman efficiency / ADX regime, Bollinger-vs-Keltner volatility (`Compression`, `Stable`, `Explosion (Breakout)`, `Expansion`), and 50-bar candle volume split (`Bulls in Control (n%)` and the stronger `Dominant` wording).
- **Signal Tracker**: latest label, live confidence, Wilder ADX, engine `Ready` or `Cooling`, and how many of the 8 filter tiers pass.
- **7-step checklist** (from the dual-module guide) and the size line: 7 passes = full, 5–6 = half, 4 = light 30%, fewer or a hard fail on steps 1, 3, 4, or 6 = stand aside. Steps 1–4 are the gates. Step 5 warns (does not pass) when H4 and D1 oppose a 3-row run. Step 6 fails a long above 80% and a short below 20%.
- **Position Status** is a virtual plan only. **Active Stop** is the trailing stop.

**Price thermometer.** Where the live price sits inside the high-low of the last 50 **closed** bars. Below 40% is `Bearish Markdown`, 40–60% is `Equilibrium Zone`, above 60% is `Bullish Markup`. The gradient runs blue to magenta.

**Oscillator.** LazyBear WaveTrend. The slow wave is the white center of a violet/cyan cloud. The histogram is `wt1 - wt2`, lime/green above zero and red/maroon below.

### Labels

| Label | Meaning |
|---|---|
| Trend Bull / Trend Bear | Early warning. Internal CHoCH. Not a permission to trade. |
| Buy / Sell | Confirmed. WaveTrend cross or a **valid** break, dual-factor resonance, WaveTrend not past ±60, causal score ≥ 60, cooldown elapsed. |
| Liquidity Sweep | Wick through the prior swing or internal high/low, close back inside. |
| Sweep + resonance alert | That sweep while volume-location and RSI agree with the reversal. |
| False Break | Sweep, or a close through a level while resonance does **not** agree. Not used as a Buy/Sell trigger. |
| Valid Break | Close through a level and resonance agrees. Can invalidate the opposite plan. |
| Internal / Swing OB | Last extreme candle between the broken pivot and the break. Swing length follows the mode (20 / 50 / 30) unless you override it. |
| BOS / CHoCH, FVG, Premium / Discount / Equilibrium | Standard SMC. Premium is the upper half of the latest swing range. |
| Accumulation, Markup, Distribution, Markdown | Phase label. The same phase feeds AI Stance. |
| Invalid | The previous Entry/TP/SL plan was replaced by an opposite signal, an opposite CHoCH, a resonant sweep, or a valid break the other way. Old TP lines are not kept. |
| Entry, SL, TP1–TP3, Trailing SL | One active plan. TP distances measured off the vendor screenshots are **0.75R, 1.5R, 2.25R**. After a closed bar trades through TP1, the trail moves to entry, then ratchets by ATR. The stop is tested against the trail from **before** the bar. |

Modes: Scalp (internal 5, swing 20, cooldown 4, kernel bandwidth 24), Swing (swing 50, cooldown 8, bandwidth 48), Range (buy only from the lower 30% of the profile, sell from the upper 70%). A structure input set above 0 replaces that mode value.

### Symbol presets

The chart symbol is matched by substring, so broker suffixes still hit (`XAUUSDm`, `XAGUSD.m`, `BTCUSD.pro`, `US100`, `USTEC`, `NAS100`). MOT Capital names are covered by `US100` and `USTEC`. Anything else keeps the generic row. **Manual** (`InpUseManual`) ignores detection and uses the generic numbers, unless you type a non-zero risk field or a session hour pair.

Session hours are **broker server time**. On a typical EET/EEST server (UTC+2 in winter, UTC+3 in summer) they line up with London through New York, and with the NY cash open, without a daylight-saving table. Set both session hours to override. Set them equal, or use Manual with the hours left at -1, for no session filter. Outside the session the engine says `Session closed` and no new Buy/Sell is created. Structure, sweeps, and the thermometer keep drawing.

A risk or profile input left at **0** keeps the preset. A number you type replaces that one field only.

| | Gold `XAU` / `GOLD` | Silver `XAG` / `SILVER` | Bitcoin `BTC` | Nasdaq `NAS` / `US100` / `USTEC` / `NDX` | Generic / Manual |
|---|---|---|---|---|---|
| Why | The published screenshots are gold. Stops match the 0.75R / 1.5R / 2.25R ladder. | Wider wicks than gold, smaller dollar price, so the stop and the profile are finer. | Large spikes, trends that run, no session. | Cash-open spikes, then a regular session. | Unknown symbol, or Manual. |
| SL | 1.50 × ATR | 1.85 × ATR | 2.00 × ATR | 1.70 × ATR | 1.50 × ATR |
| Min / max stop | 0.60–2.50 ATR | 0.85–3.00 ATR | 1.00–3.50 ATR | 0.75–2.80 ATR | 0.60–2.50 ATR |
| TP1 / TP2 / TP3 | 0.75R / 1.50R / 2.25R | 0.70R / 1.40R / 2.20R | 1.00R / 2.00R / 3.50R | 0.75R / 1.50R / 2.25R | 0.75R / 1.50R / 2.25R |
| Trail after TP1 | 1.20 × ATR | 1.40 × ATR | 1.80 × ATR | 1.30 × ATR | 1.20 × ATR |
| Extra cooldown | +0 bars | +2 | +2 | +1 | +0 |
| Profile rows | 28 | 32 | 36 | 24 | 28 |
| Dead volatility | ATR percentile under 20 fails tier 1 | under 25 | under 15 | under 22 | under 20 |
| Expansion ratio | bandwidth > 1.08 × the bar 3 back | 1.12 | 1.05 | 1.10 | 1.08 |
| Session | 10:00–23:00 server, London through NY | same | none (24h) | 16:00–23:00 server, NY cash on an EET server | none |

The Nasdaq window starts at hour 16, so 16:00 inclusive through 22:59. That is about 14:30–21:00 UTC in winter and 13:30–20:00 UTC in summer on an EET server, which is the NY cash session. Gold and silver use 10:00–23:00, about 08:00–21:00 UTC in winter and 07:00–20:00 UTC in summer: London open through the NY afternoon.

### Eight filter tiers

Shown as `n/8`. They score the live direction. They do not delete a label that already passed the confirmation rule.

1. Volatility level: ATR percentile over 100 bars is at least the symbol's dead-volatility line (20 on gold, 25 on silver, 15 on bitcoin, 22 on the Nasdaq).
2. Volume intensity: last closed bar vs 0.8 × its 20-bar average.
3. Momentum limit: WaveTrend not beyond ±60 against the direction.
4. Momentum compression: histogram not shrinking while a squeeze is on.
5. Major cycle: at least 3 radar rows share the direction.
6. Signal cooling: cooldown bars since the last Buy/Sell.
7. Structural inflection: a confirmed label is still inside the fresh-label window.
8. Volatility pattern: Explosion or Expansion in scalp/swing; Compression or Stable in range mode.

### Alerts (21)

Buy, Sell, Trend Bull, Trend Bear, BOS both ways, CHoCH both ways, bullish and bearish OB break, bullish and bearish OB retest, channel breakout both ways, resistance break, support break, volatility explosion, TP1 break-even, liquidity sweep, sweep plus structural resonance, false breakout. History is replayed silently. A popup fires only when a new closed bar produces the event after the indicator is already on the chart.

### Best-estimate formulas and sources

No vendor formula was published, and no leaked or decompiled source was used. Each number is an estimate that uses a public technique and is tuned to the screenshots and the guide.

| Module | Estimate | Source |
|---|---|---|
| Regression curve | Nadaraya–Watson rational quadratic, endpoint form, so a closed bar does not change. Fast curve uses one-third of the bandwidth. | jdehorty, [Nadaraya-Watson: Rational Quadratic Kernel (Non-Repainting)](https://www.tradingview.com/script/AWNvbPRM-Nadaraya-Watson-Rational-Quadratic-Kernel-Non-Repainting/). Formula `K = (1 + d² / (2 α h²))^(-α)`. Reimplemented, not copied. |
| Channel | Rolling linear regression of closes, ±1 residual standard deviation. Fit ends on the previous closed bar so a break is a new close outside that fit. The channel is a live fit; signal labels are not. | Ordinary least squares. |
| Oscillator | `esa = EMA(hlc3, n1)`, `d = EMA(\|hlc3-esa\|, n1)`, `ci = (hlc3-esa) / (0.015 d)`, `wt1 = EMA(ci, n2)`, `wt2 = SMA(wt1, 4)`. | LazyBear, [WaveTrend Oscillator](https://www.tradingview.com/script/2KE8wTuF-Indicator-WaveTrend-Oscillator-WT/). Math reimplemented. |
| Squeeze state | Bollinger 20, 2.0 inside Keltner 20, 1.5 ATR = Compression. Leaving that state = Explosion. Bandwidth expanding = Expansion. Otherwise Stable. | John Carter, *Mastering the Trade*, ch. 11, and LazyBear's public Squeeze Momentum description. BB multiplier is 2.0. |
| ADX / RSI | Wilder. | Welles Wilder, *New Concepts in Technical Trading Systems*. |
| Regime | Kaufman efficiency ratio over 20 closes, with ADX. | Perry Kaufman efficiency ratio. |
| Volume split | Tick volume × `(close-low)/(high-low)`. XAUUSD volume on both platforms is tick volume. | Standard candle approximation. Same idea as this repo's `VP_Dow_EA.mq5`. |
| Volume profile | Uniform tick volume across each bar's high-low, POC = heaviest bin, value area grown from the POC to 70%. The panel score is the percent of that volume at or below price. | Market Profile / volume profile. Implementation follows this repo's EA, not a third-party script. |
| SMC | Internal pivot length 5. A pivot is confirmed only after `length` bars to its right. BOS continues the internal trend; the first break the other way is CHoCH. The order block is the most extreme candle between that pivot and the candle before the break. A wick through the far side mitigates it. FVG is a three-candle gap larger than 0.15 ATR. | Public ICT / SMC rules. LuxAlgo's Smart Money Concepts is CC BY-NC-SA 4.0, so none of that source is included. The pivot length and "extreme candle between the pivot and the break" are the behavior described in public write-ups of that script, reimplemented independently. |
| Liquidity sweep | High trades beyond the stored swing or internal high and the close finishes back below it, or the mirror image at a low. | SMC liquidity sweep. The Facebook notes on the vendor page describe the combined sweep + resonance alert. |
| False vs valid break | Close through the level with resonance in the break's direction = valid. Close through without that resonance, or a wick that closes back inside = false. | Same notes: false breaks are the liquidity ones; valid breaks agree with structure. |
| Confidence | Starts at 20. Adds up to 20 for live resonance, 12 for volume alignment, 12 for ADX, 12 for thermometer location, 14 for radar agreement, 10 for volatility quality. The **label** uses a causal score with no higher-timeframe term, so old Buy/Sell marks do not move when today's radar changes. The **panel** number includes the radar and can differ. | The guide's 0–100 score and the 60-point line. Weights are this build's estimate. |
| Risk | Stop is the swing extreme when that distance is between 0.6 and 2.5 ATR, otherwise `1.5 × ATR`. | The site's dual stop (volatility plus structure). The R multiples are measured from the published screenshots. |
| Checklist and size | Seven questions and the full / half / 30% / stand-aside table. | *Cloud Cabin · Quantum AI Dual-Module Trading System*, 30 pages, supplied with this task. |
| Three engines, eight tiers, four phases, 3 modes | Names and pass/fail rules above. | Vendor site (home, toolkits, features, risk, FAQ), the 17-page product PDF, and the Facebook notes in the task. |

Higher-timeframe reads use `CopyRates` from shift 1, so the forming higher-timeframe bar is not included. Chart signals use only bars that have already closed.

## XAU Bred стратеги (#1, #2, #3)

- **#1** ба **#2** нь **XAUUSD H1** дээр ажиллана.
- **#3** нь **XAUUSD H4** дээр ажиллана.
- MQL5 EA-уудыг MetaEditor дээр **0 errors**-той компайлсан.
- Зөвхөн **демо / тест**. Санхүүгийн зөвлөгөө биш.

## Orochi-Style All-In-One

Two original **Pine Script v6** scripts for **XAUUSD**. Both compiled on TradingView’s compiler with **0 errors**. They are not an Orochi Trading product.

| File | Where it sits |
|---|---|
| `tradingview/Orochi_Style_AllInOne.pine` | Overlay on the price chart |
| `tradingview/Orochi_Style_Delta_Pane.pine` | Separate lower pane (`overlay = false`) |

**Add either script:** Pine Editor → paste the whole file → **Save** → **Add to chart**. Add the pane script the same way; it opens under the price chart.

### English

**Look.** Theme is **Dark** or **Light**. Label size defaults to **Medium**. Primary levels are thin solid lines, mids and previous bands are dotted, sessions are dashed. Lines stop a short distance to the right of the last bar. Labels use a monospace font, a translucent background, and sit in one right-hand column. Nearby prices merge as `A / B`, and matching VWAP bands merge as `M / Q VAH`. Prices use the symbol mintick with thousands separators. Volume and delta use K/M suffixes. The delta table is a dark translucent panel with a header row.

**VWAP.** Source is `hlc3`. The mean line is the anchored VWAP (D/W/M/Q/Y). **±1σ is the VAH/VAL band and is filled.** **±2σ is on and is not filled.** ±3σ is off until you enable it. Short labels look like `wVAH` and `pwVWAP`. **Labels only** hides the VWAP lines and keeps the tags. A faint box marks the previous period’s value area.

**TPO.** Value area defaults to **68%**. Blocks are **30 minutes**. Several completed profiles are drawn, plus the developing profile on the right. Single prints are filled purple and extend until price trades back through them. Labels look like `PD VAH (2,345.20)`. On a daily profile you can also show **PW** and **PM** levels. Excess and poor high/low markers are off until you turn them on. Naked POCs drop off once price touches them.

**Key levels.** Daily is blue, weekly is green, monthly and quarterly are red, yearly is white (dark gray on the Light theme). Previous mids are dotted. Naked opens keep at most **5** per timeframe and disappear once touched.

**Delta.** The default threshold is **Relative**: the mean absolute delta of the last **20** bars, with tiers at **1.5× / 2.5× / 3.5×**. **Z-score** (length 50) and **SMA** (length 300) are optional. Spikes recolor the candles. Bubbles mark the spike; the latest ones also print the delta. The lower pane draws delta as columns around zero and CVD as candles. Open interest is crypto-perpetual only: a change must be at least **5×** the recent mean, OI RSI uses length **20**, and the read is new longs, new shorts, shorts closing, or longs closing.

**Auto-adapt** is on by default. Inputs at the bottom (`5m`, `1H`, `4H`, `D`, `MN`) override that preset. Turn Auto-adapt off to use the global toggles instead.

| Chart | Also used for | VWAP | Levels | TPO | Volume profile |
|---|---|---|---|---|---|
| **5m** | 1m, 3m, 15m, 30m | Daily + Weekly | PDH/PDL, daily open, Asia/London/NY | Daily, 30-minute blocks | Asia, London, and NY profiles, plus the current day |
| **1H** | 2H, 3H | Daily + Weekly | PDH/PDL, daily open, sessions | Daily | One daily profile per day, last N days |
| **4H** | 6H, 8H, 12H | Weekly + Monthly | PDH/PDL and PWH/PWL, sessions off | Weekly | Weekly profiles |
| **Daily** | 2D, 3D, Weekly | Monthly + Quarterly + Yearly | Weekly and monthly levels, sessions off | Monthly | Monthly profiles |
| **Monthly** | 3M, 6M, 12M | Yearly only | Yearly open and prior-year high/low | Off | Yearly profiles |

Each preset sets its own row count, value-area percent, colors, past-profile count, label size, line length, and delta tier. Optional signals and alerts stay off until enabled.

**Limitation:** XAUUSD volume on TradingView is **tick volume** (how often the price changes). Delta, bubbles, bar colors, and volume profiles are built from that tick volume.

### Монгол

**Харагдац.** **Theme** нь Бараан эсвэл Цайвар. **Label size** анхдагч нь **Medium**. Гол түвшин нарийн бүтэн шугам, дундаж ба өмнөх зурвас тасархай цэг, сешн тасархай зураас. Шугамууд сүүлийн баараас баруун тийш богино. Шошго нь monospace, бүдэг дэвсгэртэй, үнийн тэнхлэгийн ойролцоо нэг баганад сууна. Ойр үнэ `A / B` болж нийлнэ. Ижил VWAP зурвас `M / Q VAH` гэж нийлнэ. Үнэ mintick-ээр, мянгатын таслалтай. Хэмжээ ба дельта K/M-ээр. Дельта хүснэгт нь бараан тунгалаг, толгой мөртэй.

**VWAP · Хэмжээстэй дундаж үнэ.** Эх үнэ `hlc3`. Дундаж шугам нь тухайн үеэс (өдөр, долоо хоног, сар, улирал, жил) тооцсон VWAP. **±1σ нь VAH/VAL бөгөөд дүүргэлттэй.** **±2σ асаалттай, дүүргэлтгүй.** ±3σ унтраалттай. Шошго `wVAH`, `pwVWAP` мэт богино. **Зөвхөн шошго** горим шугамыг нууж шошгыг үлдээнэ. Өмнөх үеийн үнийн бүс бүдэг хайрцагаар гарна.

**TPO · Цагийн профайл.** Үнийн бүс **68%**. Блок **30 минут**. Хэд хэдэн хаагдсан профайл, дээр нь баруун талд хөгжиж буй профайл. Нэг хэвлэл (single print) ягаанаар дүүрч, үнэ буцаж туулах хүртэл сунана. Шошго `PD VAH (2,345.20)` хэлбэртэй. Өдрийн профайл дээр **PW** (өмнөх долоо хоног) ба **PM** (өмнөх сар) түвшин нэмж болно. Илүүдэл ба сул орой/ёроол анхдагчаар унтраалттай. Хөндөгдөөгүй POC үнэ дахин хүрвэл арилна.

**Гол түвшин.** Өдөр цэнхэр, долоо хоног ногоон, сар ба улирал улаан, жил цагаан (цайвар загварт бараан саарал). Өмнөх дундаж тасархай цэг. Нүцгэн нээлт үе бүр дээр хамгийн ихдээ **5**, хүрвэл арилна.

**Дельта.** Анхдагч босго **Relative**: сүүлийн **20** баарын үнэмлэхүй дельтагийн дундаж, шат **1.5 / 2.5 / 3.5 дахин**. **Z-score** (урт 50) ба **SMA** (урт 300) сонголттой. Огцом дельта лааг будна. Бөмбөлөг гарч, сүүлийн хэдэн дээр нь тоо бичигдэнэ. Доод цонхонд дельта тэг орчим багана, CVD лаа байна. Нээлттэй сонирхол зөвхөн крипто перпетуал дээр: өөрчлөлт нь сүүлийн дунджаас **5 дахин** их, OI RSI урт **20**. Тайлбар: OI өсөж дельта эерэг = шинэ лонг, OI өсөж дельта сөрөг = шинэ шорт, OI буурч дельта эерэг = шорт хаагдаж байна, OI буурч дельта сөрөг = лонг хаагдаж байна.

**Автоматаар цагт тааруулах** анхдагчаар асаалттай. Доод талын `5m`, `1H`, `4H`, `D`, `MN` бүлэг тухайн цагийн пресетийг тус тусад нь өөрчилнө. Унтраавал ерөнхий сэлгүүр үйлчилнэ.

| Чарт | Мөн эдгээр цагт | VWAP | Түвшин | TPO | Хэмжээний профайл |
|---|---|---|---|---|---|
| **5м** | 1м, 3м, 15м, 30м | Өдөр + долоо хоног | PDH/PDL, өдрийн нээлт, Ази/Лондон/Нью-Йорк | Өдөр, 30 минутын блок | Ази, Лондон, Нью-Йорк тус бүр, нэмэх өнөөдөр |
| **1ц** | 2ц, 3ц | Өдөр + долоо хоног | PDH/PDL, өдрийн нээлт, сешн | Өдөр | Өдөр бүр нэг профайл, сүүлийн N өдөр |
| **4ц** | 6ц, 8ц, 12ц | Долоо хоног + сар | PDH/PDL ба PWH/PWL, сешн унтарсан | Долоо хоног | Долоо хоногийн профайлууд |
| **Өдөр** | 2 өдөр, 3 өдөр, долоо хоног | Сар + улирал + жил | Долоо хоног ба сарын түвшин, сешн унтарсан | Сар | Сарын профайлууд |
| **Сар** | 3 сар, 6 сар, 12 сар | Зөвхөн жил | Жилийн нээлт, өмнөх жилийн өндөр/доод | Унтарсан | Жилийн профайлууд |

Пресет бүр мөрийн тоо, үнийн бүсийн хувь, өнгө, өмнөх профайлын тоо, шошгын хэмжээ, шугамын урт, дельтагийн шатыг тусад нь өгнө. Дохио ба alert анхдагчаар унтраалттай.

**Хязгаарлалт:** TradingView дээрх XAUUSD-ийн volume нь **тик хэмжээ** (үнийн өөрчлөлтийн тоо). Дельта, бөмбөлөг, лааны өнгө, хэмжээний профайл энэ тик хэмжээнээс тооцогдоно.

**Нэмэх**

1. [TradingView](https://www.tradingview.com) дээр **XAUUSD** чарт нээнэ.
2. **Pine Editor**-ийг нээнэ.
3. `tradingview/Orochi_Style_AllInOne.pine` файлыг бүхэлд нь буулгана.
4. **Save**, дараа нь **Add to chart**.
5. Доод цонх хэрэгтэй бол `tradingview/Orochi_Style_Delta_Pane.pine` файлыг мөн адил нэмнэ.

## TradingView дээр индикатор нэмэх

1. [TradingView](https://www.tradingview.com)-д нэвтэрч **XAUUSD** чарт нээнэ. Зөвлөмж: 1м, 5м эсвэл 15м.
2. Чартны доод хэсэгт **Pine Editor**-ийг нээнэ.
3. `tradingview/XAU_Footprint_Pro.pine` файлын кодыг бүхэлд нь хуулж, редактор дахь хуучин кодыг солино.
4. **Save** дарж нэр өгөөд **Add to chart** дарна. Индикатор чарт дээр POC, VAH, VAL, Фибоначчийн бүс, footprint хүснэгт болон BUY/SELL дохиог харуулна.
5. Дохиогоор сэрэмжлүүлэг авах бол индикаторын нэр дээр баруун товч → **Add alert on…** → **BUY дохио** эсвэл **SELL дохио**.

## Анхааруулга

Үр дүн баталгаагүй. Өмнөх үр дүн ирээдүйн ашгийг баталдаггүй. Бодит мөнгөөр ашиглахаас өмнө **демо данс** дээр (MT5 бол эхлээд Strategy Tester, дараа нь демо) туршина уу. Арилжаа алдагдалд хүргэж болно.
