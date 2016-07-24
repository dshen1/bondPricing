function dates = makeBusDate(dates, movingDirection, notAllowedDates)
% move non-business days to business days
%
% Inputs:
%   dates               nx1 vector of numeric dates
%   movingDirection     char indicating which direction to move to: ( follow | previous )
%   notAllowedDates     optional: lx1 vector of not allowed dates
%
% Outputs:
%   dates               nx1 vector of business dates

% get weekday and calendar definitions
GS = GlobalSettings();
if nargin == 2
    notAllowedDates = GS.Holidays;
    %notAllowedDates = holidays();
end

% make column vector
dates = dates(:);

% get weekend indicator in MATLAB order
weekendInd = replaceVals(1:7, GS.WeekdayConventions, 'MatlabNum', 'weekendInd');
% weekendInd = [1 0 0 0 0 0 1];

% find not-business days
xxInd = ~isbusday(dates, notAllowedDates, weekendInd);
toMoveDats = dates(xxInd);

% move to business days
movedDats = busdate(toMoveDats, movingDirection, notAllowedDates, weekendInd);    
dates(xxInd) = movedDats;

end