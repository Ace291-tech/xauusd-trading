# XAUUSD арилжааны хэрэгслүүд

Энэ репозитор нь **XAUUSD** (алт)-д зориулсан арилжааны хэрэгслүүдийг агуулна.

- **TradingView Pine Script v5 индикатор** (`tradingview/XAU_Footprint_Pro.pine`): footprint-ийн ойролцоо тооцоо, volume profile (**POC / VAH / VAL**), Доугийн онолын трэнд, Фибоначчийн бүс, buy/sell дохио.
- **MT5 Expert Advisor** (`mt5/VP_Dow_EA.mq5`): volume profile болон Доугийн трэнд ашиглан оролт хийнэ. Суулгалт, компайл, Strategy Tester болон тохиргооны тайлбар `mt5/README_mn.md` файлд байна.
- **Algo-breeder стратеги** (`tradingview/strategies/`, `mt5/experts/`): XAU Bred #1, #2, #3. Товч тайлбар `tradingview/strategies/README.md`, судалгааны тайлан `research/algo-breeder/REPORT.md`.

## Хавтасны бүтэц

```
.
├── README.md
├── tradingview/
│   ├── XAU_Footprint_Pro.pine    # Pine v5 индикатор
│   └── strategies/               # XAU Bred #1–#3 (Pine v5)
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

## TradingView дээр индикатор нэмэх

1. [TradingView](https://www.tradingview.com)-д нэвтэрч **XAUUSD** чарт нээнэ. Зөвлөмж: 1м, 5м эсвэл 15м.
2. Чартны доод хэсэгт **Pine Editor**-ийг нээнэ.
3. `tradingview/XAU_Footprint_Pro.pine` файлын кодыг бүхэлд нь хуулж, редактор дахь хуучин кодыг солино.
4. **Save** дарж нэр өгөөд **Add to chart** дарна. Индикатор чарт дээр POC, VAH, VAL, Фибоначчийн бүс, footprint хүснэгт болон BUY/SELL дохиог харуулна.
5. Дохиогоор сэрэмжлүүлэг авах бол индикаторын нэр дээр баруун товч → **Add alert on…** → **BUY дохио** эсвэл **SELL дохио**.

## Анхааруулга

Үр дүн баталгаагүй. Өмнөх үр дүн ирээдүйн ашгийг баталдаггүй. Бодит мөнгөөр ашиглахаас өмнө **демо данс** дээр (MT5 бол эхлээд Strategy Tester, дараа нь демо) туршина уу. Арилжаа алдагдалд хүргэж болно.
