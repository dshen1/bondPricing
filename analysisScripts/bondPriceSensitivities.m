%% bond price sensitivity
% - create basket of bonds with different maturities / coupon rates
% - price them for different yield curves

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

%% define maturities of interest

% maturities are given in years
genInfo.maturs = [0.25 1 4 7 10 20 30];

xx = cellstr(num2str(genInfo.maturs'));
xx = strrep(xx, ' ', '');
xx = strcat(xx, ' years');
genInfo.maturNames = xx;

xx = strcat('y', num2str(genInfo.maturs'));
xx = strrep(cellstr(xx), ' ', '');
xx = strrep(xx, '.', '_');
genInfo.maturColNames = xx;

% get maturity names, colors, ...
genInfo.nMaturs = length(genInfo.maturs);

xx = ['jet(' num2str(genInfo.nMaturs) ')'];
genInfo.maturColors = colormap(xx);

close;

%% create basket of bonds

couponRates = [0, 2, 4, 6, 8]/100/2;
nCouponRates = length(couponRates);

GS = GlobalSettings();

todayAuctionDate = '1985-11-25';

allBonds = [];
for ii=1:nCouponRates
    for jj=1:genInfo.nMaturs
        thisBond = Treasury('TNote', genInfo.maturs(jj), todayAuctionDate, GS, couponRates(ii));
        allBonds = [allBonds; thisBond];
    end
end

%% get associated yields

histYields = svenssonYields(paramsTable{:, 2:end}, genInfo.maturs);

%% eliminate extrapolated yields

histYields = avoidExtrapolation(histYields, paramsTable.Date, genInfo.maturs, true);

%% attach meta-data

histYields = array2table(histYields, 'VariableNames', genInfo.maturColNames);
histYields = [paramsTable(:, 'Date'), histYields];

% histYields = histYields(histYields.Date > datenum('1990-01-01'), :);

%% get prices for basket of bonds
nDates = size(paramsTable, 1);
equalDateParams = paramsTable;
equalDateParams.Date = datenum(todayAuctionDate)*ones(nDates, 1);

nBonds = length(allBonds);
allPrices = nan(nDates, nBonds);
for ii=1:nBonds
    thisBond = allBonds(ii);
    allPrices(:, ii) = svenssonBondPrice(thisBond, equalDateParams);
end

%%

bondProps = summaryTable(allBonds);
bondProps.StdDevAbs = std(allPrices)';

xx = diff(allPrices) ./ allPrices(1:end-1, :);
bondProps.StdDevRel = std(xx)';

%%

[xxGrid, yyGrid] = meshgrid(couponRates, genInfo.maturs);
zzVals = reshape(bondProps.StdDevRel, size(xxGrid));

%%

surf(xxGrid, yyGrid, zzVals)
grid minor
xlabel('Coupon rate')
ylabel('Maturity')

%%
plot3(bondProps.MaturityInDays, bondProps.CouponRate, bondProps.StdDev, '.')
grid minor


