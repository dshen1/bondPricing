function discFacts = yieldToDiscount(yields)
% transform yields to discount factors
% 
% Inputs:
%   yields  nx2 table with maturities and yields
%
% Outputs:
%   discFacts   nx2 table with discount rates and associated maturities

% calculate discount factors
discFacts = exp((-1)*yields{:, 2} .* yields{:, 1});

% attach meta data
discFacts = array2table([yields{:, 1} discFacts(:)], 'VariableNames', {'Maturity', 'DiscFact'});
