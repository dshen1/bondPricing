%% analyse holdings of real bond ETF

holdings = readtable('../notes/IBTM_holdings_Aug_04_2016.csv');

% split into bonds and notes
allTNotes = selRowsProp(holdings, 'Name', 'TREASURY NOTE');
allTBonds = selRowsProp(holdings, 'Name', 'TREASURY BOND');

% show weights of bonds and notes
classWgts = array2table([sum(allTNotes.Weight), sum(allTBonds.Weight)],...
    'VariableNames', {'NOTES', 'BONDS'})

%% plot chosen maturities

subplot(1, 2, 1)
% get weights per maturity
stem(datenum(allTNotes.Maturity), allTNotes.Weight)
datetick 'x'
grid on
grid minor

% include date ranges for eligible bonds
thisDate = datenum('2016-08-04');
thisMin = thisDate + 7*365;
thisMax = thisDate + 10*365;

hold on
yLim = get(gca, 'YLim');
plot([thisMin, thisMin], yLim, '-r')
plot([thisMax, thisMax], yLim, '-r')
hold off

title('Maturities of T-Notes')
xlabel('Maturity')
ylabel('Weight')

subplot(1, 2, 2)
% get weights per maturity
stem(datenum(allTBonds.Maturity), allTBonds.Weight)
datetick 'x'
grid on
grid minor

% include date ranges for eligible bonds
thisDate = datenum('2016-08-04');
thisMin = thisDate + 7*365;
thisMax = thisDate + 10*365;

hold on
yLim = get(gca, 'YLim');
plot([thisMin, thisMin], yLim, '-r')
plot([thisMax, thisMax], yLim, '-r')
hold off

title('Maturities of T-Bonds')
xlabel('Maturity')
ylabel('Weight')

