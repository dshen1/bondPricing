function prices = totalReturnPrices(paramsTable)
% compute total return prices for coupon bond

% get auction date
auctionDate = paramsTable.Date(1);

% get global settings
GS = GlobalSettings();

% get coupon bond
couponBond = Treasury('TNote', 5, auctionDate, GS);
cpRate = svenssonCouponRate(couponBond, paramsTable(1, :));
couponBond = modifyCouponRate(couponBond, cpRate);

% get zero coupon bond with equal maturity
zcWeeks = floor((couponBond.Maturity - auctionDate)/7);
zcAuctionDate = couponBond.Maturity - zcWeeks * 7;
zeroCouponBond = Treasury('TBill', zcWeeks, zcAuctionDate, GS, 0);

% get prices with fixed interest rates
zeroCouponPrices = svenssonBondPrice(zeroCouponBond, paramsTable);
couponPrices = svenssonBondPrice(couponBond, paramsTable);

% fix last price
zeroCouponPrices(end) = zeroCouponBond.NominalValue;
couponPrices(end) = couponBond.NominalValue;

%% re-investment of coupon payments

% at coupon dates we get coupon payments that can be invested again until
% maturity of the original bond

% get maturities until final date
reinvestDates = couponBond.CfTable.Date(1:end-1);
reinvestMaturs = couponBond.Maturity - reinvestDates;
reinvestMaturs = reinvestMaturs / 365;

reinvestYieldCurves = selRowsProp(paramsTable, 'Date', couponBond.CfTable.Date(1:end-1));
[xx, ~] = svenssonYields(reinvestYieldCurves{:, 2:end}, ...
    repmat(reinvestMaturs', size(reinvestMaturs, 1), 1));
reinvestYields = diag(xx);

% get principal of reinvested coupons
reinvestVals = couponBond.CfTable.CF(1:end-1) .* exp(reinvestMaturs .* reinvestYields./100);

aggrReinvestVals = cumsum(reinvestVals);

%%

reinvestmentPrices = zeros(size(paramsTable.Date));
for ii=1:size(reinvestDates)
    thisReinvestDate = reinvestDates(ii);
    
    % find larger dates
    xxInds = paramsTable.Date >= thisReinvestDate;
    
    reinvestmentPrices(xxInds) = aggrReinvestVals(ii);
end

%%

trPrices = couponPrices + reinvestmentPrices .* zeroCouponPrices / 100;

% fix last price
trPrices(end) = trPrices(end) + couponBond.CouponRate * couponBond.NominalValue;

prices = [zeroCouponPrices, couponPrices, trPrices];
prices = array2table([paramsTable.Date, prices], ...
    'VariableNames', {'Date', 'ZeroCoupon', 'Coupon', 'TotalReturn'});