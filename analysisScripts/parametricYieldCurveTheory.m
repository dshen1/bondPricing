%% nelson-siegel introductory pics and stylized yield curve facts


%% set up general settings

genInfo.pos = [50 50 1200 600];
genInfo.GS = GlobalSettings();
genInfo.fmt = 'png'; % define default figure format
genInfo.figClose = true;
genInfo.picsDir = '../../dissDataAndPics/bondPricing/pics/devPics';

% set data directory
dataDir = '../priv_bondPriceData';

%% load historic estimated parameters

fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, :}), 2), :);

%% define maturities of interest

% maturities are given in years
genInfo.maturs = [0.25 1 4 7 10 20 30];

xx = cellstr(num2str(genInfo.maturs'));
xx = strrep(xx, ' ', '');
xx = strcat(xx, ' years');
genInfo.maturNames = xx;

xx = strcat('y', num2str(genInfo.maturs'));
xx = strrep(cellstr(xx), ' ', '');
xx = strrep(xx, '.', '_');
genInfo.maturColNames = xx;

% get maturity names, colors, ...
genInfo.nMaturs = length(genInfo.maturs);

xx = ['jet(' num2str(genInfo.nMaturs) ')'];
genInfo.maturColors = colormap(xx);

close;

%% get associated yields

histYields = svenssonYields(paramsTable{:, 2:end}, genInfo.maturs);

%% eliminate extrapolated yields

histYields = avoidExtrapolation(histYields, paramsTable.Date, genInfo.maturs, true);

%% attach meta-data

histYields = array2table(histYields, 'VariableNames', genInfo.maturColNames);
histYields = [paramsTable(:, 'Date'), histYields];

% histYields = histYields(histYields.Date > datenum('1990-01-01'), :);

%% Visualize interest rate environment

allMaturs = genInfo.maturs;

% get full grid matrices
fullMaturGrid = repmat(allMaturs, size(paramsTable, 1), 1);
fullTimeGrid = repmat(paramsTable.Date, 1, length(allMaturs));

% define maturity granularity
maturs = allMaturs;
[~, matursInds] = ismember(maturs, allMaturs);
matursInds = matursInds(matursInds > 0);

% define date granularity
freq = 10; 
dateInds = 1:freq:length(paramsTable.Date);

% get respective data
timeGrid = fullTimeGrid(dateInds, matursInds);
maturSurfaceGrid = fullMaturGrid(dateInds, matursInds);

fullYields = histYields(:, 2:end);
yields = fullYields{dateInds, matursInds};

%% visualize yield curve surface

% plot yield curves over time
f = figure('Position', genInfo.pos);

h = surf(timeGrid, maturSurfaceGrid, yields);
set(h, 'EdgeColor', 'none')
shading interp
camlight
view(15, 40)
lighting gouraud
camproj perspective
datetick 'x'
set(gca, 'XTickLabelRot', 45)
grid on
grid minor
caxis([0 12])

% write to disk
exportFig(f, 'yieldCurveSurface_noExtrapolation', genInfo.picsDir, genInfo.fmt, genInfo.figClose)

%% visualize yields of selected maturities over time

f = figure('pos', genInfo.pos);

for ii=1:genInfo.nMaturs
    hold on;
    plot(histYields.Date, histYields{:, ii+1}, 'Color', genInfo.maturColors(ii, :))
end
datetick 'x'
xlabel('Date')
ylabel('Yield')
set(gca, 'XTickLabelRotation', 45)
title('Continuously compounded yield (%)')
grid minor
legend(genInfo.maturNames, 'Location', 'NorthWest')

exportFig(f, 'selectedYieldsOverTime', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% stylized facts: term premium 

f = figure('pos', genInfo.pos);

plot(histYields.Date, histYields.y10 - histYields.y0_25)
datetick 'x'
xlabel('Date')
ylabel('30 year yield - 1 year yield')
set(gca, 'XTickLabelRotation', 45)
title('Term premium')
grid minor

exportFig(f, 'yieldCurveSlopeOverTime', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% stylized facts: yield distributions

f = figure();

boxplot(histYields{:, 2:end}, genInfo.maturs)
grid minor
xlabel('Maturity in years')
ylabel('Yield')

exportFig(f, 'yieldCurveDistributions', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% stylized facts: yield change distributions

f = figure();

boxplot(diff(histYields{:, 2:end}), genInfo.maturs)
grid minor
xlabel('Maturity in years')
ylabel('Yield change')

exportFig(f, 'yieldChangeDistributions', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)


%% stylized facts: relative yield change distributions

f = figure();

xx = diff(histYields{:, 2:end}) ./ histYields{1:end-1, 2:end};
boxplot(xx, genInfo.maturs)
grid minor
xlabel('Maturity in years')
ylabel('Relative yield change')

exportFig(f, 'yieldRelChangeDistributions', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% Yield correlations: different maturities

f = figure();

yieldCorrs = corr(histYields{:, 2:end}, 'rows', 'pairwise');
imagesc(yieldCorrs, [min(min(yieldCorrs)), 1])
set(gca, 'XTick', 1:genInfo.nMaturs)
set(gca, 'XTickLabel', genInfo.maturNames)
set(gca, 'XTickLabelRot', 45)
set(gca, 'YTick', 1:genInfo.nMaturs)
set(gca, 'YTickLabel', genInfo.maturNames)
xlabel('Maturity')
ylabel('Maturity')
title('Interest rate correlations')
colorbar()

exportFig(f, 'yieldCorrelations', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% Yield dependencies: different maturities

f = figure('pos', genInfo.pos);

maturSset = [1, 2, 4, 7];
nMaturSset = length(maturSset);

counter = 1;
for ii=[1, 7]
    for jj=1:nMaturSset
        if ii == maturSset(jj)
            
        else
            subplot(2, nMaturSset, counter)
            xx = [histYields{:, maturSset(jj)+1}, histYields{:, ii+1}];
            xx = xx(~any(isnan(xx), 2), :);
            U = ranks(xx);
            plot(U(:, 1), U(:, 2), '.')
            xlabel(genInfo.maturNames(maturSset(jj)))
            ylabel(genInfo.maturNames(ii))
            grid minor
            axis square
        end
        counter = counter + 1;
    end
end

exportFig(f, 'yieldDependencies', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% Dependence over time

nLags = 100;
for ii=1:genInfo.nMaturs;
    subplot(2, 4, ii)
    xx = histYields{:, ii+1};
    xx = xx(~any(isnan(xx), 2), :);
    U = ranks([xx(1:end-nLags), xx(nLags+1:end)]);
    plot(U(:, 1), U(:, 2), '.')
    grid minor
    axis square
end


%% plot loadings of Svensson yield curve

load1 = @(x, alpha)((1-exp(-x./alpha))./(x./alpha));
load2 = @(x, alpha)((1-exp(-x./alpha))./(x./alpha) - exp(-x./alpha));

xxGrid = [0.000001, 0.1:0.1:30];

f = figure();

plot(xxGrid, ones(size(xxGrid)), '-.')
hold on
plot(xxGrid, load1(xxGrid, 2.5), '--')
plot(xxGrid, load2(xxGrid, 2.5), '-')
text(15, 0.5, '\alpha=2.5', 'FontSize', 14)
grid minor
set(gca, 'YLim', [0, 1.1])
xlabel('Maturity')
title('Nelson-Siegel loadings')
l = legend('\beta_{0}', '\beta_{1}', '\beta_{2}', 'Location', 'SouthOutside',...
    'Orientation', 'Horizontal');
set(l, 'FontSize', 12)

exportFig(f, 'nelsonSiegelLoadings', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)

%% split up nelson siegel curve

xxInd = find(paramsTable.Date == datenum('2006-05-09'));
ycParams = paramsTable(xxInd, :);

load1 = @(x, alpha)((1-exp(-x./alpha))./(x./alpha));
load2 = @(x, alpha)((1-exp(-x./alpha))./(x./alpha) - exp(-x./alpha));

xxGrid = [0.000001, 0.1:0.1:30];


f = figure();

plot(xxGrid, ycParams.BETA0*ones(size(xxGrid)), '-.')
hold on
plot(xxGrid, ycParams.BETA1*load1(xxGrid, ycParams.TAU1), '--')
plot(xxGrid, ycParams.BETA2*load2(xxGrid, ycParams.TAU1), '-')
plot(xxGrid, ycParams.BETA3*load2(xxGrid, ycParams.TAU2), '-')
grid minor
xlabel('Maturity')
title('Nelson-Siegel components')
l = legend('\beta_{0}', '\beta_{1}', '\beta_{2}', '\beta_{3}', 'Location', 'SouthOutside',...
    'Orientation', 'Horizontal');
set(l, 'FontSize', 12)

%%
exportFig(f, 'nelsonSiegelComponents', genInfo.picsDir, genInfo.fmt, genInfo.figClose, true)


%% plot level, slope and curvature components over time
% get values over time

% preallocation
nDays = size(paramsTable.Date, 1);
allLevels = ones(nDays, size(xxGrid, 2));
allSlopes = ones(nDays, size(xxGrid, 2));
allCurvatures = ones(nDays, size(xxGrid, 2));

for ii=1:nDays
    ycParams = paramsTable(ii, :);
    allLevels(ii, :) = ycParams.BETA0*ones(size(xxGrid));
    %allSlopes(ii, :) = ycParams.BETA1*load1(xxGrid, ycParams.TAU1);
    allSlopes(ii, :) = load1(xxGrid, ycParams.TAU1);
    %xx = ycParams.BETA2*load2(xxGrid, ycParams.TAU1) + ...
    %    ycParams.BETA3*load2(xxGrid, ycParams.TAU2);
    xx = load2(xxGrid, ycParams.TAU1) + ...
        load2(xxGrid, ycParams.TAU2);
    allCurvatures(ii, :) = xx;
end

%%
% plot values
% not really meaningful?!


% get full grid matrices
fullMaturGrid = repmat(xxGrid, nDays, 1);
fullTimeGrid = repmat(paramsTable.Date, 1, length(xxGrid));

% define date granularity
freq = 10; 
dateInds = 1:freq:length(paramsTable.Date);

% define maturity granularity
maturs = xxGrid;
[~, matursInds] = ismember(maturs, [maturs(1), 1:1:30]);
%matursInds = matursInds(matursInds > 0);
matursInds = matursInds > 0;

% get respective data
timeGrid = fullTimeGrid(dateInds, matursInds);
maturSurfaceGrid = fullMaturGrid(dateInds, matursInds);

%surf(timeGrid, maturSurfaceGrid, allCurvatures(dateInds, matursInds))
surf(timeGrid, maturSurfaceGrid, allSlopes(dateInds, matursInds))
datetick 'x'
grid minor

%%
% plot quantiles around all curvatures
% not really meaningful?!

xx = allCurvatures;
xx = quantile(xx, [0.25, 0.75]);

plot(xx')
hold on
plot(allCurvatures(1:1000:end, :)')
grid minor





