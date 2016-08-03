classdef GlobalSettings < handle
    
    properties (SetAccess = immutable)
        %% date / calendar handling
       	DateFormat = 'yyyy-mm-dd';      % standard date format
        Holidays = holidays;            % defined holidays
        WeekdayConventions
        WeekendInd
        DateIDFormat = 'yyyy_mm_dd';    % date format for date IDs
    end
    
%    properties (Dependent)
%    end
    
     methods % Constructor
        function obj = GlobalSettings()
            persistent pers_weekdayConventions
            persistent pers_weekendInd
            
            if isempty(pers_weekdayConventions)
                pers_weekdayConventions = GlobalSettings.getWeekdayConventions();
            end
                
            obj.WeekdayConventions = pers_weekdayConventions;
            
            % get weekend indicators in MATLAB sorting
            if isempty(pers_weekendInd)
                pers_weekendInd = replaceVals(1:7, obj.WeekdayConventions, ...
                    'MatlabNum', 'weekendInd');
            end
            
            obj.WeekendInd = pers_weekendInd;
        end
     end

     %% dependent properties
     methods
         %% display method
         function disp(obj)
             disp('***********************************************');
             disp(['DateFormat:               ''', obj.DateFormat,'''']);
             disp(['Holidays:                 call to ''holidays()''']);
             disp(['WeekdayConventions:       look-up table']);
             disp(['WeekdayInd                ']);
             disp('***********************************************');
         end
         
     end
     
     methods (Static)
         % get lookup table for weekday conventions
         function lookUp = getWeekdayConventions()
             % weekday names
             xxMonToSun = datenum('2016-07-18'):datenum('2016-07-24');
             shortNames = cellstr(datestr(xxMonToSun, 'ddd'));
             [~, longNames] = weekday(xxMonToSun, 'long');
             
             % weekday numeric code
             weekdayCode = [2:7, 1]';
             
             % weekend indicator
             weekend = [0 0 0 0 0 1 1]';
             
             % generate lookup table
             lookUp = table(cellstr(longNames), shortNames, weekdayCode, weekend);
             lookUp.Properties.VariableNames = ...
                 {'weekday', 'weekdayShort', 'MatlabNum', 'weekendInd'};
             
         end
     end
end