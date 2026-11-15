# Quantum AI — нэг Pine Script v6 индикатор

`tradingview/QuantumAI_XAU.pine`

Энэ нь Cloud Chamber / Quantum AI-ийн олон нийтийн модулийн жагсаалт, самбарын нэр, 30 хуудас гарын авлагад тулгуурласан **өөрийн** хувилбар. Худалдааны скрипт биш. Захиалга өгдөггүй. Санхүүгийн зөвлөгөө биш.

Нэг файл. Осциллятор доод цонхонд, үнийн зургууд чарт дээр (`force_overlay`).

## Суулгах (TradingView)

1. [TradingView](https://www.tradingview.com) дээр **XAUUSD**, **XAGUSD**, **BTCUSD** эсвэл **NAS100 / US100** чарт нээнэ.
2. Доод талын **Pine Editor**-ийг нээнэ.
3. `tradingview/QuantumAI_XAU.pine` файлыг бүхэлд нь хуулж редакторт буулгана.
4. **Save**, дараа нь **Add to chart**.
5. Доод цонхонд Resonance Distributor (ягаан/цэнхэр үүл, ногоон/улаан багана) гарна. POC, захиалгын блок, шошго, баруун талын хүснэгт үнийн чарт дээр байна.
6. Дохионы сэрэмж: индикаторын нэр → **Add alert** → Buy / Sell гэх мэт. Мессеж нь webhook-д тохирно: `QAI {{ticker}} Buy confirmed @ {{close}}`.

## Юу харагдах вэ

- **Resonance Engine** (баруун дээд): Volume Profile, Momentum Trend, Core Resonance, Market Bias.
- **Scalp / Swing / Range самбар**: AI Stance, лааны үе, 5 мөрт радар, Core Analytics, Signal Tracker, 7 алхам, позиц.
- **Термометр** (баруун доод): сүүлийн 50 хаагдсан баарын мужид үнэ хаана байгаа.
- Баруун талд volume profile, POC / VAH / VAL, **Core cost** ба **Liquidity** бүс (их хэмжээтэй түвшин).
- Buy / Sell, Trend Bull / Bear, BOS / CHoCH, OB, FVG, sweep, False / Valid Break, Entry / SL / TP1–TP3 / trailing.

## Лааны 4 үе

| Үе | Утга |
|---|---|
| Expansion | Бие/муж ≈ 0.6-аас их, муж ATR-ын ≈ 1.2 дахин. Хурдан шилжилт. |
| Consolidation | Нарийн муж, чиглэлгүй, давхцсан баар. |
| Retracement | Expansion-ийн дараа эсрэг тийш сул, жижиг биетэй, эхлэлийн үнийг эвдээгүй. |
| Reversal | CHoCH эсвэл expansion-ийн эхлэлийг эвдсэн эсрэг хөдөлгөөн. |

Энэ үе **AI Stance** мөрийг тэжээнэ. Жишээ: `Expansion - Look For Longs`, `Retracement - Sell Rallies`, `Consolidation - Cash is King`, `Reversal - Wait For Confirmation`.

## Шүүлт

Баталгаат Buy/Sell зөвхөн хаагдсан баар дээр. Нэмж: хэмжээ дунджаас доош бол (дуу чимээ) ордоггүй, олон цагийн радарын дор хаяж 3 мөр чиглэлтэй таарна (унтрааж болно), итгэл 60-аас дээш, резонанс таарна, сешн нээлттэй.

7 алхам: 7 = бүтэн хэмжээ, 5–6 = хагас, 4 = 30%, түүнээс бага эсвэл 1/3/4/6-р алхам унавал — хүлээ.

## Тэмдэгтийн пресет

Нэрэнд `XAU`/`GOLD`, `XAG`/`SILVER`, `BTC`, `NAS`/`US100`/`USTEC`/`NDX` байвал автоматаар. **Manual** унтраана. 0 гэсэн оролт пресетийг үлдээнэ.

| | Алт | Мөнгө | BTC | Nasdaq |
|---|---|---|---|---|
| SL | 1.50 ATR | 1.85 ATR | 2.00 ATR | 1.70 ATR |
| TP1 / TP2 / TP3 | 0.75 / 1.50 / 2.25 R | 0.70 / 1.40 / 2.20 R | 1.00 / 2.00 / 3.50 R | 0.75 / 1.50 / 2.25 R |
| Сешн | Лондон 08:00–17:00 эсвэл Нью-Йорк 08:00–17:00 | адил | 24 цаг | Нью-Йоркийн касс 09:30–16:00 |

Сешний гадна шинэ Buy/Sell гардаггүй. Бүтэц зурагдсаар байна.

## Дахин будахгүй

Дохио, шошго, бүс зөвхөн **баар хаагдсаны дараа**. Шошгыг дараа нь зөөдөггүй. `request.security` нь `lookahead_off`, дээд цагийн `[1]` (хаагдсан) утга. Идэвхтэй OB/FVG баруун ирмэгээрээ сунаад, цохигдвол зогсоно. Профайл шинэ баар хаагдахад нэг удаа шинэчлэгдэнэ. TradingView 500 шошгоос хэтэрвэл хамгийн хуучныг нь хасдаг.

---

# Quantum AI — one Pine Script v6 indicator

`tradingview/QuantumAI_XAU.pine`

An original script. It follows the public Cloud Chamber / Quantum AI module list, panel names, and the 30-page dual-module guide. It is not that product and it does not place orders.

One file. The Resonance Distributor oscillator sits in the script pane. Price drawings and the dashboard use `force_overlay`, so they stay on the chart.

## Add it on TradingView

1. Open a chart for **XAUUSD**, **XAGUSD**, **BTCUSD**, or **NAS100 / US100**.
2. Open the **Pine Editor** at the bottom.
3. Paste the whole of `tradingview/QuantumAI_XAU.pine`.
4. **Save**, then **Add to chart**.
5. The lower pane is the oscillator (violet/cyan cloud and green/red momentum bars). Order blocks, the right-hand profile, and the tables are on the price chart.
6. Alerts: indicator name → **Add alert** → pick a condition. Messages are webhook-friendly, for example `QAI {{ticker}} Buy confirmed @ {{close}}`.

## What you see

- **Resonance Engine** (top right): Volume Profile, Momentum Trend, Core Resonance, Market Bias (`Resonance Bull`, `Resonance Bear`, or `Waiting`).
- **Mode panel**: AI Stance, candle phase, five-row radar, core analytics, signal tracker, 7-step checklist, position.
- **Thermometer** (bottom right): where price sits in the last 50 closed bars. Below 40% is Bearish Markdown, 40–60% is Equilibrium Zone, above 60% is Bullish Markup.
- Right-side volume profile with **POC / VAH / VAL**. Bins near the heaviest row are **Core cost** (the POC band) or **Liquidity** (other stacked high-volume rows).
- Buy / Sell, Trend Bull / Bear, BOS / CHoCH, internal and swing order blocks, FVG, premium / discount / equilibrium, liquidity sweeps, False Break / Valid Break, Entry / SL / TP1–TP3. After a closed bar trades through TP1 the trail moves to entry, then ratchets. An opposite signal, opposite CHoCH, valid break, or resonant sweep marks the old plan **Invalid** and removes its targets.

## Four candle phases

| Phase | Rule |
|---|---|
| Expansion | Body/range at least about 0.6 and range at least about 1.2 × ATR. Fast displacement. |
| Consolidation | Narrow versus ATR, little net move. |
| Retracement | After an expansion, a weak opposite move with a small body that does not break the expansion origin. |
| Reversal | CHoCH, or a close through the expansion origin. |

The phase is the AI Stance line: `Expansion - Look For Longs`, `Expansion - Look For Shorts`, `Retracement - Buy Dips`, `Retracement - Sell Rallies`, `Consolidation - Cash is King`, `Reversal - Wait For Confirmation`. Optional background tint and a label when the phase changes.

## Filters

A confirmed Buy or Sell needs a closed bar, dual-factor resonance (range location and RSI on the same side of 45/55), WaveTrend not past ±60, confidence at least 60, the cooldown, an open session, volume at least the preset multiple of its 20-bar average (this drops scattered noise), and, unless you turn it off, at least 3 radar rows in the same direction.

Checklist size: 7 passes = full, 5–6 = half, 4 = light 30%. Fewer than that, or a hard fail on steps 1, 3, 4, or 6, means stand aside.

## Symbol presets

Detected from the ticker text, so broker-style names still match. **Manual preset** ignores detection. An input left at 0 keeps the preset; a number you type replaces that one field.

| | Gold | Silver | Bitcoin | Nasdaq |
|---|---|---|---|---|
| Match | `XAU`, `GOLD` | `XAG`, `SILVER` | `BTC` | `NAS`, `US100`, `USTEC`, `NDX` |
| Stop | 1.50 × ATR | 1.85 × ATR | 2.00 × ATR | 1.70 × ATR |
| Stop band | 0.60–2.50 ATR | 0.85–3.00 ATR | 1.00–3.50 ATR | 0.75–2.80 ATR |
| TP1 / TP2 / TP3 | 0.75 / 1.50 / 2.25 R | 0.70 / 1.40 / 2.20 R | 1.00 / 2.00 / 3.50 R | 0.75 / 1.50 / 2.25 R |
| Trail after TP1 | 1.20 × ATR | 1.40 × ATR | 1.80 × ATR | 1.30 × ATR |
| Extra cooldown | 0 | +2 bars | +2 | +1 |
| Profile rows | 28 | 32 | 36 | 24 |
| Quiet-volatility cut | percentile 20 | 25 | 15 | 22 |
| Min volume vs average | 0.80 | 0.90 | 0.70 | 0.85 |
| Session | London 08:00–17:00 or New York 08:00–17:00 | same | none | New York cash 09:30–16:00 |

Sessions use those clocks, not a broker server offset. Outside the session, new Buy/Sell labels are not created.

## No future data

Signals, labels, and zones are decided only after the bar closes. A signal label is not moved later. Higher-timeframe values use `request.security` with `lookahead_off` and the previous closed higher-timeframe bar (`[1]`). Active order blocks and gaps extend to the right until price mitigates them, then the right edge stays. The profile and the cost/liquidity bands are rebuilt once when a new bar closes, from that closed window. TradingView keeps at most 500 labels; past that, only the oldest are dropped.

## Alerts

Buy, Sell, Trend Bull, Trend Bear, BOS both ways, CHoCH both ways, bullish and bearish order-block break, bullish and bearish order-block retest, channel breakout up, channel breakdown, resistance break, support break, volatility explosion, TP1 break-even. Also liquidity sweep, sweep with resonance, false breakout, and reversal phase.

## Formulas

No vendor source was used. Nadaraya–Watson rational quadratic (endpoint), LazyBear WaveTrend, Wilder RSI and ADX, Bollinger inside Keltner for the squeeze, a 70% value area grown from the heaviest bin, and public SMC pivot rules (internal length 5, swing length from the mode). The confidence weights and the R multiples are this script's estimate, checked against the published screenshots.
