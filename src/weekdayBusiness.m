function weekdayDates = weekdayBusiness(dateRange, dayName, notAllowedDates)
% get dates of given weekday, but take next business day for holidays
%
% Inputs:
%   dateRange       vector comprising all serial dates within given period
%   dayName         name of weekday: 'Mon' or 'Tue'
%   notAllowedDates     vector of not allowed dates to pick
%
% Outputs:
%   weekdayDates     column vector comprising dates of given weekday or next business days 

% make column vector
allDates = dateRange(:);

% get weekday numeric code
switch dayName
    case 'Mon'
        weekDayCode = 2;
    case 'Tue'
        weekDayCode = 3;
    otherwise
        error('bondPricing:weekdayBusiness', 'Given weekday name is not implemented.')
end
            
% get all weekdays
xx = weekday(allDates);
weekdayDates = allDates(xx == weekDayCode);

% possibly move to next allowed business day
weekdayDates = moveToAllowedBusinessDay(weekdayDates, allDates(:), notAllowedDates);

% create table for debuggin
% weekdayDatesTab = table(weekdayDates, datestr(weekdayDates), datestr(weekdayDates, 'ddd'));

end