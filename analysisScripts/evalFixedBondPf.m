function [forecastPfValue, pfMacDurs, pfWgts] = evalFixedBondPf(yields, pfHistory, cashAccount, thisComponents)
%% open questions / problems
% - should morning or evening volumes be investigated? 
% - morning volumes it should be if sensitivity analysis should have an
%   impact on trading decisions
% - take maturities into account: may bonds expiry during forecast period?

%%

%% derive some general properties

genInfo.nForecast = size(yields, 1);
genInfo.thisDate = yields.Date(1);
genInfo.nBonds = length(thisComponents);
genInfo.treasuryLabels = {thisComponents.TreasuryID}';

%% get current portfolio in long format

% select long format history at respective date
currPf = selRowsProp(pfHistory, 'Date', genInfo.thisDate);
currPf.EveningVolumes = currPf.MorningVolumes + currPf.Orders;
%currPf = currPf(currPf.EveningVolumes > 0, :);

% get current volumes in correct order
xx = currPf;
xx.TreasuryID = cellstr(xx.TreasuryID);
genInfo.currVols = replaceVals(genInfo.treasuryLabels, xx, 'TreasuryID', 'EveningVolumes');

%% forecast bond prices, durations and cash-flows

% preallocation
allPrices = zeros(genInfo.nForecast, genInfo.nBonds);
cfAdjustedPrices = allPrices;
macDurs = allPrices;

% for each bond in the portfolio and each forecast yield curve
for ii=1:genInfo.nBonds
    % get bond prices and Macaulay durations
    [allPrices(:, ii), macDurs(:, ii)] = svenssonBondPrice(thisComponents(ii), yields);
    
    % cash flows
    thisCashFlowDates = thisComponents(ii).CfDates;
    thisCashFlowValues = thisComponents(ii).CfValues;
    
    % adjust bond prices for cash-flows
    [xxInds, xxLoc] = ismember(thisCashFlowDates, yields.Date);
    if any(xxInds)
        addUpValues = zeros(genInfo.nForecast, 1);
        xxLocValue = xxLoc(xxInds);
        addUpValues(xxLocValue) = thisCashFlowValues(xxInds);
        cfAdjustedPrices(:, ii) = allPrices(:, ii) + cumsum(addUpValues);
    else
        cfAdjustedPrices(:, ii) = allPrices(:, ii);
    end
end

%% plot predicted prices vs cash-flow adjusted prices

% % plot adjusted prices
% plot(adjustedPrices.Date, cfAdjustedPrices{:, 2:end})
% datetick 'x'
% grid on
% grid minor
% 
% hold on
% plot(allPrices.Date, allPrices{:, 2:end}, '--')
% hold off

%% get portfolio values

% multiply bonds with respective volumes
forecastPfValue = cfAdjustedPrices(:, :) * genInfo.currVols;

% add current cash value
currCash = selRowsKey(cashAccount, 'Date', genInfo.thisDate);
currCash = sum(currCash{:, 2:end}, 2, 'omitnan');

% add to bond values and attach metadata / previously 40 s
forecastPfValue = table(yields.Date, forecastPfValue + currCash, ...
    'VariableNames', {'Date', 'PfValForecast'});

%% get portfolio durations

% get true bond values
forecastUnadjValues = allPrices .* repmat(genInfo.currVols', genInfo.nForecast, 1);

% get portfolio weights
pfWgts = forecastUnadjValues ./ repmat(forecastPfValue.PfValForecast, 1, genInfo.nBonds);

% get portfolio durations
pfMacDurs = sum(macDurs .* pfWgts, 2);

% attach dates / previously 40s
pfMacDurs = table(yields.Date, pfMacDurs, 'VariableNames', {'Date', 'MacDur'});

end
