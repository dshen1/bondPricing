function newDates = moveToAllowedBusinessDay(origDates, dateRange, notAllowedDates)
% move given dates to next allowed day
%
% Inputs:
%   origDates       nx1 vector of dates to move (usually following some
%                   pattern specified in some prior function)
%   dateRange       mx1 vector of all dates within date range
%   notAllowedDates     lx1 vector of not allowed dates
%
% Outputs:
%   newDates        nx1 vector of possibly adjusted new dates

% get indices for dates that are on not allowed dates
xxHolidayInd = ismember(origDates, notAllowedDates);

% move to next trading day
xxToMove = origDates(xxHolidayInd);
newDates = origDates;
newDates(xxHolidayInd) = busdate(xxToMove, 1, notAllowedDates, [1 0 0 0 0 0 1]);

% only pick dates within original range
xxInd = newDates <= dateRange(end) & newDates >= dateRange(1);
newDates = newDates(xxInd);

end