%% Idea
% - bond prices depend on yield curves
% - changing yield curves does change bond prices
% - how sensitive are bond prices with regards to changes?
% - measurement: sensitivity of bond prices with regards to bond yield
%   changes
% - how do yield changes relate to yield curve changes?
% - do yields of bonds that trade at premium / discount behave differently
%   with regards to yield curve changes?
%
% yield curve change -> yield change
% bond price + sensitivity + yield change -> new bond price

%% create synthetic historic bond market

% load historic yield curve parameters
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

[longPrices, allTreasuries] = createSynthBondMarket_svensson(paramsTable);

%% select single bond

thisBond = allTreasuries(7430);
thisPrices = selRowsProp(longPrices, 'TreasuryID', thisBond.TreasuryID);

%% calculate bond yields

[yields, durations] = bondYield(thisBond, thisPrices);

%% calculate macaulay durations with different way

% get respective yield curves
xxYields = outerjoin(thisPrices(:, 'Date'), paramsTable, 'Keys', 'Date', ...
    'MergeKeys', true, 'Type', 'left');

[~, macDurs] = svenssonBondPrice(thisBond, xxYields);

%%

plot(thisPrices.Date, yields*100)
hold on
plot(thisPrices.Date, durations)
plot(thisPrices.Date, durations, '-b')
hold off
datetick 'x'
grid minor
grid on

%%

fakeParamsTable = paramsTable;
fakeParamsTable.Date = repmat(datenum('1995-03-03'), size(paramsTable, 1), 1);
[fakePrices, fakeDurs] = svenssonBondPrice(thisBond, fakeParamsTable);

xxPriceTable = table(fakeParamsTable.Date, fakePrices, 'VariableNames', {'Date', 'Price'});
[fakeYields, ~] = bondYield(thisBond, xxPriceTable);

%%

plot(paramsTable.Date, fakePrices)
datetick 'x'
grid on
grid minor

%%

plot(diff(fakePrices), -100*fakeDurs(1:end-1).*diff(fakeYields), '.')
hold on
plot([-3 3], [-3 3], '-r')
hold off
grid on
grid minor
xlabel('Price change')
ylabel('Approximated price change')