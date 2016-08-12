%% load data

clearvars -except longPrices allTreasuries
% load all bond prices
% dataDir = '../priv_bondPriceData';
% fname = fullfile(dataDir, 'syntheticBondsLongFormat.mat');
% load(fname)

if ~exist('longPrices', 'var')
    historicBondPrices;
end

% load backtest results
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'bondPortfolioBacktestPerformance.mat');
load(fname)

% load historic yield curve parameters
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);

% remove days with NaN in parameters
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

%% define strategy parameters

GS = GlobalSettings;

% initial wealth
initWealth = 10000;

% transaction costs
transCosts = 10 / 10000;

% define initial starting date and move to next business day
desiredInitDate = datenum('1975-01-02');
initDate = makeBusDate(desiredInitDate, 'follow', GS.Holidays, GS.WeekendInd);

% define TTM range
minDur = 7*365 + 2; % exclude 7 year notes
maxDur = 10*365;

% define grid of desired maturities for initial portfolio allocation
maturGrid = datetime(datevec(initDate)) + calyears(7) + calmonths(3:3:36);
maturGrid = datenum(maturGrid);
maturGridDays = maturGrid - initDate;

%% get eligible bonds for strategy

btPrices = longPrices;

% get observations within backtest period
xxInd = btPrices.Date >= initDate;
btPrices = btPrices(xxInd, :);

% get time to maturity for each observation
btPrices = sortrows(btPrices, 'Date');
btPrices.CurrentMaturity = btPrices.Maturity - btPrices.Date;

% eliminate 30 year bonds
xxInds = strcmp(btPrices.TreasuryType, '30-Year BOND');
btPrices = btPrices(~xxInds, :);

% reduce to eligible bonds with small buffer
xxEligible = btPrices.CurrentMaturity >= minDur & btPrices.CurrentMaturity <= maxDur;
btPrices = btPrices(xxEligible, :);

%% visualize number of eligible bonds over time

% get number of eligible bonds per date
nEligibleBonds = grpstats(btPrices(:, {'Date', 'CurrentMaturity'}), 'Date');
nEligibleBonds = sortrows(nEligibleBonds, 'Date');

figure()
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

figure()

% get some average yields
paramsTableBt = paramsTable(paramsTable.Date >= initDate, :);
[avgYield, ~] = svenssonYields(paramsTableBt{:, 2:end}, 8.5);

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
btHistory = outerjoin(btHistory, longPrices(:, {'TreasuryID', 'Date', 'Maturity'}),...
    'Keys', {'TreasuryID', 'Date'}, 'MergeKeys', true, 'Type', 'left');
btHistory.TTM = btHistory.Maturity - btHistory.Date;

figure()
plot(btHistory.Date, btHistory.TTM / 365, '.')
hold on
xlim = get(gca, 'XLim');
for ii=1:length(maturGrid)
    plot(xlim, maturGridDays(ii) / 365*[1 1], '-r')
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

%% plot bond portfolio performance

figure()
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

figure()
plot(pfValues.Date(2:end), logRets*100)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

%% squared log returns

figure()
plot(pfValues.Date(2:end), (logRets*100).^2)
datetick 'x'
grid on
grid minor
xlabel('date')
title('logarithmic returns (%)')

%% moving average of returns

[xxShort, ~] = movavg(logRets, 300, 300, 0);
plot(pfValues.Date(2:end), xxShort)
datetick 'x'
grid on
grid minor
title('Moving average, 300 days')

%% plot distributions

figure()
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

%%
btWide = unstack(btHistory(:, {'Date', 'TreasuryID', 'Price'}), 'Price', 'TreasuryID');

%% plot distributions, yields, bond prices

% get some average yields
paramsTableBt = paramsTable(paramsTable.Date >= initDate, :);
[avgYield, ~] = svenssonYields(paramsTableBt{:, 2:end}, 8.5);

figure()
subplot(2, 1, 1)
xxInds = ~(btHistory.CouponPayment == 0);
plot(btHistory.Date(xxInds), btHistory.CouponPayment(xxInds), '.')
hold on
plot(paramsTableBt.Date, avgYield/2, '-r')
plot(sellDate, gain, '.r')
hold off
datetick 'x'
grid on
grid minor


subplot(2, 1, 2)
plot(btWide.Date, btWide{:, 2:end}, '-k')
hold on
plot(paramsTableBt.Date, 100 + 6*(mean(avgYield/2) - avgYield/2), '-r')
datetick 'x'
grid on
grid minor

%% Buying vs selling price

btWide = unstack(btHistory(:, {'Date', 'TreasuryID', 'Price'}), 'Price', 'TreasuryID');

figure()
plot(btWide.Date, btWide{:, 2:end}, '-b')
datetick 'x'
grid on
grid minor

%% get return per bond

nAss = size(btWide, 2) - 1;
dats = btWide.Date;
vals = btWide{:, 2:end};

% preallocation
holdingDur = zeros(nAss, 1);
sellDate = zeros(nAss, 1);
discRet = zeros(nAss, 1);
gain = zeros(nAss, 1);

for ii=1:nAss
    % get current time series
    thisSeries = vals(:, ii);
    
    % get first observation
    xxIndBeg = find(~isnan(thisSeries), 1, 'first');
    xxIndEnd = find(~isnan(thisSeries), 1, 'last');
    
    sellDate(ii) = dats(xxIndEnd);
    holdingDur(ii) = dats(xxIndEnd) - dats(xxIndBeg);
    discRet(ii) = (thisSeries(xxIndEnd) - thisSeries(xxIndBeg))/thisSeries(xxIndBeg);
    gain(ii) = thisSeries(xxIndEnd) - thisSeries(xxIndBeg);
    
end

%% individual realized bond returns

figure()
subplot(1, 2, 1)
plot(sellDate, discRet, '.')
datetick 'x'
grid on
grid minor
xlabel('Selling date')
title('Bond returns vs selling date')

subplot(1, 2, 2)
plot(holdingDur / 365, discRet, '.')
grid on
grid minor
xlabel('Time that bond was held (years)')
title('Bond returns vs holding duration')


%% histogram of individual bond returns

figure()
hist(discRet, 30)
title('Bond price returns (dirty price)')
grid on
grid minor

%% portfolio weights

lastDate = max(btHistory.Date);
lastDatePf = selRowsProp(btHistory, 'Date', lastDate);
plot(sort(lastDatePf.MarketValue), '.')
grid on
grid minor
title('Market value of individual bond positions')
xlabel('Bond')
ylabel('Market value')

%% define granularity of surface plot

% specify high granularity to evaluate yield curves
allMaturs = [0.5:0.1:10];

% get yields / foward rates
paramsTableBt = paramsTable(paramsTable.Date >= initDate, :);
[fullYields, fowRates] = svenssonYields(paramsTableBt{:, 2:end}, allMaturs);

% get full grid matrices
fullMaturGrid = repmat(allMaturs, size(paramsTableBt, 1), 1);
fullTimeGrid = repmat(paramsTableBt.Date, 1, length(allMaturs));

%% define granularity for plots

% define maturity granularity
maturs = allMaturs;
[~, matursInds] = ismember(maturs, allMaturs);
matursInds = matursInds(matursInds > 0);

% define date granularity
freq = 10; 
dateInds = 1:freq:length(paramsTableBt.Date);

% get respective data
timeGrid = fullTimeGrid(dateInds, matursInds);
maturGrid = fullMaturGrid(dateInds, matursInds);
yields = fullYields(dateInds, matursInds);


%% plot yield curves over time

figure()
h = surf(timeGrid, maturGrid, yields);
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


%% different angle

figure()
h = surf(timeGrid, maturGrid, yields);
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

