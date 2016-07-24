function allTBills = getTBill(dateBeg, dateEnd, nTerm)

% get complete date range in numeric format
firstDate = datenum(dateBeg);
lastDate = datenum(dateEnd);
allDates = (firstDate:lastDate)';

% each Monday
GS = GlobalSettings();
switch nTerm
    case 4
        % each Tuesday
        TBdates = weekdayBusiness(allDates, 'Tue', GS.Holidays);
    case 13
        % each Monday
        TBdates = weekdayBusiness(allDates, 'Mon', GS.Holidays);
    case 26
        % each Monday
        TBdates = weekdayBusiness(allDates, 'Mon', GS.Holidays);
    case 52
        % each 4th Tuesday
        TBdates = fourWeekTuesdays(allDates, GS.Holidays);
    otherwise
        error('bondPricing:getTBill', 'Wrong term specified. Has to be 4, 13, 26 or 52.')
end

% create T-Bill for each auction day
nBills = length(TBdates);
allTBills(nBills, 1) = Treasury('TBill', nTerm, TBdates(end), GS);
for ii=1:(nBills-1)
    allTBills(ii) = Treasury('TBill', nTerm, TBdates(ii), GS);
end

end