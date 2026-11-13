//+------------------------------------------------------------------+
//|                                                    VP_Dow_EA.mq5 |
//|  Volume Profile (prev. day POC/VAH/VAL) + Dow swing trend filter |
//|  Version 1.00 - for demo account / Strategy Tester use first.    |
//|  No profit is guaranteed. Trading involves risk of loss.         |
//+------------------------------------------------------------------+
#property copyright "VP_Dow_EA"
#property version   "1.00"
#property description "Prev-day Volume Profile (POC/VAH/VAL) rejections filtered by Dow swing trend."
#property description "Test in Strategy Tester and on a DEMO account first. Results are not guaranteed."

#include <Trade\Trade.mqh>

//--- enums
enum ETPMode
  {
   TP_FIXED_RR   = 0,   // Fixed risk:reward (InpMinRR)
   TP_NEXT_LEVEL = 1    // Next VP level (skip if RR < InpMinRR)
  };

enum ETrend
  {
   TR_RANGE = 0,
   TR_UP    = 1,
   TR_DOWN  = 2
  };

//--- inputs
input group "=== Timeframes ==="
input ENUM_TIMEFRAMES InpEntryTF      = PERIOD_M15; // Entry timeframe (logic runs on its new bar)
input ENUM_TIMEFRAMES InpTrendTF      = PERIOD_H1;  // Trend (Dow swing) timeframe
input ENUM_TIMEFRAMES InpProfileTF    = PERIOD_M5;  // Bars used to build the volume profile

input group "=== Volume Profile ==="
input int     InpBinPoints            = 50;    // Profile bin size (points)
input double  InpValueAreaPct         = 70.0;  // Value area (%)
input bool    InpDrawLines            = true;  // Draw POC/VAH/VAL lines

input group "=== Dow trend (swings) ==="
input int     InpSwingStrength        = 3;     // Bars on each side to confirm a swing pivot
input int     InpSwingLookback        = 300;   // Bars of trend TF to scan

input group "=== Entries ==="
input bool    InpAllowRangeTrades     = false; // Range: buy VAL->POC, sell VAH->POC

input group "=== Risk ==="
input bool    InpUseFixedLot          = false; // Use fixed lot instead of risk %
input double  InpFixedLot             = 0.01;  // Fixed lot
input double  InpRiskPercent          = 1.0;   // Risk per trade (% of equity)
input int     InpATRPeriod            = 14;    // ATR period (entry TF)
input double  InpATRMult              = 1.0;   // SL = level -/+ ATR * mult
input ETPMode InpTPMode               = TP_FIXED_RR; // Take-profit mode
input double  InpMinRR                = 1.5;   // Min risk:reward
input int     InpMaxTradesPerDay      = 3;     // Max trades per day
input int     InpMaxSpreadPoints      = 50;    // Max spread (points)

input group "=== Session (server time) ==="
input int     InpSessionStartHour     = 8;     // Session start hour (0-23)
input int     InpSessionEndHour       = 20;    // Session end hour (0-23, exclusive)

input group "=== Misc ==="
input long    InpMagic                = 20261113; // Magic number
input int     InpSlippagePoints       = 30;    // Max deviation (points)

//--- globals
CTrade   trade;
int      g_atrHandle   = INVALID_HANDLE;
datetime g_lastBarTime = 0;
datetime g_profileDay  = 0;     // D1 open time of the day the profile was built for
bool     g_profileOk   = false;
double   g_POC = 0.0, g_VAH = 0.0, g_VAL = 0.0;

const string OBJ_POC = "VPDOW_POC";
const string OBJ_VAH = "VPDOW_VAH";
const string OBJ_VAL = "VPDOW_VAL";

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpBinPoints <= 0 || InpValueAreaPct <= 0.0 || InpValueAreaPct > 100.0)
     {
      Print("Invalid profile inputs.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpSwingStrength < 1 || InpSwingLookback < InpSwingStrength * 4 + 2)
     {
      Print("Invalid swing inputs.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMinRR <= 0.0 || InpATRMult <= 0.0 || InpATRPeriod < 1)
     {
      Print("Invalid risk inputs.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   g_atrHandle = iATR(_Symbol, InpEntryTF, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
     {
      Print("Failed to create ATR handle, error ", GetLastError());
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints((ulong)InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   ObjectDelete(0, OBJ_POC);
   ObjectDelete(0, OBJ_VAH);
   ObjectDelete(0, OBJ_VAL);
   Comment("");
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   //--- run only once per new bar of the entry timeframe
   datetime barTime = iTime(_Symbol, InpEntryTF, 0);
   if(barTime == 0 || barTime == g_lastBarTime)
      return;
   g_lastBarTime = barTime;

   //--- rebuild the profile when a new day starts
   datetime d0 = iTime(_Symbol, PERIOD_D1, 0);
   if(d0 != 0 && d0 != g_profileDay)
     {
      g_profileOk = BuildProfile();
      if(g_profileOk)
        {
         g_profileDay = d0;
         if(InpDrawLines)
            DrawLevels();
        }
     }
   if(!g_profileOk)
      return;

   ETrend trend = GetTrend();
   ShowStatus(trend);

   //--- filters
   if(HasOpenPosition())
      return;
   if(!InSession())
      return;
   if(TradesToday() >= InpMaxTradesPerDay)
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
      return;
   double spreadPts = (ask - bid) / _Point;
   if(spreadPts > InpMaxSpreadPoints)
      return;

   //--- last two closed bars of the entry TF: r[0] = bar 1, r[1] = bar 2
   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, InpEntryTF, 1, 2, r) < 2)
      return;

   if(trend == TR_UP)
     {
      // deeper level first
      if(IsBullRejection(g_VAL, r[0], r[1]) && OpenTrade(true, g_VAL, g_POC, "VAL buy"))
         return;
      if(IsBullRejection(g_POC, r[0], r[1]) && OpenTrade(true, g_POC, g_VAH, "POC buy"))
         return;
     }
   else if(trend == TR_DOWN)
     {
      if(IsBearRejection(g_VAH, r[0], r[1]) && OpenTrade(false, g_VAH, g_POC, "VAH sell"))
         return;
      if(IsBearRejection(g_POC, r[0], r[1]) && OpenTrade(false, g_POC, g_VAL, "POC sell"))
         return;
     }
   else if(InpAllowRangeTrades)
     {
      if(IsBullRejection(g_VAL, r[0], r[1]) && OpenTrade(true, g_VAL, g_POC, "Range VAL buy"))
         return;
      if(IsBearRejection(g_VAH, r[0], r[1]) && OpenTrade(false, g_VAH, g_POC, "Range VAH sell"))
         return;
     }
  }

//+------------------------------------------------------------------+
//| Previous day's volume profile from tick volume                   |
//+------------------------------------------------------------------+
bool BuildProfile()
  {
   datetime dayStart = iTime(_Symbol, PERIOD_D1, 1);
   datetime dayEnd   = iTime(_Symbol, PERIOD_D1, 0);
   if(dayStart == 0 || dayEnd == 0 || dayEnd <= dayStart)
      return(false);

   MqlRates r[];
   int n = CopyRates(_Symbol, InpProfileTF, dayStart, dayEnd - 1, r);
   if(n <= 0)
     {
      Print("BuildProfile: CopyRates failed/empty, error ", GetLastError());
      return(false);
     }

   double hi = -DBL_MAX, lo = DBL_MAX;
   for(int i = 0; i < n; i++)
     {
      if(r[i].high > hi) hi = r[i].high;
      if(r[i].low  < lo) lo = r[i].low;
     }
   if(hi <= lo)
      return(false);

   double bin = InpBinPoints * _Point;
   int nb = (int)MathFloor((hi - lo) / bin) + 1;
   if(nb < 1 || nb > 100000)
     {
      Print("BuildProfile: bad bin count ", nb, " - adjust InpBinPoints.");
      return(false);
     }

   double vols[];
   ArrayResize(vols, nb);
   ArrayInitialize(vols, 0.0);
   double total = 0.0;

   for(int i = 0; i < n; i++)
     {
      double v = (double)r[i].tick_volume;
      if(v <= 0.0)
         continue;
      int a = (int)MathFloor((r[i].low  - lo) / bin);
      int b = (int)MathFloor((r[i].high - lo) / bin);
      if(a < 0) a = 0;
      if(b > nb - 1) b = nb - 1;
      if(b < a) b = a;
      double per = v / (double)(b - a + 1);   // spread bar volume evenly over its range
      for(int k = a; k <= b; k++)
         vols[k] += per;
      total += v;
     }
   if(total <= 0.0)
      return(false);

   int poc = ArrayMaximum(vols, 0, WHOLE_ARRAY);
   if(poc < 0)
      return(false);

   //--- value area: expand from POC towards the larger neighbour
   double target = total * InpValueAreaPct / 100.0;
   double acc = vols[poc];
   int up = poc, dn = poc;
   while(acc < target && (up < nb - 1 || dn > 0))
     {
      double vu = (up < nb - 1) ? vols[up + 1] : -1.0;
      double vd = (dn > 0)      ? vols[dn - 1] : -1.0;
      if(vu >= vd)
        {
         up++;
         acc += vols[up];
        }
      else
        {
         dn--;
         acc += vols[dn];
        }
     }

   g_POC = NormalizePrice(lo + (poc + 0.5) * bin);
   g_VAH = NormalizePrice(lo + (up + 1) * bin);
   g_VAL = NormalizePrice(lo + dn * bin);

   PrintFormat("Profile %s: POC=%s VAH=%s VAL=%s (bars=%d, bins=%d)",
               TimeToString(dayStart, TIME_DATE),
               DoubleToString(g_POC, _Digits), DoubleToString(g_VAH, _Digits),
               DoubleToString(g_VAL, _Digits), n, nb);
   return(true);
  }

//+------------------------------------------------------------------+
//| Dow trend from the last two swing highs / lows                   |
//+------------------------------------------------------------------+
bool IsPivotHigh(const double &a[], const int i, const int s)
  {
   for(int k = 1; k <= s; k++)
      if(a[i] <= a[i - k] || a[i] < a[i + k])
         return(false);
   return(true);
  }

bool IsPivotLow(const double &a[], const int i, const int s)
  {
   for(int k = 1; k <= s; k++)
      if(a[i] >= a[i - k] || a[i] > a[i + k])
         return(false);
   return(true);
  }

ETrend GetTrend()
  {
   double h[], l[];
   ArraySetAsSeries(h, true);
   ArraySetAsSeries(l, true);
   int ch = CopyHigh(_Symbol, InpTrendTF, 0, InpSwingLookback, h);
   int cl = CopyLow(_Symbol, InpTrendTF, 0, InpSwingLookback, l);
   int cnt = MathMin(ch, cl);
   int s = InpSwingStrength;
   if(cnt < s * 2 + 3)
      return(TR_RANGE);

   double ph[2], pl[2];
   int nph = 0, npl = 0;
   // start at s+1 so the forming bar (index 0) is never used for confirmation
   for(int i = s + 1; i < cnt - s && (nph < 2 || npl < 2); i++)
     {
      if(nph < 2 && IsPivotHigh(h, i, s)) { ph[nph] = h[i]; nph++; }
      if(npl < 2 && IsPivotLow(l, i, s))  { pl[npl] = l[i]; npl++; }
     }
   if(nph < 2 || npl < 2)
      return(TR_RANGE);

   // index 0 = most recent swing
   if(ph[0] > ph[1] && pl[0] > pl[1])
      return(TR_UP);
   if(ph[0] < ph[1] && pl[0] < pl[1])
      return(TR_DOWN);
   return(TR_RANGE);
  }

//+------------------------------------------------------------------+
//| Rejection patterns (bar1 = last closed, bar2 = the one before)   |
//+------------------------------------------------------------------+
bool IsBullRejection(const double level, const MqlRates &bar1, const MqlRates &bar2)
  {
   // came from above, wicked into/through level, closed back above
   return(level > 0.0 && bar2.close > level && bar1.low <= level && bar1.close > level);
  }

bool IsBearRejection(const double level, const MqlRates &bar1, const MqlRates &bar2)
  {
   return(level > 0.0 && bar2.close < level && bar1.high >= level && bar1.close < level);
  }

//+------------------------------------------------------------------+
//| Order placement                                                  |
//+------------------------------------------------------------------+
bool OpenTrade(const bool isBuy, const double level, const double nextLevel, const string tag)
  {
   double atrBuf[];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atrBuf) < 1)
      return(false);
   double atr = atrBuf[0];
   if(atr <= 0.0)
      return(false);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry = isBuy ? ask : bid;

   long stopsLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDist = ((double)MathMax(stopsLvl, freezeLvl) + 1.0) * _Point;

   //--- stop loss beyond the level by ATR * mult
   double sl = isBuy ? level - atr * InpATRMult : level + atr * InpATRMult;
   if(isBuy && entry - sl < minDist)
      sl = entry - minDist;
   if(!isBuy && sl - entry < minDist)
      sl = entry + minDist;
   double risk = MathAbs(entry - sl);
   if(risk <= 0.0)
      return(false);

   //--- take profit
   double tp;
   if(InpTPMode == TP_NEXT_LEVEL && nextLevel > 0.0)
     {
      tp = nextLevel;
      double reward = isBuy ? tp - entry : entry - tp;
      double rr = reward / risk;
      if(rr < InpMinRR)
        {
         PrintFormat("%s skipped: RR to next level %.2f < %.2f", tag, rr, InpMinRR);
         return(false);
        }
     }
   else
      tp = isBuy ? entry + risk * InpMinRR : entry - risk * InpMinRR;

   if(MathAbs(tp - entry) < minDist)
     {
      PrintFormat("%s skipped: TP closer than stops level", tag);
      return(false);
     }

   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   double lots = CalcLots(isBuy, entry, sl);
   if(lots <= 0.0)
      return(false);

   bool ok;
   if(isBuy)
      ok = trade.Buy(lots, _Symbol, ask, sl, tp, tag);
   else
      ok = trade.Sell(lots, _Symbol, bid, sl, tp, tag);

   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED && rc != TRADE_RETCODE_DONE_PARTIAL))
     {
      PrintFormat("%s failed: retcode=%u (%s)", tag, rc, trade.ResultRetcodeDescription());
      return(false);
     }
   PrintFormat("%s opened: lots=%.2f entry=%s sl=%s tp=%s", tag, lots,
               DoubleToString(entry, _Digits), DoubleToString(sl, _Digits), DoubleToString(tp, _Digits));
   return(true);
  }

//+------------------------------------------------------------------+
//| Lot size (risk % or fixed), normalized to symbol volume limits   |
//+------------------------------------------------------------------+
double NormalizeLots(double lots)
  {
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vstep <= 0.0) vstep = vmin;
   if(vstep <= 0.0) return(0.0);

   lots = MathFloor(lots / vstep + 1e-9) * vstep;
   if(lots < vmin) return(0.0);
   if(lots > vmax) lots = vmax;

   int vdigits = (int)MathMax(0.0, MathCeil(-MathLog10(vstep) - 1e-9));
   return(NormalizeDouble(lots, vdigits));
  }

double CalcLots(const bool isBuy, const double entry, const double sl)
  {
   ENUM_ORDER_TYPE type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double lots;

   if(InpUseFixedLot)
     {
      lots = NormalizeLots(InpFixedLot);
      if(lots <= 0.0)
         lots = NormalizeLots(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
     }
   else
     {
      double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskPercent / 100.0;
      double lossPerLot = 0.0;
      double profit = 0.0;
      if(OrderCalcProfit(type, _Symbol, 1.0, entry, sl, profit))
         lossPerLot = MathAbs(profit);
      if(lossPerLot <= 0.0)
        {
         double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         if(tickSize > 0.0)
            lossPerLot = MathAbs(entry - sl) / tickSize * tickValue;
        }
      if(lossPerLot <= 0.0)
         return(0.0);

      lots = NormalizeLots(riskMoney / lossPerLot);
      if(lots <= 0.0)
        {
         Print("Calculated lot is below the symbol minimum for this risk - trade skipped.");
         return(0.0);
        }
     }

   //--- reduce lot if free margin is not enough
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin = 0.0;
   while(lots >= vmin && OrderCalcMargin(type, _Symbol, lots, entry, margin) && margin > freeMargin)
     {
      lots = NormalizeLots(lots - vstep);
      if(lots <= 0.0)
        {
         Print("Not enough free margin - trade skipped.");
         return(0.0);
        }
     }
   return(lots);
  }

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double NormalizePrice(const double price)
  {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double p = price;
   if(ts > 0.0)
      p = MathRound(p / ts) * ts;
   return(NormalizeDouble(p, _Digits));
  }

bool HasOpenPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return(true);
     }
   return(false);
  }

int TradesToday()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime dayStart = StructToTime(dt);
   if(!HistorySelect(dayStart, TimeCurrent() + 60))
      return(0);

   int count = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
         continue;
      if(HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
         count++;
     }
   return(count);
  }

bool InSession()
  {
   if(InpSessionStartHour == InpSessionEndHour)
      return(true);                       // equal hours = trade all day
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(InpSessionStartHour < InpSessionEndHour)
      return(h >= InpSessionStartHour && h < InpSessionEndHour);
   return(h >= InpSessionStartHour || h < InpSessionEndHour);   // overnight session
  }

void DrawHLine(const string name, const double price, const color clr, const string text)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, text + " " + DoubleToString(price, _Digits));
  }

void DrawLevels()
  {
   DrawHLine(OBJ_POC, g_POC, clrGold,       "POC");
   DrawHLine(OBJ_VAH, g_VAH, clrDodgerBlue, "VAH");
   DrawHLine(OBJ_VAL, g_VAL, clrTomato,     "VAL");
   ChartRedraw(0);
  }

void ShowStatus(const ETrend trend)
  {
   string t = (trend == TR_UP) ? "UP" : (trend == TR_DOWN ? "DOWN" : "RANGE");
   Comment(StringFormat("VP_Dow_EA\nTrend (%s): %s\nPOC: %s\nVAH: %s\nVAL: %s\nTrades today: %d/%d",
                        EnumToString(InpTrendTF), t,
                        DoubleToString(g_POC, _Digits), DoubleToString(g_VAH, _Digits),
                        DoubleToString(g_VAL, _Digits), TradesToday(), InpMaxTradesPerDay));
  }
//+------------------------------------------------------------------+
