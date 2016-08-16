% backtest portfolio strategy:
% - with some interest rates over time
% - get all synthetic bonds and bond prices
% - backtest some strategy
% - visualize it

doRecompute = true;

%% define yields to use

% load historic yield curve parameters
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

% flip upside down
%paramsTable{:, 2:end} = flipud(paramsTable{:, 2:end});

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
    [pfHistory, cashAccount] = backtestRollingStrategy(strategyParams, longPrices, allTreasuries);
end

%% visualize

visualizeStrategy(paramsTable, allTreasuries, longPrices, pfHistory, cashAccount, strategyParams)

%%

close all