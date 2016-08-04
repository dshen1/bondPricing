function prices = svenssonBondPrice(thisBond, thisYieldCurve)
% get bond price for given yield curve
%
% Inputs:
%   thisBond        Treasury bond object
%   thisYieldCurve  1x7 table of date and svensson parameters
%
% Output:
%   price           1x2 table of date and bond price

% preallocate output
thisDates = thisYieldCurve.Date;
prices = zeros(size(thisDates));

% assign NaN to dates where bond is not traded
tradedDateBools = isTraded(thisBond, thisDates);
prices(~tradedDateBools) = NaN;

% get table of cash-flows
thisCfs = cfs(thisBond);

% for each traded day, get durations to cash-flows
tradedDateInds = find(tradedDateBools);

% get svensson parameters in matrix
svenssonParams = thisYieldCurve{:, 2:end};
for ii=tradedDateInds'

    % get outstanding cash-flow dates
    xxInds = thisDates(ii) < thisCfs.Date; % IMPORTANT: cash-flows of present day are not included!
    % NOTE: this amounts to pretending that cash-flows occur in the morning.
    outstandCfs = thisCfs(xxInds, :);
    
    % get durations to outstanding cash-flows as fractions of years
    durs = outstandCfs.Date - thisDates(ii); % NOTE: always greater than 0; see above
    durs = durs / 365; % NOTE: hard-coded number of days per year
    
    % get associated discount factors
    curveParams = svenssonParams(ii, :);
    [yields, ~] = svenssonYields(curveParams, durs');
    %xxYield = array2table([durs(:), yields(:)/100], 'VariableNames', {'Maturity', 'Yield'});
    discFacts = yieldToDiscount(durs, yields(:)/100);
    
    % get present value of cash-flows
    vals = outstandCfs.CF;
    prices(ii) = sum(vals .* discFacts);
end
    
end