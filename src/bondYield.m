function [yields, macDurs] = bondYield(thisBond, bondPrices)
% get internal rate of return for given bond
%
% Inputs:
%   thisBond    Treasury object
%   bondPrices  nx2 table of bond prices
%
% Outputs:
%   yields      nx2 table of yields


%%

% get cash-flow dates and cash-flows
thisCfDates = thisBond.CfDates;
thisCfValues = thisBond.CfValues;
nCfs = length(thisCfDates);

% get evaluation dates
yieldDates = bondPrices.Date;
nDates = length(yieldDates);

% get durations to cash-flows
durs = (repmat(thisCfDates', nDates, 1) - repmat(yieldDates, 1, nCfs)) / 365;
durs = max(0, durs);

% preallocation
yields = nan(nDates, 1);
macDurs = nan(nDates, 1);

% get yields
priceMatr = bondPrices.Price;
x0 = thisBond.CouponRate * 2;
for ii=1:nDates
    % get current price
    thisPrice = priceMatr(ii);
    
    % this durations
    xxInd = durs(ii, :) > 0;
    currentDurations = durs(ii, xxInd);
    currentCfs = thisCfValues(xxInd);
    
    % anonymous function to find zero yields
    btPrice = @(x)sum(currentCfs'.*exp((-1)*currentDurations*x)) - thisPrice;

    if ~isempty(currentCfs)
        thisYield = fzero(btPrice, x0);
        yields(ii) = thisYield;
    
        % update initial guess
        x0 = yields(ii);
        
        % calculate macaulay durations
        discFacts = exp(-currentDurations * thisYield);
        macDurs(ii) = sum(currentDurations .* currentCfs' .* discFacts, 2) ./ thisPrice;
    end
    
end


