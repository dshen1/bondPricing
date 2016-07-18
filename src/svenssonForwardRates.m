function fwdRates = svenssonForwardRates(params, days)
% get forward rates for given Svensson model
%
% Inputs:
%   params      1x  vector of model parameters
%   days        nx1 vector of dates to get forward rate
%
% Outputs:
%   fwdRates    nx1 vector of associated forward rates

beta0 = params(1);
beta1 = parmas(2);
beta2 = params(3);
beta3 = params(4);
