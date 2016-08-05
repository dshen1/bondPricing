% bond portfolio strategy

%% load data

% set data directory
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'syntheticBondsLongFormat.mat');
load(fname)

%% define strategy parameters

% define duration bounds
minDur = 7*365 + 1; % do not allow notes with maturity 7 years
maxDur = 9*365;

%% 

% get time to maturity for each observation
longPrices = sortrows(longPrices, 'Date');
longPrices.CurrentMaturity = longPrices.Maturity - longPrices.Date;

%% find re-openings

smallLongPrices = longPrices(1:20000, :);
xxGrouped = grpstats(smallLongPrices(:, {'Maturity', 'CouponRate', 'Date'}), ...
    {'Maturity', 'CouponRate', 'Date'});


%% eligible bonds

% reduce to eligible bonds
xxEligible = longPrices.CurrentMaturity >= minDur & longPrices.CurrentMaturity <= maxDur;
eligiblePrices = longPrices(xxEligible, :);

%% get number of eligible bonds over time

xxEnd = 100000;
plot(eligiblePrices.Date(1:xxEnd), eligiblePrices.CurrentMaturity(1:xxEnd), '.')
grid on
grid minor
datetick 'x'

%% find all bonds for given day

% select day
thisDay = datenum('1990-01-01');

% make valid business day
uniqueDats = eligiblePrices.Date;
thisDay = uniqueDats(find(uniqueDats >= thisDay, 1, 'first'));

singleDayBonds = selRowsProp(eligiblePrices, 'Date', thisDay);

% visualize selection
plot(singleDayBonds.MaturityInDays, singleDayBonds.CurrentMaturity, '.')
xlabel('Initial maturity')
ylabel('Current maturity')
grid on
grid minor

%% Inspect 30-Year Bonds

xxBond30 = selRowsProp(singleDayBonds, 'TreasuryType', '30-Year BOND');
xxBond30 = sortrows(xxBond30, 'AuctionDate');
stem(xxBond30.AuctionDate, ones(size(xxBond30, 1)))
datetick 'x'
grid on
grid minor

%% Inspect coupon rates

subplot(1, 2, 1)
plot(singleDayBonds.AuctionDate, singleDayBonds.CouponRate, '.')
datetick 'x'
grid on
grid minor
xlabel('Initial auction date')
ylabel('Coupon rate')

subplot(1, 2, 2)
plot(singleDayBonds.CurrentMaturity, singleDayBonds.CouponRate, '.')
grid on
grid minor
xlabel('Days until maturity')
ylabel('Coupon rate')








