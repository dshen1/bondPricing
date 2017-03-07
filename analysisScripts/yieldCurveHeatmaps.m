%% yield curve heatmaps


%% set up general settings

genInfo.pos = [50 50 1200 600];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = true;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';
genInfo.valueLabelFormat = '%2.1f';
genInfo.valueLabelFormat = [];

% set data directory
dataDir = '../priv_bondPriceData';

%% load historic estimated parameters

fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, :}), 2), :);

%% get mean yearly interest rates

allMaturs = 1:2:30;
allMaturColNames = strcat('dur_', strrep(cellstr(num2str(allMaturs')), ' ', ''));

[yields, ~] = svenssonYields(paramsTable{:, 2:end}, allMaturs);

thisDats = paramsTable.Date;
xxTab = array2table([thisDats, yields]);
xxTab.Properties.VariableNames{1} = 'Date';
xxTab.Properties.VariableNames(2:end) = allMaturColNames;

% get x-labels
xlabs = cellstr(strcat(num2str(allMaturs'), ' years'));


f = figure('Position', genInfo.pos);

% Realized annualized volas
meanYields = aggrPerPeriod(xxTab, 'yearly', 'mean', []);

xx = meanYields{:, 2:end};
heatmap(xx, xlabs, datestr(meanYields.Date, 'yyyy-mm'), ...
    genInfo.valueLabelFormat, 'FontSize', 12, 'ColorMap', 'jet', 'TickAngle', 45);
xlabel('Duration')
colorbar();
title('Mean interest rates')

% write to disk
exportFig(f, 'heatMapMeanAnnualRates', genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% get interest rate vola

% Realized annualized volas
yieldVola = aggrPerPeriod(xxTab, 'yearly', 'std');

f = figure('Position', genInfo.pos);

xx = yieldVola{:, 2:end};
heatmap(xx, xlabs, datestr(yieldVola.Date, 'yyyy-mm'), ...
    genInfo.valueLabelFormat, 'FontSize', 12, 'ColorMap', 'jet', 'TickAngle', 45);
colorbar();
xlabel('Duration')
title('Interest rate standard deviation') 

% write to disk
exportFig(f, 'heatMapAnnualRatesVola', genInfo.picsDir, genInfo.fmt, genInfo.figClose)


%% get realized interest rate changes

thisDats = paramsTable.Date;
xxTab = array2table([thisDats(2:end), diff(yields)]);
xxTab.Properties.VariableNames{1} = 'Date';
xxTab.Properties.VariableNames(2:end) = allMaturColNames;

% Realized annualized volas
yieldDiff = aggrPerPeriod(xxTab, 'yearly', 'sum', []);

f = figure('pos', genInfo.pos);

xx = yieldDiff{:, 2:end};
heatmap(xx, xlabs, datestr(yieldDiff.Date, 'yyyy-mm'), ...
    genInfo.valueLabelFormat, 'FontSize', 12, 'ColorMap', 'money', 'TickAngle', 45);
colorbar();
xlabel('Duration')
title('Absolute interest rate changes')

% write to disk
exportFig(f, 'heatMapAnnualAbsRateChanges', genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% get relative realized interest rate changes

thisDats = paramsTable.Date;
xxTab = array2table([thisDats(2:end), diff(log(yields))]);
xxTab.Properties.VariableNames{1} = 'Date';
xxTab.Properties.VariableNames(2:end) = allMaturColNames;

% Realized annualized volas
yieldDiff = aggrPerPeriod(xxTab, 'yearly', 'sum', []);

f = figure('pos', genInfo.pos);

xx = yieldDiff{:, 2:end};
heatmap(xx, xlabs, datestr(yieldDiff.Date, 'yyyy-mm'), ...
    genInfo.valueLabelFormat, 'FontSize', 12, 'ColorMap', 'money', 'TickAngle', 45);
colorbar();
xlabel('Duration')
title('Relative interest rate changes') 

% write to disk
exportFig(f, 'heatMapAnnualRelRateChanges', genInfo.picsDir, genInfo.fmt, genInfo.figClose)
