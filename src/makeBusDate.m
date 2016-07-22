function dates = makeBusDate(dates, movingDirection)
% move non-business days to business days
%
% Inputs:
%   dates               nx1 vector of numeric dates
%   movingDirection     char indicating which direction to move to: ( follow | previous )
%
% Outputs:
%   dates               nx1 vector of business dates

% get weekday and calendar definitions
GS = GlobalSettings();

% make column vector
dates = dates(:);

% find not-business days
xxInd = ~isbusday(dates, GS.Holidays, [1 0 0 0 0 0 1]);
toMoveDats = dates(xxInd);

% move to business days
movedDats = busdate(toMoveDats, movingDirection, GS.Holidays, [1 0 0 0 0 0 1]);
dates(xxInd) = movedDats;

end