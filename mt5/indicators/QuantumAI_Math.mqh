//+------------------------------------------------------------------+
//| QuantumAI_Math.mqh                                               |
//| Causal building blocks for the Quantum AI XAU indicators.        |
//| Formulas are the public ones named in mt5/README and the repo    |
//| README. No vendor source is included.                            |
//+------------------------------------------------------------------+
#ifndef QUANTUMAI_MATH_MQH
#define QUANTUMAI_MATH_MQH

void QaiEma(const double &x[], int n, int len, double &out[])
{
   ArrayResize(out, n);
   if(n <= 0 || len < 1)
      return;
   double a = 2.0 / ((double)len + 1.0);
   out[0] = x[0];
   for(int i = 1; i < n; i++)
      out[i] = out[i - 1] + a * (x[i] - out[i - 1]);
}

void QaiSma(const double &x[], int n, int len, double &out[])
{
   ArrayResize(out, n);
   if(n <= 0 || len < 1)
      return;
   double s = 0.0;
   for(int i = 0; i < n; i++)
   {
      s += x[i];
      if(i >= len)
         s -= x[i - len];
      int d = (i + 1 < len) ? (i + 1) : len;
      out[i] = s / (double)d;
   }
}

// Wilder RSI. Early bars stay at 50 so later logic always has a number.
void QaiRsi(const double &c[], int n, int len, double &rsi[])
{
   ArrayResize(rsi, n);
   ArrayInitialize(rsi, 50.0);
   if(n <= len || len < 1)
      return;
   double g = 0.0, l = 0.0;
   for(int i = 1; i <= len; i++)
   {
      double ch = c[i] - c[i - 1];
      if(ch >= 0.0)
         g += ch;
      else
         l -= ch;
   }
   g /= (double)len;
   l /= (double)len;
   rsi[len] = (l <= 0.0) ? 100.0 : (100.0 - 100.0 / (1.0 + g / l));
   for(int i = len + 1; i < n; i++)
   {
      double ch = c[i] - c[i - 1];
      double gg = (ch > 0.0) ? ch : 0.0;
      double ll = (ch < 0.0) ? -ch : 0.0;
      g = (g * (double)(len - 1) + gg) / (double)len;
      l = (l * (double)(len - 1) + ll) / (double)len;
      rsi[i] = (l <= 0.0) ? 100.0 : (100.0 - 100.0 / (1.0 + g / l));
   }
}

// Wilder ATR. Seed is the mean of the first `len` true ranges.
void QaiAtr(const double &h[], const double &l[], const double &c[], int n, int len, double &out[])
{
   ArrayResize(out, n);
   ArrayInitialize(out, 0.0);
   if(n <= 0 || len < 1)
      return;
   double sum = 0.0;
   for(int i = 0; i < n; i++)
   {
      double tr = h[i] - l[i];
      if(i > 0)
      {
         double a = MathAbs(h[i] - c[i - 1]);
         double b = MathAbs(l[i] - c[i - 1]);
         if(a > tr)
            tr = a;
         if(b > tr)
            tr = b;
      }
      if(tr < 0.0)
         tr = 0.0;
      if(i < len)
      {
         sum += tr;
         out[i] = sum / (double)(i + 1);
      }
      else
         out[i] = (out[i - 1] * (double)(len - 1) + tr) / (double)len;
   }
}

// Wilder ADX. Bars before the seed are filled with the first valid ADX.
void QaiAdx(const double &h[], const double &l[], const double &c[], int n, int len, double &adx[])
{
   ArrayResize(adx, n);
   ArrayInitialize(adx, 0.0);
   if(n < len + 2 || len < 2)
      return;
   double tr[], pdm[], mdm[], dx[];
   ArrayResize(tr, n);
   ArrayResize(pdm, n);
   ArrayResize(mdm, n);
   ArrayResize(dx, n);
   ArrayInitialize(dx, 0.0);
   tr[0] = h[0] - l[0];
   pdm[0] = 0.0;
   mdm[0] = 0.0;
   for(int i = 1; i < n; i++)
   {
      double up = h[i] - h[i - 1];
      double dn = l[i - 1] - l[i];
      pdm[i] = (up > dn && up > 0.0) ? up : 0.0;
      mdm[i] = (dn > up && dn > 0.0) ? dn : 0.0;
      double a = h[i] - l[i];
      double b = MathAbs(h[i] - c[i - 1]);
      double d = MathAbs(l[i] - c[i - 1]);
      tr[i] = MathMax(a, MathMax(b, d));
   }
   double str = 0.0, sp = 0.0, sm = 0.0;
   for(int i = 1; i <= len && i < n; i++)
   {
      str += tr[i];
      sp += pdm[i];
      sm += mdm[i];
   }
   for(int i = len; i < n; i++)
   {
      if(i > len)
      {
         str = str - str / (double)len + tr[i];
         sp = sp - sp / (double)len + pdm[i];
         sm = sm - sm / (double)len + mdm[i];
      }
      double pdi = (str > 0.0) ? 100.0 * sp / str : 0.0;
      double mdi = (str > 0.0) ? 100.0 * sm / str : 0.0;
      double den = pdi + mdi;
      dx[i] = (den > 0.0) ? 100.0 * MathAbs(pdi - mdi) / den : 0.0;
   }
   int seedEnd = len + len - 1;
   if(seedEnd >= n)
      seedEnd = n - 1;
   if(seedEnd < len)
      return;
   double sdx = 0.0;
   int cnt = 0;
   for(int i = len; i <= seedEnd; i++)
   {
      sdx += dx[i];
      cnt++;
   }
   if(cnt <= 0)
      return;
   adx[seedEnd] = sdx / (double)cnt;
   for(int i = seedEnd + 1; i < n; i++)
      adx[i] = (adx[i - 1] * (double)(len - 1) + dx[i]) / (double)len;
   for(int i = 0; i < seedEnd; i++)
      adx[i] = adx[seedEnd];
}

// LazyBear WaveTrend. ap is usually hlc3. sig is the wt2 SMA, 4 in the original.
void QaiWaveTrend(const double &ap[], int n, int n1, int n2, int sig, double &wt1[], double &wt2[])
{
   ArrayResize(wt1, n);
   ArrayResize(wt2, n);
   ArrayInitialize(wt1, 0.0);
   ArrayInitialize(wt2, 0.0);
   if(n <= 0 || n1 < 1 || n2 < 1 || sig < 1)
      return;
   double esa[], absdev[], d[], ci[];
   QaiEma(ap, n, n1, esa);
   ArrayResize(absdev, n);
   for(int i = 0; i < n; i++)
      absdev[i] = MathAbs(ap[i] - esa[i]);
   QaiEma(absdev, n, n1, d);
   ArrayResize(ci, n);
   for(int i = 0; i < n; i++)
   {
      double den = 0.015 * d[i];
      ci[i] = (den > 1e-12) ? (ap[i] - esa[i]) / den : 0.0;
   }
   QaiEma(ci, n, n2, wt1);
   QaiSma(wt1, n, sig, wt2);
}

// Nadaraya-Watson rational quadratic, endpoint form (jdehorty).
// Uses only src[i], src[i-1], ... so a closed bar never changes later.
double QaiKernelAt(const double &src[], int i, int bandwidth, double alpha)
{
   if(i < 0)
      return 0.0;
   if(bandwidth < 2 || alpha <= 0.0)
      return src[i];
   int maxK = i;
   if(maxK > bandwidth)
      maxK = bandwidth;
   double denom = (double)bandwidth * (double)bandwidth * 2.0 * alpha;
   if(denom < 1e-12)
      denom = 1e-12;
   double cw = 0.0, sw = 0.0;
   for(int k = 0; k <= maxK; k++)
   {
      double kk = (double)k;
      double w = MathPow(1.0 + (kk * kk) / denom, -alpha);
      cw += src[i - k] * w;
      sw += w;
   }
   if(sw <= 0.0)
      return src[i];
   return cw / sw;
}

// Bollinger bands. Pine ta.stdev is the population standard deviation.
void QaiBollinger(const double &c[], int n, int len, double mult, double &mid[], double &up[], double &dn[])
{
   QaiSma(c, n, len, mid);
   ArrayResize(up, n);
   ArrayResize(dn, n);
   for(int i = 0; i < n; i++)
   {
      int a = i - len + 1;
      if(a < 0)
         a = 0;
      int m = i - a + 1;
      double sd = 0.0;
      for(int k = a; k <= i; k++)
      {
         double d = c[k] - mid[i];
         sd += d * d;
      }
      sd = (m > 0) ? MathSqrt(sd / (double)m) : 0.0;
      up[i] = mid[i] + mult * sd;
      dn[i] = mid[i] - mult * sd;
   }
}

// Keltner channel around `mid`, width = mult * ATR.
void QaiKeltner(const double &mid[], const double &atr[], int n, double mult, double &up[], double &dn[])
{
   ArrayResize(up, n);
   ArrayResize(dn, n);
   for(int i = 0; i < n; i++)
   {
      double w = mult * atr[i];
      up[i] = mid[i] + w;
      dn[i] = mid[i] - w;
   }
}

// Linear regression of y[a..b] inclusive. Returns slope, intercept on x = 0 at index a,
// and the residual standard deviation.
bool QaiLinReg(const double &y[], int a, int b, double &slope, double &intercept, double &residSd)
{
   slope = 0.0;
   intercept = y[a];
   residSd = 0.0;
   int m = b - a + 1;
   if(m < 3)
      return false;
   double sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumXX = 0.0;
   for(int i = 0; i < m; i++)
   {
      double x = (double)i;
      double v = y[a + i];
      sumX += x;
      sumY += v;
      sumXY += x * v;
      sumXX += x * x;
   }
   double den = (double)m * sumXX - sumX * sumX;
   if(MathAbs(den) < 1e-12)
      return false;
   slope = ((double)m * sumXY - sumX * sumY) / den;
   intercept = (sumY - slope * sumX) / (double)m;
   double ss = 0.0;
   for(int i = 0; i < m; i++)
   {
      double fit = intercept + slope * (double)i;
      double d = y[a + i] - fit;
      ss += d * d;
   }
   residSd = MathSqrt(ss / (double)m);
   return true;
}

double QaiClamp(double v, double lo, double hi)
{
   if(v < lo)
      return lo;
   if(v > hi)
      return hi;
   return v;
}

#endif
