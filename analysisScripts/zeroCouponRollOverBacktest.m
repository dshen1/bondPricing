%% load historic estimated parameters

fname = fullfile(dataDir, 'paramsData_FED.csv');
paramsTable = readtable(fname);
paramsTable = paramsTable(~any(isnan(paramsTable{:, :}), 2), :);

%% define strategy parameters

stratParams.currPrice = 1;
stratParams.strategyDuration = 8;
stratParams.rollFreq = 250; % rolling frequency in BUSINESS days

% get length of backtest
nBtDays = size(paramsTable, 1);

% preallocation
allPrices = nan(nBtDays, 1);

%% initialize strategy

paramsMatrix = paramsTable{:, 2:end};

% get current maturity in business days
nBusDaysToFirstExpiry = stratParams.strategyDuration*250;

% get associated expiry date
expiryDate = paramsTable.Date(nBusDaysToFirstExpiry + 1); % running variable, each rebalance
currDate = paramsTable.Date(1);
currMaturInYears = (expiryDate - currDate)/365;

% get current guaranteed yield
guarteedYield = svenssonYields(paramsMatrix(1, :), currMaturInYears);

% get guaranteed payoff
currPrice = stratParams.currPrice; % running variable, daily
guarteedPayOff = currPrice * exp(guarteedYield/100 * currMaturInYears); % running variable, each rebalance

% iterate over days
for ii=2:nBtDays
    
    % update variables
    currDate = paramsTable.Date(ii);
    currMaturInYears = (expiryDate - currDate)/365;
    currYield = svenssonYields(paramsMatrix(ii, :), currMaturInYears);
    currPrice = guarteedPayOff * exp((-1)*currYield/100 * currMaturInYears);
    
    % store for later
    allPrices(ii) = currPrice;
    
    % if rebalancing is required
    if ii==1 || mod(ii, stratParams.rollFreq) == 0 % update guaranteed payoff
        
        % push expiry further into future
        xxInd = nBusDaysToFirstExpiry + ii;
        if xxInd > nBtDays
            busDayOverlap = xxInd - nBtDays;
            expiryDate = paramsTable.Date(end) + busDayOverlap * (7/5);
        else
            expiryDate = paramsTable.Date(nBusDaysToFirstExpiry + ii); % running variable, each rebalance
        end
        
        % update guaranteed payoff
        currMaturInYears = (expiryDate - currDate)/365;
        
        % get current guaranteed yield
        guarteedYield = svenssonYields(paramsMatrix(ii, :), currMaturInYears);
        guarteedPayOff = currPrice * exp(guarteedYield/100 * currMaturInYears);
        
    end
end
