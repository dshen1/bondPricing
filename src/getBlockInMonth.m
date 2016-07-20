function validDates = getBlockInMonth(blockDayCodes, periodId, thisYear, thisMonth)
% find given block in period of month

% get different date proposals for first day of block
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

end