%% load historic estimated Svensson parameters

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);

%% select sub-sample

xxInds = paramsTable.Date > datenum('1000-01-01');
paramsTable = paramsTable(xxInds, :);

%% create bonds auctioned in given period

dateBeg = paramsTable.Date(1);
dateEnd = paramsTable.Date(end);
allTreasuries = getAllTreasuries(dateBeg, dateEnd);

%%

xxInfoTab = summaryTable(allTreasuries);
xxInds = paramsTable.Date > datenum('2001-01-04');
svenssonParams = paramsTable(xxInds, :);

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


