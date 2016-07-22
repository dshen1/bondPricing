classdef UnitTestsTreasuries < matlab.unittest.TestCase
    
    properties
        % oldPath
    end
    
    methods(TestClassSetup)
        
        function setPaths(testCase)
            addpath(genpath('../'))
        end
        
    end
    
    methods (Test)
        %% makeBusDay()
        function testMakeBusDay(testCase)
           GS = GlobalSettings();
           % test moving of holiday
           xx = GS.Holidays;
           thisDate = xx(ceil(length(xx)/2));
           testCase.verifyTrue(makeBusDate(thisDate, 'previous') == thisDate - 1)
           testCase.verifyTrue(makeBusDate(thisDate, 'follow') == thisDate + 1)
           
           % test no action for business day
           thisDate = datenum('2016-07-22');
           testCase.verifyTrue(makeBusDate(thisDate, 'follow') == thisDate)
        end
        
        %% Treasury.isTraded()
        function testIsTraded(testCase)
            objTreasury = Treasury('TBill', 4, '2016-04-04');
            lastDay = objTreasury.Maturity;
            testCase.verifyTrue(isTraded(objTreasury, datenum('2016-04-21')))
            testCase.verifyTrue(~isTraded(objTreasury, lastDay + 2));
            testCase.verifyTrue(~isTraded(objTreasury, datenum('2016-04-02')));
        end
        
        %% Treasury.disp()
        function testDispTreasury(testCase)
            objTreasury = Treasury('TBill', 4, '2016-04-04');
            disp('\n')
            disp('***********************************************')
            disp('********* Unit test: display method ***********')
            disp('***********************************************')
            disp('')
            disp(objTreasury)
            disp('\n')
        end
    end
    
end