function visualizeBondMarket(paramsTable, allTreasuries, longPrices, strategyParams, marketName)
% visualize bond market
%
% Inputs:
%   marketName      if not empty this will determine the name of output
%                   files

doExportPics = false;

if exist('marketName', 'var') == true
    if ~isempty(marketName)
        doExportPics = true;
    end
end

%% specify settings for graphics

genInfo.pos = [50 50 1200 600];
genInfo.fmt = 'png';
genInfo.picsDir = '../../dissDataAndPics/bondPricing/';

if doExportPics
    genInfo.marketName = marketName;
    genInfo.suffix = ['_' genInfo.marketName];
end
genInfo.figClose = true;

% make some variables more easily accessible
initWealth = strategyParams.initWealth;
transCosts = strategyParams.transCosts;
initDate = strategyParams.initDate;
minDur = strategyParams.minDur;
maxDur = strategyParams.maxDur;
maturGrid = strategyParams.maturGrid;

%%

% remove days with NaN in parameters
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);


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
[avgYield, ~] = svenssonYields(paramsTableBt{:, 2:end}, 10);
benchYield = [paramsTableBt(:, 'Date'), array2table(avgYield, 'VariableNames', {'Yield'})];

subplot(3, 1, 1)
plot(paramsTableBt.Date, avgYield)
datetick 'x'
grid on
grid minor
title('Yield of maturity 10')


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