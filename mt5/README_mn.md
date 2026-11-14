# MT5 файлууд

**Quantum AI XAU** индикатор (захиалга өгдөггүй, зөвхөн зурна): `indicators/QuantumAI_XAU.mq5`, `indicators/QuantumAI_Oscillator.mq5`, `indicators/QuantumAI_Math.mqh`.

Суулгах: **File → Open Data Folder** → `MQL5/Indicators/` руу гурван файлыг хуулна → MetaEditor дээр тус бүрийг **F7**. XAUUSD чарт дээр overlay-г, доор нь Resonance цонхыг нэмнэ. Дэлгэрэнгүй, томъёо, 7 алхам англиар үндсэн `README.md` дотор.

---

# VP_Dow_EA — XAUUSD-д зориулсан MT5 Expert Advisor (хувилбар 1.00)

> ⚠️ **Анхааруулга:** Энэ бот ашиг өгнө гэсэн баталгаа байхгүй. Өмнөх үр дүн ирээдүйн үр дүнг баталдаггүй. Эхлээд **Strategy Tester** дээр, дараа нь **демо данс** дээр туршаад, бодит мөнгөөр ажиллуулах эсэхээ өөрөө шийдээрэй.

## Юу хийдэг вэ
1. **Volume Profile (өмнөх өдрийн):** Өмнөх өдрийн M5 баарын tick volume-ийг үнийн түвшнээр (bin) хуваарилж **POC** (хамгийн их эзэлхүүнтэй түвшин), **VAH / VAL** (Value Area, анхдагчаар 70%)-ийг тооцоолж чарт дээр хэвтээ шугамаар зурна.
2. **Доугийн онол (трэнд):** H1 дээрх сүүлийн 2 swing high, 2 swing low-г харьцуулна.
   - Higher High + Higher Low → **Өсөх трэнд**
   - Lower High + Lower Low → **Буурах трэнд**
   - Бусад тохиолдолд → **Range (хажуу)**
3. **Орох нөхцөл (зөвхөн шинэ баар хаагдахад шалгана):**
   - Өсөх трэнд: баар VAL эсвэл POC-д дээрээс хүрээд буцаад дээгүүр нь хаагдвал → **BUY**
   - Буурах трэнд: баар VAH эсвэл POC-д доороос хүрээд буцаад доогуур нь хаагдвал → **SELL**
   - Range үед (тохиргоогоор асаавал): VAL-аас BUY → TP POC, VAH-аас SELL → TP POC
4. **Эрсдэлийн удирдлага:** Нэг арилжаанд эрсдэлийн % эсвэл тогтмол лот, SL = түвшин ∓ ATR×үржвэр, TP = тогтмол RR эсвэл дараагийн VP түвшин, өдөрт дээд арилжааны тоо, дээд спред, арилжааны цагийн шүүлтүүр, нэг удаад зөвхөн нэг позиц.

## Суулгах
1. MT5-аа нээгээд **File → Open Data Folder** дарна.
2. `MQL5\Experts\` хавтас руу `VP_Dow_EA.mq5` файлыг хуулна.
3. MT5 дотор **Navigator** цонхонд **Expert Advisors** дээр баруун товч → **Refresh**.

## Компайл хийх (MetaEditor)
1. MT5 дээр **F4** дарж MetaEditor нээнэ (эсвэл Tools → MetaQuotes Language Editor).
2. `Experts\VP_Dow_EA.mq5` файлыг нээгээд **F7** (Compile) дарна.
3. Доод хэсэгт `0 errors` гарвал болсон. Алдаа гарвал алдааны мөрийг хуулж надад илгээгээрэй, засаж өгнө.

## Эхлээд Strategy Tester дээр турших
1. MT5 дээр **Ctrl+R** (View → Strategy Tester).
2. Expert: `VP_Dow_EA`, Symbol: `XAUUSD` (брокерын нэр өөр байж болно, жишээ нь `XAUUSDm`, `GOLD`).
3. Timeframe: **M15** (InpEntryTF-тэй ижил байлгавал зүгээр).
4. Modeling: **Every tick based on real ticks** (хамгийн бодит).
5. Хугацаа: дор хаяж 6–12 сар. **Start** дарна.
6. Үр дүн (Profit factor, Drawdown, арилжааны тоо)-г шалгаад, дараа нь **демо данс** дээр 2–4 долоо хоног ажиллуулна.
7. Чарт дээр ажиллуулахдаа **Algo Trading** товчийг асаасан байх ёстой.

## Тохиргоо (Inputs)
| Тохиргоо | Анхдагч | Тайлбар |
|---|---|---|
| InpEntryTF | M15 | Орох дохио шалгах timeframe (шинэ баар бүрт ажиллана) |
| InpTrendTF | H1 | Доугийн трэнд тодорхойлох timeframe |
| InpProfileTF | M5 | Volume profile тооцоолоход ашиглах баар |
| InpBinPoints | 50 | Profile-ийн нэг түвшний өндөр (point). XAUUSD 2 оронтой бол 50 point = 0.50$ |
| InpValueAreaPct | 70 | Value Area-ийн хувь |
| InpDrawLines | true | POC/VAH/VAL шугам зурах эсэх |
| InpSwingStrength | 3 | Swing цэг батлахад хоёр талд нь шаардах баарын тоо |
| InpSwingLookback | 300 | Трэнд TF дээр хэдэн баар хайх |
| InpAllowRangeTrades | false | Range үед VAL→POC, VAH→POC арилжаа хийх эсэх |
| InpUseFixedLot | false | true бол тогтмол лот, false бол эрсдэлийн % |
| InpFixedLot | 0.01 | Тогтмол лот |
| InpRiskPercent | 1.0 | Нэг арилжаанд эрсдэлд оруулах equity-ийн % |
| InpATRPeriod | 14 | ATR-ийн үе |
| InpATRMult | 1.0 | SL = түвшин ∓ ATR × энэ тоо |
| InpTPMode | Fixed RR | Fixed RR: TP = эрсдэл × InpMinRR. Next level: TP = дараагийн VP түвшин (RR нь InpMinRR-ээс бага бол арилжаа алгасна) |
| InpMinRR | 1.5 | Хамгийн бага эрсдэл:ашгийн харьцаа |
| InpMaxTradesPerDay | 3 | Өдөрт хамгийн ихдээ хэдэн арилжаа |
| InpMaxSpreadPoints | 50 | Спред үүнээс их бол орохгүй (point) |
| InpSessionStartHour / InpSessionEndHour | 8 / 20 | Арилжаа хийх цаг (**брокерын серверийн цагаар**). Хоёулаа ижил бол бүтэн өдөр |
| InpMagic | 20261113 | Энэ ботын арилжааг ялгах дугаар |
| InpSlippagePoints | 30 | Зөвшөөрөх дээд гулсалт (point) |

## Мэдэх ёстой зүйлс
- Алт MT5 дээр ихэвчлэн CFD тул **tick volume** (үнийн өөрчлөлтийн тоо) ашиглана, жинхэнэ биржийн эзэлхүүн биш.
- Баарын эзэлхүүнийг high–low хооронд жигд хуваарилдаг ойролцоо profile.
- Даваа гарагт "өмнөх өдөр" нь Баасан (зарим брокерт Ням гарагийн богино баар) байж болно.
- Footprint/дельта, Фибоначчи энэ хувилбарт **ороогүй**, дараагийн алхмаар нэмнэ.
- Брокер бүрийн point, лотын алхам, спред өөр тул тохиргоог өөрийн брокерт тааруулна уу.
