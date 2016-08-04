function discFacts = yieldToDiscount(maturs, yields)
% transform yields to discount factors
% 
% Inputs:
%   maturs  nx1 vector of maturities
%   yields  nx1 vector of yields
%
% Outputs:
%   discFacts   nx1 vector of discount rates

% calculate discount factors
discFacts = exp((-1)*maturs .* yields);

