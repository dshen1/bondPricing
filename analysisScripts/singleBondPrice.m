function price = singleBondPrice(thisBond, thisYieldCurve)
% get bond price for given yield curve
%
% Inputs:
%   thisBond        Treasury bond object
%   thisYieldCurve  1x7 table of date and svensson parameters
%
% Output:
%   price           1x2 table of date and bond price

thisDate = thisYieldCurve.Date;

% test if bond is traded
if ~isTraded(thisBond, thisDate)
    price = NaN;
else
    % get table of cash-flows
    thisCfs = cfs(thisBond);
    
    % get outstanding cash-flow dates
    xxInds = thisDate < thisCfs.Date;
    outstandCfs = thisCfs(xxInds, :);
    
    % get durations to outstanding cash-flows as fractions of years
    durs = outstandCfs.Date - thisDate;
    durs = durs / 365;
    
    % get associated discount factors
    [yields, ~] = svenssonYields(thisYieldCurve{:, 2:end}, durs);
    xxYield = array2table([durs(:), yields(:)/100], 'VariableNames', {'Maturity', 'Yield'});
    discFacts = yieldToDiscount(xxYield);
    
    % get present value of cash-flows
    vals = outstandCfs.CF;
    price = sum(vals .* discFacts{:, 2});
    
end