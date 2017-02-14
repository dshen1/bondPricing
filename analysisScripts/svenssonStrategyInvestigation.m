% backtest portfolio strategy:
% - with some interest rates over time
% - get all synthetic bonds and bond prices
% - backtest some strategy
% - visualize it

doRecompute = true;

%% set up plotting values

genInfo.pos = [50 50 1200 600];

%% define yields to use

% load historic yield curve parameters
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

%% yield curve reversal

paramsTable{:, 2:end} = flipud(paramsTable{:, 2:end});

%% define strategy

% general settings
GS = GlobalSettings;
strategyParams.initWealth = 10000;
strategyParams.transCosts = 10 / 10000;
desiredInitDate = datenum('1965-01-02');
initDate = makeBusDate(desiredInitDate, 'follow', GS.Holidays, GS.WeekendInd);
strategyParams.initDate = initDate;

% rolling over bond strategy
strategyParams.minDur = 7*365 + 2; % exclude 7 year notes
strategyParams.maxDur = 10*365;
maturGrid = datetime(datevec(initDate)) + calyears(7) + calmonths(3:3:36);
strategyParams.maturGrid = datenum(maturGrid);

%% conduct backtest

if doRecompute
    [longPrices, allTreasuries] = createSynthBondMarket_svensson(paramsTable);
    [pfHistory, cashAccount, pfTimeTrend, macDurs] = backtestRollingStrategy(strategyParams, ...
        longPrices, allTreasuries, paramsTable);
end

%% visualize bond market

visualizeBondMarket(paramsTable, allTreasuries, longPrices, strategyParams, 'yieldReversal_rolling_7to10')

%% visualize bond portfolio

visualizeStrategy(paramsTable, pfHistory, cashAccount, pfTimeTrend, macDurs, strategyParams, 'yieldReversal_rolling_7to10')

%%
close all