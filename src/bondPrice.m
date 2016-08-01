function prices = bondPrice(thisBond, yieldCurves)
% determine bond price with given yield curve
%
% Inputs:
%   thisBond        Treasury object
%   yieldCurves     nx7 table of dates and Svensson parameters
% 
% Outputs:
%   prices          nx1 table of bond prices

%%
% get pricing dates and pre-allocate prices
pricingDates = yieldCurves.Date; 
prices = nan(size(pricingDates));

%%

% get traded dates
tradedDayInds = pricingDates >= thisBond.AuctionDate & ...
    thisBond.Maturity < pricingDates;
datesWithPrice = pricingDates(tradedDayInds);
nDates = size(datesWithPrice, 1);

%% get price for each traded day

% get cash-flow dates
cfs = cfdates(thisBond);

existingPrices = zeros(nDates, 1);
for ii=1:nDates
    % get current date
    thisDate = datesWithPrice(ii);
    
    % get time to individual cash-flows
    durs = cfs - thisDate;
    durs = durs(durs > 0);
    
    
end



