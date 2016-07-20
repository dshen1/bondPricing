function allBusinessDates = blockInPeriodOfMonth(allDates, blockOfDays, periodId, notAllowedDates)
% get given weekday in a given period of the month, such that full block of
% days is in period
%
% Inputs:
%   allDates            nx1 vector comprising all dates
%   blockOfDays         cell array of ddd char denoting weekdays
%   periodId            scalar value to denote week of month (e.g. 3rd week
%                       in month)
%   notAllowedDates     mx1 vector of not allowed dates
%
% Outputs:
%   validDates  lx1 vector of valid dates within date range

%%
% extend all dates to beginning of this month
firstOfMonth = datenum(year(allDates(1)), month(allDates(1)), 1);

if firstOfMonth < allDates(1)
    extendedAllDates = [(firstOfMonth:1:(allDates(1)-1))'; allDates];
else
    extendedAllDates = allDates(:);
end

%% transform char block of days to integer codes

% specify MATLAB weekday encoding
weekDayLookup = containers.Map({'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'}, ...
    [2, 3, 4, 5, 6, 7, 1]);

% get numeric code for weekdays
blockDayCodes = cellfun(@(x)weekDayLookup(x), blockOfDays);
blockDayCodes = blockDayCodes(:);

% sort increasingly
blockDayCodes = sort(blockDayCodes);

%%

% get unique months / years
xx = datevec(extendedAllDates);
allYearMonths = unique(xx(:, 1:2), 'rows');

%%

allWeekdayDates = [];
for ii=1:size(allYearMonths, 1)
    % get current year-month
    thisYearMonth = allYearMonths(ii, :);
    
    % get block dates in given month
    validDates = getBlockInMonth(blockDayCodes, periodId, ...
        thisYearMonth(1), thisYearMonth(2));
    
    % attach
    allWeekdayDates = [allWeekdayDates; validDates'];
end

%% make non-overlapping business days

allBusinessDates = zeros(size(allWeekdayDates));
for ii=1:size(allWeekdayDates, 2)
    % get original dates
    origDates = allWeekdayDates(:, ii);
    
    % get indices for dates that are on not allowed dates
    xxHolidayInd = ismember(origDates, notAllowedDates);
    
    % move to next trading day
    xxToMove = origDates(xxHolidayInd);
    newDates = origDates;
    newDates(xxHolidayInd) = busdate(xxToMove, 1, notAllowedDates, [1 0 0 0 0 0 1]);
   
    % increase set of not allowed days
    notAllowedDates = [notAllowedDates; newDates];
    
    % add to business dates
    allBusinessDates(:, ii) = newDates;
end

end

