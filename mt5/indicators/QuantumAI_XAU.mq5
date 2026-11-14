//+------------------------------------------------------------------+
//| QuantumAI_XAU.mq5                                                |
//| Original XAUUSD decision dashboard for MetaTrader 5.            |
//|                                                                  |
//| Visual layout and module names follow the public Cloud Chamber  |
//| / Quantum AI site, product PDF, and 30-page dual-module guide.  |
//| The math is rebuilt from published techniques (see README).     |
//| This is not the vendor's indicator and it does not place orders.|
//|                                                                  |
//| Signals, structure and the trade plan are decided on closed     |
//| bars only. A label is written once and never moved.             |
//+------------------------------------------------------------------+
#property copyright "xauusd-trading"
#property version   "1.00"
#property description "XAUUSD decision dashboard: signals, SMC, volume profile, risk lines, panels."
#property description "Closed bars only. Not the commercial Cloud Chamber product. Not financial advice."
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  0xDC3CBE
#property indicator_width1  2
#property indicator_label1  "Kernel"
#property indicator_type2   DRAW_LINE
#property indicator_color2  0xD2DC00
#property indicator_width2  1
#property indicator_label2  "Fast kernel"

#include <Canvas/Canvas.mqh>
#include "QuantumAI_Math.mqh"

enum ENUM_QAI_MODE
{
   QAI_SCALP = 0, // Ultra-short / Scalp
   QAI_SWING = 1, // Swing
   QAI_RANGE = 2  // Range-bound
};

input group "=== 1. Mode ==="
input ENUM_QAI_MODE InpMode = QAI_SCALP; // System mode
input int    InpMaxBars     = 1200;      // Bars to study (closed history)
input double InpMinScore    = 60.0;      // Confirmed signal needs this score
input int    InpLife        = 30;        // Confirmed label stays "fresh" this many bars

input group "=== 2. Symbol and overrides ==="
input bool   InpUseManual   = false;     // Manual: ignore symbol presets
input int    InpInternalLen = 0;         // Internal pivot length, 0 = mode
input int    InpSwingLen    = 0;         // Swing pivot length, 0 = mode
input int    InpCooldown    = 0;         // Signal cooling, bars, 0 = mode + symbol
input int    InpKernelH     = 0;         // Kernel bandwidth, 0 = mode
input double InpKernelA     = 0.0;       // Kernel alpha, 0 = mode
input int    InpChannelLen  = 0;         // Regression channel length, 0 = mode
input int    InpSessStart   = -1;        // Session start hour, server time, -1 = preset
input int    InpSessEnd     = -1;        // Session end hour, server time, -1 = preset

input group "=== 3. Modules ==="
input bool   InpKernel      = true;      // Quantum regression curve
input bool   InpChannel     = true;      // Regression channel
input bool   InpSignals     = true;      // Buy / Sell confirmations
input bool   InpEarly       = true;      // Trend Bull / Trend Bear reminders
input bool   InpStruct      = true;      // BOS / CHoCH
input bool   InpOB          = true;      // Internal order blocks
input bool   InpFVG         = true;      // Fair value gaps
input bool   InpZones       = true;      // Premium / discount / equilibrium
input bool   InpTrendline   = true;      // Pivot trendline
input bool   InpMarkers     = true;      // Support / resistance dots
input bool   InpInstit      = true;      // Accumulation, shakeout, markup, sell-off
input bool   InpProfile     = true;      // Volume profile
input bool   InpRisk        = true;      // Entry, SL, TP1-3, trailing SL
input bool   InpDash        = true;      // Scalp / swing / range panel
input bool   InpResPanel    = true;      // Resonance engine panel
input bool   InpThermo      = true;      // Price thermometer

input group "=== 4. Risk geometry (0 = symbol preset) ==="
input int    InpAtrLen      = 14;        // ATR length
input double InpAtrMult     = 0.0;       // ATR stop multiple, 0 = preset
input double InpTp1R        = 0.0;       // TP1 in R, 0 = preset
input double InpTp2R        = 0.0;       // TP2 in R, 0 = preset
input double InpTp3R        = 0.0;       // TP3 in R, 0 = preset
input double InpTrailAtr    = 0.0;       // Trail ATR after break-even, 0 = preset
input double InpMinStopAtr  = 0.0;       // Minimum stop, ATR, 0 = preset
input double InpMaxStopAtr  = 0.0;       // Maximum stop, ATR, 0 = preset

input group "=== 5. Profile and flow (0 = symbol preset) ==="
input int    InpFlowLen     = 50;        // Volume-flow lookback
input int    InpThermoLen   = 50;        // Thermometer lookback
input int    InpVpLook      = 140;       // Volume profile lookback
input int    InpVpBins      = 0;         // Volume profile rows, 0 = preset
input int    InpDeadPct     = 0;         // Dead-volatility percentile, 0 = preset
input double InpVaPct       = 70.0;      // Value area percent
input int    InpVpWidth     = 18;        // Profile width, bars

input group "=== 6. Cross-cycle rows ==="
input ENUM_TIMEFRAMES InpTF1 = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF2 = PERIOD_M30;
input ENUM_TIMEFRAMES InpTF3 = PERIOD_H1;
input ENUM_TIMEFRAMES InpTF4 = PERIOD_H4;
input ENUM_TIMEFRAMES InpTF5 = PERIOD_D1;

input group "=== 7. Alerts ==="
input bool   InpAlert       = true;      // Alert() popup
input bool   InpPush        = true;      // Mobile push
input bool   InpMail        = false;     // Email (MT5 mailbox must be set)
input string InpWebhook     = "";        // POST url, empty = off
input string InpChatId      = "";        // Telegram chat id, optional

input group "=== 8. Panel placement ==="
input int    InpPanelX      = 8;         // Right margin, pixels
input int    InpPanelY      = 18;        // Top margin, pixels

//--- kinds stored on marks
#define MK_BUY    1
#define MK_SELL   2
#define MK_TBULL  3
#define MK_TBEAR  4
#define MK_BOSU   5
#define MK_BOSD   6
#define MK_CHU    7
#define MK_CHD    8
#define MK_ACC    9
#define MK_SHAKE  10
#define MK_MARKUP 11
#define MK_SELLO  12
#define MK_SWEEP  13
#define MK_VALID  14
#define MK_FALSE  15
#define MK_DIST   16
#define MK_DOWN   17
#define MK_SUP    20
#define MK_RES    21

#define AL_BUY 0
#define AL_SELL 1
#define AL_TBULL 2
#define AL_TBEAR 3
#define AL_BOSU 4
#define AL_BOSD 5
#define AL_CHU 6
#define AL_CHD 7
#define AL_OBBU 8
#define AL_OBBD 9
#define AL_OBRU 10
#define AL_OBRD 11
#define AL_CHUP 12
#define AL_CHDN 13
#define AL_RESBR 14
#define AL_SUPBR 15
#define AL_EXPL 16
#define AL_TP1 17
#define AL_SWEEP 18
#define AL_SWRES 19
#define AL_FALSE 20
#define AL_COUNT 21

struct SMark
{
   int idx;
   int kind;
};

struct SZone
{
   int    i1;
   int    i2;
   double top;
   double bot;
   int    kind;      // +1 bull OB, -1 bear OB, +2 bull FVG, -2 bear FVG
   bool   alive;
   bool   retested;
   bool   used;
};

struct SState
{
   string stance;
   string modeName;
   string biasText;
   double vpScore;
   double momScore;
   int    resDir;
   string regime;
   string volText;
   string flowText;
   string latest;
   string engine;
   string tiers;
   double confidence;
   double adx;
   string adxTag;
   string posText;
   double activeStop;
   double thermo;
   string thermoTag;
   int    passes;
   string sizeText;
   string stepTxt[7];
   int    stepSt[7];
   string tfBias[5];
   double tfStr[5];
   int    tfSign[5];
   string tfBucket[5];
   string htfText;
   bool   htfOk;
};

double KernelBuf[];
double FastBuf[];

double   g_op[], g_hi[], g_lo[], g_cl[], g_vol[], g_buy[], g_sell[];
double   g_atr[], g_rsi[], g_adx[], g_wt1[], g_wt2[], g_ker[];
double   g_bbU[], g_bbD[], g_kcU[], g_kcD[];
datetime g_tm[];
int      g_n = 0;

int    wInt = 5, wSw = 20, wCool = 4, wKern = 24, wChan = 48;
double wAlpha = 8.0;
bool   wRange = false;
double wAtrMult = 1.50, wTp1 = 0.75, wTp2 = 1.50, wTp3 = 2.25, wTrail = 1.20;
double wMinAtr = 0.60, wMaxAtr = 2.50, wExpRatio = 1.08;
int    wBins = 28, wDeadPct = 20, wCoolAdd = 0;
int    wSessStart = 0, wSessEnd = 0;
bool   wSessOn = false;
string wSymName = "Generic";
string wSessName = "24h";

SMark  g_marks[];
SZone  g_ob[8];
SZone  g_fvg[6];
int    g_obCount = 0;
int    g_fvgCount = 0;

int    g_posDir = 0;
int    g_planIdx = -1;
double g_entry = 0, g_sl = 0, g_tp1 = 0, g_tp2 = 0, g_tp3 = 0, g_trail = 0;
bool   g_be = false;
bool   g_hasPlan = false;
int    g_lastConfirm = -1;
int    g_latestKind = 0;
int    g_latestIdx = -1;
int    g_intTrend = 0;

double g_swHi = 0, g_swLo = 0;
int    g_swHiI = -1, g_swLoI = -1;
bool   g_swOk = false;

bool   g_regOk = false;
double g_regSlope = 0, g_regIcept = 0, g_regSd = 0;
int    g_regA = 0, g_regB = 0;

double g_tly1 = 0, g_tly2 = 0;
int    g_tlI1 = -1, g_tlI2 = -1;
int    g_tlKind = 0; // +1 support line, -1 resistance line

double g_bin[];
double g_binBuy[];
double g_vpLo = 0, g_vpHi = 0, g_poc = 0, g_vah = 0, g_val = 0;
int    g_bins = 28;

bool   g_ev[21];
string g_phase = "Balance";
double g_core = 50.0;
int    g_invIdx = -1;
double g_invPx = 0.0;
int    g_invDir = 0;
SState g_st;
CCanvas g_dash, g_res, g_th;
bool   g_canvas = false;

int ActiveDir(int last)
{
   int dir = g_st.resDir;
   if(g_posDir != 0)
      dir = g_posDir;
   if(g_lastConfirm >= 0 && (last - g_lastConfirm) <= InpLife)
   {
      if(g_latestKind == MK_BUY || g_latestKind == MK_TBULL)
         dir = 1;
      if(g_latestKind == MK_SELL || g_latestKind == MK_TBEAR)
         dir = -1;
   }
   return dir;
}

void ApplyMode()
{
   if(InpMode == QAI_SWING)
   {
      wInt = 5; wSw = 50; wCool = 8; wKern = 48; wAlpha = 8.0; wChan = 80; wRange = false;
      g_st.modeName = "Swing Mode";
   }
   else if(InpMode == QAI_RANGE)
   {
      wInt = 5; wSw = 30; wCool = 5; wKern = 32; wAlpha = 8.0; wChan = 50; wRange = true;
      g_st.modeName = "Range Mode";
   }
   else
   {
      wInt = 5; wSw = 20; wCool = 4; wKern = 24; wAlpha = 8.0; wChan = 48; wRange = false;
      g_st.modeName = "Scalp Mode";
   }
   if(InpInternalLen > 0) wInt = InpInternalLen;
   if(InpSwingLen > 0)    wSw = InpSwingLen;
   if(InpCooldown > 0)    wCool = InpCooldown;
   if(InpKernelH > 0)     wKern = InpKernelH;
   if(InpKernelA > 0.0)   wAlpha = InpKernelA;
   if(InpChannelLen > 0)  wChan = InpChannelLen;
   if(wInt < 2) wInt = 2;
   if(wSw < wInt) wSw = wInt;
   if(wCool < 1) wCool = 1;
   if(wKern < 4) wKern = 4;
   if(wChan < 10) wChan = 10;
   ApplySymbol();
}

int DetectInstrument()
{
   string s = _Symbol;
   StringToUpper(s);
   if(StringFind(s, "XAU") >= 0 || StringFind(s, "GOLD") >= 0)
      return 1;
   if(StringFind(s, "XAG") >= 0 || StringFind(s, "SILVER") >= 0)
      return 2;
   if(StringFind(s, "BTC") >= 0)
      return 3;
   if(StringFind(s, "NAS") >= 0 || StringFind(s, "US100") >= 0 || StringFind(s, "USTEC") >= 0 || StringFind(s, "NDX") >= 0)
      return 4;
   return 0;
}

void ApplySymbol()
{
   int id = InpUseManual ? 0 : DetectInstrument();
   wAtrMult = 1.50; wTp1 = 0.75; wTp2 = 1.50; wTp3 = 2.25; wTrail = 1.20;
   wMinAtr = 0.60; wMaxAtr = 2.50; wExpRatio = 1.08;
   wBins = 28; wDeadPct = 20; wCoolAdd = 0;
   wSessOn = false; wSessStart = 0; wSessEnd = 24;
   wSymName = "Generic"; wSessName = "24h";
   if(!InpUseManual && id == 1)
   {
      wSymName = "XAU"; wSessName = "London/NY";
      wSessOn = true; wSessStart = 10; wSessEnd = 23;
   }
   else if(!InpUseManual && id == 2)
   {
      wSymName = "XAG"; wSessName = "London/NY";
      wAtrMult = 1.85; wTp1 = 0.70; wTp2 = 1.40; wTp3 = 2.20; wTrail = 1.40;
      wMinAtr = 0.85; wMaxAtr = 3.00; wExpRatio = 1.12;
      wBins = 32; wDeadPct = 25; wCoolAdd = 2;
      wSessOn = true; wSessStart = 10; wSessEnd = 23;
   }
   else if(!InpUseManual && id == 3)
   {
      wSymName = "BTC"; wSessName = "24h";
      wAtrMult = 2.00; wTp1 = 1.00; wTp2 = 2.00; wTp3 = 3.50; wTrail = 1.80;
      wMinAtr = 1.00; wMaxAtr = 3.50; wExpRatio = 1.05;
      wBins = 36; wDeadPct = 15; wCoolAdd = 2;
      wSessOn = false;
   }
   else if(!InpUseManual && id == 4)
   {
      wSymName = "NAS"; wSessName = "NY cash";
      wAtrMult = 1.70; wTp1 = 0.75; wTp2 = 1.50; wTp3 = 2.25; wTrail = 1.30;
      wMinAtr = 0.75; wMaxAtr = 2.80; wExpRatio = 1.10;
      wBins = 24; wDeadPct = 22; wCoolAdd = 1;
      wSessOn = true; wSessStart = 16; wSessEnd = 23;
   }
   if(!InpUseManual && InpCooldown <= 0)
      wCool += wCoolAdd;
   if(InpAtrMult > 0.0) wAtrMult = InpAtrMult;
   if(InpTp1R > 0.0) wTp1 = InpTp1R;
   if(InpTp2R > 0.0) wTp2 = InpTp2R;
   if(InpTp3R > 0.0) wTp3 = InpTp3R;
   if(InpTrailAtr > 0.0) wTrail = InpTrailAtr;
   if(InpMinStopAtr > 0.0) wMinAtr = InpMinStopAtr;
   if(InpMaxStopAtr > 0.0) wMaxAtr = InpMaxStopAtr;
   if(InpVpBins > 0) wBins = InpVpBins;
   if(InpDeadPct > 0) wDeadPct = InpDeadPct;
   if(InpSessStart >= 0 && InpSessEnd >= 0)
   {
      wSessStart = InpSessStart;
      wSessEnd = InpSessEnd;
      wSessOn = (InpSessStart != InpSessEnd);
      if(!wSessOn)
         wSessName = "24h";
      else
         wSessName = "Custom";
   }
   if(InpUseManual)
   {
      wSymName = "Manual";
      if(InpSessStart < 0)
      {
         wSessOn = false;
         wSessName = "24h";
      }
   }
   if(wBins < 8) wBins = 8;
   if(wBins > 48) wBins = 48;
   if(wMinAtr < 0.2) wMinAtr = 0.2;
   if(wMaxAtr < wMinAtr) wMaxAtr = wMinAtr;
   if(wDeadPct < 1) wDeadPct = 1;
   if(wDeadPct > 80) wDeadPct = 80;
   if(wExpRatio < 1.01) wExpRatio = 1.01;
}

bool InSession(datetime t)
{
   if(!wSessOn)
      return true;
   MqlDateTime dt;
   TimeToStruct(t, dt);
   int h = dt.hour;
   if(wSessStart == wSessEnd)
      return true;
   if(wSessStart < wSessEnd)
      return (h >= wSessStart && h < wSessEnd);
   return (h >= wSessStart || h < wSessEnd);
}

int OnInit()
{
   SetIndexBuffer(0, KernelBuf, INDICATOR_DATA);
   SetIndexBuffer(1, FastBuf, INDICATOR_DATA);
   ArraySetAsSeries(KernelBuf, true);
   ArraySetAsSeries(FastBuf, true);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME, "Quantum AI XAU");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   ArrayResize(g_bin, 48);
   ArrayResize(g_binBuy, 48);
   g_canvas = false;
   bool a = MakeCanvas(g_res,  "QAI_RES",  300, 168, CORNER_RIGHT_UPPER, InpPanelX, InpPanelY);
   bool b = MakeCanvas(g_dash, "QAI_DASH", 372, 640, CORNER_RIGHT_UPPER, InpPanelX, InpPanelY + 176);
   bool c = MakeCanvas(g_th,   "QAI_THM",  340, 78,  CORNER_RIGHT_LOWER, InpPanelX, 28);
   g_canvas = (a && b && c);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_res.Destroy();
   g_dash.Destroy();
   g_th.Destroy();
   ObjectsDeleteAll(0, "QAI_");
   if(reason == REASON_REMOVE || reason == REASON_RECOMPILE || reason == REASON_PARAMETERS ||
      reason == REASON_CHARTCHANGE || reason == REASON_CHARTCLOSE || reason == REASON_TEMPLATE ||
      reason == REASON_INITFAILED || reason == REASON_ACCOUNT || reason == REASON_CLOSE)
      Comment("");
}

bool MakeCanvas(CCanvas &cv, const string name, int w, int h, int corner, int x, int y)
{
   ObjectDelete(0, name);
   if(!cv.CreateBitmapLabel(0, 0, name, x, y, w, h, COLOR_FORMAT_ARGB_NORMALIZE))
      return false;
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   return true;
}

void ClearDrawings()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, 0, -1);
      if(StringFind(n, "QAI_") != 0)
         continue;
      if(n == "QAI_DASH" || n == "QAI_RES" || n == "QAI_THM")
         continue;
      ObjectDelete(0, n);
   }
}

void PushMark(int idx, int kind)
{
   int n = ArraySize(g_marks);
   ArrayResize(g_marks, n + 1, 512);
   g_marks[n].idx = idx;
   g_marks[n].kind = kind;
   if(kind >= MK_BUY && kind <= MK_TBEAR)
   {
      g_latestKind = kind;
      g_latestIdx = idx;
   }
}

bool PivotHigh(int c, int left, int right, int last)
{
   if(c < left || c + right > last)
      return false;
   double v = g_hi[c];
   for(int k = c - left; k <= c + right; k++)
   {
      if(k == c)
         continue;
      if(g_hi[k] >= v)
         return false;
   }
   return true;
}

bool PivotLow(int c, int left, int right, int last)
{
   if(c < left || c + right > last)
      return false;
   double v = g_lo[c];
   for(int k = c - left; k <= c + right; k++)
   {
      if(k == c)
         continue;
      if(g_lo[k] <= v)
         return false;
   }
   return true;
}

int VolStateAt(int i)
{
   if(i < 5)
      return 1;
   bool sq = (g_bbU[i] < g_kcU[i] && g_bbD[i] > g_kcD[i]);
   if(sq)
      return 0;
   bool recent = false;
   int a = i - 5;
   if(a < 1)
      a = 1;
   for(int k = a; k < i; k++)
   {
      if(g_bbU[k] < g_kcU[k] && g_bbD[k] > g_kcD[k])
         recent = true;
   }
   double bw = g_bbU[i] - g_bbD[i];
   double prev = g_bbU[i - 3] - g_bbD[i - 3];
   if(prev < 0.0)
      prev = 0.0;
   if(recent && bw > prev)
      return 2;
   if(bw > prev * wExpRatio)
      return 3;
   return 1;
}

string VolName(int v)
{
   if(v == 0) return "Compression";
   if(v == 2) return "Explosion (Breakout)";
   if(v == 3) return "Expansion";
   return "Stable";
}

double DistAt(int i)
{
   int len = InpFlowLen;
   if(len < 5)
      len = 5;
   int a = i - len + 1;
   if(a < 0)
      a = 0;
   double b = 0.0, s = 0.0;
   for(int k = a; k <= i; k++)
   {
      b += g_buy[k];
      s += g_sell[k];
   }
   double t = b + s;
   if(t <= 0.0)
      return 50.0;
   return 100.0 * b / t;
}

double ProfileAt(int i, bool store)
{
   int look = InpVpLook;
   if(look < 20)
      look = 20;
   int bins = wBins;
   if(bins < 8)
      bins = 8;
   if(bins > 48)
      bins = 48;
   int a = i - look + 1;
   if(a < 0)
      a = 0;
   double hh = g_hi[a];
   double ll = g_lo[a];
   for(int k = a; k <= i; k++)
   {
      if(g_hi[k] > hh) hh = g_hi[k];
      if(g_lo[k] < ll) ll = g_lo[k];
   }
   if(hh <= ll)
      return 50.0;
   double vol[];
   double buy[];
   ArrayResize(vol, bins);
   ArrayResize(buy, bins);
   ArrayInitialize(vol, 0.0);
   ArrayInitialize(buy, 0.0);
   double step = (hh - ll) / (double)bins;
   if(step <= 0.0)
      return 50.0;
   for(int k = a; k <= i; k++)
   {
      int b1 = (int)MathFloor((g_lo[k] - ll) / step);
      int b2 = (int)MathFloor((MathMax(g_hi[k] - _Point, g_lo[k]) - ll) / step);
      if(b1 < 0) b1 = 0;
      if(b2 < 0) b2 = 0;
      if(b1 >= bins) b1 = bins - 1;
      if(b2 >= bins) b2 = bins - 1;
      if(b2 < b1)
      {
         int tmp = b1;
         b1 = b2;
         b2 = tmp;
      }
      int span = b2 - b1 + 1;
      double each = g_vol[k] / (double)span;
      double buyFrac = 0.5;
      double barRange = g_hi[k] - g_lo[k];
      if(barRange > 0.0)
         buyFrac = (g_cl[k] - g_lo[k]) / barRange;
      buyFrac = QaiClamp(buyFrac, 0.0, 1.0);
      for(int b = b1; b <= b2; b++)
      {
         vol[b] += each;
         buy[b] += each * buyFrac;
      }
   }
   double total = 0.0;
   int poc = 0;
   for(int b = 0; b < bins; b++)
   {
      total += vol[b];
      if(vol[b] > vol[poc])
         poc = b;
   }
   double acc = vol[poc];
   int lo = poc, hi = poc;
   double target = total * (InpVaPct / 100.0);
   while(acc < target && (lo > 0 || hi < bins - 1))
   {
      double left = (lo > 0) ? vol[lo - 1] : -1.0;
      double right = (hi < bins - 1) ? vol[hi + 1] : -1.0;
      if(right >= left && hi < bins - 1)
      {
         hi++;
         acc += vol[hi];
      }
      else if(lo > 0)
      {
         lo--;
         acc += vol[lo];
      }
      else
         break;
   }
   int cut = (int)MathFloor((g_cl[i] - ll) / step);
   if(cut < 0) cut = -1;
   if(cut >= bins) cut = bins - 1;
   double below = 0.0;
   for(int b = 0; b < bins; b++)
   {
      if(b <= cut)
         below += vol[b];
   }
   double score = (total > 0.0) ? 100.0 * below / total : 50.0;
   if(store)
   {
      g_bins = bins;
      ArrayResize(g_bin, bins);
      ArrayResize(g_binBuy, bins);
      for(int b = 0; b < bins; b++)
      {
         g_bin[b] = vol[b];
         g_binBuy[b] = buy[b];
      }
      g_vpLo = ll;
      g_vpHi = hh;
      g_poc = ll + ((double)poc + 0.5) * step;
      g_val = ll + (double)lo * step;
      g_vah = ll + (double)(hi + 1) * step;
   }
   return score;
}

double ScoreCausal(int i, int dir, int res)
{
   double s = 20.0;
   if(res == dir)
      s += 20.0;
   double imb = 2.0 * (DistAt(i) - 50.0);
   double volAlign = 0.0;
   if(dir > 0 && imb > 0.0)
      volAlign = QaiClamp(imb / 25.0, 0.0, 1.0);
   if(dir < 0 && imb < 0.0)
      volAlign = QaiClamp((-imb) / 25.0, 0.0, 1.0);
   s += 12.0 * volAlign;
   double adxF = QaiClamp(g_adx[i] / 35.0, 0.0, 1.0);
   int back = i - 3;
   if(back < 0)
      back = 0;
   double slope = g_ker[i] - g_ker[back];
   bool slopeOk = (dir > 0 && slope >= 0.0) || (dir < 0 && slope <= 0.0);
   s += slopeOk ? (12.0 * adxF) : 3.0;
   double loc = ProfileAt(i, false);
   double locScore;
   if(dir > 0)
      locScore = (loc <= 50.0) ? 1.0 : (loc <= 75.0 ? 0.45 : 0.15);
   else
      locScore = (loc >= 50.0) ? 1.0 : (loc >= 25.0 ? 0.45 : 0.15);
   s += 12.0 * locScore;
   int vs = VolStateAt(i);
   if(vs == 2) s += 14.0;
   else if(vs == 3) s += 10.0;
   else if(vs == 1) s += 6.0;
   else s += 3.0;
   if(g_intTrend == dir)
      s += 10.0;
   else
      s += 2.0;
   return QaiClamp(s, 0.0, 100.0);
}

void RememberOB(int i1, int i2, double top, double bot, int kind)
{
   if(i1 < 0)
      return;
   if(top < bot)
   {
      double t = top;
      top = bot;
      bot = t;
   }
   if(top - bot <= _Point)
      return;
   int slot = g_obCount % 8;
   g_ob[slot].i1 = i1;
   g_ob[slot].i2 = i2;
   g_ob[slot].top = top;
   g_ob[slot].bot = bot;
   g_ob[slot].kind = kind;
   g_ob[slot].alive = true;
   g_ob[slot].retested = false;
   g_ob[slot].used = true;
   g_obCount++;
}

void MakeOB(int breakIdx, int pivotIdx, int dir)
{
   if(pivotIdx < 0 || breakIdx <= pivotIdx)
      return;
   int best = pivotIdx;
   if(dir > 0)
   {
      for(int k = pivotIdx; k < breakIdx; k++)
      {
         if(g_lo[k] < g_lo[best])
            best = k;
      }
   }
   else
   {
      for(int k = pivotIdx; k < breakIdx; k++)
      {
         if(g_hi[k] > g_hi[best])
            best = k;
      }
   }
   RememberOB(best, breakIdx, g_hi[best], g_lo[best], dir);
}

void RememberFVG(int i1, int i2, double top, double bot, int kind)
{
   if(top < bot)
   {
      double t = top;
      top = bot;
      bot = t;
   }
   if(top - bot <= _Point)
      return;
   int slot = g_fvgCount % 6;
   g_fvg[slot].i1 = i1;
   g_fvg[slot].i2 = i2;
   g_fvg[slot].top = top;
   g_fvg[slot].bot = bot;
   g_fvg[slot].kind = kind;
   g_fvg[slot].alive = true;
   g_fvg[slot].retested = false;
   g_fvg[slot].used = true;
   g_fvgCount++;
}

void Mitigate(int i, int last)
{
   int obN = g_obCount;
   if(obN > 8)
      obN = 8;
   for(int z = 0; z < obN; z++)
   {
      if(!g_ob[z].used || !g_ob[z].alive)
         continue;
      if(g_ob[z].kind > 0)
      {
         if(g_lo[i] <= g_ob[z].top && g_hi[i] >= g_ob[z].bot && !g_ob[z].retested)
         {
            g_ob[z].retested = true;
            if(i == last)
               g_ev[AL_OBRU] = true;
         }
         if(g_lo[i] < g_ob[z].bot)
         {
            g_ob[z].alive = false;
            g_ob[z].i2 = i;
            if(i == last)
               g_ev[AL_OBBU] = true;
         }
      }
      else
      {
         if(g_hi[i] >= g_ob[z].bot && g_lo[i] <= g_ob[z].top && !g_ob[z].retested)
         {
            g_ob[z].retested = true;
            if(i == last)
               g_ev[AL_OBRD] = true;
         }
         if(g_hi[i] > g_ob[z].top)
         {
            g_ob[z].alive = false;
            g_ob[z].i2 = i;
            if(i == last)
               g_ev[AL_OBBD] = true;
         }
      }
   }
   int fn = g_fvgCount;
   if(fn > 6)
      fn = 6;
   for(int z = 0; z < fn; z++)
   {
      if(!g_fvg[z].used || !g_fvg[z].alive)
         continue;
      if(g_fvg[z].kind > 0 && g_lo[i] <= g_fvg[z].bot)
      {
         g_fvg[z].alive = false;
         g_fvg[z].i2 = i;
      }
      if(g_fvg[z].kind < 0 && g_hi[i] >= g_fvg[z].top)
      {
         g_fvg[z].alive = false;
         g_fvg[z].i2 = i;
      }
   }
}

int ResAt(int i)
{
   if(i < 5)
      return 0;
   int a = i - 49;
   if(a < 0)
      a = 0;
   double hh = g_hi[a];
   double ll = g_lo[a];
   for(int k = a; k <= i; k++)
   {
      if(g_hi[k] > hh)
         hh = g_hi[k];
      if(g_lo[k] < ll)
         ll = g_lo[k];
   }
   double loc = (hh > ll) ? 100.0 * (g_cl[i] - ll) / (hh - ll) : 50.0;
   if(loc >= 55.0 && g_rsi[i] >= 55.0)
      return 1;
   if(loc <= 45.0 && g_rsi[i] <= 45.0)
      return -1;
   return 0;
}

void InvalidatePlan()
{
   if(!g_hasPlan || g_planIdx < 0)
      return;
   g_invIdx = g_planIdx;
   g_invPx = g_entry;
   g_invDir = g_posDir;
   g_hasPlan = false;
   g_posDir = 0;
   g_be = false;
}

void NoteSweep(int i, int last, int dir)
{
   PushMark(i, MK_SWEEP);
   if(i == last)
      g_ev[AL_SWEEP] = true;
   if(ResAt(i) == dir)
   {
      if(i == last)
         g_ev[AL_SWRES] = true;
      if(g_posDir != 0 && g_posDir != dir)
         InvalidatePlan();
   }
}

void OpenPos(int i, int dir)
{
   if(g_hasPlan && g_posDir != 0 && g_posDir != dir)
      InvalidatePlan();
   double atr = g_atr[i];
   if(atr < _Point * 5.0)
      atr = _Point * 5.0;
   double minD = atr * wMinAtr;
   double maxD = atr * wMaxAtr;
   double entry = g_cl[i];
   double sl;
   if(dir > 0)
   {
      double structStop = (g_swOk ? g_swLo : entry) - atr * 0.10;
      double distS = entry - structStop;
      if(distS >= minD && distS <= maxD)
         sl = structStop;
      else
         sl = entry - atr * wAtrMult;
      if(entry - sl < minD)
         sl = entry - minD;
      if(entry - sl > maxD)
         sl = entry - maxD;
   }
   else
   {
      double structStop = (g_swOk ? g_swHi : entry) + atr * 0.10;
      double distS = structStop - entry;
      if(distS >= minD && distS <= maxD)
         sl = structStop;
      else
         sl = entry + atr * wAtrMult;
      if(sl - entry < minD)
         sl = entry + minD;
      if(sl - entry > maxD)
         sl = entry + maxD;
   }
   double risk = MathAbs(entry - sl);
   if(risk < _Point)
      risk = _Point;
   g_posDir = dir;
   g_planIdx = i;
   g_entry = entry;
   g_sl = sl;
   g_trail = sl;
   g_be = false;
   g_hasPlan = true;
   g_tp1 = entry + (double)dir * wTp1 * risk;
   g_tp2 = entry + (double)dir * wTp2 * risk;
   g_tp3 = entry + (double)dir * wTp3 * risk;
   g_lastConfirm = i;
}

void UpdatePos(int i, int last)
{
   if(g_posDir == 0 || i <= g_planIdx)
      return;
   double atr = g_atr[i];
   if(atr < _Point)
      atr = _Point;
   if(g_posDir > 0)
   {
      if(g_lo[i] <= g_trail)
      {
         g_posDir = 0;
         return;
      }
      if(!g_be && g_hi[i] >= g_tp1)
      {
         g_be = true;
         if(g_entry > g_trail)
            g_trail = g_entry;
         if(i == last)
            g_ev[AL_TP1] = true;
      }
      if(g_be)
      {
         double nsl = g_cl[i] - atr * wTrail;
         if(nsl > g_trail)
            g_trail = nsl;
      }
   }
   else
   {
      if(g_hi[i] >= g_trail)
      {
         g_posDir = 0;
         return;
      }
      if(!g_be && g_lo[i] <= g_tp1)
      {
         g_be = true;
         if(g_entry < g_trail)
            g_trail = g_entry;
         if(i == last)
            g_ev[AL_TP1] = true;
      }
      if(g_be)
      {
         double nsl = g_cl[i] + atr * wTrail;
         if(nsl < g_trail)
            g_trail = nsl;
      }
   }
}

void TrySignal(int i, bool bosUp, bool bosDn)
{
   if(i < 6)
      return;
   if(!InSession(g_tm[i]))
      return;
   bool crossUp = (g_wt1[i] > g_wt2[i] && g_wt1[i - 1] <= g_wt2[i - 1]);
   bool crossDn = (g_wt1[i] < g_wt2[i] && g_wt1[i - 1] >= g_wt2[i - 1]);
   int dir = 0;
   if(wRange)
   {
      double loc = ProfileAt(i, false);
      if(loc <= 30.0 && crossUp)
         dir = 1;
      if(loc >= 70.0 && crossDn)
         dir = -1;
   }
   else
   {
      if(crossUp || bosUp)
         dir = 1;
      if(crossDn || bosDn)
         dir = -1;
      if(crossUp)
         dir = 1;
      if(crossDn)
         dir = -1;
   }
   if(dir == 0)
      return;
   if(g_lastConfirm >= 0 && (i - g_lastConfirm) < wCool)
      return;
   double f1 = ProfileAt(i, false);
   double f2 = g_rsi[i];
   int res = 0;
   if(f1 >= 55.0 && f2 >= 55.0)
      res = 1;
   else if(f1 <= 45.0 && f2 <= 45.0)
      res = -1;
   if(res != dir)
      return;
   bool momOk = (dir > 0) ? (g_wt1[i] < 60.0) : (g_wt1[i] > -60.0);
   if(!momOk)
      return;
   double score = ScoreCausal(i, dir, res);
   if(score < InpMinScore)
      return;
   PushMark(i, (dir > 0) ? MK_BUY : MK_SELL);
   OpenPos(i, dir);
   if(i == g_n - 2)
      g_ev[(dir > 0) ? AL_BUY : AL_SELL] = true;
}

void ShiftPivot(double &px[], int &ix[], int &n, double price, int idx)
{
   if(n < 4)
   {
      px[n] = price;
      ix[n] = idx;
      n++;
      return;
   }
   for(int k = 0; k < 3; k++)
   {
      px[k] = px[k + 1];
      ix[k] = ix[k + 1];
   }
   px[3] = price;
   ix[3] = idx;
}

double SmaVol(int i, int len)
{
   int a = i - len + 1;
   if(a < 0)
      a = 0;
   double s = 0.0;
   int m = 0;
   for(int k = a; k <= i; k++)
   {
      s += g_vol[k];
      m++;
   }
   if(m <= 0)
      return 0.0;
   return s / (double)m;
}

void Rebuild()
{
   int last = g_n - 2;
   if(last < 80)
      return;
   ApplyMode();
   ArrayResize(g_marks, 0);
   g_obCount = 0;
   g_fvgCount = 0;
   for(int z = 0; z < 8; z++)
      g_ob[z].used = false;
   for(int z = 0; z < 6; z++)
      g_fvg[z].used = false;
   for(int a = 0; a < AL_COUNT; a++)
      g_ev[a] = false;
   g_posDir = 0;
   g_hasPlan = false;
   g_invIdx = -1;
   g_invDir = 0;
   g_planIdx = -1;
   g_lastConfirm = -1;
   g_latestKind = 0;
   g_latestIdx = -1;
   g_be = false;
   g_intTrend = 0;
   g_swOk = false;

   bool iHiSet = false, iLoSet = false;
   double iHi = 0.0, iLo = 0.0;
   int iHiI = -1, iLoI = -1;
   bool sHiSet = false, sLoSet = false;
   double sHi = 0.0, sLo = 0.0;
   int sHiI = -1, sLoI = -1;
   double phPx[4], plPx[4];
   int phIx[4], plIx[4];
   int phN = 0, plN = 0;
   int prevVs = -1;

   for(int i = 0; i <= last; i++)
   {
      UpdatePos(i, last);

      bool bosUp = false, bosDn = false, chUp = false, chDn = false;
      bool swept = false;
      if(sHiSet && g_hi[i] > sHi && g_cl[i] < sHi)
      {
         NoteSweep(i, last, -1);
         swept = true;
         PushMark(i, MK_FALSE);
         if(i == last)
            g_ev[AL_FALSE] = true;
      }
      else if(iHiSet && g_hi[i] > iHi && g_cl[i] < iHi)
      {
         NoteSweep(i, last, -1);
         swept = true;
         PushMark(i, MK_FALSE);
         if(i == last)
            g_ev[AL_FALSE] = true;
      }
      if(!swept && sLoSet && g_lo[i] < sLo && g_cl[i] > sLo)
      {
         NoteSweep(i, last, 1);
         swept = true;
         PushMark(i, MK_FALSE);
         if(i == last)
            g_ev[AL_FALSE] = true;
      }
      else if(!swept && iLoSet && g_lo[i] < iLo && g_cl[i] > iLo)
      {
         NoteSweep(i, last, 1);
         PushMark(i, MK_FALSE);
         if(i == last)
            g_ev[AL_FALSE] = true;
      }

      if(sHiSet && g_cl[i] > sHi)
      {
         int rd = ResAt(i);
         if(rd == 1)
         {
            PushMark(i, MK_VALID);
            if(g_posDir < 0)
               InvalidatePlan();
         }
         else
         {
            PushMark(i, MK_FALSE);
            if(i == last)
               g_ev[AL_FALSE] = true;
         }
         MakeOB(i, sHiI, 3);
         sHiSet = false;
      }
      if(sLoSet && g_cl[i] < sLo)
      {
         int rd = ResAt(i);
         if(rd == -1)
         {
            PushMark(i, MK_VALID);
            if(g_posDir > 0)
               InvalidatePlan();
         }
         else
         {
            PushMark(i, MK_FALSE);
            if(i == last)
               g_ev[AL_FALSE] = true;
         }
         MakeOB(i, sLoI, -3);
         sLoSet = false;
      }

      if(iHiSet && g_cl[i] > iHi)
      {
         if(g_intTrend < 0)
            chUp = true;
         else
            bosUp = true;
         g_intTrend = 1;
         iHiSet = false;
         MakeOB(i, iHiI, 1);
         if(ResAt(i) == 1)
         {
            PushMark(i, MK_VALID);
            bosUp = true;
         }
         else
         {
            PushMark(i, MK_FALSE);
            bosUp = false;
            if(i == last)
               g_ev[AL_FALSE] = true;
         }
         PushMark(i, chUp ? MK_CHU : MK_BOSU);
         if(i == last)
            g_ev[chUp ? AL_CHU : AL_BOSU] = true;
      }
      if(iLoSet && g_cl[i] < iLo)
      {
         if(g_intTrend > 0)
            chDn = true;
         else
            bosDn = true;
         g_intTrend = -1;
         iLoSet = false;
         MakeOB(i, iLoI, -1);
         if(ResAt(i) == -1)
         {
            PushMark(i, MK_VALID);
            bosDn = true;
         }
         else
         {
            PushMark(i, MK_FALSE);
            bosDn = false;
            if(i == last)
               g_ev[AL_FALSE] = true;
         }
         PushMark(i, chDn ? MK_CHD : MK_BOSD);
         if(i == last)
            g_ev[chDn ? AL_CHD : AL_BOSD] = true;
      }
      if(chUp)
      {
         PushMark(i, MK_TBULL);
         if(g_posDir < 0)
            InvalidatePlan();
         if(i == last)
            g_ev[AL_TBULL] = true;
      }
      if(chDn)
      {
         PushMark(i, MK_TBEAR);
         if(g_posDir > 0)
            InvalidatePlan();
         if(i == last)
            g_ev[AL_TBEAR] = true;
      }

      int cI = i - wInt;
      if(PivotHigh(cI, wInt, wInt, last))
      {
         iHi = g_hi[cI];
         iHiI = cI;
         iHiSet = true;
      }
      if(PivotLow(cI, wInt, wInt, last))
      {
         iLo = g_lo[cI];
         iLoI = cI;
         iLoSet = true;
      }

      int cS = i - wSw;
      if(PivotHigh(cS, wSw, wSw, last))
      {
         sHi = g_hi[cS];
         sHiI = cS;
         sHiSet = true;
         g_swOk = (sLoI >= 0);
         PushMark(cS, MK_RES);
         ShiftPivot(phPx, phIx, phN, g_hi[cS], cS);
      }
      if(PivotLow(cS, wSw, wSw, last))
      {
         if(plN >= 1 && g_lo[cS] < plPx[plN - 1] && g_cl[cS] > plPx[plN - 1])
            PushMark(cS, MK_SHAKE);
         double loc = ProfileAt(cS, false);
         double avg = SmaVol(cS, 20);
         if(g_cl[cS] > g_op[cS] && avg > 0.0 && g_vol[cS] > avg * 1.40 && loc < 40.0)
            PushMark(cS, MK_ACC);
         sLo = g_lo[cS];
         sLoI = cS;
         sLoSet = true;
         g_swOk = (sHiI >= 0);
         PushMark(cS, MK_SUP);
         ShiftPivot(plPx, plIx, plN, g_lo[cS], cS);
      }

      if(i >= 2 && g_atr[i] > 0.0)
      {
         double gapUp = g_lo[i] - g_hi[i - 2];
         double gapDn = g_lo[i - 2] - g_hi[i];
         if(gapUp > g_atr[i] * 0.15 && g_cl[i - 1] > g_hi[i - 2])
            RememberFVG(i - 2, i, g_lo[i], g_hi[i - 2], 2);
         if(gapDn > g_atr[i] * 0.15 && g_cl[i - 1] < g_lo[i - 2])
            RememberFVG(i - 2, i, g_lo[i - 2], g_hi[i], -2);
      }

      Mitigate(i, last);

      int vs = VolStateAt(i);
      if(bosUp && (vs == 2 || vs == 3))
         PushMark(i, MK_MARKUP);
      if(bosDn && (vs == 2 || vs == 3))
         PushMark(i, MK_SELLO);
      if(i == last && prevVs != 2 && vs == 2)
         g_ev[AL_EXPL] = true;
      prevVs = vs;

      if(g_swOk)
      {
         g_swHi = sHi;
         g_swLo = sLo;
         g_swHiI = sHiI;
         g_swLoI = sLoI;
      }
      TrySignal(i, bosUp, bosDn);
   }

   g_swHi = sHi;
   g_swLo = sLo;
   g_swHiI = sHiI;
   g_swLoI = sLoI;
   g_swOk = (sHiSet && sLoSet && sHi > sLo);

   g_tlKind = 0;
   if(phN >= 2 && phPx[phN - 1] < phPx[phN - 2])
   {
      g_tlKind = -1;
      g_tlI1 = phIx[phN - 2];
      g_tlI2 = phIx[phN - 1];
      g_tly1 = phPx[phN - 2];
      g_tly2 = phPx[phN - 1];
   }
   else if(plN >= 2 && plPx[plN - 1] > plPx[plN - 2])
   {
      g_tlKind = 1;
      g_tlI1 = plIx[plN - 2];
      g_tlI2 = plIx[plN - 1];
      g_tly1 = plPx[plN - 2];
      g_tly2 = plPx[plN - 1];
   }
   if(g_tlKind != 0 && g_tlI2 != g_tlI1)
   {
      double s = (g_tly2 - g_tly1) / (double)(g_tlI2 - g_tlI1);
      double at = g_tly1 + s * (double)(last - g_tlI1);
      if(g_tlKind < 0 && g_cl[last] > at && g_cl[last - 1] <= g_tly1 + s * (double)(last - 1 - g_tlI1))
         g_ev[AL_RESBR] = true;
      if(g_tlKind > 0 && g_cl[last] < at && g_cl[last - 1] >= g_tly1 + s * (double)(last - 1 - g_tlI1))
         g_ev[AL_SUPBR] = true;
   }

   g_regOk = false;
   int b = last - 1;
   int a = b - wChan + 1;
   if(a < 0)
      a = 0;
   if(b - a >= 10 && QaiLinReg(g_cl, a, b, g_regSlope, g_regIcept, g_regSd))
   {
      g_regOk = true;
      g_regA = a;
      g_regB = b;
      double up = g_regIcept + g_regSlope * (double)(last - a) + g_regSd;
      double dn = g_regIcept + g_regSlope * (double)(last - a) - g_regSd;
      double upPrev = g_regIcept + g_regSlope * (double)(last - 1 - a) + g_regSd;
      double dnPrev = g_regIcept + g_regSlope * (double)(last - 1 - a) - g_regSd;
      if(g_cl[last] > up && g_cl[last - 1] <= upPrev)
         g_ev[AL_CHUP] = true;
      if(g_cl[last] < dn && g_cl[last - 1] >= dnPrev)
         g_ev[AL_CHDN] = true;
   }

   FillState(last);
}

string BucketOf(double strength)
{
   if(strength >= 32.0)
      return "Strong";
   if(strength >= 22.0)
      return "Medium";
   return "Weak";
}

string BiasOf(int sign, bool ranging)
{
   if(ranging && sign > 0) return "Ranging Bullish";
   if(ranging && sign < 0) return "Ranging Bearish";
   if(sign > 1) return "Strong Bullish";
   if(sign == 1) return "Moderate Bullish";
   if(sign < -1) return "Strong Bearish";
   if(sign == -1) return "Moderate Bearish";
   return "Neutral";
}

void ReadTf(ENUM_TIMEFRAMES tf, int slot)
{
   g_st.tfBias[slot] = "n/a";
   g_st.tfStr[slot] = 0.0;
   g_st.tfSign[slot] = 0;
   g_st.tfBucket[slot] = "-";
   MqlRates r[];
   ArraySetAsSeries(r, false);
   int got = CopyRates(_Symbol, tf, 1, 180, r);
   if(got < 80)
      return;
   double cl[], hi[], lo[];
   ArrayResize(cl, got);
   ArrayResize(hi, got);
   ArrayResize(lo, got);
   for(int i = 0; i < got; i++)
   {
      cl[i] = r[i].close;
      hi[i] = r[i].high;
      lo[i] = r[i].low;
   }
   double emaF[], emaS[], rsi[], atr[];
   QaiEma(cl, got, 21, emaF);
   QaiEma(cl, got, 55, emaS);
   QaiRsi(cl, got, 14, rsi);
   QaiAtr(hi, lo, cl, got, 14, atr);
   int i = got - 1;
   double strength = MathAbs(rsi[i] - 50.0) * 2.0;
   bool stackedUp = (cl[i] > emaF[i] && emaF[i] > emaS[i]);
   bool stackedDn = (cl[i] < emaF[i] && emaF[i] < emaS[i]);
   bool ranging = (atr[i] > 0.0 && MathAbs(cl[i] - emaS[i]) < atr[i] * 0.35 && !stackedUp && !stackedDn);
   bool tight = (ranging && strength < 25.0);
   int sign = 0;
   if(tight)
      sign = 0;
   else if(stackedUp && strength >= 32.0)
      sign = 2;
   else if(stackedDn && strength >= 32.0)
      sign = -2;
   else if(cl[i] >= emaS[i])
      sign = 1;
   else
      sign = -1;
   g_st.tfStr[slot] = strength;
   if(sign > 0)
      g_st.tfSign[slot] = 1;
   else if(sign < 0)
      g_st.tfSign[slot] = -1;
   else
      g_st.tfSign[slot] = 0;
   if(tight)
      g_st.tfBias[slot] = "Tight Consolidation";
   else
      g_st.tfBias[slot] = BiasOf(sign, ranging);
   g_st.tfBucket[slot] = BucketOf(strength);
}

int AtrPercentile(int i)
{
   int a = i - 99;
   if(a < 0)
      a = 0;
   int below = 0, tot = 0;
   for(int k = a; k <= i; k++)
   {
      tot++;
      if(g_atr[k] <= g_atr[i])
         below++;
   }
   if(tot <= 0)
      return 50;
   return (int)MathRound(100.0 * (double)below / (double)tot);
}

void SetStep(int n, int st, const string txt)
{
   g_st.stepSt[n] = st;
   g_st.stepTxt[n] = txt;
}

void FillChecklist(int last, int dir)
{
   for(int s = 0; s < 7; s++)
      SetStep(s, 0, "-");
   g_st.passes = 0;
   g_st.sizeText = "Stand aside";
   if(dir == 0)
   {
      SetStep(0, 0, "No direction");
      return;
   }

   bool neutral = (StringFind(g_st.stance, "Unclear") >= 0 || StringFind(g_st.stance, "Cash is King") >= 0);
   if(neutral)
      SetStep(0, 0, "Unclear - stand aside");
   else
      SetStep(0, 1, "Clear");

   bool fresh = (g_lastConfirm >= 0 && (last - g_lastConfirm) <= InpLife && (g_latestKind == MK_BUY || g_latestKind == MK_SELL));
   bool freshDir = false;
   if(fresh)
      freshDir = ((g_latestKind == MK_BUY && dir > 0) || (g_latestKind == MK_SELL && dir < 0));
   if(freshDir)
      SetStep(1, 1, (dir > 0) ? "Buy confirmed" : "Sell confirmed");
   else if(g_latestKind == MK_TBULL || g_latestKind == MK_TBEAR)
      SetStep(1, 0, "Early warning only");
   else
      SetStep(1, 0, "No confirmation");

   if(g_st.resDir == dir)
      SetStep(2, 1, (dir > 0) ? "Resonant Long" : "Resonant Short");
   else if(g_st.resDir == 0)
      SetStep(2, 0, "Waiting for Resonance");
   else
      SetStep(2, 0, "Resonance disagrees");

   int vs = VolStateAt(last);
   if(wRange)
   {
      if(vs == 0 || vs == 1)
         SetStep(3, 1, VolName(vs));
      else
         SetStep(3, 0, "Breakout - leave range mode");
   }
   else
   {
      if(vs == 2 || vs == 3)
         SetStep(3, 1, VolName(vs));
      else
         SetStep(3, 0, VolName(vs) + " - skip");
   }

   bool consec = false;
   for(int k = 0; k <= 2; k++)
   {
      int s0 = g_st.tfSign[k];
      int s1 = g_st.tfSign[k + 1];
      int s2 = g_st.tfSign[k + 2];
      if(s0 == dir && s1 == dir && s2 == dir)
         consec = true;
   }
   bool htfAgainst = (g_st.tfSign[3] == -dir && g_st.tfSign[4] == -dir);
   if(!consec)
      SetStep(4, 0, "No 3-row run");
   else if(htfAgainst)
      SetStep(4, 2, "HTF against - reduce");
   else
      SetStep(4, 1, "3+ timeframes agree");

   double th = g_st.thermo;
   if(dir > 0)
   {
      if(th > 80.0)
         SetStep(5, 0, "Too hot to chase");
      else if(th >= 20.0 && th <= 60.0)
         SetStep(5, 1, "Safe zone");
      else
         SetStep(5, 2, "Outside the sweet spot");
   }
   else
   {
      if(th < 20.0)
         SetStep(5, 0, "Too cold to chase");
      else if(th >= 40.0 && th <= 80.0)
         SetStep(5, 1, "Safe zone");
      else
         SetStep(5, 2, "Outside the sweet spot");
   }

   double imb = 2.0 * (DistAt(last) - 50.0);
   if(dir > 0 && imb >= 8.0)
      SetStep(6, 1, "Bulls in control");
   else if(dir < 0 && imb <= -8.0)
      SetStep(6, 1, "Bears in control");
   else if(MathAbs(imb) < 8.0)
      SetStep(6, 2, "Balanced - reduce");
   else
      SetStep(6, 0, "Flow disagrees");

   int passes = 0;
   for(int s = 0; s < 7; s++)
   {
      if(g_st.stepSt[s] == 1)
         passes++;
   }
   g_st.passes = passes;
   bool hard = (g_st.stepSt[0] == 0 || g_st.stepSt[2] == 0 || g_st.stepSt[3] == 0 || g_st.stepSt[5] == 0);
   if(hard)
      g_st.sizeText = "Stand aside";
   else if(passes >= 7)
      g_st.sizeText = "Full size";
   else if(passes >= 5)
      g_st.sizeText = "Half size";
   else if(passes >= 4)
      g_st.sizeText = "Light 30%";
   else
      g_st.sizeText = "Stand aside";
}

string ThermoName(double th)
{
   if(th > 60.0)
      return "Bullish Markup";
   if(th < 40.0)
      return "Bearish Markdown";
   return "Equilibrium Zone";
}

void FillState(int last)
{
   for(int s = 0; s < 5; s++)
   {
      ENUM_TIMEFRAMES tf = InpTF1;
      if(s == 1) tf = InpTF2;
      if(s == 2) tf = InpTF3;
      if(s == 3) tf = InpTF4;
      if(s == 4) tf = InpTF5;
      ReadTf(tf, s);
   }
   int bulls = 0, bears = 0;
   bool allSame = true;
   int sign0 = 0;
   for(int s = 0; s < 5; s++)
   {
      int sg = g_st.tfSign[s];
      if(sg > 0) bulls++;
      if(sg < 0) bears++;
      if(sg == 0)
         allSame = false;
      else if(sign0 == 0)
         sign0 = sg;
      else if(sign0 != sg)
         allSame = false;
   }
   g_st.htfOk = allSame && sign0 != 0;
   g_st.htfText = g_st.htfOk ? "Resonant" : "No Resonance";

   g_st.vpScore = ProfileAt(last, true);
   g_st.momScore = g_rsi[last];
   g_st.resDir = 0;
   if(g_st.vpScore >= 55.0 && g_st.momScore >= 55.0)
      g_st.resDir = 1;
   else if(g_st.vpScore <= 45.0 && g_st.momScore <= 45.0)
      g_st.resDir = -1;
   if(g_st.resDir > 0)
      g_st.biasText = "Resonance Bull";
   else if(g_st.resDir < 0)
      g_st.biasText = "Resonance Bear";
   else
      g_st.biasText = "Waiting";
   g_core = 0.5 * (g_st.vpScore + g_st.momScore);

   int htfSign = 0;
   if(bulls > bears)
      htfSign = 1;
   else if(bears > bulls)
      htfSign = -1;
   int local = g_st.resDir;
   if(local == 0)
      local = (g_st.momScore >= 50.0) ? 1 : -1;
   int vs = VolStateAt(last);
   int back = last - 3;
   if(back < 0)
      back = 0;
   double slope = g_ker[last] - g_ker[back];
   double loc = g_st.vpScore;
   if(slope < 0.0 && g_adx[last] >= 18.0 && loc < 70.0)
      g_phase = "Markdown";
   else if(slope > 0.0 && g_adx[last] >= 18.0 && loc > 30.0)
      g_phase = "Markup";
   else if(loc >= 55.0)
      g_phase = "Distribution";
   else if(loc <= 45.0)
      g_phase = "Accumulation";
   else
      g_phase = "Balance";

   if(!wRange && vs == 0 && g_st.resDir == 0)
      g_st.stance = "Coiling - Wait For Break";
   else if(g_phase == "Distribution" && local > 0)
      g_st.stance = "Bear Distribution - Sell Rallies";
   else if(g_phase == "Markdown" && local > 0)
      g_st.stance = "Bear Distribution - Sell Rallies";
   else if(g_phase == "Accumulation" && local < 0)
      g_st.stance = "Bull Accumulation - Buy Dips";
   else if(g_phase == "Markup" && local < 0)
      g_st.stance = "Bull Accumulation - Buy Dips";
   else if((g_phase == "Markup" || htfSign > 0) && local > 0)
      g_st.stance = "Strong Bullish - Look For Longs";
   else if((g_phase == "Markdown" || htfSign < 0) && local < 0)
      g_st.stance = "Strong Bearish - Look For Shorts";
   else if(wRange && (vs == 2 || vs == 3))
      g_st.stance = "Pause Range - Switch To Trend";
   else
      g_st.stance = "Neutral Bias - Cash is King";

   double erDen = 0.0;
   int erLen = 20;
   if(last >= erLen)
   {
      for(int k = last - erLen + 1; k <= last; k++)
         erDen += MathAbs(g_cl[k] - g_cl[k - 1]);
      double er = (erDen > 0.0) ? MathAbs(g_cl[last] - g_cl[last - erLen]) / erDen : 0.0;
      if(g_adx[last] >= 22.0 || er >= 0.35)
         g_st.regime = "Trending";
      else if(g_adx[last] < 18.0 && er < 0.22)
         g_st.regime = "Ranging";
      else
         g_st.regime = "Transition";
   }
   else
      g_st.regime = "Transition";
   g_st.volText = VolName(vs);

   double imb = 2.0 * (DistAt(last) - 50.0);
   double aimb = MathAbs(imb);
   string side = "Balanced";
   if(imb >= 25.0) side = "Bulls Dominant";
   else if(imb >= 8.0) side = "Bulls in Control";
   else if(imb <= -25.0) side = "Bears Dominant";
   else if(imb <= -8.0) side = "Bears in Control";
   g_st.flowText = side + " (" + DoubleToString(aimb, 0) + "%)";

   g_st.adx = g_adx[last];
   if(g_st.adx < 20.0) g_st.adxTag = "Weak";
   else if(g_st.adx < 30.0) g_st.adxTag = "Medium";
   else g_st.adxTag = "Strong";

   if(g_latestKind == MK_BUY) g_st.latest = "Buy";
   else if(g_latestKind == MK_SELL) g_st.latest = "Sell";
   else if(g_latestKind == MK_TBULL) g_st.latest = "Trend Bull";
   else if(g_latestKind == MK_TBEAR) g_st.latest = "Trend Bear";
   else g_st.latest = "None";

   int since = 10000;
   if(g_lastConfirm >= 0)
      since = last - g_lastConfirm;
   if(wSessOn && !InSession(TimeCurrent()))
      g_st.engine = "Session closed";
   else if(since < wCool)
      g_st.engine = "Cooling " + IntegerToString(wCool - since);
   else
      g_st.engine = "Ready";

   if(g_posDir > 0) g_st.posText = "Long Active";
   else if(g_posDir < 0) g_st.posText = "Short Active";
   else g_st.posText = "Flat";
   g_st.activeStop = (g_posDir != 0) ? g_trail : 0.0;

   int tLen = InpThermoLen;
   if(tLen < 10)
      tLen = 10;
   int a = last - tLen + 1;
   if(a < 0)
      a = 0;
   double hh = g_hi[a], ll = g_lo[a];
   for(int k = a; k <= last; k++)
   {
      if(g_hi[k] > hh) hh = g_hi[k];
      if(g_lo[k] < ll) ll = g_lo[k];
   }
   double px = g_cl[g_n - 1];
   g_st.thermo = (hh > ll) ? QaiClamp(100.0 * (px - ll) / (hh - ll), 0.0, 100.0) : 50.0;
   g_st.thermoTag = ThermoName(g_st.thermo);

   int dir = ActiveDir(last);

   double live = 20.0;
   if(g_st.resDir == dir && dir != 0)
      live += 20.0;
   double volAlign = 0.0;
   if(dir > 0 && imb > 0.0)
      volAlign = QaiClamp(imb / 25.0, 0.0, 1.0);
   if(dir < 0 && imb < 0.0)
      volAlign = QaiClamp((-imb) / 25.0, 0.0, 1.0);
   live += 12.0 * volAlign;
   live += 12.0 * QaiClamp(g_adx[last] / 35.0, 0.0, 1.0);
   if(dir > 0)
      live += 12.0 * ((g_st.thermo <= 50.0) ? 1.0 : 0.4);
   else if(dir < 0)
      live += 12.0 * ((g_st.thermo >= 50.0) ? 1.0 : 0.4);
   int agree = 0;
   for(int s = 0; s < 5; s++)
   {
      if(dir != 0 && g_st.tfSign[s] == dir)
         agree++;
   }
   live += 14.0 * ((double)agree / 5.0);
   if(vs == 2) live += 10.0;
   else if(vs == 3) live += 8.0;
   else if(vs == 1) live += 4.0;
   else live += 2.0;
   g_st.confidence = QaiClamp(live, 0.0, 100.0);

   int tiers = 0;
   if(AtrPercentile(last) >= wDeadPct)
      tiers++;
   double avg = SmaVol(last, 20);
   if(avg <= 0.0 || g_vol[last] >= avg * 0.80)
      tiers++;
   if(dir > 0 && g_wt1[last] < 60.0)
      tiers++;
   if(dir < 0 && g_wt1[last] > -60.0)
      tiers++;
   if(dir == 0)
      tiers++;
   double hist = MathAbs(g_wt1[last] - g_wt2[last]);
   double histP = MathAbs(g_wt1[last - 1] - g_wt2[last - 1]);
   if(hist >= histP || vs != 0)
      tiers++;
   if(dir != 0 && agree >= 3)
      tiers++;
   if(since >= wCool)
      tiers++;
   if(g_lastConfirm >= 0 && (last - g_lastConfirm) <= InpLife)
      tiers++;
   if(wRange)
   {
      if(vs == 0 || vs == 1)
         tiers++;
   }
   else if(vs == 2 || vs == 3)
      tiers++;
   if(tiers > 8)
      tiers = 8;
   g_st.tiers = IntegerToString(tiers) + "/8";

   FillChecklist(last, dir);
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
   if(rates_total < 100)
      return 0;
   if(ArraySize(spread) < 0 || ArraySize(time) < rates_total)
      return 0;

   int n = rates_total;
   if(InpMaxBars > 200 && n > InpMaxBars)
      n = InpMaxBars;
   int start = rates_total - n;
   ArrayResize(g_op, n);
   ArrayResize(g_hi, n);
   ArrayResize(g_lo, n);
   ArrayResize(g_cl, n);
   ArrayResize(g_vol, n);
   ArrayResize(g_buy, n);
   ArrayResize(g_sell, n);
   ArrayResize(g_tm, n);
   for(int i = 0; i < n; i++)
   {
      int src = start + i;
      g_op[i] = open[src];
      g_hi[i] = high[src];
      g_lo[i] = low[src];
      g_cl[i] = close[src];
      g_tm[i] = time[src];
      double tv = (double)tick_volume[src];
      double rv = (double)volume[src];
      g_vol[i] = (tv > 0.0) ? tv : rv;
      if(g_vol[i] <= 0.0)
         g_vol[i] = 1.0;
      double range = g_hi[i] - g_lo[i];
      double buyFrac = 0.5;
      if(range > 0.0)
         buyFrac = (g_cl[i] - g_lo[i]) / range;
      buyFrac = QaiClamp(buyFrac, 0.0, 1.0);
      g_buy[i] = g_vol[i] * buyFrac;
      g_sell[i] = g_vol[i] - g_buy[i];
   }
   g_n = n;

   double ap[];
   ArrayResize(ap, n);
   for(int i = 0; i < n; i++)
      ap[i] = (g_hi[i] + g_lo[i] + g_cl[i]) / 3.0;

   ApplyMode();
   QaiAtr(g_hi, g_lo, g_cl, n, InpAtrLen, g_atr);
   QaiRsi(g_cl, n, 14, g_rsi);
   QaiAdx(g_hi, g_lo, g_cl, n, 14, g_adx);
   QaiWaveTrend(ap, n, 10, 21, 4, g_wt1, g_wt2);
   double mid[];
   QaiBollinger(g_cl, n, 20, 2.0, mid, g_bbU, g_bbD);
   QaiKeltner(mid, g_atr, n, 1.5, g_kcU, g_kcD);

   ArrayResize(g_ker, n);
   static int s_kernelN = 0;
   static datetime s_kernelT0 = 0;
   bool kernelFull = (prev_calculated == 0 || s_kernelN != n || s_kernelT0 != g_tm[0]);
   int kFirst = kernelFull ? 0 : (n - 1);
   if(kFirst < 0)
      kFirst = 0;
   int fastH = wKern / 3;
   if(fastH < 8)
      fastH = 8;
   for(int i = kFirst; i < n; i++)
      g_ker[i] = QaiKernelAt(g_cl, i, wKern, wAlpha);
   s_kernelN = n;
   s_kernelT0 = g_tm[0];

   ArrayInitialize(KernelBuf, EMPTY_VALUE);
   ArrayInitialize(FastBuf, EMPTY_VALUE);
   if(InpKernel)
   {
      for(int i = 0; i < n; i++)
      {
         int shift = rates_total - 1 - (start + i);
         if(shift >= 0 && shift < rates_total)
         {
            KernelBuf[shift] = g_ker[i];
            FastBuf[shift] = QaiKernelAt(g_cl, i, fastH, wAlpha);
         }
      }
   }

   static datetime s_closed = 0;
   datetime closed = g_tm[n - 2];
   bool rebuild = (prev_calculated == 0 || closed != s_closed || s_closed == 0);
   s_closed = closed;
   if(rebuild)
   {
      Rebuild();
      ClearDrawings();
      DrawAll();
      if(prev_calculated > 0)
         Dispatch();
   }
   else
   {
      int last = n - 2;
      int tLen = InpThermoLen;
      if(tLen < 10)
         tLen = 10;
      int a = last - tLen + 1;
      if(a < 0)
         a = 0;
      double hh = g_hi[a], ll = g_lo[a];
      for(int k = a; k <= last; k++)
      {
         if(g_hi[k] > hh) hh = g_hi[k];
         if(g_lo[k] < ll) ll = g_lo[k];
      }
      double px = g_cl[n - 1];
      g_st.thermo = (hh > ll) ? QaiClamp(100.0 * (px - ll) / (hh - ll), 0.0, 100.0) : 50.0;
      g_st.thermoTag = ThermoName(g_st.thermo);
      FillChecklist(last, ActiveDir(last));
   }
   DrawPanels();
   return rates_total;
}

void Dispatch()
{
   string name[21] = {
      "Buy confirmed", "Sell confirmed", "Trend Bull", "Trend Bear",
      "BOS bullish", "BOS bearish", "CHoCH bullish", "CHoCH bearish",
      "Bullish OB break", "Bearish OB break", "Bullish OB retest", "Bearish OB retest",
      "Channel breakout up", "Channel breakdown", "Resistance break", "Support break",
      "Volatility explosion", "TP1 break-even",
      "Liquidity sweep", "Sweep plus resonance", "False breakout"
   };
   for(int i = 0; i < AL_COUNT; i++)
   {
      if(!g_ev[i])
         continue;
      string msg = "QAI " + _Symbol + " " + name[i] + " @ " + DoubleToString(g_cl[g_n - 2], _Digits);
      if(InpAlert)
         Alert(msg);
      if(InpPush)
         SendNotification(msg);
      if(InpMail)
         SendMail("Quantum AI", msg);
      if(StringLen(InpWebhook) > 8)
         PostHook(msg);
      g_ev[i] = false;
   }
}

void PostHook(const string msg)
{
   string body;
   if(StringLen(InpChatId) > 0)
      body = "{\"chat_id\":\"" + InpChatId + "\",\"text\":\"" + msg + "\"}";
   else
      body = "{\"text\":\"" + msg + "\"}";
   uchar data[];
   uchar result[];
   string headers;
   StringToCharArray(body, data, 0, StringLen(body), CP_UTF8);
   string hdr = "Content-Type: application/json\r\n";
   int code = WebRequest("POST", InpWebhook, hdr, 3000, data, result, headers);
   if(code == -1)
   {
      static bool told = false;
      if(!told)
      {
         Print("QAI webhook was refused. Add the URL under Tools - Options - Expert Advisors - Allow WebRequest.");
         told = true;
      }
   }
}

string Px(double v)
{
   return DoubleToString(v, _Digits);
}

void StyleObj(const string name)
{
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void TagBox(const string name, datetime t, double price, const string text, color bg, color fg)
{
   double atr = g_atr[g_n - 2];
   if(atr <= 0.0)
      atr = _Point * 20.0;
   double half = atr * 0.28;
   int sec = PeriodSeconds();
   if(sec <= 0)
      sec = 60;
   datetime t2 = t + (datetime)(sec * 4);
   string box = name + "b";
   ObjectDelete(0, box);
   ObjectDelete(0, name);
   if(!ObjectCreate(0, box, OBJ_RECTANGLE, 0, t, price + half, t2, price - half))
      return;
   ObjectSetInteger(0, box, OBJPROP_COLOR, bg);
   ObjectSetInteger(0, box, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, box, OBJPROP_FILL, true);
   StyleObj(box);
   if(!ObjectCreate(0, name, OBJ_TEXT, 0, t, price))
      return;
   ObjectSetString(0, name, OBJPROP_TEXT, " " + text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
   StyleObj(name);
}

void HLine(const string name, datetime t1, double price, color col, int style, int width)
{
   datetime t2 = g_tm[g_n - 1] + (datetime)(PeriodSeconds() * 12);
   ObjectDelete(0, name);
   if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price))
      return;
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   StyleObj(name);
}

void DrawAll()
{
   int last = g_n - 2;
   if(last < 2)
      return;
   double atr = g_atr[last];
   if(atr <= 0.0)
      atr = _Point * 20.0;

   if(InpChannel && g_regOk)
   {
      int sec = PeriodSeconds();
      datetime tA = g_tm[g_regA];
      datetime tB = g_tm[last] + (datetime)(sec * 8);
      double xB = (double)(last - g_regA);
      double midB = g_regIcept + g_regSlope * xB;
      double upA = g_regIcept + g_regSd;
      double dnA = g_regIcept - g_regSd;
      double upB = midB + g_regSd;
      double dnB = midB - g_regSd;
      string nm[3] = {"QAI_CHU", "QAI_CHM", "QAI_CHD"};
      double p1[3] = {upA, g_regIcept, dnA};
      double p2[3] = {upB, midB, dnB};
      for(int k = 0; k < 3; k++)
      {
         ObjectDelete(0, nm[k]);
         if(!ObjectCreate(0, nm[k], OBJ_TREND, 0, tA, p1[k], tB, p2[k]))
            continue;
         ObjectSetInteger(0, nm[k], OBJPROP_COLOR, C'150,80,220');
         ObjectSetInteger(0, nm[k], OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nm[k], OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, nm[k], OBJPROP_RAY_RIGHT, true);
         StyleObj(nm[k]);
      }
   }

   if(InpTrendline && g_tlKind != 0 && g_tlI1 >= 0 && g_tlI2 > g_tlI1 && g_tlI2 <= last)
   {
      ObjectDelete(0, "QAI_TL");
      if(ObjectCreate(0, "QAI_TL", OBJ_TREND, 0, g_tm[g_tlI1], g_tly1, g_tm[g_tlI2], g_tly2))
      {
         ObjectSetInteger(0, "QAI_TL", OBJPROP_COLOR, C'220,60,80');
         ObjectSetInteger(0, "QAI_TL", OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, "QAI_TL", OBJPROP_RAY_RIGHT, true);
         StyleObj("QAI_TL");
      }
   }

   if(InpZones && g_swOk && g_swHi > g_swLo && g_swHiI >= 0 && g_swLoI >= 0)
   {
      double eq = (g_swHi + g_swLo) * 0.5;
      int iFrom = g_swHiI;
      if(g_swLoI < iFrom)
         iFrom = g_swLoI;
      datetime t1 = g_tm[iFrom];
      datetime t2 = g_tm[g_n - 1] + (datetime)(PeriodSeconds() * 6);
      ObjectDelete(0, "QAI_PREM");
      ObjectDelete(0, "QAI_DISC");
      if(ObjectCreate(0, "QAI_PREM", OBJ_RECTANGLE, 0, t1, g_swHi, t2, eq))
      {
         ObjectSetInteger(0, "QAI_PREM", OBJPROP_COLOR, C'120,40,60');
         ObjectSetInteger(0, "QAI_PREM", OBJPROP_BGCOLOR, C'90,20,40');
         ObjectSetInteger(0, "QAI_PREM", OBJPROP_FILL, true);
         ObjectSetInteger(0, "QAI_PREM", OBJPROP_BACK, true);
         StyleObj("QAI_PREM");
      }
      if(ObjectCreate(0, "QAI_DISC", OBJ_RECTANGLE, 0, t1, eq, t2, g_swLo))
      {
         ObjectSetInteger(0, "QAI_DISC", OBJPROP_COLOR, C'0,90,80');
         ObjectSetInteger(0, "QAI_DISC", OBJPROP_BGCOLOR, C'0,70,65');
         ObjectSetInteger(0, "QAI_DISC", OBJPROP_FILL, true);
         ObjectSetInteger(0, "QAI_DISC", OBJPROP_BACK, true);
         StyleObj("QAI_DISC");
      }
      HLine("QAI_EQ", t1, eq, C'150,160,170', STYLE_DASH, 1);
      TagBox("QAI_EQL", g_tm[last], eq, "Equilibrium", C'30,36,48', clrWhite);
      TagBox("QAI_PRL", g_tm[last], g_swHi - atr * 0.4, "Premium", C'90,20,40', C'255,160,180');
      TagBox("QAI_DIL", g_tm[last], g_swLo + atr * 0.4, "Discount", C'0,70,65', C'120,230,210');
   }

   if(InpOB)
   {
      int n = g_obCount;
      if(n > 8)
         n = 8;
      for(int z = 0; z < n; z++)
      {
         if(!g_ob[z].used)
            continue;
         string nm = "QAI_OB" + IntegerToString(z);
         int i2 = g_ob[z].i2;
         if(g_ob[z].alive || i2 < g_ob[z].i1 || i2 > last)
            i2 = last;
         color bg = (g_ob[z].kind > 0) ? C'0,90,110' : C'120,30,50';
         color edge = (g_ob[z].kind > 0) ? C'0,180,170' : C'200,60,80';
         ObjectDelete(0, nm);
         if(!ObjectCreate(0, nm, OBJ_RECTANGLE, 0, g_tm[g_ob[z].i1], g_ob[z].top, g_tm[i2], g_ob[z].bot))
            continue;
         ObjectSetInteger(0, nm, OBJPROP_COLOR, edge);
         ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
         ObjectSetInteger(0, nm, OBJPROP_FILL, true);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         StyleObj(nm);
         bool swingOb = (MathAbs(g_ob[z].kind) >= 3);
         string lab = "Internal OB Bearish";
         if(swingOb && g_ob[z].kind > 0)
            lab = "Swing OB Bullish";
         else if(swingOb)
            lab = "Swing OB Bearish";
         else if(g_ob[z].kind > 0)
            lab = "Internal OB Bullish";
         TagBox(nm + "t", g_tm[g_ob[z].i1], g_ob[z].top, lab, bg, clrWhite);
      }
   }

   if(InpFVG)
   {
      int n = g_fvgCount;
      if(n > 6)
         n = 6;
      for(int z = 0; z < n; z++)
      {
         if(!g_fvg[z].used)
            continue;
         string nm = "QAI_FVG" + IntegerToString(z);
         int i2 = g_fvg[z].alive ? last : g_fvg[z].i2;
         if(i2 < g_fvg[z].i1 || i2 > last)
            i2 = last;
         color bg = (g_fvg[z].kind > 0) ? C'0,70,60' : C'90,20,40';
         ObjectDelete(0, nm);
         if(!ObjectCreate(0, nm, OBJ_RECTANGLE, 0, g_tm[g_fvg[z].i1], g_fvg[z].top, g_tm[i2], g_fvg[z].bot))
            continue;
         ObjectSetInteger(0, nm, OBJPROP_COLOR, bg);
         ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
         ObjectSetInteger(0, nm, OBJPROP_FILL, true);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         StyleObj(nm);
         string lab = (g_fvg[z].kind > 0) ? "Bullish FVG" : "Bearish FVG";
         TagBox(nm + "t", g_tm[g_fvg[z].i1], (g_fvg[z].top + g_fvg[z].bot) * 0.5, lab, bg, clrWhite);
      }
   }

   int sigN = 0, stN = 0, mkN = 0, inN = 0;
   for(int k = ArraySize(g_marks) - 1; k >= 0; k--)
   {
      int kind = g_marks[k].kind;
      int idx = g_marks[k].idx;
      if(idx < 0 || idx > last)
         continue;
      string nm = "QAI_K" + IntegerToString(k);
      if((kind == MK_BUY || kind == MK_SELL) && InpSignals && sigN < 24)
      {
         sigN++;
         bool buy = (kind == MK_BUY);
         double y = buy ? g_lo[idx] - atr * 0.55 : g_hi[idx] + atr * 0.55;
         TagBox(nm, g_tm[idx], y, buy ? "Buy" : "Sell", buy ? C'0,150,90' : C'190,30,50', clrWhite);
      }
      else if((kind == MK_TBULL || kind == MK_TBEAR) && InpEarly && stN < 16)
      {
         stN++;
         bool bull = (kind == MK_TBULL);
         double y = bull ? g_lo[idx] - atr * 1.15 : g_hi[idx] + atr * 1.15;
         TagBox(nm, g_tm[idx], y, bull ? "Trend Bull" : "Trend Bear", bull ? C'40,80,180' : C'150,40,90', clrWhite);
      }
      else if(kind >= MK_BOSU && kind <= MK_CHD && InpStruct && stN < 28)
      {
         stN++;
         string lab = "BOS";
         color col = C'0,200,190';
         if(kind == MK_BOSD) { lab = "BOS"; col = C'230,70,90'; }
         if(kind == MK_CHU)  { lab = "CHoCH"; col = C'80,160,255'; }
         if(kind == MK_CHD)  { lab = "CHoCH"; col = C'230,70,90'; }
         ObjectDelete(0, nm);
         if(ObjectCreate(0, nm, OBJ_TEXT, 0, g_tm[idx], g_cl[idx]))
         {
            ObjectSetString(0, nm, OBJPROP_TEXT, lab);
            ObjectSetInteger(0, nm, OBJPROP_COLOR, col);
            ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
            ObjectSetString(0, nm, OBJPROP_FONT, "Arial");
            StyleObj(nm);
         }
      }
      else if((kind == MK_SUP || kind == MK_RES) && InpMarkers && mkN < 10)
      {
         mkN++;
         bool sup = (kind == MK_SUP);
         ObjectDelete(0, nm);
         double y = sup ? g_lo[idx] : g_hi[idx];
         if(ObjectCreate(0, nm, OBJ_ARROW, 0, g_tm[idx], y))
         {
            ObjectSetInteger(0, nm, OBJPROP_ARROWCODE, 159);
            ObjectSetInteger(0, nm, OBJPROP_COLOR, sup ? clrLime : clrGold);
            ObjectSetInteger(0, nm, OBJPROP_WIDTH, 2);
            StyleObj(nm);
         }
         TagBox(nm + "t", g_tm[idx], sup ? y - atr * 0.35 : y + atr * 0.35, sup ? "Support" : "Resistance",
                sup ? C'0,80,40' : C'120,90,20', clrWhite);
      }
      else if(kind >= MK_ACC && kind <= MK_DOWN && InpInstit && inN < 12)
      {
         inN++;
         string lab = "Accumulation";
         if(kind == MK_SHAKE) lab = "Shakeout";
         if(kind == MK_MARKUP) lab = "Markup";
         if(kind == MK_SELLO) lab = "Sell-off";
         if(kind == MK_SWEEP) lab = "Liquidity Sweep";
         if(kind == MK_VALID) lab = "Valid Break";
         if(kind == MK_FALSE) lab = "False Break";
         if(kind == MK_DIST) lab = "Distribution";
         if(kind == MK_DOWN) lab = "Markdown";
         TagBox(nm, g_tm[idx], g_hi[idx] + atr * 0.3, lab, C'40,20,60', C'230,180,255');
      }
   }

   if(g_invIdx >= 0 && g_invIdx <= last)
      TagBox("QAI_INV", g_tm[g_invIdx], g_invPx, "Invalid", C'70,70,80', clrWhite);
   if(InpInstit && last > 2 && g_phase != "Balance")
      TagBox("QAI_PHASE", g_tm[last], g_cl[last], g_phase, C'40,20,60', C'230,180,255');

   if(InpRisk && g_hasPlan && g_planIdx >= 0 && g_planIdx <= last)
   {
      datetime t0 = g_tm[g_planIdx];
      color slCol = C'200,50,60';
      color trCol = C'170,110,40';
      HLine("QAI_EN", t0, g_entry, C'40,120,220', STYLE_SOLID, 1);
      HLine("QAI_SL", t0, g_sl, slCol, STYLE_SOLID, 1);
      HLine("QAI_TR", t0, g_trail, trCol, STYLE_DOT, 1);
      HLine("QAI_T1", t0, g_tp1, C'0,170,110', STYLE_DASH, 1);
      HLine("QAI_T2", t0, g_tp2, C'0,170,110', STYLE_DASH, 1);
      HLine("QAI_T3", t0, g_tp3, C'0,170,110', STYLE_DASH, 1);
      datetime tagT = g_tm[last];
      TagBox("QAI_ENT", tagT, g_entry, "Entry " + Px(g_entry), C'30,90,180', clrWhite);
      TagBox("QAI_SLT", tagT, g_sl, "SL " + Px(g_sl), slCol, clrWhite);
      TagBox("QAI_TRT", tagT, g_trail, "Trailing SL " + Px(g_trail), trCol, clrWhite);
      TagBox("QAI_T1T", tagT, g_tp1, "TP 1 " + Px(g_tp1), C'0,140,90', clrWhite);
      TagBox("QAI_T2T", tagT, g_tp2, "TP 2 " + Px(g_tp2), C'0,140,90', clrWhite);
      TagBox("QAI_T3T", tagT, g_tp3, "TP 3 " + Px(g_tp3), C'0,140,90', clrWhite);
   }

   if(InpProfile && g_bins > 2 && g_vpHi > g_vpLo)
   {
      double step = (g_vpHi - g_vpLo) / (double)g_bins;
      double maxV = 0.0;
      for(int b = 0; b < g_bins; b++)
      {
         if(g_bin[b] > maxV)
            maxV = g_bin[b];
      }
      if(maxV <= 0.0)
         maxV = 1.0;
      int sec = PeriodSeconds();
      datetime t0 = g_tm[g_n - 1] + (datetime)(sec * 2);
      for(int b = 0; b < g_bins; b++)
      {
         string nm = "QAI_VP" + IntegerToString(b);
         double y1 = g_vpLo + (double)b * step;
         double y2 = y1 + step;
         int barsW = (int)MathRound((double)InpVpWidth * g_bin[b] / maxV);
         if(barsW < 1)
            barsW = 1;
         datetime t1 = t0 + (datetime)(sec * barsW);
         ObjectDelete(0, nm);
         if(!ObjectCreate(0, nm, OBJ_RECTANGLE, 0, t0, y2, t1, y1))
            continue;
         bool bullBin = (g_binBuy[b] >= (g_bin[b] - g_binBuy[b]));
         color col = bullBin ? C'0,180,190' : C'200,40,140';
         ObjectSetInteger(0, nm, OBJPROP_COLOR, col);
         ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, col);
         ObjectSetInteger(0, nm, OBJPROP_FILL, true);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         StyleObj(nm);
      }
      HLine("QAI_POC", g_tm[last - 20 > 0 ? last - 20 : 0], g_poc, clrWhite, STYLE_DOT, 1);
      HLine("QAI_VAH", g_tm[last - 20 > 0 ? last - 20 : 0], g_vah, C'200,160,255', STYLE_DOT, 1);
      HLine("QAI_VAL", g_tm[last - 20 > 0 ? last - 20 : 0], g_val, C'0,200,190', STYLE_DOT, 1);
   }
}

uint UCol(color c)
{
   return ColorToARGB(c, 255);
}

void PanelFrame(CCanvas &cv, int w, int h, color edge)
{
   cv.Erase(ColorToARGB(C'8,12,22', 235));
   cv.Rectangle(0, 0, w - 1, h - 1, UCol(edge));
   cv.Rectangle(1, 1, w - 2, h - 2, UCol(edge));
}

void Row(CCanvas &cv, int &y, int w, const string left, const string right, uint lc, uint rc)
{
   cv.FontSet("Arial", 12, 0);
   cv.TextOut(12, y, left, lc, TA_LEFT);
   cv.TextOut(w - 12, y, right, rc, TA_RIGHT);
   y += 18;
}

void Section(CCanvas &cv, int &y, int w, const string title)
{
   y += 4;
   cv.FontSet("Arial", 11, 0);
   uint dim = UCol(C'150,160,180');
   cv.TextOut(w / 2, y, title, dim, TA_CENTER);
   y += 16;
}

void DrawPanels()
{
   if(!g_canvas)
      return;
   uint txt = UCol(C'220,226,236');
   uint dim = UCol(C'150,160,180');
   uint bull = UCol(C'0,210,170');
   uint bear = UCol(C'255,80,130');
   uint cyan = UCol(C'0,200,220');
   uint warn = UCol(C'240,190,70');

   if(InpResPanel)
   {
      g_res.FontSet("Arial", 12, 0);
      PanelFrame(g_res, 300, 168, C'0,190,210');
      g_res.TextOut(150, 8, "Quantum AI - Resonance Engine", cyan, TA_CENTER);
      g_res.FontSet("Arial", 10, 0);
      g_res.TextOut(150, 26, "Independent Signals", dim, TA_CENTER);
      int y = 44;
      uint vpC = (g_st.vpScore >= 55.0) ? bull : ((g_st.vpScore <= 45.0) ? bear : txt);
      uint moC = (g_st.momScore >= 55.0) ? bull : ((g_st.momScore <= 45.0) ? bear : txt);
      string vpSide = (g_st.vpScore >= 55.0) ? "Bullish" : ((g_st.vpScore <= 45.0) ? "Bearish" : "Neutral");
      string moSide = (g_st.momScore >= 55.0) ? "Bullish" : ((g_st.momScore <= 45.0) ? "Bearish" : "Neutral");
      Row(g_res, y, 300, "Volume Profile", DoubleToString(g_st.vpScore, 1) + "  " + vpSide, txt, vpC);
      Row(g_res, y, 300, "Momentum Trend", DoubleToString(g_st.momScore, 1) + "  " + moSide, txt, moC);
      g_res.FontSet("Arial", 10, 0);
      g_res.TextOut(150, y, "Core Resonance", dim, TA_CENTER);
      y += 16;
      string coreSide = (g_core >= 55.0) ? "Bullish" : ((g_core <= 45.0) ? "Bearish" : "Mixed");
      uint coreC = (g_core >= 55.0) ? bull : ((g_core <= 45.0) ? bear : warn);
      Row(g_res, y, 300, "Core Resonance", DoubleToString(g_core, 1) + "  " + coreSide, txt, coreC);
      uint bC = (g_st.resDir > 0) ? bull : ((g_st.resDir < 0) ? bear : warn);
      Row(g_res, y, 300, "Market Bias", g_st.biasText, txt, bC);
      g_res.Update(false);
      ObjectSetInteger(0, "QAI_RES", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   else
      ObjectSetInteger(0, "QAI_RES", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);

   if(InpDash)
   {
      int w = 372;
      int h = 640;
      PanelFrame(g_dash, w, h, C'0,170,220');
      g_dash.FontSet("Arial", 13, 0);
      string sessBit = wSessName;
      if(wSessOn)
         sessBit = wSessName + (InSession(TimeCurrent()) ? " open" : " closed");
      g_dash.TextOut(w / 2, 6, "Quantum AI [" + g_st.modeName + "]", cyan, TA_CENTER);
      g_dash.FontSet("Arial", 10, 0);
      g_dash.TextOut(w / 2, 22, wSymName + "  ·  " + sessBit, dim, TA_CENTER);
      g_dash.FontSet("Arial", 11, 0);
      uint stC = txt;
      if(StringFind(g_st.stance, "Bull") >= 0) stC = bull;
      if(StringFind(g_st.stance, "Bear") >= 0) stC = bear;
      if(StringFind(g_st.stance, "Neutral") >= 0 || StringFind(g_st.stance, "Cash") >= 0 || StringFind(g_st.stance, "Coiling") >= 0 || StringFind(g_st.stance, "Pause") >= 0)
         stC = warn;
      g_dash.TextOut(12, 36, "AI Stance: " + g_st.stance, stC, TA_LEFT);
      int y = 56;
      Section(g_dash, y, w, "Multi-TF Radar");
      g_dash.FontSet("Arial", 10, 0);
      g_dash.TextOut(12, y, "TF", dim, TA_LEFT);
      g_dash.TextOut(52, y, "Trend Bias", dim, TA_LEFT);
      g_dash.TextOut(w - 12, y, "Momentum Strength", dim, TA_RIGHT);
      y += 16;
      string tfN[5] = {"15M", "30M", "1H", "4H", "1D"};
      tfN[0] = TfShort(InpTF1);
      tfN[1] = TfShort(InpTF2);
      tfN[2] = TfShort(InpTF3);
      tfN[3] = TfShort(InpTF4);
      tfN[4] = TfShort(InpTF5);
      for(int s = 0; s < 5; s++)
      {
         uint c = (g_st.tfSign[s] > 0) ? bull : bear;
         g_dash.FontSet("Arial", 11, 0);
         g_dash.TextOut(12, y, tfN[s], txt, TA_LEFT);
         g_dash.TextOut(52, y, g_st.tfBias[s], c, TA_LEFT);
         int bw = (int)MathRound(54.0 * QaiClamp(g_st.tfStr[s] / 100.0, 0.0, 1.0));
         if(bw < 2)
            bw = 2;
         g_dash.FillRectangle(228, y + 4, 228 + bw, y + 12, c);
         g_dash.TextOut(w - 12, y, DoubleToString(g_st.tfStr[s], 1) + " (" + g_st.tfBucket[s] + ")", c, TA_RIGHT);
         y += 16;
      }
      Section(g_dash, y, w, "Core Analytics");
      uint hC = g_st.htfOk ? bull : warn;
      Row(g_dash, y, w, "HTF Resonance", g_st.htfText, txt, hC);
      Row(g_dash, y, w, "Market Regime", g_st.regime, txt, txt);
      uint vC = (StringFind(g_st.volText, "Explosion") >= 0 || StringFind(g_st.volText, "Expansion") >= 0) ? bull : warn;
      Row(g_dash, y, w, "Volatility State", g_st.volText, txt, vC);
      uint fC = (StringFind(g_st.flowText, "Bull") >= 0) ? bull : ((StringFind(g_st.flowText, "Bear") >= 0) ? bear : txt);
      Row(g_dash, y, w, "Volume Flow", g_st.flowText, txt, fC);
      Section(g_dash, y, w, "Signal Tracker");
      uint lC = txt;
      if(g_st.latest == "Buy" || g_st.latest == "Trend Bull") lC = bull;
      if(g_st.latest == "Sell" || g_st.latest == "Trend Bear") lC = bear;
      Row(g_dash, y, w, "Latest Signal", g_st.latest, txt, lC);
      uint cC = (g_st.confidence >= InpMinScore) ? bull : warn;
      Row(g_dash, y, w, "Confidence Score", DoubleToString(g_st.confidence, 1) + " pts", txt, cC);
      uint aC = (g_st.adxTag == "Strong") ? bear : ((g_st.adxTag == "Medium") ? warn : dim);
      Row(g_dash, y, w, "Current ADX", DoubleToString(g_st.adx, 1) + " (" + g_st.adxTag + ")", txt, aC);
      Row(g_dash, y, w, "Engine Filter", g_st.engine, txt, (g_st.engine == "Ready") ? bull : warn);
      Row(g_dash, y, w, "Filter tiers", g_st.tiers, txt, txt);
      Section(g_dash, y, w, "7-Step Checklist");
      Row(g_dash, y, w, IntegerToString(g_st.passes) + "/7", g_st.sizeText, txt, (g_st.sizeText == "Stand aside") ? bear : bull);
      string sn[7] = {"1 AI stance", "2 Main label", "3 Resonance", "4 Volatility", "5 Cross-cycle", "6 Thermometer", "7 Volume flow"};
      for(int s = 0; s < 7; s++)
      {
         uint sc = bear;
         string tag = "Fail";
         if(g_st.stepSt[s] == 1) { sc = bull; tag = "Pass"; }
         if(g_st.stepSt[s] == 2) { sc = warn; tag = "Warn"; }
         Row(g_dash, y, w, sn[s], tag + "  " + g_st.stepTxt[s], dim, sc);
      }
      Section(g_dash, y, w, "Position Status");
      uint pC = (g_posDir > 0) ? bull : ((g_posDir < 0) ? bear : dim);
      Row(g_dash, y, w, "Position Stance", g_st.posText, txt, pC);
      string stopTxt = (g_posDir == 0) ? "-" : Px(g_st.activeStop);
      Row(g_dash, y, w, "Active Stop Level", stopTxt, txt, txt);
      Row(g_dash, y, w, "Size guide", g_st.sizeText, txt, (g_st.sizeText == "Stand aside") ? bear : bull);
      g_dash.Update(false);
      ObjectSetInteger(0, "QAI_DASH", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   else
      ObjectSetInteger(0, "QAI_DASH", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);

   if(InpThermo)
   {
      int w = 340;
      int h = 78;
      PanelFrame(g_th, w, h, C'0,160,170');
      g_th.FontSet("Arial", 11, 0);
      g_th.TextOut(12, 6, "Price Thermometer: " + DoubleToString(g_st.thermo, 1) + "%   [" + g_st.thermoTag + "]", txt, TA_LEFT);
      int x0 = 12, x1 = w - 12, y0 = 30, y1 = 44;
      int span = x1 - x0;
      for(int x = 0; x < span; x++)
      {
         double t = (span <= 1) ? 0.0 : (double)x / (double)(span - 1);
         g_th.Line(x0 + x, y0, x0 + x, y1, UCol(HeatColor(t)));
      }
      int mx = x0 + (int)MathRound((g_st.thermo / 100.0) * (double)(span - 1));
      g_th.FillRectangle(mx - 1, y0 - 3, mx + 1, y1 + 3, UCol(clrWhite));
      g_th.FontSet("Arial", 10, 0);
      g_th.TextOut(x0, 50, "Low (0%)", UCol(C'80,160,255'), TA_LEFT);
      g_th.TextOut((x0 + x1) / 2, 50, "Mid (50%)", dim, TA_CENTER);
      g_th.TextOut(x1, 50, "High (100%)", bear, TA_RIGHT);
      g_th.Update(false);
      ObjectSetInteger(0, "QAI_THM", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   else
      ObjectSetInteger(0, "QAI_THM", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);

   ChartRedraw(0);
}

color HeatColor(double t)
{
   // blue -> cyan -> green -> yellow -> orange -> magenta
   int n = 5;
   double x = QaiClamp(t, 0.0, 1.0) * (double)n;
   int i = (int)MathFloor(x);
   if(i >= n)
      i = n - 1;
   double f = x - (double)i;
   int r1[6] = {40, 0, 40, 240, 255, 210};
   int g1[6] = {90, 210, 190, 210, 120, 40};
   int b1[6] = {255, 220, 90, 40, 30, 150};
   int r = r1[i] + (int)MathRound(f * (double)(r1[i + 1] - r1[i]));
   int g = g1[i] + (int)MathRound(f * (double)(g1[i + 1] - g1[i]));
   int b = b1[i] + (int)MathRound(f * (double)(b1[i + 1] - b1[i]));
   if(r < 0) r = 0;
   if(g < 0) g = 0;
   if(b < 0) b = 0;
   if(r > 255) r = 255;
   if(g > 255) g = 255;
   if(b > 255) b = 255;
   return (color)((r) | (g << 8) | (b << 16));
}

string TfShort(ENUM_TIMEFRAMES tf)
{
   if(tf == PERIOD_M1) return "1M";
   if(tf == PERIOD_M5) return "5M";
   if(tf == PERIOD_M15) return "15M";
   if(tf == PERIOD_M30) return "30M";
   if(tf == PERIOD_H1) return "1H";
   if(tf == PERIOD_H4) return "4H";
   if(tf == PERIOD_D1) return "1D";
   if(tf == PERIOD_W1) return "1W";
   return EnumToString(tf);
}
