function [yields, fowRates] = svenssonYields(params, maturs)
% get forward rates from Svensson model
%
% Inputs:
%   params      nx6 matrix of parameters
%   maturs      row vector of m maturities or nxm matrix of maturities

% make sure that params are given in row dimension
[nDays, nParams] = size(params);
if nParams ~= 6
    error('bondPricing:svenssonYields', ['Svensson yield curve must be parameterized '...
        'by exactly 6 parameters'])
end

[nRows, nCol] = size(maturs);
if isvector(maturs) % vector of maturities case
    if nRows > 1 && nRows ~= nDays % column vector
        error('bondPricing:svenssonYields', ['If maturities are given as column vector, '...
            'there must be exactly one row of maturities per given yield curve day.'])
    end
elseif nRows > 1 && nCol > 1 % maturities given as matrix
    if nRows ~= size(params, 1)
        error('bondPricing:svenssonYields', ['If maturities are given as matrix, '...
            'there must be exactly one row of maturities per given yield curve day.'])
    end
else
    error('bondPricing:svenssonYields', 'Maturities must be given as vector or matrix')
end

% get number of different parameter settings / maturities
nMaturs = size(maturs, 2);
if size(maturs, 1) == 1
    maturs = repmat(maturs, nDays, 1);
end

% extract parameters
beta0 = repmat(params(:, 1), 1, nMaturs);
beta1 = repmat(params(:, 2), 1, nMaturs);
beta2 = repmat(params(:, 3), 1, nMaturs);
beta3 = repmat(params(:, 4), 1, nMaturs);
tau1 = repmat(params(:, 5), 1, nMaturs);
tau2 = repmat(params(:, 6), 1, nMaturs);

% get helping terms to reduce computational burden
term1 = maturs./tau1;
term2 = maturs./tau2;
expTerm1 = exp(-term1);
expTerm2 = exp(-term2);

% calculate forward rates elementwise
fowRates = beta0 + beta1.*expTerm1 + beta2.*term1.*expTerm1 + beta3.*term2.*expTerm2;

% calculate continuously compounded zero-coupon yields elementwise
yields = beta0 + beta1.*(1 - expTerm1)./term1 + ...
    beta2.*( (1 - expTerm1)./term1 - expTerm1) +...
    beta3.*( (1 - expTerm2)./term2 - expTerm2);

end