%% load historic estimated Svensson parameters

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);

%% select sub-sample

xxInds = paramsTable.Date > datenum('2012-01-01');
paramsTable = paramsTable(xxInds, :);

%% create bonds auctioned in given period

dateBeg = paramsTable.Date(1);
dateEnd = paramsTable.Date(end);
allTreasuries = getAllTreasuries(dateBeg, dateEnd);

%%

thisTreasury = allTreasuries(436);
xxInds = paramsTable.Date > datenum('2016-01-04');
thisYields = paramsTable(xxInds, :);
thisYields = thisYields(1, :);

%% plot current yields curve

[yy, fwd] = svenssonYields(thisYields{:, 2:end}, 1:30);
plot(1:30, yy)

%%

singleBondPrice(thisTreasury, thisYields)
