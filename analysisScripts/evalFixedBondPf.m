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
macDurs = allPrices;
cashFlows = cell2table(cell(0, 3), 'VariableNames', {'TreasuryID', 'Date', 'CF'});

% for each bond in the portfolio and each forecast yield curve
for ii=1:genInfo.nBonds
    % get bond prices and Macaulay durations
    [allPrices(:, ii), macDurs(:, ii)] = svenssonBondPrice(thisComponents(ii), yields);
    
    % cash flows
    xxCashFlows = cfs(thisComponents(ii));
    xxCashFlows.TreasuryID = repmat({thisComponents(ii).TreasuryID}, size(xxCashFlows, 1), 1);
    cashFlows = [cashFlows; xxCashFlows];
end

% attach metadata
allPrices = array2table(allPrices, 'VariableNames', genInfo.treasuryLabels);
allPrices = [yields(:, 'Date'), allPrices];
macDurs = array2table(macDurs, 'VariableNames', genInfo.treasuryLabels);
macDurs = [yields(:, 'Date'), macDurs];

%% transform cash-flows to wide table

cashFlowsWide = unstack(cashFlows, 'CF', 'TreasuryID');

% get only cash-flows in relevant time range
cashFlowsWide = outerjoin(yields(:, 'Date'), cashFlowsWide, 'Keys', 'Date',...
    'MergeKeys', true, 'Type', 'left');
cashFlowsWide = tableFillNaN(cashFlowsWide, 0, 1);

% NOTE: cash-flows at present day already have been taken into account
cashFlowsWide{1, 2:end} = 0;

%% calculate cash-flow adjusted individual components

% include cash-flows again into bond price series
adjustedPrices = allPrices;
adjustedPrices{:, 2:end} = adjustedPrices{:, 2:end} + ...
    cumsum(cashFlowsWide{:, genInfo.treasuryLabels}, 1);

%% plot predicted prices vs cash-flow adjusted prices

% % plot adjusted prices
% plot(adjustedPrices.Date, adjustedPrices{:, 2:end})
% datetick 'x'
% grid on
% grid minor
% 
% hold on
% plot(allPrices.Date, allPrices{:, 2:end}, '--')
% hold off

%% get portfolio values

% multiply bonds with respective volumes
forecastPfValue = adjustedPrices{:, cellstr(genInfo.treasuryLabels)} * genInfo.currVols;

% add current cash value
currCash = selRowsKey(cashAccount, 'Date', genInfo.thisDate);
currCash = sum(currCash{:, 2:end}, 2, 'omitnan');

% add to bond values
forecastPfValue = array2table(forecastPfValue + currCash, ...
    'VariableNames', {'PfValForecast'});

% attach dates
forecastPfValue = [yields(:, 'Date'), forecastPfValue];

%% get portfolio durations

% get true bond values
forecastUnadjValues = allPrices{:, cellstr(genInfo.treasuryLabels)} .* ...
    repmat(genInfo.currVols', genInfo.nForecast, 1);

% get portfolio weights
pfWgts = forecastUnadjValues ./ repmat(forecastPfValue.PfValForecast, 1, genInfo.nBonds);

% get portfolio durations
pfMacDurs = sum(macDurs{:, cellstr(genInfo.treasuryLabels)} .* pfWgts, 2);

% attach dates
pfMacDurs = [yields(:, 'Date'), array2table(pfMacDurs, 'VariableNames', {'MacDur'})];

end
