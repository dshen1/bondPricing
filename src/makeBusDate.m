function dates = makeBusDate(dates, movingDirection, notAllowedDates, weekendInd)
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
if nargin == 2 | nargin == 3
    GS = GlobalSettings();
    if ~exist('notAllowedDates', 'var')
        notAllowedDates = GS.Holidays;
    end
    if ~exist('weekendInd', 'var')
        % get weekend indicator in MATLAB order
        weekendInd = GS.WeekendInd;
    end
end

% make column vector
dates = dates(:);

% find not-business days
xxInd = ~isbusday(dates, notAllowedDates, weekendInd);
toMoveDats = dates(xxInd);

% move to business days
movedDats = busdate(toMoveDats, movingDirection, notAllowedDates, weekendInd);    
dates(xxInd) = movedDats;

end