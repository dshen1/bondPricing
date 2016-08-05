%% analyse synthetic historic bond prices


%% find certain treasuries

% find all TBonds
allTBonds = allTreasuries(strcmp({allTreasuries.Type}, 'TBond'));

% get their IDs
tbondNames = {allTBonds.ID};


%%

%xxInd = 3822;

plot(allPricesTable.Date, allPricesTable{:, tbondNames})
grid on
grid minor
datetick 'x'
hold on

cfDats = cfdates(allTBonds(2));
for ii=1:length(cfDats)
    thisCfDat = cfDats(ii);
    
    if thisCfDat < histSvenssonParams.Date(end) & thisCfDat > histSvenssonParams.Date(1)
       plot([thisCfDat thisCfDat], get(gca, 'YLim'), 'r') 
    end
end
hold off
        
    
%% debugging

xx = svenssonBondPrice(allTreasuries(xxInd), histSvenssonParams);

%%

xxBond = allTreasuries(11230);
xx = svenssonCouponRate(xxBond, histSvenssonParams(2364, :));

