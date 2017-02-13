function visualizeStrategy(paramsTable, allTreasuries, longPrices, pfHistory, cashAccount, strategyParams, stratName)
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
genInfo.picsDir = '../../dissDataAndPics/bondPricing/';

if doExportPics
    genInfo.stratName = stratName;
    genInfo.suffix = ['_' genInfo.stratName];
end
genInfo.figClose = true;

%%

% remove days with NaN in parameters
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

% make some variables more easily accessible
initWealth = strategyParams.initWealth;
transCosts = strategyParams.transCosts;
initDate = strategyParams.initDate;
minDur = strategyParams.minDur;
maxDur = strategyParams.maxDur;
maturGrid = strategyParams.maturGrid;

%% Visualize interest rate environment
% Plot historic yield curves used for bond pricing and backtesting.

% specify high granularity to evaluate yield curves
allMaturs = [0.5:0.1:10];

% get yields / foward rates
paramsTableBt = paramsTable(paramsTable.Date >= initDate, :);
[fullYields, fowRates] = svenssonYields(paramsTableBt{:, 2:end}, allMaturs);

% get full grid matrices
fullMaturGrid = repmat(allMaturs, size(paramsTableBt, 1), 1);
fullTimeGrid = repmat(paramsTableBt.Date, 1, length(allMaturs));

% define maturity granularity
maturs = allMaturs;
[~, matursInds] = ismember(maturs, allMaturs);
matursInds = matursInds(matursInds > 0);

% define date granularity
freq = 10; 
dateInds = 1:freq:length(paramsTableBt.Date);

% get respective data
timeGrid = fullTimeGrid(dateInds, matursInds);
maturSurfaceGrid = fullMaturGrid(dateInds, matursInds);
yields = fullYields(dateInds, matursInds);

%% visualize yield curve surface

% plot yield curves over time
f = figure('Position', genInfo.pos);

h = surf(timeGrid, maturSurfaceGrid, yields);
set(h, 'EdgeColor', 'none')
shading interp
camlight
view(20, 20)
lighting gouraud
camproj perspective
datetick 'x'
grid on
grid minor
caxis([0 12])

% write to disk
exportFig(f, ['yieldCurveSurface' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% surface in gray

% different angle
f = figure('Position', genInfo.pos);

h = surf(timeGrid, maturSurfaceGrid, yields);
colormap gray
set(h, 'EdgeColor', 'none')
%shading facet
%camlight
view(-18, 25)
%lightangle(-50,-20)
%lighting gouraud
%camproj perspective
datetick 'x'
grid on
grid minor
caxis([0 20])

% write to disk
exportFig(f, ['yieldCurveSurfaceGray' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% get eligible bonds for strategy and visualize them

btPrices = longPrices;

% get observations within backtest period
xxInd = btPrices.Date >= initDate;
btPrices = btPrices(xxInd, :);

% join additional information to prices
bondInfoTable = summaryTable(allTreasuries);
btPrices = outerjoin(btPrices, bondInfoTable, 'Keys', {'TreasuryID'},...
    'MergeKeys', true, 'Type', 'left');

% get time to maturity for each observation
btPrices = sortrows(btPrices, 'Date');
btPrices.CurrentMaturity = btPrices.Maturity - btPrices.Date;

% eliminate 30 year bonds
xxInds = strcmp(btPrices.TreasuryType, '30-Year BOND');
btPrices = btPrices(~xxInds, :);

% reduce to eligible bonds with small buffer
xxEligible = btPrices.CurrentMaturity >= minDur & btPrices.CurrentMaturity <= maxDur;
btPrices = btPrices(xxEligible, :);

% get number of eligible bonds per date
nEligibleBonds = grpstats(btPrices(:, {'Date', 'CurrentMaturity'}), 'Date');
nEligibleBonds = sortrows(nEligibleBonds, 'Date');

%% number of eligible bonds

f = figure('Position', genInfo.pos);
plot(nEligibleBonds.Date, nEligibleBonds.GroupCount, '.')
grid on
grid minor
datetick 'x'
xlabel('time')
ylabel('Number of eligible bonds')

% write to disk
exportFig(f, ['numberEligibleBonds' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot eligible bond prices and coupon payments

% get only coupon payments
xxInds = ~(btPrices.CouponPayment == 0);
eligCoupons = btPrices(xxInds, :);

f = figure('Position', genInfo.pos);

% get some average yields
paramsTableBt = paramsTable(paramsTable.Date >= initDate, :);
[avgYield, ~] = svenssonYields(paramsTableBt{:, 2:end}, 8.5);
benchYield = [paramsTableBt(:, 'Date'), array2table(avgYield, 'VariableNames', {'Yield'})];

subplot(3, 1, 1)
plot(paramsTableBt.Date, avgYield)
datetick 'x'
grid on
grid minor
title('Yield of maturity 8.5')


subplot(3, 1, 2)
plot(eligCoupons.Date, eligCoupons.CouponPayment, '.')
hold on
plot(paramsTableBt.Date, avgYield/2, '-r')
hold off
datetick 'x'
grid on
grid minor
xlabel('date')
ylabel('Coupon payment')
title('Coupon payments of eligible bonds')


% plot eligible bonds
widePrices = unstack(btPrices(:, {'Date', 'TreasuryID', 'Price'}), 'Price', 'TreasuryID');

subplot(3, 1, 3)
plot(widePrices.Date, widePrices{:, 2:end}, 'Color', 0.4*[1, 1, 1])
hold on
plot([widePrices.Date(1), widePrices.Date(end)], 100*[1, 1], '-r')
hold off
datetick 'x'
grid on
grid minor
xlabel('date')
ylabel('price')
title('Eligible bond prices')

% write to disk
exportFig(f, ['eligibleBondPricesAndCoupons' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

% %% In 3D - rather useless
% 
% yVals = repmat(1:size(widePrices(:, 2:end), 2), size(widePrices, 1), 1);
% plot3(widePrices.Date, yVals, widePrices{:, 2:end}, '.k')%, 'Color', 0.4*[1, 1, 1])
% camlight
% datetick 'x'
% grid on
% grid minor
% xlabel('date')
% ylabel('price')
% title('Eligible bond prices')

%% analyse portfolio TTMs

btHistory = pfHistory;

% get TTMs
btHistory = outerjoin(btHistory, btPrices(:, {'TreasuryID', 'Date', 'Maturity'}),...
    'Keys', {'TreasuryID', 'Date'}, 'MergeKeys', true, 'Type', 'left');
btHistory.TTM = btHistory.Maturity - btHistory.Date;

f = figure('Position', genInfo.pos);
plot(btHistory.Date, btHistory.TTM / 365, '.')
hold on
xlim = get(gca, 'XLim');
for ii=1:length(maturGrid)
    plot(xlim, (maturGrid(ii) - initDate) / 365*[1 1], '-r')
end
hold off
datetick 'x'
grid on
grid minor
ylabel('Time to maturity in years')
title('TTMs of portfolio vs desired TTMs')

% write to disk
exportFig(f, ['ttmOfBonds' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% get bond portfolio performance

pfValues = bondPfPerformance(btHistory, cashAccount);

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
exportFig(f, ['bondPortfolioPerformance' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% portfolio returns

% get logarithmic returns
logRets = diff(log(pfValues.FullValue));

f = figure('Position', genInfo.pos);
plot(pfValues.Date(2:end), logRets*100)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

% write to disk
exportFig(f, ['bondPortfolioReturns' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot portfolio returns vs changes of average yields

yieldRets = diff(log(benchYield.Yield));

f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(yieldRets * 100, (-1)*logRets*100, '.')
grid on
grid minor
xlabel('Log-difference of yields')
ylabel('Log portfolio return')

U = ranks([yieldRets logRets]);
subplot(1, 2, 2)
plot(U(:, 1), U(:, 2), '.')
grid on
grid minor
axis square
xlabel('Yield changes')
ylabel('Portfolio returns')

% write to disk
exportFig(f, ['bondPfReturnsVsYieldChanges' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot change ratio over time

ratios = (-1)*logRets ./ yieldRets;
dats = benchYield.Date(2:end);
xxInds = abs(yieldRets)*100 > 0.15 & abs(logRets)*100 > 0.15;
xxShort = movingAvg(ratios, 300, true);
xxShort2 = movingAvg(ratios(xxInds), 300, true);

f = figure('Position', genInfo.pos);
subplot(3, 1, 1)
plot(dats(xxInds), ratios(xxInds))
datetick 'x'
grid on
grid minor
title('Portfolio return / yield change ratio: outlier free')

subplot(3, 1, 2)
plot(dats, xxShort)
datetick 'x'
grid on
grid minor
title('Portfolio return / yield change ratio: movAvg - unstable close to zero returns')

subplot(3, 1, 3)
plot(dats(xxInds), xxShort2)
datetick 'x'
grid on
grid minor
title('Portfolio return / yield change ratio: robust movAvg')

% write to disk
exportFig(f, ['bondPfReturnsVsYieldChangeRatio' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% find observations deviating from diagonal

dats = benchYield.Date(2:end);
xxInds = U(:, 1) + U(:, 2) < 0.7;

f = figure('Position', genInfo.pos);
stem(dats(~xxInds), logRets(~xxInds), '.r')
hold on
stem(dats(xxInds), logRets(xxInds), '.')
hold off
datetick 'x'
axis tight
grid on
grid minor


% write to disk
exportFig(f, ['bondPfReturnsVsYieldChangeOutliers' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% squared log returns

f = figure('Position', genInfo.pos);
plot(pfValues.Date(2:end), (logRets*100).^2)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

% write to disk
exportFig(f, ['bondPfSquaredRets' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% moving average of returns

xxShort = movingAvg(logRets, 300, true);
f = figure('Position', genInfo.pos);
plot(pfValues.Date(2:end), xxShort)
hold on
plot(paramsTableBt.Date, (-1)*avgYield / 100 / 365)
hold off
datetick 'x'
grid on
grid minor
title('Moving average, 300 days')

% write to disk
exportFig(f, ['bondPfMeanReturns' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% plot distributions

f = figure('Position', genInfo.pos);
subplot(2, 1, 1)
plot(btHistory.Date, btHistory.CouponPayment, '.')
datetick 'x'
grid on
grid minor
title('Distributions per single volume')

subplot(2, 1, 2)
plot(btHistory.Date, btHistory.CouponPayment .* btHistory.MorningVolumes, '.r')
datetick 'x'
grid on
grid minor
title('Distributions per bond position')


% write to disk
exportFig(f, ['bondDistributions' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% portfolio weights

lastDate = max(btHistory.Date);
lastDatePf = selRowsProp(btHistory, 'Date', lastDate);

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

btWide = unstack(btHistory(:, {'Date', 'TreasuryID', 'Price'}), 'Price', 'TreasuryID');

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
aggrBondDistributions = grpstats(btPrices(:, {'TreasuryID', 'CouponPayment'}), ...
    'TreasuryID', 'sum');

fullBondCashFlows = outerjoin(bondComponentProperties, ...
    aggrBondDistributions(:, {'TreasuryID', 'sum_CouponPayment'}), 'Keys', 'TreasuryID',...
    'MergeKeys', true, 'Type', 'left');
fullBondCashFlows.Overall = fullBondCashFlows.sum_CouponPayment + fullBondCashFlows.PriceGain;

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
exportFig(f, ['bondPrices' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

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
plot(paramsTableBt.Date, avgYield, '-r')
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
plot(fullBondCashFlows.SellDate, fullBondCashFlows.DiscRet, '.')
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Bond returns vs selling date')

subplot(1, 2, 2)
plot(fullBondCashFlows.HoldingDur / 365, fullBondCashFlows.DiscRet, '.')
grid on
grid minor
xlabel('Time that bond was held (years)')
title('Bond returns vs holding duration')


% write to disk
exportFig(f, ['bondReturns' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% histogram of individual bond returns

f = figure('Position', genInfo.pos);
hist(fullBondCashFlows.DiscRet, 30)
title('Bond price returns (dirty price)')
grid on
grid minor

% write to disk
exportFig(f, ['bondReturnsHistogram' genInfo.suffix], genInfo.picsDir, genInfo.fmt, genInfo.figClose)

