function histYields = avoidExtrapolation(histYields, histDates, maturs, doExtrapTo10)
% set yields to NaN whenever they would be extrapolated
%
% Inputs:
%   doExtrapTo10        allow exeption to extrapolate yields to 10 years
%                       also in the very first years where we actually
%                       observed maximum 7 year bonds. 


% define extrapolation borders
firstTenYear = datenum('1971-08-16');
firstFifteen = datenum('1971-11-15');
firstTwenty = datenum('1981-07-02');
firstThirty = datenum('1985-11-25');

% allow or disallow interpolation to 10 years
xxDateInds = histDates < firstTenYear;
if doExtrapTo10
    xxMaturInds = maturs > 10;
else
    xxMaturInds = maturs > 7;
end
histYields(xxDateInds, xxMaturInds) = NaN;

% skip maturities larger than 10
xxDateInds = histDates < firstFifteen;
xxMaturInds = maturs > 10;
histYields(xxDateInds, xxMaturInds) = NaN;

% skip maturities larger than 15
xxDateInds = histDates < firstTwenty;
xxMaturInds = maturs > 15;
histYields(xxDateInds, xxMaturInds) = NaN;

% skip maturities larger than 20
xxDateInds = histDates < firstThirty;
xxMaturInds = maturs > 20;
histYields(xxDateInds, xxMaturInds) = NaN;