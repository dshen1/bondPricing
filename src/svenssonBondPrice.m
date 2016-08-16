function [prices, macDurs] = svenssonBondPrice(thisBond, yieldCurves)
% get bond price for given yield curve
%
% Inputs:
%   thisBond        Treasury bond object
%   thisYieldCurve  nx7 table of dates and svensson parameters
%
% Output:
%   price           nx1 vector of bond prices
%   macDurs         nx1 vector of Macaulay durations

% preallocate output
allDates = yieldCurves.Date;
prices = NaN(size(allDates));
macDurs = NaN(size(allDates));

% find indices of dates where bond is traded
bondIsTraded = isTraded(thisBond, allDates);
yieldCurveExists = ~all(isnan(yieldCurves{:, 2:end}), 2);
tradedDateInds = bondIsTraded & yieldCurveExists;
tradedDates = allDates(tradedDateInds);
nTradedDays = sum(tradedDateInds);

if nTradedDays > 0 % fill in prices on traded days
    
    % get table of cash-flows
    allCfs = cfs(thisBond);
    cashFlowVals = repmat(allCfs.CF', nTradedDays, 1);
    nMaturs = size(cashFlowVals, 2); % get number of maturities
    
    % NOTE: hard-coded number of days per year
    durs = (repmat(allCfs.Date', nTradedDays, 1) - repmat(tradedDates, 1, nMaturs))/365;
    durs = max(0, durs); % set duration to zero for past cash-flows
    
    % extract svensson parameters to matrix for faster performance
    svenssonParams = yieldCurves{tradedDateInds, 2:end};
    
    % get associated discount factors for traded days
    [yields, ~] = svenssonYields(svenssonParams, durs);
    
    % get associated discount factors
    discFacts = yieldToDiscount(durs, yields/100);
    
    % set NaN discount factors to zero
    discFacts(isnan(discFacts)) = 0;
    
    % calculate prices
    prices(tradedDateInds) = sum(cashFlowVals .* discFacts, 2);
    
    % calculate macaulay durations
    macDurs(tradedDateInds) = sum(durs .* cashFlowVals .* discFacts, 2) ./ prices(tradedDateInds);

end
end