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
paramsTable2.Date = flipud(paramsTable.Date(end) - paramsTable.Date) + paramsTable.Date(end) + 1;
paramsTable = [paramsTable; paramsTable2];
%paramsTable = paramsTable(1:20000, :);

%% get representative yield curve

reprMat = 8;
reprYields = svenssonYields(paramsTable{:, 2:end}, reprMat);

%%

doPlot = false;
plotFreq = 100;

if doPlot

f = figure('pos', genInfo.pos);
ax1 = subplot(2, 2, 1:2);
ax2 = subplot(2, 2, 3);
ax3 = subplot(2, 2, 4);

plot(paramsTable.Date, reprYields)
grid minor
datetick 'x'

end

% length of yield curve for re-balancing
nCurveHorizon = 10;
futureMaturs = 0.1:0.1:10; % points to evaluate yield curve on

% set length of "backtest"
nBtDays = size(paramsTable, 1) - nCurveHorizon*250;

allBtDurs = [3, 5, 7, 9];
allBtRollFreq = [0.1, 0.3, 0.5, 0.8];

allBtPrices = nan(nBtDays, length(allBtDurs)*length(allBtRollFreq));
counter = 1;

for kk=1:length(allBtDurs)
    for ll=1:length(allBtRollFreq)

stratParams.currPrice = 1;
stratParams.strategyDuration = allBtDurs(kk);
stratParams.rollFreq = ceil(allBtDurs(kk)*allBtRollFreq(ll)*250); % in days

currExpiryInd = stratParams.strategyDuration*250;

allPrices = nan(nBtDays, 1);
allGuarteedPrices = [];
allGuarteedDates = [];

currPrice = stratParams.currPrice;

% for each day, show current price, current maturity and current alternatives
for ii=1:nBtDays
    
    currDate = paramsTable.Date(ii);

    if ii==1 || mod(ii, stratParams.rollFreq) == 0 % update guaranteed payoff
        
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

    if doPlot
    if mod(ii, plotFreq) == 0
        axes(ax1);
        plot(expiryDate, log(guarteedPayOff), 'or')
        hold on
        plot(currDate, log(currPrice), 'xr')
        plot(paramsTable.Date(1:ii), log(allPrices(1:ii)), '-k')
        plot(alternativeDates, log(alternativePayoffs), '-b')
        plot(predDates, log(predVals), '-g')
        plot(allGuarteedDates, log(allGuarteedPrices), 'ob', 'MarkerSize', 2)
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
    
end

allBtPrices(:, counter) = allPrices;
counter = counter + 1;

    end
end

%%

plot(paramsTable.Date(1:size(allBtPrices, 1)), log(allBtPrices))
datetick 'x'
grid minor

%%

fullLogRets = log(allBtPrices(end, :)) - log(allBtPrices(1, :));
annualLogRets = fullLogRets ./ ((paramsTable.Date(end)-paramsTable.Date(1))/365);
xxannualRets = (exp(annualLogRets) - 1)*100;

%% get table of final annual rets

annualRets = nan(length(allBtDurs), length(allBtRollFreq));

counter = 1;
for kk=1:length(allBtDurs)
    for ll=1:length(allBtRollFreq)
        annualRets(kk, ll) = xxannualRets(1, counter);
        counter = counter + 1;
    end
end






%% get annualized return

annualRet = exp(log(allPrices(end)) - log(allPrices(1))/((paramsTable.Date(end)-paramsTable.Date(1))/365))-1


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












