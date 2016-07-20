%% check matching

realAuctions = readtable('notes/tentativeAuctionSchedule.csv');
synthAuctions = readtable('notes/artificialAuctions.csv');

% get numerical dates for real auctions
realAuctions.Date = datenum(realAuctions.AuctionDate);

%% do matching

% for each security find the closest matching synthetic one
allTypes = unique(realAuctions.SecurityType);

for ii=1:length(allTypes)
    thisType = allTypes{ii};
    
    % select all associated securities
    thisTypeReal = selRowsProp(realAuctions, 'SecurityType', thisType);
    thisTypeSynth = selRowsProp(synthAuctions, 'Name', thisType);

end

%% find closest match

thisMatch = thisTypeReal(:, 1:3);

for ii=1:size(thisTypeReal, 1)
    thisDate = thisTypeReal.Date;
    
    [~, I] = min(abs(thisTypeSynth.AuctionDate - thisDate));
    
    thisMatch(ii, :) = thisTypeSynth(I, {'WeekDay', 'Date'})

end