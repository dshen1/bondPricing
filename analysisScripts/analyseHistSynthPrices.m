%% analyse synthetic historic bond prices

%% load data

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'syntheticRealBondsLongFormat.mat');
load(fname)

%% load historic estimated parameters

fname = fullfile(dataDir, 'paramsData_FED.csv');
svenssonParams = readtable(fname);

%% visualize coupon rates for treasury types

% remove bills from analysis
xxBills = strcmp({allTreasuries.Type}, 'TBill');
allNotesBonds = allTreasuries(~xxBills, :);

% get different types
bondInfoTable = summaryTable(allNotesBonds);
treasuryTypes = unique(bondInfoTable(:, {'TreasuryType', 'Type', 'NTerm'}));
treasuryTypes = sortrows(treasuryTypes, 'NTerm');
nTreasuryTypes = size(treasuryTypes, 1);

allNotesBondsTable = summaryTable(allNotesBonds);

figure()
for ii=1:nTreasuryTypes
    subplot(2, 3, ii)
    
    % get current type
    thisType = treasuryTypes.TreasuryType(ii);
    
    % get associated securities
    thisSecurs = selRowsProp(allNotesBondsTable, 'TreasuryType', thisType);

    % plot coupon rates
    plot(thisSecurs.AuctionDate, thisSecurs.CouponRate * 100, '.')
    datetick 'x'
    xlabel('Auction date')
    title(thisType)
    grid on
    grid minor
    set(gca, 'YLim', [0 10])
    
end

%% visualize price evolutions

% get different treasury types, sorted with regards to maturity
bondInfoTable = summaryTable(allTreasuries);
treasuryTypes = grpstats(bondInfoTable(:, {'TreasuryType', 'MaturityInDays'}), ...
    'TreasuryType');
treasuryTypes.Properties.RowNames = {};
treasuryTypes.GroupCount = [];
treasuryTypes = sortrows(treasuryTypes, 'mean_MaturityInDays');
treasuryTypes = treasuryTypes.TreasuryType;
nTypes = length(treasuryTypes);

%%

colors = evalColormap(1:nTypes, 'jet', [1, nTypes]);

%%

for ii=1:10
    figure(ii)
    
    % get current type
    thisType = treasuryTypes(ii);
    
    % get associated individual treasuries
    xx = selRowsProp(bondInfoTable, 'TreasuryType', thisType);
    
    % only take bonds that are observed until maturity
    lastDay = svenssonParams.Date(end);
    xxInds = xx.Maturity < lastDay;
    thisTypeTreasuries = xx(xxInds, :);
    
    % get associated prices
    allTypePrices = selRowsProp(longPrices, 'TreasuryID', thisTypeTreasuries.TreasuryID);
    
    % join maturity dates
    allTypePrices = outerjoin(allTypePrices, bondInfoTable(:, {'TreasuryID', 'Maturity'}), ...
        'Keys', 'TreasuryID', 'MergeKeys', true, 'Type', 'left');
    
    % calculate time to maturity
    allTypePrices.TTM = allTypePrices.Maturity - allTypePrices.Date;
    
    % unstack to wide format
    xx = allTypePrices(:, {'TTM', 'Price', 'TreasuryID'});
    xx = unstack(xx, 'Price', 'TreasuryID');
    thisTypePrices = sortrows(xx, 'TTM');
    
    % plot
    %plot(allTypePrices.TTM, allTypePrices.Price, '.')
    xxInds = thisTypePrices.TTM == 0;
    thisTypePrices = thisTypePrices(~xxInds, :);
    
    plot(thisTypePrices.TTM, thisTypePrices{:, 2:end}, 'Color', colors(ii, :))
    grid on
    grid minor
    %%
end

%% compare auction prices

% auction prices: first observable price
auctionPrices = varfun(@(x)x(find(~isnan(x), 1, 'last')), thisTypePrices(:, 2:end));
auctionPrices.Properties.VariableNames = tabnames(thisTypePrices(:, 2:end));

auctionPrices = stack(auctionPrices, tabnames(auctionPrices), ...
    'NewDataVariableName', 'AuctionPrice',...
    'IndexVariableName', {'TreasuryID', });

auctionPrices = outerjoin(auctionPrices, thisTypeTreasuries(:, {'TreasuryID', 'AuctionDate', 'CouponRate'}),...
    'Keys', 'TreasuryID', 'MergeKeys', true, 'Type', 'left');

%%
figure()
subplot(1, 3, 1)
hist(auctionPrices.AuctionPrice, 30)
xlabel('Auction price')
grid on
grid minor

subplot(1, 3, 2)
plot(auctionPrices.CouponRate, auctionPrices.AuctionPrice, '.')
xlabel('Coupon rate')
ylabel('Auction price')
grid on
grid minor

subplot(1, 3, 3)
plot(auctionPrices.AuctionDate, auctionPrices.AuctionPrice, '.')
datetick 'x'
xlabel('Auction date')
ylabel('Auction price')
grid on
grid minor


%% take normalized snapshot

begTTM = 7*365;
endTTM = begTTM + 3*30;

% get prices in TTM range
xxValidTTM = thisTypePrices.TTM >= begTTM & thisTypePrices.TTM <= endTTM;
snapshotPrices = thisTypePrices(xxValidTTM, :);

% flip upside down
snapshotPrices{:, :} = flipud(snapshotPrices{:, :});

% get initial prices
initPrices = varfun(@(x)x(find(~isnan(x), 1, 'first')), snapshotPrices(:, 2:end));

% normalize by init prices
normFacts = repmat(initPrices{:, :}, size(snapshotPrices, 1), 1);
snapshotPrices{:, 2:end} = snapshotPrices{:, 2:end} ./ normFacts;

%%

plot(snapshotPrices.TTM, snapshotPrices{:, 2:end})

%%
xx = thisTypePrices{:, 2};
xx = flipud(xx);
xx = xx/xx(1);
plot(xx)

%% compare prices evolution
% with
%   - returns over time
%   - changing interest rates
%   - durations (also depending on coupon rates?)
%   - volas for TTM

%% why do we get weekend NaNs?
% in terms of TTM, every bond has weekends on different TTMs

% fill with last observation


%% how close are initial prices to 100?
% does it depend on coupon rate = interest rate level?

%%

%xxInd = 3822;

plot(allPricesTable.Date, allPricesTable{:, tbondNames})
grid on
grid minor
datetick 'x'
hold on

cfDats = cfdates(allTBonds(2));
for ii=1:length(cfDats)
    thisCfDat = cfDats(ii);
    
    if thisCfDat < histSvenssonParams.Date(end) & thisCfDat > histSvenssonParams.Date(1)
       plot([thisCfDat thisCfDat], get(gca, 'YLim'), 'r') 
    end
end
hold off


