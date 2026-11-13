//+------------------------------------------------------------------+
//| XAU_Bred_1.mq5  -  strategy bred by algo-breeder (genetic search)  |
//| H1 long+short | EMA(14) x EMA(25) | filters: trend SMA(116), hours 07:00+9h (broker) | exits: SL 3.2xATR, TP 8.1xATR, trail 2.7xATR, time exit 150 bars, exit on opposite signal
//| Backtest (Dukascopy XAUUSD, costs+swap): IS PF 1.34 / OOS PF 1.51 |
//| DEMO-TEST FIRST. Past results do not guarantee future profit.     |
//| Not financial advice.                                             |
//+------------------------------------------------------------------+
#property copyright "algo-breeder"
#property version   "1.00"
#property description "Bred XAUUSD rule-based strategy #1. Attach to any chart of the gold symbol; it trades on InpTF."
#include <Trade/Trade.mqh>

input group "=== Strategy (bred defaults) ==="
input ENUM_TIMEFRAMES InpTF       = PERIOD_H1;   // Signal timeframe
input int    InpDirection         = 2;      // 0=long only, 1=short only, 2=both
input int    InpEntry             = 0;    // 0=EMA cross, 1=Donchian breakout, 2=RSI reversion, 3=Bollinger reversion
input int    InpEmaFast           = 14;
input int    InpEmaSlow           = 25;
input int    InpDonchianLen       = 39;
input int    InpRsiLen            = 6;
input double InpRsiLow            = 37.0;    // long when RSI crosses back above; short below 100-this
input int    InpBBLen             = 20;
input double InpBBDev             = 2.20;
input int    InpTrendSMA          = 116;    // 0 = off; else long only above SMA, short only below
input double InpVolMin            = 0.00;      // 0 = off; else ATR14 >= InpVolMin * SMA(ATR14,100)
input int    InpSessStartHour     = 7;       // server-time hour the entry window opens
input int    InpSessHours         = 9;     // 24 = trade all hours
input bool   InpH4Confirm         = false;     // last closed H4 candle must point in trade direction
input double InpSL_ATR            = 3.20;       // stop loss = x * ATR14 (always set)
input double InpTP_ATR            = 8.10;       // take profit = x * ATR14 (always set)
input double InpTrail_ATR         = 2.70;    // 0 = off; trailing stop x * ATR14 from closed-bar close
input int    InpMaxBars           = 150;     // 0 = off; close after N completed bars
input bool   InpExitOpposite      = true;    // close on opposite raw signal

input group "=== Risk / execution ==="
input double InpRiskPercent       = 0.5;        // % of balance risked per trade (0 = use fixed lot)
input double InpFixedLot          = 0.01;       // used when InpRiskPercent = 0 (lot step 0.01)
input double InpMaxLot            = 0.50;       // hard cap
input int    InpMaxSpreadPoints   = 80;         // skip new entries if spread > this (80 pts = 0.80 USD)
input int    InpSlippagePoints    = 30;
input long   InpMagic             = 20261101;

CTrade   trade;
datetime g_lastBar = 0;
#define NBARS 1500

//--- indicator helpers on arrays ordered OLDEST -> NEWEST (last element = last closed bar)
void EmaArr(const double &x[], int n, int len, double &out[])
{
   ArrayResize(out, n); double a = 2.0 / (len + 1.0); out[0] = x[0];
   for(int i = 1; i < n; i++) out[i] = out[i-1] + a * (x[i] - out[i-1]);
}
double SmaAt(const double &x[], int idx, int len)
{
   if(idx - len + 1 < 0) return EMPTY_VALUE;
   double s = 0; for(int k = idx - len + 1; k <= idx; k++) s += x[k];
   return s / len;
}
double StdAt(const double &x[], int idx, int len) // population stdev
{
   double mu = SmaAt(x, idx, len); if(mu == EMPTY_VALUE) return EMPTY_VALUE;
   double v = 0; for(int k = idx - len + 1; k <= idx; k++) v += (x[k] - mu) * (x[k] - mu);
   return MathSqrt(v / len);
}
void RmaArr(const double &x[], int n, int len, double &out[]) // Wilder, SMA seed
{
   ArrayResize(out, n); double s = 0;
   for(int i = 0; i < n; i++)
   {
      if(i < len) { s += x[i]; out[i] = (i == len - 1) ? s / len : EMPTY_VALUE; }
      else out[i] = out[i-1] + (x[i] - out[i-1]) / len;
   }
}
void AtrArr(const MqlRates &r[], int n, int len, double &out[])
{
   double tr[]; ArrayResize(tr, n); tr[0] = r[0].high - r[0].low;
   for(int i = 1; i < n; i++)
      tr[i] = MathMax(r[i].high - r[i].low, MathMax(MathAbs(r[i].high - r[i-1].close), MathAbs(r[i].low - r[i-1].close)));
   RmaArr(tr, n, len, out);
}
void RsiArr(const double &c[], int n, int len, double &out[])
{
   double up[], dn[], ru[], rd[]; int m = n - 1;
   ArrayResize(up, m); ArrayResize(dn, m); ArrayResize(out, n); out[0] = EMPTY_VALUE;
   for(int i = 1; i < n; i++) { double d = c[i] - c[i-1]; up[i-1] = d > 0 ? d : 0; dn[i-1] = d < 0 ? -d : 0; }
   RmaArr(up, m, len, ru); RmaArr(dn, m, len, rd);
   for(int i = 0; i < m; i++)
   {
      if(ru[i] == EMPTY_VALUE) out[i+1] = EMPTY_VALUE;
      else out[i+1] = (rd[i] == 0) ? 100.0 : 100.0 - 100.0 / (1.0 + ru[i] / rd[i]);
   }
}
double Highest(const MqlRates &r[], int from, int to) { double m = r[from].high; for(int k = from + 1; k <= to; k++) m = MathMax(m, r[k].high); return m; }
double Lowest (const MqlRates &r[], int from, int to) { double m = r[from].low;  for(int k = from + 1; k <= to; k++) m = MathMin(m, r[k].low);  return m; }

//--- position helpers
bool GetMyPosition(ulong &ticket, int &dir)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      ticket = t; dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      return true;
   }
   return false;
}
double NormLot(double lots)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), InpMaxLot);
   if(step <= 0) step = 0.01;
   lots = MathFloor(lots / step + 1e-9) * step;
   lots = MathMax(vmin, MathMin(vmax, lots));
   return NormalizeDouble(lots, 2);
}
double LotsForRisk(double slDist)
{
   if(InpRiskPercent <= 0) return NormLot(InpFixedLot);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0 || tickValue <= 0 || slDist <= 0) return NormLot(InpFixedLot);
   double lossPerLot = slDist / tickSize * tickValue;
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   return NormLot(risk / lossPerLot);
}

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   if(InpSL_ATR <= 0 || InpTP_ATR <= 0) { Print("SL and TP multipliers must be > 0"); return INIT_PARAMETERS_INCORRECT; }
   if(InpEntry == 0 && InpEmaSlow <= InpEmaFast) { Print("EMA slow must be > fast"); return INIT_PARAMETERS_INCORRECT; }
   return INIT_SUCCEEDED;
}

void OnTick()
{
   datetime bar0 = iTime(_Symbol, InpTF, 0);
   if(bar0 == 0 || bar0 == g_lastBar) return;          // act once per new bar of InpTF

   MqlRates r[];
   ArraySetAsSeries(r, false);
   int n = CopyRates(_Symbol, InpTF, 1, NBARS, r);      // closed bars only, oldest first
   int need = (int)MathMax(MathMax(InpEmaSlow, InpTrendSMA), MathMax(InpDonchianLen, 120)) + 5;
   if(n < need) return;                                 // not enough history yet (retry next tick)
   g_lastBar = bar0;
   int L = n - 1;                                       // index of last closed bar (= shift 1)

   double c[]; ArrayResize(c, n); for(int i = 0; i < n; i++) c[i] = r[i].close;
   double atr[]; AtrArr(r, n, 14, atr);
   double a1 = atr[L];

   //--- raw signal on the last closed bar
   int raw = 0;
   if(InpEntry == 0)
   {
      double ef[], es[]; EmaArr(c, n, InpEmaFast, ef); EmaArr(c, n, InpEmaSlow, es);
      if(ef[L] > es[L] && ef[L-1] <= es[L-1]) raw = 1;
      else if(ef[L] < es[L] && ef[L-1] >= es[L-1]) raw = -1;
   }
   else if(InpEntry == 1)
   {
      double hh = Highest(r, L - InpDonchianLen, L - 1), ll = Lowest(r, L - InpDonchianLen, L - 1);
      if(c[L] > hh) raw = 1; else if(c[L] < ll) raw = -1;
   }
   else if(InpEntry == 2)
   {
      double rs[]; RsiArr(c, n, InpRsiLen, rs);
      double hi = 100.0 - InpRsiLow;
      if(rs[L-1] < InpRsiLow && rs[L] >= InpRsiLow) raw = 1;
      else if(rs[L-1] > hi && rs[L] <= hi) raw = -1;
   }
   else
   {
      double m1 = SmaAt(c, L, InpBBLen), m2 = SmaAt(c, L - 1, InpBBLen);
      double s1 = StdAt(c, L, InpBBLen), s2 = StdAt(c, L - 1, InpBBLen);
      double lo1 = m1 - InpBBDev * s1, lo2 = m2 - InpBBDev * s2, up1 = m1 + InpBBDev * s1, up2 = m2 + InpBBDev * s2;
      if(c[L-1] < lo2 && c[L] >= lo1) raw = 1;
      else if(c[L-1] > up2 && c[L] <= up1) raw = -1;
   }

   //--- filters
   int sig = raw;
   if(sig == 1 && InpDirection == 1) sig = 0;
   if(sig == -1 && InpDirection == 0) sig = 0;
   if(sig != 0 && InpTrendSMA > 0)
   {
      double t = SmaAt(c, L, InpTrendSMA);
      if(sig == 1 && !(c[L] > t)) sig = 0;
      if(sig == -1 && !(c[L] < t)) sig = 0;
   }
   if(sig != 0 && InpVolMin > 0)
   {
      double va = SmaAt(atr, L, 100);
      if(va == EMPTY_VALUE || !(a1 >= InpVolMin * va)) sig = 0;
   }
   if(sig != 0 && InpSessHours < 24)
   {
      MqlDateTime dt; TimeToStruct(bar0, dt);          // hour of the bar we would enter on (server time)
      if(((dt.hour - InpSessStartHour + 24) % 24) >= InpSessHours) sig = 0;
   }
   if(sig != 0 && InpH4Confirm)
   {
      double ho = iOpen(_Symbol, PERIOD_H4, 1), hc = iClose(_Symbol, PERIOD_H4, 1);
      int hdir = (hc > ho) ? 1 : (hc < ho ? -1 : 0);
      if(hdir != sig) sig = 0;
   }

   //--- manage open position (decisions made on the closed bar)
   ulong ticket; int pdir = 0;
   if(GetMyPosition(ticket, pdir))
   {
      bool closeIt = false;
      int held = iBarShift(_Symbol, InpTF, (datetime)PositionGetInteger(POSITION_TIME));
      if(InpMaxBars > 0 && held >= InpMaxBars) closeIt = true;
      if(InpExitOpposite && raw == -pdir) closeIt = true;
      if(closeIt)
      {
         if(!trade.PositionClose(ticket)) Print("Close failed: ", trade.ResultRetcodeDescription());
      }
      else if(InpTrail_ATR > 0)
      {
         double curSL = PositionGetDouble(POSITION_SL), curTP = PositionGetDouble(POSITION_TP);
         double stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(pdir == 1)
         {
            double ns = NormalizeDouble(c[L] - InpTrail_ATR * a1, _Digits);
            if(ns > curSL + _Point && ns < bid - stopsLvl) trade.PositionModify(ticket, ns, curTP);
         }
         else
         {
            double ns = NormalizeDouble(c[L] + InpTrail_ATR * a1, _Digits);
            if((curSL == 0 || ns < curSL - _Point) && ns > ask + stopsLvl) trade.PositionModify(ticket, ns, curTP);
         }
      }
   }

   //--- new entry when flat
   if(sig == 0 || GetMyPosition(ticket, pdir)) return;
   long spreadPts = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spreadPts > InpMaxSpreadPoints) { Print("Spread too wide (", spreadPts, " pts), entry skipped"); return; }
   double slDist = InpSL_ATR * a1, tpDist = InpTP_ATR * a1;
   double minDist = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 1) * _Point;
   slDist = MathMax(slDist, minDist); tpDist = MathMax(tpDist, minDist);
   double lots = LotsForRisk(slDist);
   string cmt = "XAU_Bred_1";
   if(sig == 1)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = NormalizeDouble(ask - slDist, _Digits), tp = NormalizeDouble(ask + tpDist, _Digits);
      if(!trade.Buy(lots, _Symbol, 0.0, sl, tp, cmt)) Print("Buy failed: ", trade.ResultRetcodeDescription());
   }
   else
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = NormalizeDouble(bid + slDist, _Digits), tp = NormalizeDouble(bid - tpDist, _Digits);
      if(!trade.Sell(lots, _Symbol, 0.0, sl, tp, cmt)) Print("Sell failed: ", trade.ResultRetcodeDescription());
   }
}
//+------------------------------------------------------------------+
