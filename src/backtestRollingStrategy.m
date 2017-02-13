function [pfHistory, cashAccount, pfTimeTrend, macDurs] = backtestRollingStrategy(strategyParams, longPrices, allTreasuries, paramsTable)
% backtest bond rolling strategy with given bond market (universe, prices)
%
% Inputs:
%   strategyParams      structure defining parameters of the rolling
%                       strategy
%   longPrices          table of bond prices and cash-flows
%   allTreasuries       array of Treasury objects
%
% Output:
%   pfHistory           long format table of backtest portfolios and prices
%   cashAccount         long format table of backtest cash account
%                       evolution

initWealth = strategyParams.initWealth;
transCosts = strategyParams.transCosts;
initDate = strategyParams.initDate;
minDur = strategyParams.minDur;
maxDur = strategyParams.maxDur;
maturGrid = strategyParams.maturGrid;

%% restrict observations with regards to chosen backtest period

% get observations within backtest period
xxInd = longPrices.Date >= initDate;
btPrices = longPrices(xxInd, :);

% join additional information to prices
bondInfoTable = summaryTable(allTreasuries);
btPrices = outerjoin(btPrices, bondInfoTable, 'Keys', {'TreasuryID'},...
    'MergeKeys', true, 'Type', 'left');

% get time to maturity for each observation
btPrices = sortrows(btPrices, 'Date');
btPrices.CurrentMaturity = btPrices.Maturity - btPrices.Date;

% eliminate 30 year bonds
xxInds = strcmp(btPrices.TreasuryType, '30-Year BOND');
btPrices = btPrices(~xxInds, :);

% reduce to eligible bonds with small buffer
xxEligible = btPrices.CurrentMaturity >= (minDur - 5) & btPrices.CurrentMaturity <= maxDur;
btPrices = btPrices(xxEligible, :);

% get relevant quantities
bondMarket = btPrices(:, {'Date', 'TreasuryID', 'Price', 'Maturity', 'CouponPayment'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% start backtest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% pre-allocate bond portfolio book-keeping

% get all backtest dates
allDates = unique(bondMarket.Date);

% preallocate cash account
xxVals = [allDates nan(length(allDates), 3)];
cashAccount = array2table(xxVals, 'VariableNames', ...
    {'Date', 'MorningCash', 'Coupons', 'Transactions'});
cashAccount{1, 'MorningCash'} = initWealth;

% initialize empty bond portfolio history
colNames = {'Date', 'TreasuryID', 'Price', 'MorningVolumes', 'Orders', 'CouponPayment', 'TransactionPrices'};
pfHistory = cell2table(cell(0, length(colNames)), 'VariableNames', colNames);

% preallocate sensitivity measures
xxMacDurs = [allDates nan(length(allDates), 1)];
macDurs = array2table(xxMacDurs, 'VariableNames', {'Date', 'MacDur'});

xxTrend = [allDates nan(length(allDates), 2)];
pfTimeTrend = array2table(xxTrend, 'VariableNames', {'Date', 'CurrentValue', 'TimeTrend'});

clearvars allDates xxVals colNames

%% select bond universe as bonds closest to desired maturities

% get prices on first date
singleDayPrices = selRowsProp(bondMarket, 'Date', initDate);

% for each desired maturity, find closest bond
bondMaturities = singleDayPrices.Maturity;
xxInds = arrayfun(@(x)find(x-bondMaturities > 0, 1, 'last'), maturGrid);
currentUniverse = singleDayPrices(xxInds, :);
currentUniverse = sortrows(currentUniverse, 'Maturity');

%% generate orders for given market

% get desired buy value for each asset
nAss = size(currentUniverse, 1);
cashLeft = initWealth;
nRemaining = nAss;

% preallocate orders
thisOrders = zeros(nAss, 1);
thisTransactionPrices = zeros(nAss, 1);

% start with smallest maturity
for ii=1:nAss
    % get market price
    currPrice = currentUniverse.Price(ii);
    
    % add transaction costs
    currTradePrice = currPrice * (1 + transCosts);
    thisTransactionPrices(ii, 1) = currTradePrice;
    
    % get desired value to buy
    cashPerAsset = cashLeft / nRemaining;
    
    % get number of full units that can be bought
    nUnits = floor(cashPerAsset / currTradePrice);
    thisOrders(ii, 1) = nUnits;
    
    % update cash values for next asset
    cashLeft = cashLeft - currTradePrice * nUnits;
    nRemaining = nRemaining - 1;

end

initOrders = currentUniverse(:, {'Date', 'TreasuryID', 'Price', 'CouponPayment'});
initOrders.Orders = thisOrders;
initOrders.TransactionPrices = thisTransactionPrices;
initOrders.MorningVolumes = zeros(size(thisTransactionPrices));

% get associated cash values for book-keeping
cashSpent = cashAccount{1, 'MorningCash'} - cashLeft;
cashAccount{1, 'Transactions'} = (-1)*cashSpent;

% attach to book-keeping
pfHistory = [pfHistory; initOrders];

% store in running variable
lastPfHistory = initOrders;

% store current bonds as Treasury objects in running variable
xxInds = ismember(bondInfoTable.TreasuryID, initOrders.TreasuryID);
thisComponents = allTreasuries(xxInds);
        
%% conduct backtest
% for each day:
% - get current bond market
% - get current portfolio
% - get coupon payments
% - sell assets, attach orders and transaction prices to assets sold
% - buy assets, attach orders and transaction prices to assets bought

nObs = size(cashAccount, 1);
for ii=2:nObs
    if mod(ii, 1000) == 0
        fracProgress = ii/nObs;
        fprintf('\nProgress of backtest: %1.3f  %%', fracProgress*100)
    end
    
    % get current date
    thisDate = cashAccount.Date(ii);
    
    % get current cash value
    currCashValue = sum(cashAccount{ii-1, 2:end}, 'omitnan');
    cashAccount.MorningCash(ii) = currCashValue;
    
    % get current bond market
    currBondMarket = selRowsProp(bondMarket, 'Date', thisDate);
    
    % get current portfolio
    currPf = lastPfHistory;
    currPf.Date = thisDate*ones(size(currPf, 1), 1);
    currPf.MorningVolumes = currPf.MorningVolumes + currPf.Orders;
    currPf.Orders = zeros(size(currPf, 1), 1);
    currPf = currPf(currPf.MorningVolumes > 0, :);
    
    % get full information on current portfolio
    currAssetsMarket = outerjoin(currPf(:, {'Date', 'TreasuryID', 'MorningVolumes', 'Orders'}), ...
        currBondMarket, 'Keys', {'Date', 'TreasuryID'},...
        'MergeKeys', true, 'Type', 'left');
    
    % get coupon payments
    couponPayments = sum(currAssetsMarket.MorningVolumes .* currAssetsMarket.CouponPayment, 'omitnan');
    cashAccount.Coupons(ii) = couponPayments;
    
    % find selling assets
    currAssetsMarket.TTM = currAssetsMarket.Maturity - currAssetsMarket.Date;
    if any(currAssetsMarket.TTM <= minDur) % TRADE
        % find asset to sell
        indSell = currAssetsMarket.TTM <= minDur;
        oldAssets = currAssetsMarket;
        oldAssets.TransactionPrices = oldAssets.Price;
        oldAssets.Orders(indSell) = (-1)*oldAssets.MorningVolumes(indSell);
        oldAssets.TransactionPrices(indSell) = oldAssets.TransactionPrices(indSell) * (1 - transCosts);
        oldAssets.TTM = [];
        
        % compute cash that one gets from transactions
        cashFromSell = (-1)*(oldAssets.TransactionPrices(indSell) * oldAssets.Orders(indSell));
        
        % compute cash available
        cashAvailable = cashFromSell + sum(cashAccount{ii, 2:end}, 'omitnan');
    
        %% find asset to buy
        % buy the one with longest maturity
        [~, xxInd] = max(currBondMarket.Maturity);
        assetToBuy = currBondMarket(xxInd, :);
    
        % add transaction costs
        currTradePrice = assetToBuy.Price + (1 + transCosts);
        assetToBuy.TransactionPrices = currTradePrice;
        
        % get number of full units that can be bought
        nUnits = floor(cashAvailable/ currTradePrice);
        assetToBuy.MorningVolumes = 0;
        assetToBuy.Orders = nUnits;
        
        % write transaction costs into cash account
        cashAccount.Transactions(ii) = (-1)*(currTradePrice * nUnits) + cashFromSell;
        
        % combine newly bought bond with already existing bonds
        if ~ismember(assetToBuy.TreasuryID, oldAssets.TreasuryID)
            currAssetsMarket = [oldAssets; assetToBuy];
        else
            % find new bond in old portfolio
            xxInd = find(oldAssets.TreasuryID == assetToBuy.TreasuryID);
            
            % replace entry with new values except for volumes
            xxVolume = oldAssets.MorningVolumes(xxInd);
            oldAssets(xxInd, tabnames(assetToBuy)) = assetToBuy;
            oldAssets.MorningVolumes(xxInd) = xxVolume;
            currAssetsMarket = oldAssets;
        end
        currAssetsMarket.Maturity = [];
        
        % update current bonds as Treasury objects
        xxKeep = (currAssetsMarket.MorningVolumes + currAssetsMarket.Orders > 1);
        xxKeepUniverse = currAssetsMarket(xxKeep, :);
        xxInds = ismember(bondInfoTable.TreasuryID, xxKeepUniverse.TreasuryID);
        thisComponents = allTreasuries(xxInds);
        
    else % NO TRADE
        % attach orders / previously did take 17s
        currAssetsMarket.Maturity = [];
        currAssetsMarket.TTM = [];
        currAssetsMarket.TransactionPrices = currAssetsMarket.Price;
    end
    
    %% get sensitivity measures for current portfolio
    
    % fix current yield curve
    xxInd = find(paramsTable.Date == thisDate);
    yields = [paramsTable(xxInd, :); paramsTable(xxInd, :)];
    if xxInd == size(paramsTable, 1) % if last entry
        yields.Date(2) = yields.Date(1) + 1;
    else
        yields.Date(2) = paramsTable.Date(xxInd + 1);
    end
    
    % get predicted portfolio values and durations
    [forecastBondValues, pfMacDurs, ~] = evalFixedBondPf(yields, currAssetsMarket, cashAccount(ii, :), thisComponents);
    macDurs.MacDur(ii) = pfMacDurs.MacDur(1);
    pfTimeTrend.CurrentValue(ii) = forecastBondValues.PfValForecast(1);
    
    % get slope of daily portfolio value trend
    deltaVal = forecastBondValues.PfValForecast(2) - forecastBondValues.PfValForecast(1);
    deltaTime = forecastBondValues.Date(2) - forecastBondValues.Date(1);
    relativeDeltaVal = deltaVal ./ forecastBondValues.PfValForecast(1);
    pfTimeTrend.TimeTrend(ii) = relativeDeltaVal ./ deltaTime;

    % attach orders to portfolio history
    pfHistory = [pfHistory; currAssetsMarket];
    
    % store in running variables
    lastPfHistory = currAssetsMarket;
end
