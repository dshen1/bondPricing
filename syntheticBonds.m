%% Set function inputs

% specify period
dateBeg = '2016-04-26';
dateEnd = '2016-11-20';

%% Specify treasury bill names

treasuryLabels = {'TB04W', 'TB13W', 'TB26W', 'TB52W', 'TN02Y', 'TN03Y', 'TN05Y', 'TN07Y', 'TN10Y', 'TB30Y'};
treasuryNames = {'4-Week BILL';
    '13-Week BILL';
    '26-Week BILL';
    '52-Week BILL';
    '2-Year NOTE';
    '3-Year NOTE';
    '5-Year NOTE';
    '7-Year NOTE';
    '10-Year NOTE';
    '30-Year BOND'};

treasuries = table(treasuryLabels', treasuryNames, 'VariableNames', {'Label', 'Name'});

%% create overview table

allAuctionDates = [TB04W_dates;
    TB13W_dates;
    TB26W_dates;
    TB52W_dates;
    TN02Y_dates;
    TN03Y_dates;
    TN05Y_dates;
    TN07Y_dates;
    TN10Y_dates;
    TB30Y_dates];
    
allLabels = [repmat({'TB04W'}, length(TB04W_dates), 1);
    repmat({'TB13W'}, length(TB13W_dates), 1);
    repmat({'TB26W'}, length(TB26W_dates), 1);
    repmat({'TB52W'}, length(TB52W_dates), 1);
    repmat({'TN02Y'}, length(TN02Y_dates), 1);
    repmat({'TN03Y'}, length(TN03Y_dates), 1);
    repmat({'TN05Y'}, length(TN05Y_dates), 1);
    repmat({'TN07Y'}, length(TN07Y_dates), 1);
    repmat({'TN10Y'}, length(TN10Y_dates), 1);
    repmat({'TB30Y'}, length(TB30Y_dates), 1)];

auctions = table(allAuctionDates, allLabels, 'VariableNames', {'AuctionDate', 'Label'});

auctions.Name = replaceVals(allLabels, treasuries, 'Label', 'Name');
auctions.Weekday = datestr(auctions.AuctionDate, 'ddd');
auctions.Date = datestr(auctions.AuctionDate, 'mmm-dd-yyyy');
auctions = sortrows(auctions, 'AuctionDate');

%% write to disk

writetable(auctions, 'notes/artificialAuctions.csv')



