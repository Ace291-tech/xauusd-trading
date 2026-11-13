# XAUUSD арилжааны хэрэгслүүд

Энэ репозитор нь **XAUUSD** (алт)-д зориулсан арилжааны хэрэгслүүдийг агуулна.

- **TradingView Pine Script v5 индикатор** (`tradingview/XAU_Footprint_Pro.pine`): footprint-ийн ойролцоо тооцоо, volume profile (**POC / VAH / VAL**), Доугийн онолын трэнд, Фибоначчийн бүс, buy/sell дохио.
- **TradingView Pine Script v6 all-in-one** (`tradingview/Orochi_Style_AllInOne.pine`) болон доод цонхны дельта (`tradingview/Orochi_Style_Delta_Pane.pine`). Тайлбар доор, англи + монгол.
- **MT5 Expert Advisor** (`mt5/VP_Dow_EA.mq5`): volume profile болон Доугийн трэнд ашиглан оролт хийнэ. Суулгалт, компайл, Strategy Tester болон тохиргооны тайлбар `mt5/README_mn.md` файлд байна.
- **Algo-breeder стратеги** (`tradingview/strategies/`, `mt5/experts/`): XAU Bred #1, #2, #3. Товч тайлбар `tradingview/strategies/README.md`, судалгааны тайлан `research/algo-breeder/REPORT.md`.

## Хавтасны бүтэц

```
.
├── README.md
├── tradingview/
│   ├── XAU_Footprint_Pro.pine         # Pine v5 индикатор
│   ├── Orochi_Style_AllInOne.pine     # Pine v6 all-in-one
│   ├── Orochi_Style_Delta_Pane.pine   # Pine v6 дельта цонх
│   └── strategies/                    # XAU Bred #1–#3 (Pine v5)
├── mt5/
│   ├── VP_Dow_EA.mq5             # Expert Advisor
│   ├── experts/                  # XAU Bred #1–#3 (MQL5)
│   └── README_mn.md              # EA-ийн монгол тайлбар
└── research/
    └── algo-breeder/REPORT.md    # breeder-ийн судалгааны тайлан
```

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
