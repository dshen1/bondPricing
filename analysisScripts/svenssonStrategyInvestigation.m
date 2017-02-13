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
    [pfHistory, cashAccount, pfTimeTrend, macDurs] = backtestRollingStrategy(strategyParams, ...
        longPrices, allTreasuries, paramsTable);
end

%% visualize
% TODO: allow figure exportation

visualizeStrategy(paramsTable, allTreasuries, longPrices, pfHistory, cashAccount, strategyParams, 'rolling_7_to_10')

%% get yield proxy

% extract dates and parameters for given time period
xxInds = paramsTable.Date >= strategyParams.initDate;
thisParams = paramsTable{xxInds, 2:end};
thisDate = paramsTable.Date(xxInds);

% maturities are given in years
maturs = [0.1 1:30];

% get yields / foward rates
[yields, fowRates] = svenssonYields(thisParams, maturs);

% get proxy for yield changes
xxProxyInd = 6;
yieldProxy = yields(:, xxProxyInd);
yieldProxyMatur = maturs(xxProxyInd);
yieldChanges = diff(yieldProxy);

%% calculate EWMA volas of yield changes and portfolio values

logRets = diff(log(pfTimeTrend.CurrentValue));

pfVolaHat = nan(size(logRets));
for ii=100:length(logRets)
    pfVolaHat(ii) = sampleStd(100*logRets(1:ii), 0.95);
end

yieldChangeVolaHat = nan(size(yieldChanges));
for ii=100:length(logRets)
    yieldChangeVolaHat(ii) = sampleStd(yieldChanges(1:ii), 0.95);
end


%% show portfolio returns, trend and sensitivity
% GOOD!

f = figure('pos', genInfo.pos);
subplot(3, 1, 1)
logRets = diff(log(pfTimeTrend.CurrentValue));
plot(pfTimeTrend.Date(2:end), 100*logRets)
grid minor
datetick 'x'
title('Logarithmic portfolio returns')

subplot(3, 1, 2)
plot(pfTimeTrend.Date, pfTimeTrend.TimeTrend*100); 
datetick 'x'; 
grid minor
title('Deterministic portfolio trend')

subplot(3, 1, 3)
plot(macDurs.Date, macDurs.MacDur)
grid minor
datetick 'x'
title('Portfolio sensitivity')

%% explain returns with trend and sensitivity
% GOOD!
% But: where does consistent deviation come from? Convexity?

f = figure('pos', genInfo.pos);

% yield change: parallel yield curve shift
% pfRet = dur .* yield change + time trend
% -> (pfRet - time trend)./ dur = yield change

pfRets = exp(logRets) - 1;
unexpectedRets = pfRets - pfTimeTrend.TimeTrend(2:end);
inferredYieldChanges = (-1)*(unexpectedRets) ./ macDurs.MacDur(2:end);
inferredYieldChanges(isnan(inferredYieldChanges)) = 0;
inferredYields = mean(yields(2, 2:end)) + 100*cumsum(inferredYieldChanges);

% plot true yields
plot(macDurs.Date(2:end), yields(2:end, 3:end), '-b')
hold on
plot(macDurs.Date(2:end), yieldProxy(2:end), '-g')
plot(macDurs.Date(2:end), inferredYields, '-r')
hold off
grid minor
datetick 'x'
title('Aggregated inferred parallel shifts')

%% inferred yield changes vs yield proxy 

f = figure();

plot(inferredYieldChanges*100, yieldChanges, '.')
hold on
plot([-1, 1], [-1, 1], '-r')
hold off
grid minor
xlabel('Inferred parallel yield curve shifts')
ylabel('Yield changes of yield proxy')

%%

f = figure('pos', genInfo.pos);

subplot(2, 1, 1)
logRets = diff(log(pfTimeTrend.CurrentValue));
plot(pfTimeTrend.Date(2:end), 100*logRets)
grid minor
datetick 'x'
ylabel('Log returns')

subplot(2, 1, 2)
plot(pfTimeTrend.Date(2:end), pfVolaHat)
grid minor
datetick 'x'
ylabel('EWMA vola')

%% vola interest rates vs vola portfolio

f = figure('pos', genInfo.pos);

subplot(2, 1, 1)
plot(pfTimeTrend.Date(2:end), pfVolaHat)
grid minor
datetick 'x'
ylabel('Pf vola')

subplot(2, 1, 2)
plot(pfTimeTrend.Date(2:end), yieldChangeVolaHat)
grid minor
datetick 'x'
ylabel('Yield vola')

%% yield change, pf value change and predicted change


f = figure('pos', genInfo.pos);
subplot(3, 1, 1)
logRets = diff(log(pfTimeTrend.CurrentValue));
plot(pfTimeTrend.Date(2:end), 100*logRets)
grid minor
datetick 'x'
ylabel('Log returns')

subplot(3, 1, 2)
plot(thisDate(2:end), yieldChanges)
grid minor
datetick 'x'
ylabel('Yield change')

subplot(3, 1, 3)
predictedPfChange = macDurs.MacDur(2:end) .* yieldChanges * (-1);
plot(macDurs.Date(2:end), predictedPfChange)
grid minor
datetick 'x'
ylabel('Predicted return')

%% returns vs predicted returns

plot(logRets*100, predictedPfChange, '.')
grid minor


%%
plot(paramsTable.Date(xxInds), yields(:, 2:end), '-b')
grid minor
datetick 'x'

%%
close all