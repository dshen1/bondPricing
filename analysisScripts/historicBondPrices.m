%% load historic estimated Svensson parameters

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);

%% create bonds traded in given period

dateBeg = paramsTable.Date(1);
dateEnd = paramsTable.Date(end);
allTreasuries = getAllTreasuries(dateBeg, dateEnd);

%% remove treasuries that are never traded within sample window

allTreasuries = allTreasuries([allTreasuries.Maturity] > dateBeg);
allTreasuries = allTreasuries([allTreasuries.AuctionDate] < dateEnd);

%% re-calibrate coupon-rates

nTreasuries = length(allTreasuries);
cpRates = zeros(nTreasuries, 1);
for ii=1:nTreasuries
    if mod(ii, 1000) == 0
        ii
    end
    thisBond = allTreasuries(ii);
    
    % get auction date yield curves
    xxInd = find(paramsTable.Date >= thisBond.AuctionDate, 1, 'first');
    thisYieldCurve = paramsTable(xxInd, :);
    
    % get coupon rate
    cpRate = svenssonCouponRate(thisBond, thisYieldCurve);
    cpRates(ii) = cpRate;
    
    % modify coupon rate
    thisBond = modifyCouponRate(thisBond, cpRate);
    allTreasuries(ii) = thisBond;
    
end



%%

xxInfoTab = summaryTable(allTreasuries);

%%

svenssonParams = paramsTable;

%% get all treasury prices
nBonds = length(allTreasuries);
IDs = cell(nBonds, 1);
allPrices = zeros(size(svenssonParams, 1), nBonds);
for ii=1:nBonds
    if mod(ii, 1000) == 0
        ii
    end
    thisTreasury = allTreasuries(ii);
    
    % get ID
    IDs{ii} = thisTreasury.ID;
    
    % get prices
    allPrices(:, ii) = svenssonBondPrice(thisTreasury, svenssonParams);
end

%% make table

allPricesTable = array2table(allPrices, 'VariableNames', IDs);
allPricesTable = [svenssonParams(:, 'Date') allPricesTable];

%% find certain treasuries

% find all TBonds
allTBonds = allTreasuries(strcmp({allTreasuries.Type}, 'TBond'));

% get their IDs
tbondNames = {allTBonds.ID};


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
    
    if thisCfDat < svenssonParams.Date(end) & thisCfDat > svenssonParams.Date(1)
       plot([thisCfDat thisCfDat], get(gca, 'YLim'), 'r') 
    end
end
hold off
        
    
%% debugging

xx = svenssonBondPrice(allTreasuries(xxInd), svenssonParams);

%%

xxBond = allTreasuries(11230);
xx = svenssonCouponRate(xxBond, svenssonParams(2364, :));


