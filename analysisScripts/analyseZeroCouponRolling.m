%% run zero coupon backtests and analyse them


%% set up general settings

genInfo.pos = [50 50 1200 600];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = true;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';
genInfo.valueLabelFormat = '%2.1f';
%genInfo.valueLabelFormat = [];

%% load historic estimated parameters

% set data directory
dataDir = '../priv_bondPriceData';

fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, :}), 2), :);

%% yield curve: extension by reflection

paramsTable2 = paramsTable;
paramsTable2{:, 2:end} = flipud(paramsTable{:, 2:end});
paramsTable2.Date = flipud(paramsTable.Date(end) - paramsTable.Date) + paramsTable.Date(end) + 1;
paramsTable = [paramsTable; paramsTable2];
%paramsTable = paramsTable(1:20000, :);

%% get benchmark yields

benchMaturs = 10;
benchYields = svenssonYields(paramsTable{:, 2:end}, benchMaturs);

%% define backtest strategies

allTargetDurs = (1:15)';
allHoldingFraction = [0.7, 0.5, 0.3, 0.1, 0.02];
allHoldingFraction = 0.1;

% preallocation
nTargetDurs = length(allTargetDurs);
nRolloverFreq = length(allHoldingFraction);
allBtPrices = nan(size(paramsTable, 1), nTargetDurs * nRolloverFreq);

allMeasures = [];

%% define strategy parameters

counter = 1;
for ii=1:nTargetDurs
    for kk=1:nRolloverFreq

        % get current strategy parameters
        thisStratParams.currPrice = 1;
        thisStratParams.strategyDuration = allTargetDurs(ii);
        
        xx = allTargetDurs(ii)*allHoldingFraction(kk); % roll over freq in years
        thisStratParams.rollFreq = ceil(xx*250); % rolling frequency in BUSINESS days
        
        %% 
        
        btPrices = zeroCouponRollOverBacktest(thisStratParams, paramsTable);
        
        %% store results
        
        allBtPrices(:, counter) = btPrices;
        counter = counter + 1;
    end
end


%% compute risk and return of strategies

nBtYears = (paramsTable.Date(end)-paramsTable.Date(1))/365;
annualRet = exp((log(allBtPrices(end, :)) - log(allBtPrices(1, :)))/nBtYears) - 1;

% get log returns
dailyLogRets = diff(log(allBtPrices))*100;
dailyLogRetTab = array2table([paramsTable.Date(2:end) dailyLogRets]);
dailyLogRetTab.Properties.VariableNames{1} = 'Date';

% get vola
annualVola = std(dailyLogRets)*sqrt(250);

% get yield changes
absYieldChanges = diff(benchYields);

%% show annualized risk / return
% TODO: use different markers for different rolling frequencies, different
% color for different durations

f = figure('pos', genInfo.pos);

subplot(1, 2, 1)
plot(annualRet)
grid minor
title('Annualized returns')

subplot(1, 2, 2)
plot(annualVola)
grid minor
title('Annualized volatility')

exportFig(f, 'zcBondRollRiskReturn', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

f = figure();
plot(annualVola, annualRet*100, '.')
grid minor
title('Risk-return profiles')
xlabel('Annualized vola')
ylabel('Annualized return')

exportFig(f, 'zcBondRollRiskVsReturn', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% show yearly returns to see good / bad periods for strategies

yearlyRets = aggrPerPeriod(dailyLogRetTab, 'yearly', 'sum');

f = figure('pos', genInfo.pos);

xx = yearlyRets{:, 2:end};
heatmap(xx, [], datestr(yearlyRets.Date, 'yyyy-mm'), ...
    [], 'FontSize', 12, 'ColorMap', 'money', 'TickAngle', 45);
colorbar();
xlabel('Duration')
title('Yearly realized returns')

exportFig(f, 'zcBondRollYearlyReturns', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% strategy correlations

f = figure('pos', genInfo.pos);

subplot(1, 2, 1)
imagesc(corr(dailyLogRets))
colormap('jet')
caxis([0.4, 1])
colorbar()
axis square
title('Daily return correlations')


subplot(1, 2, 2)
imagesc(corr(yearlyRets{:, 2:end}))
colormap('jet')
caxis([0.4, 1])
colorbar()
axis square
title('Yearly return correlations')


exportFig(f, 'zcBondRollStratCorrelations', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)


%% explaining strategy returns
% what's the better predictor:
% - current level
% - simultaneous interest rate movement
% - does it depend on the investment horizon?

% specify investment horizons to be explained
allWindSizes = [1, 50, 500, 1000, 2500];

% get explanatory variables and returns to be explained
dailyLogRets = diff(log(allBtPrices));
explVars = [benchYields(2:end), absYieldChanges];

% preallocate results
nStrats = size(allBtPrices, 2); % for each strategy
nTimeHorizons = length(allWindSizes); % and each time horizon
nResults = 5; % get this number of measures
allRegrResults = nan(nResults, nStrats, nTimeHorizons);

for ll=1:length(allWindSizes)
    % get current time horizon
    windSize = allWindSizes(ll);
    
    % preallocate smoothed changes
    changeMatrix = [explVars(:, 2), dailyLogRets];
    smoothedChanges = nan(size(changeMatrix));
    for ii=1:size(smoothedChanges, 2);
        xx = movingAvg(changeMatrix(:, ii), windSize, true);
        xx = xx * 250;
        smoothedChanges(:, ii) = xx;
    end
    smoothedChanges(1:windSize-1, :) = [];
    
    % current explanatory variables
    currExplVars = [explVars(1:end-windSize+1, 1), smoothedChanges(:, 1)];
    yVals = smoothedChanges(:, 2:end);
    
    % conduct least-squares with both explanatory variables
    coeffs = currExplVars\yVals;
    yHat = currExplVars * coeffs;
    
    % get goodness of regression
    SST = sum((yVals - repmat(mean(yVals), size(yVals, 1), 1)).^2);
    SSR = sum((yVals - yHat).^2);
    Rsqu = 1 - SSR./SST;
    
    % conduct least-squares with single explanatory variable only
    xxMatr = [ones(size(currExplVars, 1), 1), currExplVars(:, 2)];
    coeffsChange = xxMatr\yVals;
    yHat = xxMatr * coeffsChange;
    SSR = sum((yVals - yHat).^2);
    RsquChange = 1 - SSR./SST;

    xxMatr = [ones(size(currExplVars, 1), 1), currExplVars(:, 1)];
    coeffsChange = xxMatr\yVals;
    yHat = xxMatr * coeffsChange;
    SSR = sum((yVals - yHat).^2);
    RsquLev = 1 - SSR./SST;

    allRegrResults(:, :, ll) = [coeffs; Rsqu; RsquLev; RsquChange];

end

%%

f = figure('pos', genInfo.pos);

subplot(2, 2, 1:2)
hold on
for ii=1:size(allRegrResults, 3)
    plot(allRegrResults(3, :, ii))
end
grid minor
legend(cellstr(num2str(allWindSizes')), 'Location', 'EastOutside')
title('R-squared for both variables')

subplot(2, 2, 3)
hold on
for ii=1:size(allRegrResults, 3)
    plot(allRegrResults(4, :, ii))
end
grid minor
title('R-squared for level only')

subplot(2, 2, 4)
hold on
for ii=1:size(allRegrResults, 3)
    plot(allRegrResults(5, :, ii))
end
grid minor
title('R-squared for yield change only')

exportFig(f, 'zcBondRollExplanations', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% hypothesis
% - future strategy returns are explainable by:
%   - current yield level
%   - future yield change
% - the importance of level / yield change varies with the time horizon
% - for longer holding periods level becomes more important

xx = allRegrResults(3, :, :);
xx = reshape(xx, nTargetDurs, nTimeHorizons);

durLabels = strcat(cellstr(num2str(allTargetDurs)), ' years');
horizonLabels = strcat(cellstr(num2str(allWindSizes')), ' days');

f = figure();

heatmap(xx, horizonLabels, durLabels, '%1.2f', 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Time horizon')
ylabel('Durations')
colorbar()
title('Explained variance of returns')


exportFig(f, 'zcBondRollExplainedHeatmap', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%%

f = figure('pos', genInfo.pos);

xx = allRegrResults(4, :, :);
xx = reshape(xx, nTargetDurs, nTimeHorizons);

durLabels = strcat(cellstr(num2str(allTargetDurs)), ' years');
horizonLabels = strcat(cellstr(num2str(allWindSizes')), ' days');

subplot(1, 2, 1)
heatmap(xx, horizonLabels, durLabels, '%1.2f', 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Time horizon')
ylabel('Durations')
colorbar()
title('Variance explained by prevailing level')


xx = allRegrResults(5, :, :);
xx = reshape(xx, nTargetDurs, nTimeHorizons);

durLabels = strcat(cellstr(num2str(allTargetDurs)), ' years');
horizonLabels = strcat(cellstr(num2str(allWindSizes')), ' days');

subplot(1, 2, 2)
heatmap(xx, horizonLabels, durLabels, '%1.2f', 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Time horizon')
ylabel('Durations')
colorbar()
title('Variance explained by yield changes only')

exportFig(f, 'zcBondRollExplanationsHeatmap', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% fraction explained by level only

f = figure('pos', genInfo.pos);

xx = allRegrResults(3, :, :);
xxFull = reshape(xx, nTargetDurs, nTimeHorizons);

xx = allRegrResults(4, :, :);
xxLevel = reshape(xx, nTargetDurs, nTimeHorizons);

xx = xxLevel ./ xxFull;

subplot(1, 2, 1)
heatmap(xx, horizonLabels, durLabels, '%1.2f', 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Time horizon')
ylabel('Durations')
colorbar()
title('Fraction explained by level')

xx = allRegrResults(3, :, :);
xxFull = reshape(xx, nTargetDurs, nTimeHorizons);

xx = allRegrResults(5, :, :);
xxLevel = reshape(xx, nTargetDurs, nTimeHorizons);

xx = xxLevel ./ xxFull;

subplot(1, 2, 2)
heatmap(xx, horizonLabels, durLabels, '%1.2f', 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Time horizon')
ylabel('Durations')
colorbar()
title('Fraction explained by yield changes')

exportFig(f, 'zcBondRollExplainedFractionsHeatmap', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% show some extreme case
% - strategies with different target duratiosn
% - same return horizon for all strategies
% - benchmark yield matching target duration

f = figure('pos', genInfo.pos);

for ii=1:15
windSize = 2500;
stratRets = diff(log(allBtPrices(:, ii)))*100;
stratRets = movingAvg(stratRets, windSize, true);
stratRets(1:windSize-1) = [];

benchMaturs = ii;
benchYields = svenssonYields(paramsTable{:, 2:end}, benchMaturs);


subplot(3, 5, ii)
xxnObs = length(stratRets);
plot(paramsTable.Date(2:(end-windSize)), benchYields(2:(end-windSize)))
hold on
plot(paramsTable.Date(2:(2+xxnObs-1)), stratRets*250)
grid minor
datetick 'x'
if ii==3
    title([num2str(windSize) ' days return'])
end

end

exportFig(f, 'zcBondRollReturnLongHoldingPeriodVsYield', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% bench yields and strategy with matching durations
% - strategies with different target durations
% - return horizon matching target duration
% - benchmark yield matching target duration

f = figure('pos', genInfo.pos);

for ii=1:15
windSize = ii*250;
stratRets = diff(log(allBtPrices(:, ii)))*100;
stratRets = movingAvg(stratRets, windSize, true);
stratRets(1:windSize-1) = [];

benchMaturs = ii;
benchYields = svenssonYields(paramsTable{:, 2:end}, benchMaturs);


subplot(3, 5, ii)
xxnObs = length(stratRets);
plot(paramsTable.Date(2:(end-windSize)), benchYields(2:(end-windSize)))
hold on
plot(paramsTable.Date(2:(2+xxnObs-1)), stratRets*250)
grid minor
datetick 'x'
title([num2str(ii) ' years'])
end

exportFig(f, 'zcBondRollReturnVsYieldEqualDuration', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% bench yield changes and returns


f = figure('pos', genInfo.pos);

for ii=1:15
windSize = 2500;
stratRets = diff(log(allBtPrices(:, ii)))*100;
stratRets = movingAvg(stratRets, windSize, true);
stratRets(1:windSize-1) = [];

benchMaturs = 8;
benchYields = svenssonYields(paramsTable{:, 2:end}, benchMaturs);
yieldChanges = movingAvg(diff(log(benchYields))*100, windSize, true);
yieldChanges(1:windSize-1) = [];

subplot(3, 5, ii)
plot(yieldChanges*(-1), stratRets*250, '.')
grid minor
% xxnObs = length(stratRets);
% plot(paramsTable.Date(2:(2+xxnObs-1)), yieldChanges*(-1)*250)
% hold on
% plot(paramsTable.Date(2:(2+xxnObs-1)), stratRets*250)
% grid minor
% datetick 'x'
title([num2str(ii) ' years'])
end
