# XAUUSD арилжааны хэрэгслүүд

Энэ репозитор нь **XAUUSD** (алт)-д зориулсан арилжааны хэрэгслүүдийг агуулна.

- **TradingView Pine Script v5 индикатор** (`tradingview/XAU_Footprint_Pro.pine`): footprint-ийн ойролцоо тооцоо, volume profile (**POC / VAH / VAL**), Доугийн онолын трэнд, Фибоначчийн бүс, buy/sell дохио.
- **TradingView Pine Script v6 all-in-one индикатор** (`tradingview/Orochi_Style_AllInOne.pine`): anchored VWAP, TPO, түвшин, volume delta. Тайлбар доорх хэсэгт, англи + монголоор.
- **MT5 Expert Advisor** (`mt5/VP_Dow_EA.mq5`): volume profile болон Доугийн трэнд ашиглан оролт хийнэ. Суулгалт, компайл, Strategy Tester болон тохиргооны тайлбар `mt5/README_mn.md` файлд байна.
- **Algo-breeder стратеги** (`tradingview/strategies/`, `mt5/experts/`): XAU Bred #1, #2, #3. Товч тайлбар `tradingview/strategies/README.md`, судалгааны тайлан `research/algo-breeder/REPORT.md`.

## Хавтасны бүтэц

```
.
├── README.md
├── tradingview/
│   ├── XAU_Footprint_Pro.pine       # Pine v5 индикатор
│   ├── Orochi_Style_AllInOne.pine   # Pine v6 all-in-one
│   └── strategies/                  # XAU Bred #1–#3 (Pine v5)
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

`tradingview/Orochi_Style_AllInOne.pine` — XAUUSD-д зориулж эхнээс нь бичсэн **Pine Script v6** all-in-one индикатор. TradingView-ийн компайлер дээр **0 алдаатай** компайлсан. Orochi Trading-тай холбоогүй, өөрийн код.

### English

An original all-in-one overlay for **XAUUSD**:

- Anchored VWAPs for the day, week, month, quarter, and year (**D / W / M / Q / Y**), with **±1σ / ±2σ / ±3σ** bands
- Rolling VWAPs (7D, 30D, 90D, 365D)
- TPO / market profile: **POC**, **VAH**, **VAL**, single prints, and naked POCs
- Key levels: previous day high/low (**PDH / PDL**), previous week high/low (**PWH / PWL**), monthly and yearly opens, and Asia / London / New York session highs and lows
- Volume-delta bubbles and tiered bar coloring
- Optional signals and alerts (off by default)

**Add it to a chart**

1. Open [TradingView](https://www.tradingview.com) and an **XAUUSD** chart.
2. Open **Pine Editor** at the bottom of the chart.
3. Paste the full contents of `tradingview/Orochi_Style_AllInOne.pine`.
4. Click **Save**, then **Add to chart**.

**Limitation:** XAUUSD volume on TradingView is **tick volume** (the count of price changes). Delta, bubbles, and bar colors are calculated from that tick volume.

### Монгол

**XAUUSD**-д зориулсан эх all-in-one индикатор:

- Өдөр, долоо хоног, сар, улирал, жилийн anchored VWAP (**D / W / M / Q / Y**) болон **±1σ / ±2σ / ±3σ** зурвас
- Rolling VWAP (7D, 30D, 90D, 365D)
- TPO профайл: **POC**, **VAH**, **VAL**, single print, naked POC
- Гол түвшнүүд: өмнөх өдрийн өндөр/доод (**PDH / PDL**), өмнөх долоо хоногийн өндөр/доод (**PWH / PWL**), сарын болон жилийн нээлт, Asia / London / New York сешний өндөр/доод
- Volume-delta бөмбөлөг болон түвшингээр будсан баар
- Сонголтот дохио болон alert (анхдагчаар унтраалттай)

**Чарт дээр нэмэх**

1. [TradingView](https://www.tradingview.com) дээр **XAUUSD** чарт нээнэ.
2. Чартны доод хэсэгт **Pine Editor**-ийг нээнэ.
3. `tradingview/Orochi_Style_AllInOne.pine` файлын кодыг бүхэлд нь хуулж буулгана (**paste**).
4. **Save** дарж хадгалаад **Add to chart** дарна.

**Хязгаарлалт:** TradingView дээрх XAUUSD-ийн volume нь **tick volume** (үнийн өөрчлөлтийн тоо). Delta, бөмбөлөг, баарын өнгө энэ tick volume-аас тооцогдоно.

## TradingView дээр индикатор нэмэх

1. [TradingView](https://www.tradingview.com)-д нэвтэрч **XAUUSD** чарт нээнэ. Зөвлөмж: 1м, 5м эсвэл 15м.
2. Чартны доод хэсэгт **Pine Editor**-ийг нээнэ.
3. `tradingview/XAU_Footprint_Pro.pine` файлын кодыг бүхэлд нь хуулж, редактор дахь хуучин кодыг солино.
4. **Save** дарж нэр өгөөд **Add to chart** дарна. Индикатор чарт дээр POC, VAH, VAL, Фибоначчийн бүс, footprint хүснэгт болон BUY/SELL дохиог харуулна.
5. Дохиогоор сэрэмжлүүлэг авах бол индикаторын нэр дээр баруун товч → **Add alert on…** → **BUY дохио** эсвэл **SELL дохио**.

## Анхааруулга

Үр дүн баталгаагүй. Өмнөх үр дүн ирээдүйн ашгийг баталдаггүй. Бодит мөнгөөр ашиглахаас өмнө **демо данс** дээр (MT5 бол эхлээд Strategy Tester, дараа нь демо) туршина уу. Арилжаа алдагдалд хүргэж болно.
