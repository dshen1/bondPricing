function validDates = periodOfMonth(allDates, dayName, periodId, notAllowedDates)
% get given weekday in the middle of the month
%
% Inputs:
%   allDates    nx1 vector comprising all dates
%   dayName     ddd char denoting weekday
%   periodId    scalar value to denote week of month
%   notAllowedDates     mx1 vector of not allowed dates
%
% Outputs:
%   validDates  lx1 vector of valid dates within date range

% extend all dates to beginning of this month
firstOfMonth = datenum(year(allDates(1)), month(allDates(1)), 1);

if firstOfMonth < allDates(1)
    extendedAllDates = [(firstOfMonth:1:(allDates(1)-1))'; allDates];
else
    extendedAllDates = allDates(:);
end

% get day identifier
% get weekday numeric code
switch dayName
    case 'Mon'
        weekDayCode = 2;
    case 'Tue'
        weekDayCode = 3;
    case 'Wed'
        weekDayCode = 4;
    case 'Thu'
        weekDayCode = 5;
    otherwise
        error('bondPricing:weekdayBusiness', 'Given weekday name is not implemented.')
end
        
% get monthly weekday date: every third Thursday in a month
weekdayDates = extendedAllDates(weekday(extendedAllDates) == weekDayCode);
associatedMonths = month(weekdayDates);

% preallocation
nWeekDayDates = length(weekdayDates);
weekDayInMonth = false(nWeekDayDates, 1);

weekDayInMonthCounter = 1;
for ii=2:nWeekDayDates
    % check for new month
    if associatedMonths(ii) ~= associatedMonths(ii-1)
        weekDayInMonthCounter = 1;
    else
        weekDayInMonthCounter = weekDayInMonthCounter + 1;
    end
    
    % check for period in month
    if weekDayInMonthCounter == periodId
        weekDayInMonth(ii) = true;
    end
end

validDates = weekdayDates(weekDayInMonth);

% possibly move to allowed business day
validDates = moveToAllowedBusinessDay(validDates, allDates, notAllowedDates);

end

