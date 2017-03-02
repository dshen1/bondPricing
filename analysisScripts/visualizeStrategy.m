function visualizeStrategy(paramsTable, pfHistory, cashAccount, pfTimeTrend, macDurs, strategyParams, stratName)
% visual inspection of backtested bond portfolio strategy
%
% Inputs:
%   stratName       if not empty this will determine the name of output
%                   files

doExportPics = false;

if exist('stratName', 'var') == true
    if ~isempty(stratName)
        doExportPics = true;
    end
end

%% specify settings for graphics

genInfo.pos = [50 50 1200 600];
genInfo.fmt = 'png';
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';

if doExportPics
    genInfo.stratName = stratName;
    genInfo.suffix = ['_' genInfo.stratName];
end
genInfo.figClose = false;

%% make some pre-calculations

logRets = diff(log(pfTimeTrend.CurrentValue));

pfVolaHat = nan(size(logRets));
for ii=100:length(logRets)
    pfVolaHat(ii) = sampleStd(100*logRets(1:ii), 0.95);
end

bskt.Date = pfTimeTrend.Date;
bskt.logRets = logRets;
bskt.pfVolaHat = pfVolaHat;

%% get bond portfolio performance

pfValues = bondPfPerformance(pfHistory, cashAccount);

% plot portfolio performance
f = figure('Position', genInfo.pos);
plot(pfValues.Date, pfValues.FullValue)
hold on
plot(pfValues.Date, pfValues.Cash)
plot(cashAccount.Date(2:end), cumsum(cashAccount.Coupons(2:end)))
hold off
datetick 'x'
grid on
grid minor
legend('Portfolio value', 'Cash value', 'Cumulated distributions', ...
    'Location', 'NorthWest')

% write to disk
exportFig(f, ['bondPfPerformance' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% log portfolio performance

f = figure();

plot(pfTimeTrend.Date, log(pfTimeTrend.CurrentValue))
datetick 'x'
grid minor
set(gca, 'XTickLabelRot', 45)
title('Log portfolio value')

% write to disk
exportFig(f, ['bondPfPerformanceLog' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% interest rates vs future portfolio return

xxInds = paramsTable.Date >= strategyParams.initDate;
thisParams = paramsTable{xxInds, 2:end};
thisDates = paramsTable.Date(xxInds);

% maturities are given in years
maturs = 8;

% get yields / foward rates
[yields, ~] = svenssonYields(thisParams, maturs);

allHorizons = [250, 500, 1000, 2500];

f = figure('Position', genInfo.pos);
for ii=1:length(allHorizons)
    subplot(2, 2, ii)
    nDaysAhead = allHorizons(ii);
    nYearsAhead = nDaysAhead / 250;
    xx = movingAvg(bskt.logRets, nDaysAhead, true)*250*100;
    plot(pfTimeTrend.Date(2:(end-nDaysAhead)), xx(nDaysAhead+1:end))
    hold on
    plot(thisDates, yields)
    title([num2str(nYearsAhead) ' years ahead'])
    datetick 'x'
    axis tight
    grid minor
    xlabel('First window date')
    ylabel([num2str(maturs) ' years yield'])
end

% write to disk
exportFig(f, ['bondPfPredictoryPowerOfYield' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% show portfolio characteristics: trend and sensitivity

f = figure('pos', genInfo.pos);
subplot(2, 1, 1)
plot(bskt.Date, pfTimeTrend.TimeTrend*100); 
datetick 'x'; 
grid minor
title('Deterministic portfolio trend')

subplot(2, 1, 2)
plot(macDurs.Date, macDurs.MacDur)
grid minor
datetick 'x'
title('Portfolio sensitivity')

% write to disk
exportFig(f, ['bondPfCharacteristics' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% predictory power of deterministic trend

nNextYears = 8;

% get associated returns
nNextDays = nNextYears * 250;
pfVals = pfValues.FullValue;
futureRets = pfVals((nNextDays+1):end)./pfVals(1:(end-nNextDays));
futureRets = futureRets.^(1/nNextYears) - 1;

f = figure('pos', genInfo.pos);
scatter(pfTimeTrend.TimeTrend(1:length(futureRets)), futureRets, ...
    8, 1:length(futureRets))
xlabel('Time trend')
ylabel('Annualized portfolio return')
title([num2str(nNextYears) ' years predictory power'])
grid minor
colorbar()

% write to disk
exportFig(f, ['bondPfPredictoryPower' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% show portfolio returns and estimated volatility

f = figure('pos', genInfo.pos);

subplot(2, 1, 1)
plot(bskt.Date(2:end), 100*logRets)
grid minor
datetick 'x'
title('Logarithmic portfolio returns, %')

subplot(2, 1, 2)
plot(bskt.Date(2:end), pfVolaHat)
grid minor
datetick 'x'
title('Estimated portfolio return volatility')

% write to disk
exportFig(f, ['bondPfReturnsAndVola' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% get yield proxy
% portfolio return = portfolio trend + portfolio sensitivity * yield change
%
% yield change: parallel yield curve shift
% pfRet = dur .* yield change + time trend
% -> (pfRet - time trend)./ dur = yield change

% extract dates and parameters for given time period
xxInds = paramsTable.Date >= strategyParams.initDate;
thisParams = paramsTable{xxInds, 2:end};

% maturities are given in years
maturs = [0.1 1:30];

% get yields / foward rates
[yields, ~] = svenssonYields(thisParams, maturs);

% get proxy for yield changes
xxProxyInd = 6;
yieldProxy = yields(:, xxProxyInd);
yieldProxyMatur = maturs(xxProxyInd);
yieldChanges = diff(yieldProxy);

bskt.yieldProxy = yieldProxy;

% infer yields from portfolio characterstics and portfolio returns
pfRets = exp(logRets) - 1;
unexpectedRets = pfRets - pfTimeTrend.TimeTrend(2:end);
inferredYieldChanges = (-1)*(unexpectedRets) ./ macDurs.MacDur(2:end) * 100;
inferredYieldChanges(isnan(inferredYieldChanges)) = 0;
inferredYields = mean(yields(2, 2:end)) + cumsum(inferredYieldChanges);

%% inferred yield changes vs yield proxy 

f = figure();

plot(inferredYieldChanges, yieldChanges, '.')
hold on
plot([-1, 1], [-1, 1], '-r')
hold off
grid minor
xlabel('Inferred parallel yield curve shifts')
ylabel('Yield changes of yield proxy')

% write to disk
exportFig(f, ['parallelShiftYieldProxy' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%%

f = figure('pos', genInfo.pos);

% plot true yields
p1 = plot(bskt.Date(2:end), yields(2:end, 3:end), '-b');
hold on
p2 = plot(bskt.Date(2:end), yieldProxy(2:end), '-g');
p3 = plot(bskt.Date(2:end), inferredYields, '-r');
hold off
grid minor
datetick 'x'
title('Aggregated inferred parallel shifts')
legend([p2, p3], [num2str(yieldProxyMatur) ' year yields'], 'Inferred yields')

% write to disk
exportFig(f, ['parallelShiftYieldProxyAggregated' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% calculate EWMA volas of yield changes and portfolio values


yieldChangeVolaHat = nan(size(yieldChanges));
for ii=100:length(logRets)
    yieldChangeVolaHat(ii) = sampleStd(yieldChanges(1:ii), 0.95);
end

bskt.yieldChangeVolaHat = yieldChangeVolaHat;

%% vola interest rates vs vola portfolio

f = figure('pos', genInfo.pos);

subplot(2, 1, 1)
plot(bskt.Date(2:end), pfVolaHat)
grid minor
datetick 'x'
title('Portfolio return volatility')

subplot(2, 1, 2)
plot(bskt.Date(2:end), yieldChangeVolaHat)
grid minor
datetick 'x'
title('Yield change (abs.) volatility')

% write to disk
exportFig(f, ['bondPfVolaVsYieldChangeVola' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% pf changes vs yield changes


f = figure('pos', genInfo.pos);
subplot(3, 1, 1)
plot(bskt.Date(2:end), 100*bskt.logRets)
grid minor
datetick 'x'
title('Log returns')

subplot(3, 1, 2)
absYieldChanges = diff(bskt.yieldProxy);
plot(bskt.Date(2:end), absYieldChanges)
grid minor
datetick 'x'
title('Yield change, abs')

subplot(3, 1, 3)
relYieldChanges = 100*diff(log(bskt.yieldProxy));
plot(bskt.Date(2:end), relYieldChanges)
grid minor
datetick 'x'
title('Yield change, rel')

% write to disk
exportFig(f, ['bondPfReturnsVsYieldChangesOverTime' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% plot portfolio returns vs changes of average yields

f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(absYieldChanges, (-1)*logRets*100, '.')
grid on
grid minor
xlabel('Absolute difference of yields')
ylabel('Log portfolio return')
axis square

U = ranks([absYieldChanges logRets]);
subplot(1, 2, 2)
plot(U(:, 1), U(:, 2), '.')
grid on
grid minor
axis square
xlabel('Yield changes')
ylabel('Portfolio returns')

% write to disk
exportFig(f, ['bondPfReturnsVsYieldChanges' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%%

f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(relYieldChanges, (-1)*logRets*100, '.')
grid on
grid minor
xlabel('Difference of log yields')
ylabel('Log portfolio return')
axis square

U = ranks([relYieldChanges logRets]);
subplot(1, 2, 2)
plot(U(:, 1), U(:, 2), '.')
grid on
grid minor
axis square
xlabel('Yield changes')
ylabel('Portfolio returns')

% write to disk
exportFig(f, ['bondPfReturnsVsRelYieldChanges' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% plot change ratio over time

yieldRets = relYieldChanges;
ratios = (-1)*logRets ./ yieldRets;
xxInds = abs(yieldRets) > 0.25 & abs(logRets)*100 > 0.25;
xxShort = movingAvg(ratios(xxInds), 300, true);

f = figure('Position', genInfo.pos);
subplot(2, 1, 1)
plot(bskt.Date(xxInds), ratios(xxInds))
datetick 'x'
grid on
grid minor
title('Portfolio return / yield change ratio: outlier free')

subplot(2, 1, 2)
plot(bskt.Date(xxInds), xxShort)
datetick 'x'
grid on
grid minor
title('Portfolio return / yield change ratio: robust movAvg')

% write to disk
exportFig(f, ['bondPfReturnsVsYieldChangeRatio' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% moving average of returns

xxShort = movingAvg(logRets, 300, true);
f = figure('Position', genInfo.pos);
p1 = plot(bskt.Date(2:end), xxShort);
hold on
p2 = plot(bskt.Date, (-1)*bskt.yieldProxy / 100 / 365);
hold off
datetick 'x'
grid on
grid minor
title('Moving average, 300 days')
legend([p1, p2], 'Moving average portfolio returns', 'Re-scaled yield proxy')

% write to disk
exportFig(f, ['bondPfMeanReturns' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot distributions

f = figure('Position', genInfo.pos);
subplot(2, 1, 1)
yVals = pfHistory.CouponPayment;
yVals(yVals == 0) = NaN;
plot(pfHistory.Date, yVals, '.')
datetick 'x'
grid on
grid minor
title('Distributions per single volume')

subplot(2, 1, 2)
yVals = pfHistory.CouponPayment .* pfHistory.MorningVolumes;
yVals(yVals == 0) = NaN;
plot(pfHistory.Date, yVals, '.r')
datetick 'x'
grid on
grid minor
title('Distributions per bond position')


% write to disk
exportFig(f, ['bondDistributions' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% portfolio weights

lastDate = max(pfHistory.Date);
lastDatePf = selRowsProp(pfHistory, 'Date', lastDate);

% get market value of each position
lastDatePf.EveningVolumes = lastDatePf.MorningVolumes + lastDatePf.Orders;
lastDatePf.MarketValue = lastDatePf.EveningVolumes .* lastDatePf.Price;

f = figure('Position', genInfo.pos);
plot(sort(lastDatePf.MarketValue), '.')
grid on
grid minor
title('Market value of individual bond positions')
xlabel('Bond')
ylabel('Market value')


% write to disk
exportFig(f, ['bondPfWeights' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% Buying vs selling price

btWide = unstack(pfHistory(:, {'Date', 'TreasuryID', 'Price'}), 'Price', 'TreasuryID');

%% get return and gain per bond

nAss = size(btWide, 2) - 1;
dats = btWide.Date;
vals = btWide{:, 2:end};

% preallocation
sellDate = zeros(nAss, 1);
buyDate = zeros(nAss, 1);
sellPrice = zeros(nAss, 1);
buyPrice = zeros(nAss, 1);

for ii=1:nAss
    % get current time series
    thisSeries = vals(:, ii);
    
    % get first observation
    xxIndBeg = find(~isnan(thisSeries), 1, 'first');
    xxIndEnd = find(~isnan(thisSeries), 1, 'last');
    
    sellDate(ii) = dats(xxIndEnd);
    buyDate(ii) = dats(xxIndBeg);
    buyPrice(ii) = thisSeries(xxIndBeg);
    sellPrice(ii) = thisSeries(xxIndEnd);
end

%%
% make table
priceGains = table(tabnames(btWide(:, 2:end))', buyDate, sellDate, ...
    buyPrice, sellPrice, ...
    'VariableNames', {'TreasuryID', 'BuyDate', 'SellDate', 'BuyPrice', 'SellPrice'});
priceGains.TreasuryID = categorical(priceGains.TreasuryID);
priceGains.HoldingDur = priceGains.SellDate - priceGains.BuyDate;
priceGains.PriceGain = priceGains.SellPrice - priceGains.BuyPrice;
priceGains.DiscRet = priceGains.PriceGain ./ priceGains.BuyPrice;

% join prevailing yields / yield differences
benchYield = array2table([bskt.Date, bskt.yieldProxy], 'VariableNames', {'Date', 'Yield'});
bondComponentProperties = outerjoin(priceGains, benchYield, 'LeftKeys', {'BuyDate'}, 'RightKeys', {'Date'},...
    'Type', 'left', 'MergeKeys', true);
bondComponentProperties.Properties.VariableNames{'Yield'} = 'InitYield';

bondComponentProperties = outerjoin(bondComponentProperties, benchYield, ...
    'LeftKeys', {'SellDate'}, 'RightKeys', {'Date'},...
    'Type', 'left', 'MergeKeys', true);
bondComponentProperties.Properties.VariableNames{'Yield'} = 'EndYield';
bondComponentProperties.YieldDiff = bondComponentProperties.EndYield - bondComponentProperties.InitYield;

bondComponentProperties.Properties.VariableNames{'BuyDate_Date'} = 'BuyDate';
bondComponentProperties.Properties.VariableNames{'SellDate_Date'} = 'SellDate';

%%
aggrBondDistributions = grpstats(pfHistory(:, {'TreasuryID', 'CouponPayment'}), ...
    'TreasuryID', 'sum');

fullBondCashFlows = outerjoin(bondComponentProperties, ...
    aggrBondDistributions(:, {'TreasuryID', 'sum_CouponPayment'}), 'Keys', 'TreasuryID',...
    'MergeKeys', true, 'Type', 'left');
fullBondCashFlows.Overall = fullBondCashFlows.sum_CouponPayment + fullBondCashFlows.PriceGain;
fullBondCashFlows.TR = fullBondCashFlows.Overall ./ fullBondCashFlows.BuyPrice;

%%
f = figure('Position', genInfo.pos);
subplot(2, 1, 1)
plot(btWide.Date, btWide{:, 2:end})
title('Portfolio component prices')
datetick 'x'
grid on
grid minor

subplot(2, 1, 2)
hold on
for ii=1:size(fullBondCashFlows, 1)
    thisPrices = [fullBondCashFlows.BuyPrice(ii), fullBondCashFlows.SellPrice(ii)];
    if thisPrices(2) > thisPrices(1)
        plot([fullBondCashFlows.BuyDate(ii), fullBondCashFlows.SellDate(ii)], ...
            thisPrices, '-b')
    else
        plot([fullBondCashFlows.BuyDate(ii), fullBondCashFlows.SellDate(ii)], ...
            thisPrices, '-r')
    end
end
hold off
title('Portfolio component prices')
datetick 'x'
grid on
grid minor


% write to disk
exportFig(f, ['bondPriceGains' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% individual bond cash-flows

f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(fullBondCashFlows.sum_CouponPayment, fullBondCashFlows.PriceGain, '.')
grid on
grid minor
hold on
ylim = get(gca, 'YLim');
plot([0 (-1)*ylim(1)], [0 ylim(1)], '-r')
hold off
xlabel('Coupon payments')
ylabel('Price gain')
title('Individual bond cash-flows')

subplot(1, 2, 2)
plot(fullBondCashFlows.SellDate, fullBondCashFlows.Overall, '.')
datetick 'x'
grid on
grid minor
xlabel('Selling date')
ylabel('Overall cash-flows')
title('Overall gain per bond')


% write to disk
exportFig(f, ['bondCashflows' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot individual bond cash-flows
% one could also compare
% - auction date yields to coupons gained
% - price gain vs difference between yield at initial date and yield at
% selling date

f = figure('Position', genInfo.pos);

subplot(2, 1, 1)
plot(benchYield.Date, benchYield.Yield, '-r')
datetick 'x'
grid on
grid minor
xlabel('Date')
title('Average yield curve')

subplot(2, 1, 2)
plot(fullBondCashFlows.SellDate, fullBondCashFlows.PriceGain, '.')
hold on
plot(fullBondCashFlows.SellDate, (-4)*fullBondCashFlows.YieldDiff, '-r')
hold off
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Price gain vs (-4) times yield difference')


% write to disk
exportFig(f, ['individualBondCashflows' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

f = figure('Position', genInfo.pos);
subplot(2, 1, 1)
plot(fullBondCashFlows.SellDate, fullBondCashFlows.sum_CouponPayment, '.')
hold on
plot(fullBondCashFlows.SellDate, fullBondCashFlows.InitYield*2, '-r')
hold off
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Cumulated coupon payments vs 2 times initially prevailing yields')

subplot(2, 1, 2)
plot(fullBondCashFlows.SellDate, fullBondCashFlows.Overall, '.')
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Overall gain per bond')

% write to disk
exportFig(f, ['individualBondCashflows2' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% individual realized bond returns

f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(fullBondCashFlows.SellDate, 100*fullBondCashFlows.TR, '.')
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Bond returns (perc.) vs selling date')

subplot(1, 2, 2)
plot(fullBondCashFlows.HoldingDur / 365, 100*fullBondCashFlows.TR, '.')
grid on
grid minor
xlabel('Time that bond was held (years)')
title('Bond returns (perc.) vs holding duration')


% write to disk
exportFig(f, ['individualBondTotalReturns' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% histogram of individual bond returns

f = figure('Position', genInfo.pos);
hist(100*fullBondCashFlows.TR, 30)
title('Bond total returns (perc.)')
grid on
grid minor

% write to disk
exportFig(f, ['individualBondTotalReturnsHistogram' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

