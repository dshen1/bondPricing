function pfValues = bondPfPerformance(pfHistory, cashAccount)
% get performance from portfolio history

% get market values of individual positions
pfHistory.EveningVolumes = pfHistory.MorningVolumes + pfHistory.Orders;
pfHistory.MarketValue = pfHistory.EveningVolumes .* pfHistory.Price;

% aggregate per date
bondValues = grpstats(pfHistory(:, {'Date', 'MarketValue'}), 'Date', 'sum');
bondValues.Properties.VariableNames{'sum_MarketValue'} = 'MarketValue';

% get cash account values in the evening
cashAccount.Cash = sum(cashAccount{:, 2:end}, 2, 'omitnan');

% join bond values and cash position
pfValues = outerjoin(bondValues(:, {'Date', 'MarketValue'}), ...
    cashAccount(:, {'Date', 'Cash'}), 'Keys', 'Date', 'MergeKeys', true, 'Type', 'left');

pfValues = sortrows(pfValues, 'Date');
pfValues.FullValue = pfValues.MarketValue + pfValues.Cash;

end