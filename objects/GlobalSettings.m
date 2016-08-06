classdef GlobalSettings < handle
    
    properties (SetAccess = immutable)
        %% date / calendar handling
       	DateFormat = 'yyyy-mm-dd';      % standard date format
        Holidays
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
            obj.Holidays = GlobalSettings.ll_getHolidays();
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
         
         function allHolidays = ll_getHolidays()
             % get MATLAB holidays
             builtInHolidays = holidays();
             
             % additionally get days with missing yield curve
             missingYieldDays = [716526;716649;716891;716922;717014;717286;717379;717622;717652;717745;717987;718017;718352;718382;718476;718717;719206;719449;719471;719478;719571;719813;719835;719843;719936;720177;720191;720199;720541;720555;720667;720905;720919;720934;720982;721032;721276;721298;721304;721397;721640;721662;721669;721762;722004;722035;722368;722397;722400;722470;722494;722600;722732;722761;722858;722965;723096;723125;723131;723223;723467;723496;723589;723831;723853;723861;723954;724195;724217;724226;724559;724588;724591;724685;724923;724952;724958;725028;725050;725294;725322;725392;725658;725687;725756;726022;726052;726120;726386;726418;726484;726750;726848;727114;727149;727219;727485;727494;727513;727583;727849;727879;727915;727916;727929;727947;727949;728038;728049;728168;728213;728230;728244;728311;728313;728483;728574;728577;728609;728675;728705;728738;728941;729039;729263;729312;729340;729410;729433;729676;729705;730040;730070;730268;730313;730322;730404;730435;730768;731132;731167;731503;731531;731867;731896;732231;732262;732595;732627;732959;733323;733358;733694;733723;734058;734088;734422;734453;734786;734818;735150;735185;735521;735549;735885;735914;736249;736279];
             
             % attach and sort
             allHolidays = unique([builtInHolidays; missingYieldDays]);
             
         end
     end
     
end