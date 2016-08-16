%% load historic estimated Svensson parameters

% set data directory and load historic Svensson parameters
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
histSvenssonParams = readtable(fname);

% create synthetic bonds and prices
[longPrices, allTreasuries] = createSynthBondMarket_svensson(histSvenssonParams);

% save to disk
fname = fullfile(dataDir, 'syntheticRealBondsLongFormat.mat');
save(fname, 'longPrices', 'allTreasuries')
