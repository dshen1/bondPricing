function allTNB = getTNoteBond(dateBeg, dateEnd, nTerm)

% get complete date range in numeric format
firstDate = datenum(dateBeg);
lastDate = datenum(dateEnd);
allDates = (firstDate:lastDate)';

% each Monday
GS = GlobalSettings();
switch nTerm
    case {2, 5, 7}
        % monthly: Tue, Wed, Thu, 4th week
        TNBdates = blockInPeriodOfMonth(allDates, {'Tue', 'Wed', 'Thu'}, 4, GS.Holidays);
    case {3, 10, 30}
        % monthly: Tue, Wed, Thu, 2th week
        TNBdates = blockInPeriodOfMonth(allDates, {'Tue', 'Wed', 'Thu'}, 2, GS.Holidays);
    otherwise
        error('bondPricing:getTNoteBond', 'Wrong term specified: 2, 3, 5, 7, 10, or 30.')
end

switch nTerm
    case 2
        TNBdates = TNBdates(:, 1);
    case 5
        TNBdates = TNBdates(:, 2);
    case 7
        TNBdates = TNBdates(:, 3);
    case 3
        TNBdates = TNBdates(:, 1);
    case 10
        TNBdates = TNBdates(:, 2);
    case 30
        TNBdates = TNBdates(:, 3);
end


% create T-Note or T-Bond for each auction day
nNotes = length(TNBdates);
allTNB = [];
for ii=1:nNotes
    if nTerm == 30
        obj = Treasury('TBond', nTerm, TNBdates(ii));
    else
        obj = Treasury('TNote', nTerm, TNBdates(ii));
    end
    allTNB = [allTNB; obj];
end

end