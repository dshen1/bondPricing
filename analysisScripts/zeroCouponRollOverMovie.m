%% visualize rolling over

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

%% yield curve: extension by reflection

paramsTable2 = paramsTable;
paramsTable2{:, 2:end} = flipud(paramsTable{:, 2:end});
paramsTable2.Date = (1:size(paramsTable2, 1))' + paramsTable.Date(end) + 1;
paramsTable = [paramsTable; paramsTable2];
paramsTable = paramsTable(1:20000, :);

%% get representative yield curve

reprMat = 8;
reprYields = svenssonYields(paramsTable{:, 2:end}, reprMat);

%%

f = figure('pos', genInfo.pos);
ax1 = subplot(1, 3, 1);
ax2 = subplot(1, 3, 2);
ax3 = subplot(1, 3, 3);

plot(paramsTable.Date, reprYields)
grid minor
datetick 'x'

% length of yield curve for re-balancing
nCurveHorizon = 10;

% set length of "backtest"
nBtDays = size(paramsTable, 1) - nCurveHorizon*250;

futureMaturs = 0.1:0.1:10;

currPrice = 1;
currExpiryInd = 9*250;

allPrices = nan(nBtDays, 1);
allGuarteedPrices = [];
allGuarteedDates = [];

% for each day, show current price, current maturity and current alternatives
for ii=1:nBtDays
    
    currDate = paramsTable.Date(ii);

    if ii==1 || mod(ii, 2) == 0 % update guaranteed payoff
        
        % get guaranteed maturity
        expiryDate = paramsTable.Date(currExpiryInd + ii);
        currMaturity = (expiryDate - currDate)/365;
        
        % get current guaranteed yield
        guarteedYield = svenssonYields(paramsTable{ii, 2:end}, currMaturity);
        
        % get guaranteed payoff
        guarteedPayOff = currPrice * exp(guarteedYield/100 * currMaturity);
        
        % get price evolution prediction
        predMaturs = 0.1:0.1:currMaturity;
        predDates = currDate + ceil(predMaturs*365);
        xx = svenssonYields(paramsTable{ii, 2:end}, predMaturs);
        predVals = currPrice * exp(xx/100 .* predMaturs);
        
        allGuarteedDates = [allGuarteedDates; expiryDate];
        allGuarteedPrices = [allGuarteedPrices; guarteedPayOff];
        
    end

    currMaturity = (expiryDate - currDate)/365;
    
    % get current guaranteed yield
    [guarteedYield, currFwdRate] = svenssonYields(paramsTable{ii, 2:end}, currMaturity);
        
    % get current price
    currPrice = guarteedPayOff * exp((-1)*guarteedYield/100 * currMaturity);
    allPrices(ii) = currPrice;
    
    % get current alternatives
    [futureYields, currFwdRates] = svenssonYields(paramsTable{ii, 2:end}, futureMaturs);
    alternativePayoffs = currPrice * exp(futureYields/100 .* futureMaturs);
    alternativeDates = currDate + futureMaturs * 365;
    
    if mod(ii, 50) == 0
        axes(ax1);
        plot(expiryDate, log(guarteedPayOff), 'or')
        hold on
        plot(currDate, log(currPrice), 'xr')
        plot(paramsTable.Date(1:ii), log(allPrices(1:ii)), '-k')
        plot(alternativeDates, log(alternativePayoffs), '-b')
        plot(predDates, log(predVals), '-g')
        plot(allGuarteedDates, log(allGuarteedPrices), 'ob')
        grid minor
        datetick 'x'
        hold off
        shg
        
        axes(ax2);
        plot(futureMaturs, currFwdRates)
        hold on
        plot(currMaturity, currFwdRate, 'or')
        hold off
        grid minor
        set(ax2, 'YLim', [0, 15])
        
        axes(ax3);
        plot(paramsTable.Date, reprYields)
        hold on
        plot(paramsTable.Date(ii), reprYields(ii), 'or')
        hold off
        grid minor
        datetick 'x'
        
        pause(0.00001)
    end
    
end


%% get annualized return

annualRet = exp(log(allPrices(end) - allPrices(1))/((paramsTable.Date(end)-paramsTable.Date(1))/365))-1


%% 

logRets = diff(log(allPrices));
allDates = paramsTable.Date(1:length(logRets));

allHorizons = [250, 500, 1000, 2500];

f = figure('Position', genInfo.pos);
for ii=1:length(allHorizons)
    subplot(2, 2, ii)
    nDaysAhead = allHorizons(ii);
    nYearsAhead = nDaysAhead / 250;
    xx = movingAvg(logRets, nDaysAhead, true)*250*100;
    plot(allDates(1:(end-nDaysAhead)), xx(nDaysAhead+1:end))
    hold on
    plot(paramsTable.Date, reprYields)
    title([num2str(nYearsAhead) ' years ahead'])
    datetick 'x'
    axis tight
    grid minor
    xlabel('First window date')
    ylabel([num2str(reprMat) ' years yield'])
end

%%

nMonths = 12;
AUMstart = 100;

allGRates = [1.1, 1.2, 1.3, 1.4];
cfTVfraction = [0.5, 0.6, 0.7, 0.8];
cfTVfraction = [0.5, 0.55, 0.6, 0.65];
multipl = 1./(1-cfTVfraction);
allModTO = [0.8, 1, 1.2];

nGRates = length(allGRates);
nModTOs = length(allModTO);

checkFullTOs = nan(nGRates, nModTOs);
estTOs = nan(nGRates, nModTOs);

for ii=1:nGRates
    for jj=1:nModTOs
        gRate = allGRates(ii);
        modTO = allModTO(jj);
        
        AUMs = AUMstart*gRate.^(0:(nMonths-1));
        adjTVs = AUMs * 2 * modTO / 12;
        fullTVs = adjTVs .* multipl(ii);

        xx = 12 * 0.5 *fullTVs ./ AUMs;
        checkFullTOs(ii, jj) = xx(1);
        
        estTOs(ii, jj) = (sum(fullTVs)/mean(AUMs))*0.5;
    end
end












