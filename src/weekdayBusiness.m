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
GS = GlobalSettings;
weekDayCode = replaceVals({dayName}, GS.WeekdayConventions, 'weekdayShort', 'MatlabNum');

% get all weekdays
xx = weekday(allDates);
weekdayDates = allDates(xx == weekDayCode);

% possibly move to next allowed business day
weekdayDates = makeBusDate(weekdayDates, 'follow', notAllowedDates, GS.WeekendInd);

% only pick dates within original range
xxInd = weekdayDates <= dateRange(end) & weekdayDates >= dateRange(1);
weekdayDates = weekdayDates(xxInd);

% create table for debuggin
% weekdayDatesTab = table(weekdayDates, datestr(weekdayDates), datestr(weekdayDates, 'ddd'));

end