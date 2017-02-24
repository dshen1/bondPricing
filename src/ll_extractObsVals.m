function [val, dat, metaDataId] = ll_extractObsVals(thisRow)

% try to match
xx = regexp(thisRow, 'TIME_PERIOD="\d\d\d\d-\d\d-\d\d"', 'match');
if isempty(xx)
    val = NaN;
    dat = '';
    metaDataId = true;
else
    metaDataId = false;
    
    xx = regexp(xx{1}, '\d\d\d\d-\d\d-\d\d', 'match');
    dat = xx{1};
    
    % get observation status
    xx = regexp(thisRow, 'OBS_STATUS="(\w+)"', 'tokens');
    if strcmp(xx{1}, 'ND')
        val = NaN;
    else
        xx = regexp(thisRow, 'OBS_VALUE="(-*[\d\.*\d*]+)" ', 'tokens');
        val = str2double(xx{1});
    end
    
end


