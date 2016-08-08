% bond portfolio strategy
% 
% The strategy will be to invest in
% - notes only:
%   - replicating real ETF behavior (almost no weight on bonds)
%   - real ETF behavior might only be a snapshot, and in reality notes
%     might have been prefered only due to different coupon rates
% - maturities between 7 and 10 years
% - only notes are taken, and in three month steps
% - re-balancing only due to expired notes; intermediate coupon cash-flows
%   are not directly re-invested

%% load data

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'syntheticBondsLongFormat.mat');
load(fname)

%% define strategy parameters

GS = GlobalSettings;

% initial wealth
initWealth = 10000;

% define initial starting date and move to next business day
desiredInitDate = datenum('1975-01-02');
initDate = makeBusDate(desiredInitDate, 'follow', GS.Holidays, GS.WeekendInd);

% define TTM range
minDur = 7*365 + 2; % exclude 7 year notes
maxDur = 10*365;

%% calculate TTMs, reduce to relevant period and allowed TTMs

% get observations within backtest period
xxInd = longPrices.Date >= initDate;
btPrices = longPrices(xxInd, :);

% get time to maturity for each observation
btPrices = sortrows(btPrices, 'Date');
btPrices.CurrentMaturity = btPrices.Maturity - btPrices.Date;

% eliminate 30 year bonds
xxInds = strcmp(btPrices.TreasuryType, '30-Year BOND');
btPrices = btPrices(~xxInds, :);

% reduce to eligible bonds
xxEligible = btPrices.CurrentMaturity >= minDur & btPrices.CurrentMaturity <= maxDur;
btPrices = btPrices(xxEligible, :);

%% get number of eligible bonds over time

nEligibleBonds = grpstats(btPrices(:, {'Date', 'CurrentMaturity'}), 'Date');
nEligibleBonds = sortrows(nEligibleBonds, 'Date');

%% visualize

plot(nEligibleBonds.Date, nEligibleBonds.GroupCount, '.')
grid on
grid minor
datetick 'x'
xlabel('time')
ylabel('Number of eligible bonds')

%% find all bonds for given day

% select some business day
thisDay = makeBusDate(datenum('1990-01-01'), 'follow', GS.Holidays, GS.WeekendInd);

% define grid of desired maturities
maturGrid = datetime(datevec(thisDay)) + calyears(7) + calmonths(3:3:36);
maturGrid = datenum(maturGrid);

% get prices
singleDayBonds = selRowsProp(btPrices, 'Date', thisDay);

% visualize selection
plot(singleDayBonds.Maturity, singleDayBonds.CurrentMaturity, '.')
hold on
ylim = get(gca, 'YLim');
for ii=1:length(maturGrid)
    plot(maturGrid(ii)*[1 1], ylim, '-r')
end
datetick 'x'
xlabel('Maturity')
ylabel('TTM in days')
title(['Desired maturities on ' datestr(thisDay)])
grid on
grid minor

%% select bonds closest to desired maturities

bondMaturities = singleDayBonds.Maturity;
xxInds = arrayfun(@(x)find(x-bondMaturities > 0, 1, 'last'), maturGrid);

currentPortfolio = singleDayBonds(xxInds, :);

%% Questions / challenges
% - some kind of generateOrders
% - when is cash burnt, and for what?
% - how is bond portfolio represented?
% - how to get cfs and maturities?
% - how to get exit / sell days for bonds?

% get portfolio as Treasury array
xx = findInKeys(currentPortfolio.TreasuryID, {allTreasuries.ID}');
pfBonds = allTreasuries(xx);

% get selling dates
sellDates = currentPortfolio.Maturity - minDur;

% get cash-flow dates in holding period
pfCfDates = cfdates([pfBonds.AuctionDate]', [pfBonds.Maturity]', {pfBonds.Period}', ...
    {pfBonds.Basis}');
pfCfDates(pfCfDates < thisDay) = NaN;
pfCfDates(pfCfDates > repmat(sellDates, 1, size(pfCfDates, 2))) = NaN;

%%
% return cash-flow dates as table, sorted with respect to cash-flows
pfCfTable = array2table(pfCfDates);
pfCfTable = [currentPortfolio(:, 'TreasuryID'), pfCfTable];
pfCfTable = stack(pfCfTable, tabnames(pfCfTable(:, 2:end)), ...
    'NewDataVariableName', 'cfDate',...
    'IndexVariableName', 'toDelete');
pfCfTable = pfCfTable(:, {'TreasuryID', 'cfDate'});
pfCfTable = pfCfTable(~isnan(pfCfTable.cfDate), :);
pfCfTable = sortrows(pfCfTable, 'cfDate');



%% define portfolio object
% bond portfolio remains the same until next selling date
% - cash position changes
% - volumes could change
% - long table:
%   - assetLabel
%   - price
%   - volume

%% define universe
% - get cash-flow dates
% - get universe change date
% - define universe change: 
%   - which asset gets removed
%   - which asset gets in
%   - what if day is simultaneously cash-flow date?





