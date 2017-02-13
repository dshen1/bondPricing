% bond portfolio strategy
% 
% The strategy will be to invest in
% - notes only:
%   - replicating real ETF behavior (almost no weight on bonds)
%   - real ETF behavior might only be a snapshot, and in reality notes
%     might have been prefered only due to different coupon rates
% - maturities between 7 and 10 years
% - only notes are taken, and in three month steps
% - re-balancing only due to expired notes; intermediate coupon cash-flows
%   are not directly re-invested

%% load data

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'syntheticRealBondsLongFormat.mat');
load(fname)

%% define strategy parameters

GS = GlobalSettings;

% initial wealth
strategyParams.initWealth = 10000;

% transaction costs
strategyParams.transCosts = 10 / 10000;

% define initial starting date and move to next business day
desiredInitDate = datenum('1975-01-02');
initDate = makeBusDate(desiredInitDate, 'follow', GS.Holidays, GS.WeekendInd);
strategyParams.initDate = initDate;

% define TTM range
strategyParams.minDur = 7*365 + 2; % exclude 7 year notes
strategyParams.maxDur = 10*365;

% define grid of desired maturities for initial portfolio allocation
maturGrid = datetime(datevec(initDate)) + calyears(7) + calmonths(3:3:36);
strategyParams.maturGrid = datenum(maturGrid);

%% conduct backtest

[pfHistory, cashAccount] = backtestRollingStrategy(strategyParams, longPrices, allTreasuries);

%% save 

dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'bondPortfolioBacktestPerformance.mat');
save(fname, 'pfHistory', 'cashAccount', 'strategyParams')

