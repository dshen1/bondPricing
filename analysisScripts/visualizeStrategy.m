function visualizeStrategy(paramsTable, allTreasuries, longPrices, pfHistory, cashAccount, strategyParams)

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

% plot yield curves over time
figure('Position', [50 50 1200 600])
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

% different angle
figure('Position', [50 50 1200 600])
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

figure('Position', [50 50 1200 600])
plot(nEligibleBonds.Date, nEligibleBonds.GroupCount, '.')
grid on
grid minor
datetick 'x'
xlabel('time')
ylabel('Number of eligible bonds')

%% plot eligible bond prices and coupon payments

% get only coupon payments
xxInds = ~(btPrices.CouponPayment == 0);
eligCoupons = btPrices(xxInds, :);

figure('Position', [50 50 1200 600])

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
datetick 'x'
grid on
grid minor
xlabel('date')
ylabel('price')
title('Eligible bond prices')

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

figure('Position', [50 50 1200 600])
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

%% get bond portfolio performance

% get market values of individual positions
btHistory.EveningVolumes = btHistory.MorningVolumes + btHistory.Orders;
btHistory.MarketValue = btHistory.EveningVolumes .* btHistory.Price;

% aggregate per date
bondValues = grpstats(btHistory(:, {'Date', 'MarketValue'}), 'Date', 'sum');
bondValues.Properties.VariableNames{'sum_MarketValue'} = 'MarketValue';

% get cash account values in the evening
cashAccount.Cash = sum(cashAccount{:, 2:end}, 2, 'omitnan');

% join bond values and cash position
pfValues = outerjoin(bondValues(:, {'Date', 'MarketValue'}), ...
    cashAccount(:, {'Date', 'Cash'}), 'Keys', 'Date', 'MergeKeys', true, 'Type', 'left');

pfValues = sortrows(pfValues, 'Date');
pfValues.FullValue = pfValues.MarketValue + pfValues.Cash;

% plot portfolio performance
figure('Position', [50 50 1200 600])
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

%% portfolio returns

% get logarithmic returns
logRets = diff(log(pfValues.FullValue));

figure('Position', [50 50 1200 600])
plot(pfValues.Date(2:end), logRets*100)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

%% plot portfolio returns vs changes of average yields

yieldRets = diff(log(benchYield.Yield));

figure('Position', [50 50 1200 600])
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

%% plot change ratio over time

ratios = yieldRets ./ logRets;
dats = benchYield.Date(2:end);
xxInds = abs(yieldRets)*100 > 0.15 & abs(logRets)*100 > 0.15;
[xxShort, ~] = movavg(ratios, 300, 300, 0);
[xxShort2, ~] = movavg(ratios(xxInds), 300, 300, 0);

figure('Position', [50 50 1200 600])
subplot(3, 1, 1)
plot(dats(xxInds), ratios(xxInds))
datetick 'x'
grid on
grid minor
title('Yield change / portfolio return ratio: outlier free')

subplot(3, 1, 2)
plot(dats, xxShort)
datetick 'x'
grid on
grid minor
title('Yield change / portfolio return ratio: movAvg')

subplot(3, 1, 3)
plot(dats(xxInds), xxShort2)
datetick 'x'
grid on
grid minor
title('Yield change / portfolio return ratio: robust movAvg')

%% find observations deviating from diagonal

dats = benchYield.Date(2:end);
xxInds = U(:, 1) + U(:, 2) < 0.7;
figure('Position', [50 50 1200 600])
stem(dats(~xxInds), logRets(~xxInds), '.r')
hold on
stem(dats(xxInds), logRets(xxInds), '.')
hold off
datetick 'x'
axis tight
grid on
grid minor

%% squared log returns

figure('Position', [50 50 1200 600])
plot(pfValues.Date(2:end), (logRets*100).^2)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

%% moving average of returns

[xxShort, ~] = movavg(logRets, 300, 300, 0);
figure('Position', [50 50 1200 600])
plot(pfValues.Date(2:end), xxShort)
hold on
plot(paramsTableBt.Date, (-1)*avgYield / 100 / 365)
hold off
datetick 'x'
grid on
grid minor
title('Moving average, 300 days')


%% plot distributions

figure('Position', [50 50 1200 600])
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

%% portfolio weights

lastDate = max(btHistory.Date);
lastDatePf = selRowsProp(btHistory, 'Date', lastDate);
figure('Position', [50 50 1200 600])
plot(sort(lastDatePf.MarketValue), '.')
grid on
grid minor
title('Market value of individual bond positions')
xlabel('Bond')
ylabel('Market value')

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
figure('Position', [50 50 1200 600])
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

%% individual bond cash-flows

figure('Position', [50 50 1200 600])
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

%% plot individual bond cash-flows
% one could also compare
% - auction date yields to coupons gained
% - price gain vs difference between yield at initial date and yield at
% selling date

figure('Position', [50 50 1200 600])

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

figure('Position', [50 50 1200 600])
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


%% individual realized bond returns

figure('Position', [50 50 1200 600])
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


%% histogram of individual bond returns

figure('Position', [50 50 1200 600])
hist(fullBondCashFlows.DiscRet, 30)
title('Bond price returns (dirty price)')
grid on
grid minor


