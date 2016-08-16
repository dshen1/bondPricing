function [forecastBondValues, pfMacDurs, pfWgts] = evalFixedBondPf(yields, pfHistory, cashAccount, allTreasuries)
%% open questions / problems
% - should morning or evening volumes be investigated? 
% - morning volumes it should be if sensitivity analysis should have an
%   impact on trading decisions
% - take maturities into account: may bonds expiry during forecast period?

%%

%% derive some general properties

genInfo.nForecast = size(yields, 1);
genInfo.thisDate = yields.Date(1);

%% get current portfolio in long format

% select long format history at respective date
currPf = selRowsProp(pfHistory, 'Date', genInfo.thisDate);
currPf.EveningVolumes = currPf.MorningVolumes + currPf.Orders;
currPf = currPf(currPf.EveningVolumes > 0, :);

%% get associated treasuries

bondInfoTable = summaryTable(allTreasuries);
xxInds = ismember(bondInfoTable.TreasuryID, currPf.TreasuryID);
thisComponents = allTreasuries(xxInds);

% add information to general info
genInfo.nBonds = length(thisComponents);

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
allPrices = array2table(allPrices, 'VariableNames', {thisComponents.TreasuryID});
allPrices = [yields(:, 'Date'), allPrices];
macDurs = array2table(macDurs, 'VariableNames', {thisComponents.TreasuryID});
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
adjustedPrices{:, 2:end} = adjustedPrices{:, 2:end} + cumsum(cashFlowsWide{:, 2:end}, 1);

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
forecastBondValues = adjustedPrices{:, cellstr(currPf.TreasuryID)} * currPf.EveningVolumes;

% add current cash value
currCash = selRowsKey(cashAccount, 'Date', genInfo.thisDate);
currCash = sum(currCash{:, 2:end}, 2, 'omitnan');

% add to bond values
forecastBondValues = array2table(forecastBondValues + currCash, ...
    'VariableNames', {'PfValForecast'});

% attach dates
forecastBondValues = [yields(:, 'Date'), forecastBondValues];

%% get portfolio durations

% get true bond values
forecastUnadjValues = allPrices{:, cellstr(currPf.TreasuryID)} .* ...
    repmat(currPf.EveningVolumes', genInfo.nForecast, 1);

% get portfolio weights
pfWgts = forecastUnadjValues ./ repmat(forecastBondValues.PfValForecast, 1, size(allPrices, 2)-1);

% get portfolio durations
pfMacDurs = sum(macDurs{:, cellstr(currPf.TreasuryID)} .* pfWgts, 2);

% attach dates
pfMacDurs = [yields(:, 'Date'), array2table(pfMacDurs, 'VariableNames', {'MacDur'})];

end
