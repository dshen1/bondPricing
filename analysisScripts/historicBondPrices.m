%% load historic estimated Svensson parameters

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
histSvenssonParams = readtable(fname);

%% create bonds that are auctioned in given period

dateBeg = histSvenssonParams.Date(1);
dateEnd = histSvenssonParams.Date(end);
allTreasuries = getAllTreasuries(dateBeg, dateEnd);

%% remove treasuries that are never traded within sample window

allTreasuries = allTreasuries([allTreasuries.Maturity] > dateBeg);
allTreasuries = allTreasuries([allTreasuries.AuctionDate] < dateEnd);

%% re-calibrate coupon-rates

nTreasuries = length(allTreasuries);
cpRates = zeros(nTreasuries, 1);
for ii=1:nTreasuries
    if mod(ii, 1000) == 0
        ii/nTreasuries % progress display
    end
    thisBond = allTreasuries(ii);
    
    % get auction date yield curves
    xxInd = find(histSvenssonParams.Date >= thisBond.AuctionDate, 1, 'first');
    thisYieldCurve = histSvenssonParams(xxInd, :);
    
    % get coupon rate
    cpRate = svenssonCouponRate(thisBond, thisYieldCurve);
    cpRates(ii) = cpRate;
    
    % modify coupon rate
    thisBond = modifyCouponRate(thisBond, cpRate);
    allTreasuries(ii) = thisBond;
    
end

%% find duplicate bonds (re-openings)

bondInfoTab = summaryTable(allTreasuries);

% find same maturity dates and coupon rates
duplicateCounter = grpstats(bondInfoTab(:, {'Maturity', 'CouponRate'}), ...
    {'Maturity', 'CouponRate'});

duplicates = duplicateCounter(duplicateCounter.GroupCount > 1, :);
duplicates.Properties.RowNames = {};

%% eliminate most recent duplicates

nBonds = size(bondInfoTab, 1);
elimInds = false(nBonds, 1);

nDuplicates = size(duplicates, 1);
for ii=1:nDuplicates
    thisDuplicate = duplicates(ii, :);
    
    % find respective bonds
    xxInds = bondInfoTab.Maturity == thisDuplicate.Maturity &...
        bondInfoTab.CouponRate == thisDuplicate.CouponRate;
    duplicateBonds = bondInfoTab(xxInds, :);
    indNums = find(xxInds);
    
    % only keep bond with earliest auction date
    [~, xxI] = min(duplicateBonds.AuctionDate);
    
    % find bond to keep with respect to duplicates only
    shortElim = true(length(indNums), 1);
    shortElim(xxI) = false;
    
    % insert decision with respect to all bonds
    elimInds(xxInds) = shortElim;
    
end

% get eliminated bonds
toBeEliminated = bondInfoTab(elimInds, :);

% eliminate bonds
allTreasuries = allTreasuries(~elimInds);

% guarantee no duplicates
bondInfoTab = summaryTable(allTreasuries);
duplicateCounter = grpstats(bondInfoTab(:, {'Maturity', 'CouponRate'}), ...
    {'Maturity', 'CouponRate'});
assert(all(duplicateCounter.GroupCount == 1))

%% get all treasury prices

nBonds = length(allTreasuries);
IDs = cell(nBonds, 1);
allPrices = zeros(size(histSvenssonParams, 1), nBonds);
for ii=1:nBonds
    if mod(ii, 1000) == 0
        ii / nBonds % display progress
    end
    thisTreasury = allTreasuries(ii);
    
    % get ID
    IDs{ii} = thisTreasury.TreasuryID;
    
    % get prices
    allPrices(:, ii) = svenssonBondPrice(thisTreasury, histSvenssonParams);
end

%% make table

allPricesTable = array2table(allPrices, 'VariableNames', IDs);
allPricesTable = [histSvenssonParams(:, 'Date') allPricesTable];

%% attach coupon and redemption payments

bondInfoTable = summaryTable(allTreasuries);
bondInfoTable.NominalValue = [allTreasuries.NominalValue]';

% get all cash-flow dates as matrix
pfCfDates = cfdates([allTreasuries.AuctionDate]', [allTreasuries.Maturity]', ...
    {allTreasuries.Period}', {allTreasuries.Basis}');

% transform cash-flow dates to table
pfCfTable = array2table(pfCfDates);
pfCfTable = [array2table(bondInfoTable.TreasuryID, 'VariableNames', {'TreasuryID'}) , pfCfTable];
pfCfTable = stack(pfCfTable, tabnames(pfCfTable(:, 2:end)), ...
    'NewDataVariableName', 'Date',...
    'IndexVariableName', 'toDelete');
pfCfTable = pfCfTable(:, {'TreasuryID', 'Date'});
pfCfTable = pfCfTable(~isnan(pfCfTable.Date), :);
pfCfTable = sortrows(pfCfTable, 'Date');

% attach coupon payments
pfCfTable = outerjoin(pfCfTable, ...
    bondInfoTable(:, {'TreasuryID', 'CouponRate', 'NominalValue'}), ...
    'Keys', 'TreasuryID', 'MergeKeys', true, 'Type', 'left');
pfCfTable.Properties.VariableNames{'CouponRate'} = 'CouponPayment';
pfCfTable.CouponPayment = pfCfTable.CouponPayment .* pfCfTable.NominalValue;
pfCfTable.NominalValue = [];

% attach payments at maturity
xxMaturityTable = bondInfoTable(:, {'TreasuryID', 'Maturity', 'NominalValue'});
xxMaturityTable.Properties.VariableNames{'Maturity'} = 'Date';
fullCashFlows = outerjoin(pfCfTable, xxMaturityTable, 'Keys', {'TreasuryID', 'Date'},...
    'MergeKeys', true, 'Type', 'full');
fullCashFlows.Properties.VariableNames{'NominalValue'} = 'PrincipalPayment';

% check that maturities and last coupon payments coincide
xxMaturInds = ~isnan(fullCashFlows.PrincipalPayment);
assert(~any(isnan(fullCashFlows.CouponPayment(xxMaturInds))))

%% save to disk as MATLAB file in wide format
% 
% % in matlab file format
% dataDir = '../priv_bondPriceData';
% fname = fullfile(dataDir, 'syntheticBonds.mat');
% save(fname, 'allPricesTable', 'allTreasuries')

%% save to disk as MATLAB file in long format

% make prices long format
xxPrices = allPricesTable;
longPrices = stack(xxPrices, tabnames(xxPrices(:, 2:end)),...
    'NewDataVariableName', 'Price', 'IndexVariableName', 'TreasuryID');

% exclude missing observations
xxInds = ~isnan(longPrices.Price);
longPrices = longPrices(xxInds, :);

% attach additional bond information
bondInfoTab = summaryTable(allTreasuries);
bondInfoTab.TreasuryID = categorical(bondInfoTab.TreasuryID);
longPrices = outerjoin(longPrices, bondInfoTab, 'Keys', {'TreasuryID'}, ...
    'MergeKeys', true, 'Type', 'left');

% attach cash-flows
longPrices = outerjoin(longPrices, fullCashFlows, 'Keys', {'TreasuryID', 'Date'},...
    'MergeKeys', true, 'Type', 'left');

% fill NaNs in cash-flows with zeros
xxIsNaN = isnan(longPrices.CouponPayment);
longPrices.CouponPayment(xxIsNaN) = 0;
xxIsNaN = isnan(longPrices.PrincipalPayment);
longPrices.PrincipalPayment(xxIsNaN) = 0;

fname = fullfile(dataDir, 'syntheticBondsLongFormat.mat');
save(fname, 'longPrices', 'allTreasuries')

%% save to disk as csv in long format

% write to disk
%dataDir = '../priv_bondPriceData';
%fname = fullfile(dataDir, 'syntheticBonds.csv');
%writetable(longPrices, fname)

