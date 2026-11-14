//+------------------------------------------------------------------+
//| QuantumAI_Oscillator.mq5                                         |
//| Resonance Distributor pane.                                      |
//|                                                                  |
//| Upper half: slow WaveTrend channel (violet / cyan edges, white  |
//| center). Lower half: LazyBear momentum histogram (wt1-wt2),     |
//| green when bullish and dark red when bearish.                   |
//|                                                                  |
//| WaveTrend math is LazyBear's public formula (n1/n2/signal SMA). |
//| Every value uses only the current bar and older bars.           |
//| Attach under the price chart, next to QuantumAI_XAU.            |
//| Not the Cloud Chamber product. Not financial advice.             |
//+------------------------------------------------------------------+
#property copyright "xauusd-trading"
#property version   "1.00"
#property description "Resonance Distributor pane: structural wave plus momentum histogram."
#property description "Closed-bar math only. Not the commercial Cloud Chamber indicator."
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   4
#property indicator_type1   DRAW_FILLING
#property indicator_color1  0xD24696, 0xA09600
#property indicator_label1  "Structure cloud"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_width2  2
#property indicator_label2  "Structure"
#property indicator_type3   DRAW_LINE
#property indicator_color3  0xD2DC00
#property indicator_width3  1
#property indicator_label3  "Oscillation"
#property indicator_type4   DRAW_COLOR_HISTOGRAM
#property indicator_color4  0x6EBE00, 0x466E00, 0x3C28BE, 0x2D1E78
#property indicator_width4  3
#property indicator_label4  "Momentum"
#property indicator_level1  60.0
#property indicator_level2  0.0
#property indicator_level3 -60.0
#property indicator_levelcolor clrDimGray
#property indicator_levelstyle STYLE_DOT

#include "QuantumAI_Math.mqh"

input group "=== Resonance Distributor ==="
input int InpFastN1   = 10;   // Fast channel length (LazyBear n1)
input int InpFastN2   = 21;   // Fast average length (LazyBear n2)
input int InpSignal   = 4;    // Signal SMA (LazyBear uses 4)
input int InpSlowN1   = 21;   // Slow structural channel
input int InpSlowN2   = 34;   // Slow structural average
input double InpBand  = 18.0; // Half-width of the structural cloud

double UpBuf[];
double DnBuf[];
double MidBuf[];
double FastBuf[];
double HistBuf[];
double HistClr[];

int OnInit()
{
   SetIndexBuffer(0, UpBuf, INDICATOR_DATA);
   SetIndexBuffer(1, DnBuf, INDICATOR_DATA);
   SetIndexBuffer(2, MidBuf, INDICATOR_DATA);
   SetIndexBuffer(3, FastBuf, INDICATOR_DATA);
   SetIndexBuffer(4, HistBuf, INDICATOR_DATA);
   SetIndexBuffer(5, HistClr, INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME, "QAI Resonance");
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   ArraySetAsSeries(UpBuf, true);
   ArraySetAsSeries(DnBuf, true);
   ArraySetAsSeries(MidBuf, true);
   ArraySetAsSeries(FastBuf, true);
   ArraySetAsSeries(HistBuf, true);
   ArraySetAsSeries(HistClr, true);
   return INIT_SUCCEEDED;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 10 || ArraySize(time) < 0 || ArraySize(open) < 0)
      return 0;
   if(ArraySize(tick_volume) < 0 || ArraySize(volume) < 0 || ArraySize(spread) < 0)
      return 0;

   int n1 = InpFastN1;
   int n2 = InpFastN2;
   int sig = InpSignal;
   int s1 = InpSlowN1;
   int s2 = InpSlowN2;
   if(n1 < 2) n1 = 2;
   if(n2 < 2) n2 = 2;
   if(sig < 1) sig = 1;
   if(s1 < 2) s1 = 2;
   if(s2 < 2) s2 = 2;

   double ap[];
   ArrayResize(ap, rates_total);
   for(int i = 0; i < rates_total; i++)
      ap[i] = (high[i] + low[i] + close[i]) / 3.0;

   double wt1[], wt2[], slow1[], slow2[];
   QaiWaveTrend(ap, rates_total, n1, n2, sig, wt1, wt2);
   QaiWaveTrend(ap, rates_total, s1, s2, sig, slow1, slow2);
   if(ArraySize(slow2) != rates_total || ArraySize(open) < 0)
      return 0;

   int first = 0;
   if(prev_calculated > 1)
      first = prev_calculated - 1;
   double band = InpBand;
   if(band < 1.0)
      band = 1.0;

   for(int src = first; src < rates_total; src++)
   {
      int shift = rates_total - 1 - src;
      double mid = slow1[src];
      UpBuf[shift] = mid + band;
      DnBuf[shift] = mid - band;
      MidBuf[shift] = mid;
      FastBuf[shift] = wt1[src];
      double h = wt1[src] - wt2[src];
      HistBuf[shift] = h;
      double prev = h;
      if(src > 0)
         prev = wt1[src - 1] - wt2[src - 1];
      if(h >= 0.0)
         HistClr[shift] = (h >= prev) ? 0.0 : 1.0;
      else
         HistClr[shift] = (h <= prev) ? 2.0 : 3.0;
   }
   return rates_total;
}
