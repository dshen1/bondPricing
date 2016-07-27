
GS = GlobalSettings()

%% hcat

objTreasury1 = Treasury('TBill', 4, '2016-04-04');
objTreasury2 = Treasury('TNote', 3, '2016-04-04');

xx = [objTreasury1; objTreasury2]

%% create synthetic treasuries

% specify period
%dateBeg = '2016-04-26';
%dateEnd = '2016-11-20';
dateBeg = '1980-04-26';
dateEnd = '2020-11-20';

%%
treasuryBills = getTBill(dateBeg, dateEnd, 13);
%%                
treasuryNotes = getTNoteBond(dateBeg, dateEnd, 3);

%%

allTreasuries = getAllTreasuries(dateBeg, dateEnd);

%% find treasuries fulfilling some condition

xxInds = [allTreasuries.AuctionDate] >= datenum('2016-09-20');
xxRelevant = allTreasuries(xxInds);

%%

thisDate = datenum('2016-09-20');
currentlyTraded = [allTreasuries.Maturity] >= thisDate & [allTreasuries.AuctionDate] <= thisDate;
allTreasuries(currentlyTraded)

%%

xxInds = isTraded(allTreasuries, thisDate);
allTreasuries(xxInds, :)

%% get remaining days until maturity

xxRemaining = [allTreasuries.Maturity]' - thisDate;
xxNotTraded = ~isTraded(allTreasuries, thisDate);
xxRemaining(xxNotTraded) = NaN;

%% visualize number of traded bonds and remaining time to maturity

dateRange = datenum(dateBeg):datenum(dateEnd);
nDays = length(dateRange);
nBonds = length(allTreasuries);
nTradedBonds = zeros(nDays, 1);
nRemaining = zeros(nDays, nBonds);
for ii=1:nDays
   thisDate = dateRange(ii);
   
   % find currently traded bonds
   xxInds = isTraded(allTreasuries, thisDate);
   nTradedBonds(ii) = sum(xxInds);
   
   todayRemaining = [allTreasuries.Maturity]' - thisDate;
   todayRemaining(~xxInds) = NaN;

   nRemaining(ii, :) = todayRemaining';
       
end

%%

plot(dateRange, nRemaining, '.')
datetick 'x'
grid on
grid minor

%%

plot(dateRange, nTradedBonds)
datetick 'x'
grid on
grid minor

%%

xx = cfdates(objTreasury);
%datestr(xx', 'yyyy-mm-dd')

%% clear todo's:
% - day-count conventions for notes and bonds
% - maturity
% - do cash-flow dates depend on convention?