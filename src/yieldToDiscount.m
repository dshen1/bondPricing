function discFacts = yieldToDiscount(yields)
% transform yields to discount factors
% 
% Inputs:
%   yields  nx2 table with yields and associated maturities
%
% Outputs:
%   discFacts   nx2 table with discount rates and associated maturities

% calculate discount factors
discFacts = exp((-1)*yields{:, 1} .* yields{:, 2});

% attach meta data
discFacts = array2table(discFacts, 'VariableNames', {'DiscFact', 'Maturity'});
