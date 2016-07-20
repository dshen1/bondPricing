function validDates = blockInPeriodOfMonth(allDates, blockOfDays, periodId, notAllowedDates)
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

for ii=1:size(allYearMonths, 1)
    % get current year-month
    thisYearMonth = allYearMonths(ii, :);
end
%% 

thisYear = allYearMonths(1, 1);
thisMonth = allYearMonths(1, 2);
    
% get different date proposals
nProposals = length(blockDayCodes)-1;
dateProposals = zeros(nProposals, 1);
for jj=1:nProposals
    dateProposals(jj) = nweekdate(periodId, blockDayCodes(1), ...
        thisYear, thisMonth, blockDayCodes(jj+1));
end

% take lastest proposal for anchor date
requestedDate = max(dateProposals);

%% get other dates from block

% get lags to other dates
if length(blockDayCodes) > 1
    lags = blockDayCodes(2:end)- blockDayCodes(1);
end

validDates = [requestedDate; requestedDate + lags];

%% conduct sanity checks

% check that block is in same week
assert(length(unique(week(datetime(datevec(validDates))))) == 1)

% check that block is within valid date range


end

