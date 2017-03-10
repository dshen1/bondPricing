% Hypothesis:
% - risk-return relation of equities (less mu and higher risk during
%   crisis) does not hold for bonds
% - vola increases during upward and downward yield trends, thereby
%   accompanying both higher and lower mu periods

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

% paramsTable2 = paramsTable;
% paramsTable2{:, 2:end} = flipud(paramsTable{:, 2:end});
% paramsTable2.Date = flipud(paramsTable.Date(end) - paramsTable.Date) + paramsTable.Date(end) + 1;
% paramsTable = [paramsTable; paramsTable2];
%paramsTable = paramsTable(1:20000, :);

%% get benchmark yields

benchMaturs = 8;
benchYields = svenssonYields(paramsTable{:, 2:end}, benchMaturs);

%% define strategy parameters

% get current strategy parameters
thisStratParams.currPrice = 1;
thisStratParams.strategyDuration = benchMaturs;
thisStratParams.rollFreq = 250;

btPrices = zeroCouponRollOverBacktest(thisStratParams, paramsTable);

%% how to show that EWMA is bullshit?
% - EWMA on interest rate changes themselves?
% - EWMA on portfolio returns
% - conditional moments of strategy over time

smoothLambda = 0.99;
windSize = round((2 - (1-smoothLambda))/(1-smoothLambda));

logRets = diff(log(btPrices))*100;
condMuHat = tsmovavg(logRets, 'e', windSize, 1);

%%

condSigmaHat = nan(size(logRets));
for ii=windSize:size(condSigmaHat, 1)
   condSigmaHat(ii, :) = sampleStd(logRets(1:ii, :), smoothLambda);
end

%% given an overview

f = figure('pos', genInfo.pos);

subplot(2, 3, 1)
plot(paramsTable.Date, log(btPrices))
grid minor
datetick 'x'
title('Strategy prices (log)')

subplot(2, 3, 2)
plot(paramsTable.Date(2:end), logRets)
grid minor
datetick 'x'
title('Strategy returns (log)')

subplot(2, 3, 3)
plot(paramsTable.Date(2:end), condMuHat)
grid minor
datetick 'x'
title('EWMA')

subplot(2, 3, 4)
plot(paramsTable.Date, benchYields)
grid minor
datetick 'x'
title('Benchmark yield')

subplot(2, 3, 5)
plot(paramsTable.Date(2:end), diff(benchYields))
grid minor
datetick 'x'
title('Absolut yield changes')

subplot(2, 3, 6)
plot(paramsTable.Date(2:end), condSigmaHat)
grid minor
datetick 'x'
title('EW-Vola')

%% try discriminatory power for different smoothing values

% determine window sizes
smoothVals = [0.1, 0.5, 0.9, 0.92, 0.95, 0.98, 0.99, 0.995];
windSize = round((2 - (1-smoothVals))./(1-smoothVals));

logRets = diff(log(btPrices));

allMuEstimates = nan(size(logRets, 1)-1, length(windSize));

for ii=1:length(windSize)
    % get moving average
    xx = tsmovavg(logRets, 'e', windSize(ii), 1);
    allMuEstimates(:, ii) = xx(1:end-1);
end

allMuEstimates(1:max(windSize), :) = [];

nObs = size(allMuEstimates, 1);
predRets = logRets(end-nObs+1:end);

%% get group into discrete quantile intervals

% set up discrete intervals
stepSize = 0.1;
alphas = (0+stepSize):stepSize:(1-stepSize);
nIntervals = length(alphas) + 1;

% preallocate
intervalAffil = nan(length(predRets), length(windSize));
estimatedIntervalMus = nan(nIntervals, length(windSize));
predIntervalMus = nan(nIntervals, length(windSize));

for ii=1:length(windSize)
    % get interval bounds
    edges = [-Inf, quantile(allMuEstimates(:, ii), alphas), Inf];
    [~, ~, intervalInd] = histcounts(allMuEstimates(:, ii), edges);

    % get interval affiliation
    intervalAffil(:, ii) = intervalInd;
    
    % get estimated and realized group averages
    muRetPredTab = array2table([allMuEstimates(:, ii)*250, predRets*250, intervalInd], ...
        'VariableNames', {'MuHat', 'Return', 'Interval'});
    xx = grpstats(muRetPredTab, 'Interval', 'mean');
    
    % store values
    estimatedIntervalMus(:, ii) = xx.mean_MuHat;
    predIntervalMus(:, ii) = xx.mean_Return;
    
end

% TODO: evaluate persistency of signals

%%

f = figure('pos', genInfo.pos);

subplot(1, 2, 1)
surf(estimatedIntervalMus)
grid minor
title('Predicted interval average')

subplot(1, 2, 2)
surf(predIntervalMus)
grid minor
title('True interval average')

%% get ROC curves

rocCurves = nan(size(allMuEstimates));

for ii=1:size(allMuEstimates, 2)
    % sort with regards to either returns or mu-hat
    [~, xxInd] = sort(allMuEstimates(:, ii));
    rocCurves(:, ii) = cumsum(predRets(xxInd));
end
    
naiveCurve = cumsum(mean(predRets)*ones(length(predRets), 1));

%% visualize ROC curves

f = figure('pos', genInfo.pos);

plot(rocCurves)
hold on
plot(naiveCurve)
grid minor
title('Discriminatory power')

rocLabs = strcat(cellstr(num2str(windSize')), ' days');
legend([rocLabs; 'Naive'], 'Location', 'NorthWest')

%% TODO
% - bias
% - persistency