%% rolling over vs buy-and-hold for zero-coupon bonds

%% set up general settings

genInfo.pos = [50 50 1200 600];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = true;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';

% set data directory
dataDir = '../priv_bondPriceData';

%% load historic estimated parameters

fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, :}), 2), :);

%% bond price trajectories: liquidity premium vs expectation hypothesis
% this shall show the different trajectories of bonds with different
% maturities. trajectories of under expectation hypothesis are compared to
% liquiditiy perimum (constant yield curve). with constant yield curve
% bonds of different maturities will have different total returns in
% initial periods.

f = figure('pos', genInfo.pos);

% pick some yield curve
thisYieldCurve = selRowsKey(paramsTable, 'Date', datenum('2012-02-02'));

% compute and plot current interest rates
xxMaturGrid = [0:0.1:4.5, 5:0.5:30];
[currentYields, currentFwdRates] = svenssonYields(thisYieldCurve{1, 2:end}, xxMaturGrid);

maturs = [1, 5, 10, 15, 20, 30];
[~, maturFwdRates] = svenssonYields(thisYieldCurve{1, 2:end}, maturs);

subplot(1, 2, 1)
p1 = plot(xxMaturGrid, currentYields, 'DisplayName', 'Yield curve');
hold on
p2 = plot(xxMaturGrid, currentFwdRates, 'DisplayName', 'Forward rates');
p3 = plot(maturs, maturFwdRates, 'ko');
grid minor
xlabel('Maturity')
legend([p1, p2], 'Location', 'SouthEast')
title('Market environment')

subplot(1, 2, 2)

% compute returns until maturity

xxMaturGrid = [0.1:0.1:maturs(end)];
xxDateGrid = thisYieldCurve.Date + xxMaturGrid*365;

% get trajectory under expectation hypothesis
[currentYields, currentFwdRates] = svenssonYields(thisYieldCurve{1, 2:end}, xxMaturGrid);
expHypTrajectory = exp(currentYields/100 .* xxMaturGrid);

% get trajectories under liquidity premium
maturRemain = repmat(maturs', 1, length(xxMaturGrid)) - repmat(xxMaturGrid, length(maturs), 1);
maturRemain(maturRemain < 0) = NaN;

finalVals = svenssonYields(thisYieldCurve{1, 2:end}, maturs);
finalVals = finalVals/100 .* maturs;
finalVals = repmat(finalVals', 1, length(xxMaturGrid));

partialYields = svenssonYields(thisYieldCurve{1, 2:end}, maturRemain(:)');
partialYields = reshape(partialYields/100, size(maturRemain));
partialYields = partialYields .* maturRemain;

partialCompouding = exp(finalVals - partialYields);

colCmd = ['jet(' num2str(length(maturs)) ')'];
trajColors = colormap(colCmd);

% for ii=1:length(maturs)
%     plot(xxDateGrid, partialCompouding(ii, :), 'Color', trajColors(ii, :))
%     hold on
% end
p1 = plot(xxMaturGrid, partialCompouding', '-b', 'DisplayName', 'LP');
hold on
p2 = plot(xxMaturGrid, expHypTrajectory, '--k', 'DisplayName', 'EH');
grid minor
xlabel('Year')
%datetick 'x'
%set(gca, 'XTickLabelRot', 45)
legend([p1(1); p2], 'Location', 'NorthWest')
title('Bond price trajectories')

exportFig(f, 'zcBondReturnOverTime', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% visualize relevant areas of forward rate curve

xxMaturGrid = [0.1:0.1:maturs(end)];
deltaTime = 1;
xxAreaGrid = 0:0.01:deltaTime;
finalTau = 10;
xxAreaGridRight = finalTau - deltaTime + xxAreaGrid;

% get trajectory under expectation hypothesis
[~, currentFwdRates] = svenssonYields(thisYieldCurve{1, 2:end}, xxMaturGrid);
[~, areaFwdRatesLeft] = svenssonYields(thisYieldCurve{1, 2:end}, xxAreaGrid);
[~, areaFwdRatesRight] = svenssonYields(thisYieldCurve{1, 2:end}, xxAreaGridRight);

f = figure();
p1 = plot(xxMaturGrid, currentFwdRates, '-k', 'DisplayName', 'Forward rate curve');
hold on
h1 = area(xxAreaGrid, areaFwdRatesLeft, 'DisplayName', 'EH');
h1.FaceColor = [1, 0.8, 0.8];
h2 = area(xxAreaGridRight, areaFwdRatesRight, 'DisplayName', 'LP');
h2.FaceColor = [0.8, 0.8, 1];
grid minor
legend([p1, h1, h2], 'Location', 'SouthEast')
title('First year compounding')

exportFig(f, 'zcBondFirstYearCompounding', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)


%% visualizing buy-and-hold trajectories

buyHoldHorizon = 2;
nDays = size(paramsTable, 1);
tradeDates = paramsTable.Date(1):buyHoldHorizon*365:paramsTable.Date(end);

% move trade dates to dates with yield curve
xx = repmat(tradeDates, nDays, 1) - repmat(paramsTable.Date, 1, length(tradeDates));
[~, ycDateInds] = min(abs(xx), [], 1);

tradeDates = paramsTable.Date(ycDateInds);
tradeDates = [tradeDates', tradeDates(end) + buyHoldHorizon*365];
nTradeDates = length(tradeDates);

daysSinceLastTrade = repmat(paramsTable.Date, 1, nTradeDates) - ...
    repmat(tradeDates, nDays, 1);
daysSinceLastTrade(daysSinceLastTrade < 0) = Inf;
[daysSinceLastTrade, relevantYCind] = min(daysSinceLastTrade, [], 2);

daysUntilNextTrade = repmat(tradeDates, nDays, 1) - ...
    repmat(paramsTable.Date, 1, nTradeDates);
daysUntilNextTrade(daysUntilNextTrade < 0) = Inf;
daysUntilNextTrade = min(daysUntilNextTrade, [], 2);

timeSinceLastTrade = daysSinceLastTrade ./ 365;
timeUntilNextTrade = daysUntilNextTrade ./ 365;

relevantYCind = ycDateInds(relevantYCind);

%% EH values

[yields, ~] = svenssonYields(paramsTable{relevantYCind, 2:end}, timeSinceLastTrade);
yields(isnan(yields)) = 0;
compoundSinceLastTrade = exp(yields/100 .* timeSinceLastTrade);

% get daily changes
xx = diff(compoundSinceLastTrade) ./ compoundSinceLastTrade(1:end-1);
xx(xx<0) = 0;

% final result
finalCompoundEH = exp(cumsum(log(1 + xx)));

%% LP values

[yields1, ~] = svenssonYields(paramsTable{relevantYCind, 2:end}, buyHoldHorizon);
[yields2, ~] = svenssonYields(paramsTable{relevantYCind, 2:end}, timeUntilNextTrade);

yields1(isnan(yields1)) = 0;
yields2(isnan(yields2)) = 0;

fullCompound = yields1/100 .* buyHoldHorizon;
remainingCompound = yields2/100 .* timeUntilNextTrade;

lpCompound = exp(fullCompound - remainingCompound);

f = figure();
plot(compoundSinceLastTrade)
hold on;
plot(lpCompound)

%%
% get daily changes
xx = diff(lpCompound) ./ lpCompound(1:end-1);
xx(abs(xx)>0.05) = 0;
xx(xx < 0) = 0;
plot(xx)

% final result
finalCompoundLP = exp(cumsum(log(1 + xx)));

%%

% visualize
plot(paramsTable.Date(1:end-1), finalCompoundEH)
hold on
plot(paramsTable.Date(1:end-1), finalCompoundLP)
datetick 'x'
grid minor

%%

% select roll-over duration
chosenDur = 1;

% select maturities to show at each trading decision
durs = [0, 0.25, 1:5];
chosenDurInd = find(durs == chosenDur, 1, 'first');

% get associated discount factors for given maturities
svenssonParams = paramsTable{1, 2:end};
[maturYields, ~] = svenssonYields(svenssonParams, durs);
maturYields(isnan(maturYields)) = 0;

% get predicted final end-of-period wealth
nextDates = durs*365 + paramsTable.Date(1);
finalDate = nextDates(chosenDurInd);
finalVal = exp(maturYields(chosenDurInd)/100 .* durs(chosenDurInd));

% plot maturity decision
plot(nextDates, exp(maturYields/100 .* durs))
hold on
plot(nextDates(chosenDurInd), finalVal, 'ro')
datetick 'x'
grid minor

%%

% include portfolio value path
remainCurves = paramsTable(paramsTable.Date <= finalDate, :);
remainDur = (finalDate - remainCurves.Date)/365;

% discount final value
[remainYields, ~] = svenssonYields(paramsTable{1, 2:end}, remainDur');
remainYields(isnan(remainYields)) = 0;

[trueYields, ~] = svenssonYields(paramsTable{1:length(remainDur), 2:end}, remainDur');
trueYields = diag(trueYields);

% plot maturity decision
plot(nextDates, exp(maturYields/100 .* durs))
hold on
plot(nextDates(chosenDurInd), finalVal, 'ro')
plot(remainCurves.Date, finalVal * exp(- remainDur .* (remainYields/100)'), '-r')
plot(remainCurves.Date, finalVal * exp(- remainDur .* trueYields/100), '-k')
datetick 'x'
grid minor


%%
% get associated discount factors
discFacts = yieldToDiscount(durs, maturYields/100);

svenssonBondPrice(thisBond, yieldCurves)

