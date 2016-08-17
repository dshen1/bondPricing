function coupRate = svenssonCouponRate(thisBond, yieldCurve)
% determine appropriate coupon rate
%
% Inputs:
%   thisBond        Treasury bond object
%   thisYieldCurve  1x7 table of date and svensson parameters
%
% Outputs:
%   coupRate        scalar value for coupon rate

if strcmp(thisBond.Type, 'TBill')
    coupRate = 0;
    
else
    %%
    
    % get current date
    thisDate = yieldCurve.Date;
    
    % get cash-flow dates
    allCfDates = thisBond.CfDates';
    nCfs = length(allCfDates);
    
    % get durations
    durs = (allCfDates - thisDate)/365;
    durs = max(0, durs);
    
    % get discount factors
    [yields, ~] = svenssonYields(yieldCurve{:, 2:end}, durs);
    if any(isnan(yields))
        coupRate = 0.02;
        return
    end
    discFacts = yieldToDiscount(durs, yields/100);
    
    % specify coupon rate grid
    cpRateGrid = (0:1/8:15)'/100;
    nCpRates = length(cpRateGrid);
  
    % create cash-flow matrix
    cfVals = repmat(cpRateGrid, 1, nCfs) .* thisBond.NominalValue;
    cfVals(:, end) = cfVals(:, end) + thisBond.NominalValue;
    
    % get prices
    discFactMatr = repmat(discFacts, nCpRates, 1);
    possiblePrices = sum(cfVals.* discFactMatr, 2);

    % pick first price below par
    xxInd = find(possiblePrices < thisBond.NominalValue, 1, 'last');
    
    coupRate = cpRateGrid(xxInd);

end