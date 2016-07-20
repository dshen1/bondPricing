function fourthWeekDates = fourWeekTuesdays(allDates, notAllowedDates)
% get every 4th Tuesday
%
% Inputs:
%   allDates            nx1 vector of dates
%   notAllowedDates     mx1 vector of not allowed dates

% set anchor to specify 4 week cycle
anchorTuesday = datenum('2016-09-13');

% set day code
tuesdayCode = 3;

% increase all dates to comprise anchor date
if anchorTuesday > allDates(end)
    extendedAllDates = [allDates(:); ((allDates(end)+1):1:anchorTuesday)'];
elseif anchorTuesday < allDates(1)
    extendedAllDates = [(anchorTuesday:1:(allDates(1)-1))'; allDates(:)];
else
    extendedAllDates = allDates(:);
end

% get all weekdays
xx = weekday(extendedAllDates);
weekdayDates = extendedAllDates(xx == tuesdayCode);

% get every fourth weekday
anchorInd = find(weekdayDates == anchorTuesday);
priorInds = fliplr(anchorInd:-4:1);
afterInds = anchorInd:4:length(weekdayDates);
allInds = [priorInds, afterInds(2:end)];
fourthWeekDates = weekdayDates(allInds(:));

% move selected days to allowed business days
fourthWeekDates = moveToAllowedBusinessDay(fourthWeekDates, allDates(:), notAllowedDates);

end