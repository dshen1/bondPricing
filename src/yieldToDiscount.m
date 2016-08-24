function discFacts = yieldToDiscount(maturs, yields)
% transform yields to discount factors
% 
% Inputs:
%   maturs  nx1 vector of maturities
%   yields  nx1 vector of yields
%
% Outputs:
%   discFacts   nx1 vector of discount rates

if any(yields > 1)
    error('bondPricing:yieldToDiscount', ['Some yield larger than 1.\n'...
        'Yields have to be given as fractional values, '...
        'and not in percent'])
end

% calculate discount factors
discFacts = exp((-1)*maturs .* yields);

