%% check matching

realAuctions = readtable('notes/tentativeAuctionSchedule.csv');
synthAuctions = readtable('notes/artificialAuctions.csv');

% get numerical dates for real auctions
realAuctions.Date = datenum(realAuctions.AuctionDate);

%% do matching

% for each security find the closest matching synthetic one
allTypes = unique(realAuctions.SecurityType);

% preallocation
matchedSecurities = [];

for ii=1:length(allTypes)
    thisType = allTypes{ii};
    
    % select all associated securities
    thisTypeReal = selRowsProp(realAuctions, 'SecurityType', thisType);
    thisTypeSynth = selRowsProp(synthAuctions, 'Name', thisType);

    % find matching synthetic securities
    thisMatch = thisTypeReal(:, 1:3); % preallocation

    for jj=1:size(thisTypeReal, 1)
        thisDate = thisTypeReal.Date(jj);
        
        [~, I] = min(abs(thisTypeSynth.AuctionDate - thisDate));
        
        thisMatch(jj, :) = thisTypeSynth(I, {'Name', 'Weekday', 'Date'});
    end
    
    % fix column names
    thisMatch.Properties.VariableNames = {'Name', 'Synth_Weekday', 'Synth_Date'};
    
    % attach matched synthetic securities
    thisTypeReal = [thisTypeReal thisMatch(:, 2:end)];
    
    % collect results
    matchedSecurities = [matchedSecurities; thisTypeReal];
end

matchedSecurities.Synth_NumDate = datenum(matchedSecurities.Synth_Date, 'mmm-dd-yyyy');

% sort columns
matchedSecurities = matchedSecurities(:, {'Date', 'Synth_NumDate', 'SecurityType', 'Weekday', ...
    'Synth_Weekday', 'AuctionDate', 'Synth_Date'});

%% check matching frequencies

xxPerfectMatch = matchedSecurities.Date == matchedSecurities.Synth_NumDate;

% get matching frequencies
matchFreq = sum(xxPerfectMatch) / size(matchedSecurities, 1);

% inspect miss-machted securities
missMatched = matchedSecurities(~xxPerfectMatch, :);