function [yields, fowRates] = svenssonYields(params, maturs)
% get forward rates from Svensson model
%
% Inputs:
%   params      nx6 matrix of parameters
%   maturs      vector of maturities

% make sure that params are given as row
assert(size(params, 2) == 6)

% make maturities row vector
maturs = maturs(:)';

% get number of different parameter settings / maturities
nDays = size(params, 1);
nMaturs = length(maturs);

% extract parameters
beta0 = repmat(params(:, 1), 1, nMaturs);
beta1 = repmat(params(:, 2), 1, nMaturs);
beta2 = repmat(params(:, 3), 1, nMaturs);
beta3 = repmat(params(:, 4), 1, nMaturs);
tau1 = repmat(params(:, 5), 1, nMaturs);
tau2 = repmat(params(:, 6), 1, nMaturs);

% get helping terms to reduce computational burden
term1 = repmat(maturs, nDays, 1)./tau1;
term2 = repmat(maturs, nDays, 1)./tau2;
expTerm1 = exp(-term1);
expTerm2 = exp(-term2);

% calculate forward rates elementwise
fowRates = beta0 + beta1.*expTerm1 + beta2.*term1.*expTerm1 + beta3.*term2.*expTerm2;

% calculate continuously compounded zero-coupon yields elementwise
yields = beta0 + beta1.*(1 - expTerm1)./term1 + ...
    beta2.*( (1 - expTerm1)./term1 - expTerm1) +...
    beta3.*( (1 - expTerm2)./term2 - expTerm2);

end