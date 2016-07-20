%% Set function inputs

% specify period
dateBeg = '2016-04-26';
dateEnd = '2016-11-20';

%% Specify treasury bill names
{'TB04W', 'TB13W', 'TB26W', 'TB52W', 'TN02Y', 'TN03Y', 'TN05Y', 'TN07Y', 'TN10Y', 'TB30Y'}


%%

% define auction schedule parameters
maturs = [1:30];

%%

% get holidays for chosen period
holidayDates = holidays(dateBeg, dateEnd);

% get complete date range
firstDate = datenum(dateBeg);
lastDate = datenum(dateEnd);
allDates = (firstDate:lastDate)';

% get mondays or next business days
mondayDates = weekdayBusiness(allDates, 'Mon', holidayDates);

% get Tuesdays, or move to next business day if Monday or Tuesday was
% holiday
notAllowedDays = sort([holidayDates(:); mondayDates]);
tuesdayDates = weekdayBusiness(allDates, 'Tue', notAllowedDays);

% get every fourth Tuesday
fourthTuesdayDates = fourWeekTuesdays(allDates, notAllowedDays);

%%


%[datestr(thursdayDates) datestr(thursdayDates, 'mm') datevec(thursdayDates)]
%datevec(thursdayDates)




%%

xxClosures = nyseclosures('2016-04-26', '2016-11-20');

datestr(xxClosures)
