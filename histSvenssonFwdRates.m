% load historic svensson parameters

histParams = readtable('../data/paramsData_FED.csv');

% eliminate NAs
xxInds = ~all(isnan(histParams{:, 2:end}), 2);
histParams = histParams(xxInds, :);

%%

maturs = [0.3, 1:1:30];
nMaturs = length(maturs);

%% calculate forward rates

nObs = size(histParams, 1);

% preallocation
fwdRates = zeros(nObs, nMaturs);

for ii=1:nObs
    % get forward rates
    fwdRates(ii, :) = svenssonForwardRates(histParams{ii, 2:end}, maturs)';
end

fwdRates = [histParams(:, 'Date') array2table(fwdRates)];

%%

[xxGrid, yyGrid] = meshgrid(histParams.Date, maturs);

mesh(xxGrid, yyGrid, fwdRates{:, 2:end}')
datetick 'x'
grid on
grid minor
xlabel('Time')
ylabel('Forward rate')
title('Svensson forward rates over time')


