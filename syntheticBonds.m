%% Set function inputs

% specify period
dateBeg = '2016-04-26';
dateEnd = '2016-11-20';

%% Specify treasury bill names

treasuryLabels = {'TB04W', 'TB13W', 'TB26W', 'TB52W', 'TN02Y', 'TN03Y', 'TN05Y', 'TN07Y', 'TN10Y', 'TB30Y'};
treasuryNames = {'4-Week BILL';
    '13-Week BILL';
    '26-Week BILL';
    '52-Week BILL';
    '2-Year NOTE';
    '3-Year NOTE';
    '5-Year NOTE';
    '7-Year NOTE';
    '10-Year NOTE';
    '30-Year BOND'};

treasuries = table(treasuryLabels', treasuryNames, 'VariableNames', {'Label', 'Name'});

%%

% define auction schedule parameters
maturs = [1:30];

%%

% get complete date range
firstDate = datenum(dateBeg);
lastDate = datenum(dateEnd);
allDates = (firstDate:lastDate)';

% get holidays for chosen period
holidayDates = holidays(dateBeg, dateEnd);

%% get weekly auction dates

% each Tuesday
TB04W_dates = weekdayBusiness(allDates, 'Tue', holidayDates);

% each Monday
TB13W_dates = weekdayBusiness(allDates, 'Mon', holidayDates);

% each Monday, not TB13W dates
% notAllowedDays = sort([holidayDates(:); TB13W_dates]);
TB26W_dates = weekdayBusiness(allDates, 'Mon', holidayDates);

%% get 4 weekly dates

% each 4th Tuesday
TB52W_dates = fourWeekTuesdays(allDates, holidayDates);

%%

dat = nweekdate(2, 3, 2016, 6, [4; 5]);
datestr(dat)
datestr(dat, 'ddd')

%% test block in period

xx = blockInPeriodOfMonth(allDates, {'Tue', 'Wed', 'Thu'}, 3, holidayDates);

%% get monthly auction dates

% 2, 5, 7: Tue, Wed, Thu, 4th week

% 2 years
TN02Y_dates = periodOfMonth(allDates, 'Tue', 4, holidayDates);

% 5 years
notAllowedDays = sort([holidayDates(:); TN02Y_dates]);
TN05Y_dates = periodOfMonth(allDates, 'Wed', 4, notAllowedDays);

% 7 years
notAllowedDays = sort([holidayDates(:); TN02Y_dates; TN05Y_dates]);
TN07Y_dates = periodOfMonth(allDates, 'Thu', 4, notAllowedDays);

%% get monthly auction dates

% 3, 10, 30: Tue, Wed, Thu, 2th week

% 3 years
TN03Y_dates = periodOfMonth(allDates, 'Tue', 2, holidayDates);

% 10 years
notAllowedDays = sort([holidayDates(:); TN03Y_dates]);
TN10Y_dates = periodOfMonth(allDates, 'Wed', 2, notAllowedDays);

% 30 years
notAllowedDays = sort([holidayDates(:); TN03Y_dates; TN10Y_dates]);
TB30Y_dates = periodOfMonth(allDates, 'Thu', 2, notAllowedDays);

%% create overview table

allAuctionDates = [TB04W_dates;
    TB13W_dates;
    TB26W_dates;
    TB52W_dates;
    TN02Y_dates;
    TN03Y_dates;
    TN05Y_dates;
    TN07Y_dates;
    TN10Y_dates;
    TB30Y_dates];
    
allLabels = [repmat({'TB04W'}, length(TB04W_dates), 1);
    repmat({'TB13W'}, length(TB13W_dates), 1);
    repmat({'TB26W'}, length(TB26W_dates), 1);
    repmat({'TB52W'}, length(TB52W_dates), 1);
    repmat({'TN02Y'}, length(TN02Y_dates), 1);
    repmat({'TN03Y'}, length(TN03Y_dates), 1);
    repmat({'TN05Y'}, length(TN05Y_dates), 1);
    repmat({'TN07Y'}, length(TN07Y_dates), 1);
    repmat({'TN10Y'}, length(TN10Y_dates), 1);
    repmat({'TB30Y'}, length(TB30Y_dates), 1)];

auctions = table(allAuctionDates, allLabels, 'VariableNames', {'AuctionDate', 'Label'});

auctions.Name = replaceVals(allLabels, treasuries, 'Label', 'Name');
auctions.Weekday = datestr(auctions.AuctionDate, 'ddd');
auctions.Date = datestr(auctions.AuctionDate, 'mmm-dd-yyyy');
auctions = sortrows(auctions, 'AuctionDate');



