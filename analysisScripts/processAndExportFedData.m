%% process historic FED data and write to disk as .csv
%
% Loading historic FED values is quite cumbersome:
% - .xls files are too large to be loaded
% - .xml files are not correctly processed by MATLAB out of the box
%
% .xml files basically have to be processed manually through regexp
% matches.
%
% Raw data can be downloaded from: 
% https://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
%
% Raw data needs to be extracted and put into directory TODO!
%
% The script can then be run and it exports Svensson yield curve parameters
% as .csv file.

%% try to read in FED historic rates

% define path to extracted file
fname = '../priv_bondPriceData/rawData/feds200628/feds200628.xml';

fid = fopen(fname);
fedDataLines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
fedDataLines = fedDataLines{1};

%% get rows containing series names
% apply regexp that searches for 'SERIES_NAME'
% - get row indices containing series names
% - get series names

% get number of rows over which to iterate
nRows = size(fedDataLines, 1);

% prellocate
isSeriesNameRow = false(nRows, 1);
allSeriesNames = cell(0, 1);

for ii=1:nRows
    xx = regexp(fedDataLines{ii}, 'SERIES_NAME="(\w+)"', 'tokens');
    if ~isempty(xx)
        isSeriesNameRow(ii) = true;
        allSeriesNames = [allSeriesNames; xx{1}];
    end
end
allSeriesInds = find(isSeriesNameRow);

%% create series identifier
% each row needs to be associated with a series

% iterate over series
nSeries = length(allSeriesInds);
seriesStarts = [1; allSeriesInds];

% for how many rows does each series hold
nReps = diff([1; allSeriesInds; nRows]);

% preallocate
seriesIds = cell(nRows, 1);

for ii=1:(nSeries+1)
    if ii==1
        thisSeriesName = 'SKIP';
    else
        thisSeriesName = allSeriesNames{ii- 1}; 
    end
    seriesIds(seriesStarts(ii):seriesStarts(ii)+nReps(ii)-1) = repmat({thisSeriesName}, nReps(ii), 1);
end

%% get observations
% parse each row to identify whether it contains metadata or an
% observation.

% preallocate
obsVals = nan(nRows, 1);
obsDats = cell(nRows, 1);
isMetaData = false(nRows, 1);

for ii=1:nRows
    [val, dat, metaDataId] = ll_extractObsVals(fedDataLines{ii});
    
    obsVals(ii) = val;
    obsDats{ii} = dat;
    isMetaData(ii) = metaDataId;
end

%% put observation values and series identifier together

dataTab = table(seriesIds, obsDats, obsVals, isMetaData, 'VariableNames', ...
    {'Name', 'Date', 'Value', 'IsMeta'});

% skip irrelevant rows
dataTab = dataTab(~dataTab.IsMeta, :);
dataTab.IsMeta = [];

% modify dates
dataTab.Date = datenum(dataTab.Date);

%% unstack to wide format

dataTabWide = unstack(dataTab, 'Value', 'Name');

%% only export yield curve parameters

% get yield curve parameters only
paramsTable = dataTabWide(:, {'Date', 'BETA0', 'BETA1', 'BETA2', 'BETA3', 'TAU1', 'TAU2'});

% write result to disk
fname = '../priv_bondPriceData/paramsData_FED.csv';
writetable(paramsTable, fname)

