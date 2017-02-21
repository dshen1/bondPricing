%% bond prices and interest rate changes


%% set up general settings

genInfo.pos = [50 50 1200 600];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = true;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';

% pick start date
genInfo.date = makeBusDate(datenum('1987-04-03'), 'follow', ...
    genInfo.GS.Holidays, genInfo.GS.WeekendInd);
genInfo.date = makeBusDate(datenum('2005-06-02'), 'follow', ...
    genInfo.GS.Holidays, genInfo.GS.WeekendInd);

%% load svensson parameters

dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

%% extract / build yield curve

% create zero-coupon bond to get relevant range
auctionDate = genInfo.date;
couponBond = Treasury('TNote', 5, auctionDate, genInfo.GS);

% get yields for lifetime of coupon bond
xxInds = paramsTable.Date >= couponBond.AuctionDate & ...
    paramsTable.Date <= couponBond.Maturity;
periodParamsTable = paramsTable(xxInds, :);

% calculate yields and forward rates
maturs = [0.001, 0.1:0.1:30];
[yields, ~] = svenssonYields(periodParamsTable{:, 2:end}, maturs);

%%

constantParams = periodParamsTable;
constantParams{:, 2:end} = repmat(periodParamsTable{1, 2:end}, size(periodParamsTable, 1), 1);

xxHighYieldParams = find(paramsTable.Date >= datenum('1985-01-01'), 1, 'first');

increasingParams = constantParams;
xxIndHalf = floor(size(constantParams, 1)/6);
xxNReps = size(periodParamsTable, 1) - xxIndHalf;
increasingParams{xxIndHalf:end, 2:end} = repmat(paramsTable{xxHighYieldParams, 2:end}, xxNReps+1, 1);

%% get total return prices

constantPrices = totalReturnPrices(constantParams);

exampleParams = increasingParams;
prices = totalReturnPrices(exampleParams);

%% visualize artificially made yield curve spike

f = figure('pos', genInfo.pos);

subplot(1, 2, 1)
% compute values to visualize yield curves
allMaturs = [0.1:1:30];
[fullYields, fowRates] = svenssonYields(exampleParams{:, 2:end}, allMaturs);
fullTimeGrid = repmat(exampleParams.Date, 1, length(allMaturs));
fullMaturGrid = repmat(allMaturs, size(exampleParams, 1), 1);

h = mesh(fullTimeGrid(1:50:end, :), fullMaturGrid(1:50:end, :), fullYields(1:50:end, :));
%zlim([0 15])
%view(20, 20)
xlabel('Date')
ylabel('Maturity')
datetick('x', 'yy')
grid on
grid minor
%caxis([0 12])

subplot(1, 2, 2)

%p1 = plot(prices.Date, prices.ZeroCoupon, 'DisplayName', 'Zero-coupon');
hold on
p1 = plot(constantPrices.Date, constantPrices.Coupon, '-r', 'DisplayName', 'Coupon, constant yields');
p2 = plot(constantPrices.Date, constantPrices.TotalReturn, '-r', 'DisplayName', 'TR, constant yields');
p3 = plot(prices.Date, prices.Coupon, '-b', 'DisplayName', 'Coupon');
p4 = plot(prices.Date, prices.TotalReturn, '-b', 'DisplayName', 'Coupon, TR');
datetick 'x'
grid minor
prices.TotalReturn(end)
legend([p1, p2, p3, p4], 'Location', 'Southoutside')


exportFig(f, 'bondTRyieldIncrease', genInfo.picsDir, genInfo.fmt, genInfo.figClose, false)

%% same for yield evolution

constantPrices = totalReturnPrices(constantParams);

exampleParams = periodParamsTable;
prices = totalReturnPrices(exampleParams);

f = figure('pos', genInfo.pos);

subplot(1, 2, 1)

% compute values to visualize yield curves
allMaturs = [0.1:1:30];
[fullYields, fowRates] = svenssonYields(exampleParams{:, 2:end}, allMaturs);
fullTimeGrid = repmat(exampleParams.Date, 1, length(allMaturs));
fullMaturGrid = repmat(allMaturs, size(exampleParams, 1), 1);

h = mesh(fullTimeGrid(1:50:end, :), fullMaturGrid(1:50:end, :), fullYields(1:50:end, :));
%zlim([0 15])
%view(20, 20)
xlabel('Date')
ylabel('Maturity')
datetick('x', 'yy')
grid on
grid minor
%caxis([0 12])

subplot(1, 2, 2)
%p1 = plot(prices.Date, prices.ZeroCoupon, 'DisplayName', 'Zero-coupon');
hold on
p1 = plot(constantPrices.Date, constantPrices.Coupon, '-r', 'DisplayName', 'Coupon, constant yields');
p2 = plot(constantPrices.Date, constantPrices.TotalReturn, '-r', 'DisplayName', 'TR, constant yields');
p3 = plot(prices.Date, prices.Coupon, '-b', 'DisplayName', 'Coupon');
p4 = plot(prices.Date, prices.TotalReturn, '-b', 'DisplayName', 'Coupon, TR');
datetick 'x'
grid minor
prices.TotalReturn(end)
legend([p1, p2, p3, p4], 'Location', 'Southoutside')


exportFig(f, 'bondTRrealYields', genInfo.picsDir, genInfo.fmt, genInfo.figClose, false)


%% bond price evolution figures

% for:
% - zero coupon bond
% - coupon bond with equal maturity

% define some example bonds


%%

plot(constantYieldCurve.Date, reinvestmentPrices.*zeroCouponPrices/100)
datetick 'x'

%%
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
plot(constantYieldCurve.Date, couponPrices + reinvestmentPrices.*zeroCouponPrices/100)
hold off
datetick 'x'
grid on
grid minor
xlabel('Date')
ylabel('Bond price')
legend('Zero coupon bond', ['Coupon bond (' num2str(couponBond.CouponRate*2*100) '%)'], ...
    'Location', 'Southeast')

%exportFig(f, 'bondPricesConstYield', genInfo.picsDir, genInfo.fmt, genInfo.figClose, false)
