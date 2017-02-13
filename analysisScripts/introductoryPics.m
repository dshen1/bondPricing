% this script shall produce some introductory pictures for fixed-income
% theory

%% set up general settings

genInfo.pos = [50 50 1200 500];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = false;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/';

% pick two different dates for which to show yield curves
genInfo.date1 = makeBusDate(datenum('1987-04-03'), 'follow', ...
    genInfo.GS.Holidays, genInfo.GS.WeekendInd);
genInfo.date2 = makeBusDate(datenum('2012-02-02'), 'follow', ...
    genInfo.GS.Holidays, genInfo.GS.WeekendInd);

%% load svensson parameters

dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

%% pick and visualize chosen yield curve

% pick yield curves for selected days
genInfo.yieldCurve1 = selRowsKey(paramsTable, 'Date', genInfo.date1);
genInfo.yieldCurve2 = selRowsKey(paramsTable, 'Date', genInfo.date2);

% calculate yields and forward rates
maturs = [0.001, 0.1:0.1:30];
[yields1, fowRates1] = svenssonYields(genInfo.yieldCurve1{1, 2:end}, maturs);
[yields2, fowRates2] = svenssonYields(genInfo.yieldCurve2{1, 2:end}, maturs);

% plot yields
f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
plot(maturs, yields1)
hold on
plot(maturs,yields2)
hold off
grid on
grid minor
xlabel('Maturity')
ylabel('Annualized yield')
title('Yield curves')
legend(datestr(genInfo.date1), datestr(genInfo.date2), 'Location', 'Southeast')

% plot forward rates
subplot(1, 2, 2)
plot(maturs, fowRates1)
hold on
plot(maturs, fowRates2)
hold off
grid on
grid minor
xlabel('Maturity')
ylabel('Forward rate')
title('Forward rates')
legend(datestr(genInfo.date1), datestr(genInfo.date2), 'Location', 'Southeast')

% write to disk
exportFig(f, 'yieldsAndFowRates', genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% Plot associated discount functions

% translate yields to discounts
discountVals1 = yieldToDiscount(maturs, yields1/100);
discountVals2 = yieldToDiscount(maturs, yields2/100);

% plot discount functions
f = figure();
plot(maturs, discountVals1)
hold on
plot(maturs, discountVals2)
hold off
grid on
grid minor
xlabel('Maturity')
ylabel('Discount factor')
title('Discount function')
legend(datestr(genInfo.date1), datestr(genInfo.date2), 'Location', 'Southwest')

% write to disk
exportFig(f, 'discountFunction', genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% show relation of zero coupon bond prices and discount function

% define some zero coupon bond
auctionDate = genInfo.date1;
zeroCouponBond = Treasury('TBill', 5*52, auctionDate, genInfo.GS, 0);

% define fixed interest rates over lifetime
lifeTimeRange = zeroCouponBond.AuctionDate:zeroCouponBond.Maturity;
nDays = length(lifeTimeRange);

% get yield curve parameters
params = genInfo.yieldCurve1{1, 2:end};
constantYieldCurve = [lifeTimeRange', repmat(params, nDays, 1)];
constantYieldCurve = array2table(constantYieldCurve, ...
    'VariableNames', tabnames(genInfo.yieldCurve1));

% get prices with fixed interest rates
zeroCouponPrices = svenssonBondPrice(zeroCouponBond, constantYieldCurve);

% fix last price
zeroCouponPrices(end) = zeroCouponBond.NominalValue;

% specify high granularity to evaluate yield curves
allMaturs = [0.1:1:30];
[fullYields, fowRates] = svenssonYields(constantYieldCurve{:, 2:end}, allMaturs);

% get full grid matrices for surface plot
fullMaturGrid = repmat(allMaturs, size(constantYieldCurve, 1), 1);
fullTimeGrid = repmat(constantYieldCurve.Date, 1, length(allMaturs));

%%

% plot discount function
f = figure('Position', [50 50 1200 300]);
subplot(1, 3, 1)
plot(maturs, discountVals1)
hold on
plot((lifeTimeRange(end)-lifeTimeRange(1))/365, zeroCouponPrices(1)/100, ...
    'o', 'MarkerSize', 8, 'LineWidth', 2)
hold off
grid on
grid minor
xlabel('Maturity (in years)')
ylabel('Discount factor')

% surface of constant yield curves
subplot(1, 3, 2)
h = mesh(fullTimeGrid(1:50:end, :), fullMaturGrid(1:50:end, :), fullYields(1:50:end, :));
zlim([0 10])
view(20, 20)
datetick('x', 'yy')
grid on
grid minor
caxis([0 12])

% evolution of bond price under constant yields
subplot(1, 3, 3)
plot(lifeTimeRange, zeroCouponPrices/100)
hold on
plot(lifeTimeRange(1), zeroCouponPrices(1)/100, 'o', 'MarkerSize', 8, 'LineWidth', 2)
hold off
datetick('x', 'yy')
grid on
grid minor
xlabel('Year')
ylabel('Bond price')

exportFig(f, 'zeroCouponConstYield', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)


%% bond price evolution figures

% for:
% - zero coupon bond
% - coupon bond with equal maturity
% show bond price evolution with
% - constant yields
% - real yields

% define some zero coupon bond
auctionDate = genInfo.date1;
zeroCouponBond = Treasury('TBill', 5*52, auctionDate, genInfo.GS, 0);
couponBond = Treasury('TNote', 5, auctionDate - 5, genInfo.GS);
cpRate = svenssonCouponRate(couponBond, genInfo.yieldCurve1);
couponBond = modifyCouponRate(couponBond, cpRate);

% get prices with fixed interest rates
zeroCouponPrices = svenssonBondPrice(zeroCouponBond, constantYieldCurve);
couponPrices = svenssonBondPrice(couponBond, constantYieldCurve);

% fix last price
zeroCouponPrices(end) = zeroCouponBond.NominalValue;
couponPrices(end) = couponBond.NominalValue;

% surface of constant yield curves
f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
h = mesh(fullTimeGrid(1:50:end, :), fullMaturGrid(1:50:end, :), fullYields(1:50:end, :));
zlim([0 10])
view(20, 20)
datetick('x', 'yy')
grid on
grid minor
caxis([0 12])

% plot prices against each other
subplot(1, 2, 2)
plot(constantYieldCurve.Date, zeroCouponPrices)
hold on
plot(constantYieldCurve.Date, couponPrices)
hold off
datetick 'x'
grid on
grid minor
xlabel('Date')
ylabel('Bond price')
legend('Zero coupon bond', ['Coupon bond (' num2str(couponBond.CouponRate*2*100) '%)'], ...
    'Location', 'Southeast')

exportFig(f, 'bondPricesConstYield', genInfo.picsDir, genInfo.fmt, genInfo.figClose, false)

%%

% get historic yields
xxInds = ismember(constantYieldCurve.Date, paramsTable.Date);
xxDates = constantYieldCurve.Date(xxInds);
historicYields = selRowsKey(paramsTable, 'Date', xxDates);
historicYields = sortrows(historicYields, 'Date');

% specify high granularity to evaluate yield curves
allMaturs = [0.1:1:30];
[fullYields, fowRates] = svenssonYields(historicYields{:, 2:end}, allMaturs);

% get full grid matrices for surface plot
fullMaturGrid = repmat(allMaturs, size(historicYields, 1), 1);
fullTimeGrid = repmat(historicYields.Date, 1, length(allMaturs));

% get prices with fixed interest rates
zeroCouponPrices = svenssonBondPrice(zeroCouponBond, historicYields);
couponPrices = svenssonBondPrice(couponBond, historicYields);

% fix last price
zeroCouponPrices(end) = zeroCouponBond.NominalValue;
couponPrices(end) = couponBond.NominalValue;

% surface of constant yield curves
f = figure('Position', genInfo.pos);
subplot(1, 2, 1)
h = mesh(fullTimeGrid(1:10:end, :), fullMaturGrid(1:10:end, :), fullYields(1:10:end, :));
zlim([0 10])
view(20, 20)
datetick('x', 'yy')
grid on
grid minor
caxis([0 12])

% plot prices against each other
subplot(1, 2, 2)
plot(historicYields.Date, zeroCouponPrices)
hold on
plot(historicYields.Date, couponPrices)
hold off
datetick 'x'
grid on
grid minor
xlabel('Date')
ylabel('Bond price')
legend('Zero coupon bond', ['Coupon bond (' num2str(couponBond.CouponRate*2*100) '%)'], ...
    'Location', 'Southeast')

exportFig(f, 'bondPricesHistoricYields', genInfo.picsDir, genInfo.fmt, genInfo.figClose, false)
