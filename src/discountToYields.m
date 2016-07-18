function yields = discountToYields(discFacts)
% transform discount factors to yields
% 
% Inputs:
%   discFacts   nx2 table with discount rates and associated maturities
%
% Outputs:
%   yields      nx2 table with yields and associated maturities

% calculate yields
yields = -log(discFacts{:, 1})./discFacts{:, 2};

% attach meta data
yields = array2table(yields, 'VariableNames', {'Yield', 'Maturity'});
