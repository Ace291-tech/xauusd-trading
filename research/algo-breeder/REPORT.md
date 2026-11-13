# XAUUSD Strategy Breeder: results

> **Research and demo testing only. This is not financial advice.** These are backtests on historical data. Passing every filter below does **not** mean a strategy will make money in the future. Run any EA on a **demo account** for weeks before you consider real money.

## Data
- **Source:** Dukascopy **spot XAUUSD** H1 BID candles (free, public), downloaded with `npx dukascopy-node`. There are 46,537 H1 bars, resampled to 12,166 H4 bars.
- **Range (server time):** 2019-01-02 to 2026-11-13.
- **Clock:** converted from UTC to MT5 server time (New York + 7h, i.e. GMT+2 in winter and GMT+3 in summer), so H4 candles close at 00/04/08/12/16/20 like most MT5 brokers. This is assumed to match MOT Capital; check your broker's server time.
- **This is not your broker's feed.** Dukascopy prices, spreads and gaps differ a little from MOT Capital. Tick volume is not used.

## Method
- **Genome (20 genes):** timeframe (H1/H4), direction (long/short/both), entry type (EMA cross, Donchian close breakout, RSI re-cross, Bollinger re-entry) with their lengths. Optional filters: trend SMA, ATR-regime, server-hour session window, and last-closed-H4-candle confirmation. Exits: ATR(14) stop loss and take profit (always set), optional ATR trailing stop, time exit, and exit on opposite signal.
- **Execution model:** signals use closed bars only and orders fill at the next bar's open, so there is no lookahead. Longs pay the ask (bid + spread). Spread = max(0.30, 0.01% of price) USD/oz, plus 0.10 USD/oz slippage per side. If SL and TP are both touched in the same bar, the SL is assumed to hit first. Gaps fill at the open. **Swap is from your MOT Capital spec:** longs pay 55.82 points/lot/night = 0.5582 USD/oz per rollover, triple on Wednesday night. Shorts pay 0.
- **Returns:** expressed as % of notional at 1x (unlevered, 1 oz per oz of exposure). Sharpe = per-trade Sharpe annualised by trades per year.
- **Split:** in-sample (IS) runs 2019-01-02 to 2023-09-21 (first 60%). Out-of-sample (OOS) runs 2023-09-21 to 2026-11-13; the GA **never** saw it. The decay check covers the last 6 months, 2026-05-13 to 2026-11-13.
- **Genetic algorithm:** 3 independent islands × population 500 × 60 generations. It uses tournament selection, uniform crossover, 12% mutation, 10 elites and 5% random immigrants. **90,000 evaluations = 87,108 unique strategy variants.**
- **Fitness (IS only):** the *minimum* over the two halves of IS of [Sharpe capped at 3 + annual-return bonus capped − penalty for drawdown above 10% − 1 if PF < 1]. Each half needs at least 25 trades. This means a variant has to work in both halves of IS.
- **Candidates sent to OOS:** only the best and one clearly different variant from each of the 24 families (timeframe × direction × entry type), 48 in total. Testing only a few variants on OOS limits data-snooping.

## Survival thresholds (all must pass)
- OOS trades >= 30
- OOS PF >= 1.20
- OOS Sharpe >= 0.50
- OOS Sharpe >= 40% of IS
- OOS maxDD <= 20%
- Walk-forward PF>1 in >=2/3 segments
- Last 6m >= 3 trades and net >= 0
- MC bootstrap P(profit) >= 90%
- MC shuffled DD95 <= 25%
- Neighbours PF>1 >= 70%
- Neighbour median fitness >= 50%
- The walk-forward split divides OOS into 3 equal sub-periods. The Monte Carlo checks use 5,000 bootstrap resamples of OOS trades and 2,000 random orderings of OOS trades. The neighbourhood check uses 100 random neighbours, where each numeric gene has a 30% chance of moving ±10%.

## Results
- **87,108 variants bred → 48 sent to OOS → 5 survivors.**
- Most common reasons candidates were rejected: MC bootstrap P(profit) >= 90% (43); OOS Sharpe >= 0.50 (39); OOS PF >= 1.20 (37); OOS Sharpe >= 40% of IS (34); Walk-forward PF>1 in >=2/3 segments (27).
- **Placebo test:** 207 *random, un-bred* genomes with positive IS fitness went through the same gate, and **10 passed (4.8%)**. The bred candidates passed at 10.4%. If those two rates are similar, the survivors may be luck or regime rather than real skill. See the caveats.
- **Buy and hold gold, for context (no swap):** IS 50.4%, OOS 101.2%, last 6 months -17.7%. The OOS period was an exceptional gold bull market.

### Survivor 1 (candidate #19, IS fitness rank among candidates by IS: 20/48)
`H1 long+short | EMA(14) x EMA(25) | filters: trend SMA(116), hours 07:00+9h (broker) | exits: SL 3.2xATR, TP 8.1xATR, trail 2.7xATR, time exit 150 bars, exit on opposite signal`

| Period | Trades | Win rate | PF | Net (% notional) | Max DD | Sharpe |
|---|---|---|---|---|---|---|
| In-sample | 184 | 35.9% | 1.34 | 14.7% | 5.7% | 0.67 |
| Out-of-sample | 110 | 38.2% | 1.51 | 17.6% | 5.9% | 0.85 |
| Last 6 months | 23 | 39.1% | 1.15 | 1.2% | 3.0% | 0.33 |

- OOS walk-forward PF by sub-period: 1.68, 1.49, 1.41. Monte Carlo P(profit) is 94.1% and the 95th-percentile drawdown is 10.3%. 100.0% of neighbours had PF > 1, and median neighbour fitness was 0.97× the original.
- OOS net by side: longs 18.6%, shorts -1.1%. Time in market OOS was 9.4%.
- Files: EA `export/XAU_Bred_1.mq5`, Pine `export/XAU_Bred_1.pine`, chart `charts/equity_survivor1.png`

![equity 1](charts/equity_survivor1.png)

### Survivor 2 (candidate #27, IS fitness rank among candidates by IS: 28/48)
`H1 long only | Donchian(84) close breakout | filters: trend SMA(54), ATR14/ATRavg100 >= 1.20, hours 12:00+22h (broker), H4-close confirm | exits: SL 3.2xATR, TP 9.3xATR, trail 3.6xATR, time exit 21 bars, exit on opposite signal`

| Period | Trades | Win rate | PF | Net (% notional) | Max DD | Sharpe |
|---|---|---|---|---|---|---|
| In-sample | 78 | 52.6% | 1.37 | 8.3% | 5.0% | 0.50 |
| Out-of-sample | 65 | 58.5% | 1.62 | 11.2% | 5.5% | 0.85 |
| Last 6 months | 7 | 71.4% | 1.51 | 1.1% | 2.1% | 0.53 |

- OOS walk-forward PF by sub-period: 1.41, 3.31, 1.12. Monte Carlo P(profit) is 94.2% and the 95th-percentile drawdown is 7.1%. 71.0% of neighbours had PF > 1, and median neighbour fitness was 0.79× the original.
- OOS net by side: longs 11.2%, shorts 0.0%. Time in market OOS was 6.6%.
- Files: EA `export/XAU_Bred_2.mq5`, Pine `export/XAU_Bred_2.pine`, chart `charts/equity_survivor2.png`

![equity 2](charts/equity_survivor2.png)

### Survivor 3 (candidate #34, IS fitness rank among candidates by IS: 35/48)
`H4 long only | Donchian(62) close breakout | filters: hours 21:00+16h (broker), H4-close confirm | exits: SL 1.2xATR, TP 2.5xATR, trail 3.0xATR, time exit 44 bars, exit on opposite signal`

| Period | Trades | Win rate | PF | Net (% notional) | Max DD | Sharpe |
|---|---|---|---|---|---|---|
| In-sample | 90 | 41.1% | 1.30 | 10.2% | 4.3% | 0.52 |
| Out-of-sample | 98 | 40.8% | 1.38 | 17.3% | 6.5% | 0.80 |
| Last 6 months | 6 | 33.3% | 1.02 | 0.1% | 2.1% | 0.04 |

- OOS walk-forward PF by sub-period: 1.09, 1.82, 1.16. Monte Carlo P(profit) is 92.6% and the 95th-percentile drawdown is 11.9%. 100.0% of neighbours had PF > 1, and median neighbour fitness was 1.00× the original.
- OOS net by side: longs 17.3%, shorts 0.0%. Time in market OOS was 12.5%.
- Files: EA `export/XAU_Bred_3.mq5`, Pine `export/XAU_Bred_3.pine`, chart `charts/equity_survivor3.png`

![equity 3](charts/equity_survivor3.png)

![IS vs OOS](charts/is_vs_oos_sharpe.png)

All candidates with every metric are in `results/candidates.csv`, and the full detail is in `results/candidates.json`.

## Honest caveats
- **Regime risk.** OOS (late 2023 to 2026) was one of the strongest gold rallies on record. Long-only breakout/trend rules naturally looked good in it. A survivor that is mostly long may simply be capturing that trend, and it can fail in a range or a decline. Compare the long/short split and the buy-and-hold figure above.
- **Multiple testing.** Tens of thousands of variants were searched. The OOS gate and the placebo test reduce this risk but cannot remove it. Treat a survivor as a hypothesis to demo-test, not as a proven edge.
- **Design iterations were disclosed.** The first run's fitness was exploited by tiny-TP/huge-SL variants that almost never lost, so Sharpe was capped and the both-halves fitness was added. The second run picked the top 50 near-duplicates and had 0 survivors, so selection was changed to 2 per family. These changes came *after* looking at OOS results, which is a mild form of snooping.
- **Data and costs.** The price feed is Dukascopy, not MOT Capital, and the spread is modelled because the broker's is floating. News spikes, requotes and stop-outs on real accounts can be worse. Intrabar order is unknown (the SL-first assumption is pessimistic). Your spec shows trading paused around server midnight to 02:00. Bars and fills in that window may differ from the backtest.
- **Platform differences.** The EA and the Pine script implement the same rules, but MT5 or TradingView results will not match the python numbers exactly. Causes include feed differences, Pine's own intrabar fill model, Pine having no swap, and indicator warm-up. **The MQL5 code could not be compiled here.** Compile it in MetaEditor and fix any warnings first. Then run the Strategy Tester ("Every tick based on real ticks") on MOT data before demo trading.
- Default risk is 0.5% of balance per trade, and the SL and TP are always set. Lot step is 0.01 and the cap is 0.50 lot.

## How to rerun
```bash
cd /workspace/algo-breeder
pip install numpy pandas numba matplotlib   # once
python breed.py                      # full run: re-downloads data if data/ is empty, ~1-2 min
python breed.py --pop 300 --gens 30 --islands 1   # quick run
rm data/xauusd_h1_bid.csv && python breed.py       # refresh with latest prices
```

Run time: 32s. Code: `data.py` (download and broker clock), `engine.py` (numba backtester and genome), `breed.py` (GA and robustness), `export.py` (MQL5/Pine), `report.py`.
