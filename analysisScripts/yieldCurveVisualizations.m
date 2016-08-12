%% script to find best visualization method for yield curves

% load historic estimated Svensson parameters
dataDir = '../priv_bondPriceData';
fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);

% remove days with NaN in parameters
paramsTable = paramsTable(~any(isnan(paramsTable{:, 2:end}), 2), :);

%% define granularity of surface plot

% specify high granularity to evaluate yield curves
allMaturs = [0.1:0.1:30];

% get yields / foward rates
[fullYields, fowRates] = svenssonYields(paramsTable{:, 2:end}, allMaturs);

% get full grid matrices
fullMaturGrid = repmat(allMaturs, size(paramsTable, 1), 1);
fullTimeGrid = repmat(paramsTable.Date, 1, length(allMaturs));

%% define granularity for plots

% define maturity granularity
maturs = allMaturs(1:5:find(allMaturs == 30));
[~, matursInds] = ismember(maturs, allMaturs);
matursInds = matursInds(matursInds > 0);

% define date granularity
freq = 10; 
dateInds = 1:freq:length(paramsTable.Date);

% get respective data
timeGrid = fullTimeGrid(dateInds, matursInds);
maturGrid = fullMaturGrid(dateInds, matursInds);
yields = fullYields(dateInds, matursInds);

%% with gray lines and very fine grids
% works best with very granular grid for maturities

mesh(fullTimeGrid, fullMaturGrid, fullYields, 'EdgeColor', [0.8 0.8 0.8]);
hold on;
datetick 'x'
grid on
grid minor
view(20, 20)
camlight

%% jet color scale with light

h = surf(timeGrid, maturGrid, yields);
set(h, 'EdgeColor', 'none')
shading interp
camlight
view(20, 20)
lighting gouraud
camproj perspective
datetick 'x'
grid on
grid minor
caxis([0 12])

%% jet color scale with bright light

h = surf(timeGrid, maturGrid, yields);
set(h, 'EdgeColor', 'none')
shading interp
camlight
view(20, 20)
lightangle(90,-20)
lighting gouraud
camproj perspective
datetick 'x'
grid on
grid minor
caxis([0 12])


%% gray color scale

h = surf(timeGrid, maturGrid, yields);
set(h, 'EdgeColor', 'none')
shading interp
colormap gray
camlight
view(20, 20)
lighting gouraud
camproj perspective
datetick 'x'
grid on
grid minor
caxis([-8 12])


%%
surf(timeGrid, maturGrid, yields)
shading interp
camlight
lightangle(160,20)
view(34, 20)
datetick 'x'
xlabel('Maturity')
ylabel('Year')
title('Continuously compounded annualized treasury yields')


%% pink color scale

surfl(timeGrid, maturGrid, yields)
shading interp
colormap pink
camlight
view(20, 20)
lightangle(160, 0)
lighting gouraud
datetick 'x'
xlabel('Maturity')
ylabel('Year')
title('Continuously compounded annualized treasury yields')


