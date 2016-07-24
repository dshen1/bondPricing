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
           
           % test with own array of holidays
           thisDate = datenum('2016-07-22');
           expDate = datenum('2016-07-21');
           testCase.verifyTrue(makeBusDate(thisDate, 'previous', thisDate) == expDate)
        end
        
        %% weekdayBusiness()
        function testWeekdayBusiness(testCase)
           GS = GlobalSettings();
           % get Mondays
           mondayDates = [datenum('2016-07-11');
               datenum('2016-07-18');
               datenum('2016-07-25')];
           
           % test automatic detection of Mondays
           dateRange = datenum('2016-07-10'):datenum('2016-07-26');
           computedDates = weekdayBusiness(dateRange, 'Mon', GS.Holidays);
           testCase.verifyTrue(all(mondayDates == computedDates))
           
           % test automatic detection if one Monday is holiday
           dateRange = datenum('2016-07-10'):datenum('2016-07-26');
           expDates = mondayDates;
           expDates(1) = expDates(1) + 1;
           computedDates = weekdayBusiness(dateRange, 'Mon', mondayDates(1));
           testCase.verifyTrue(all(expDates == computedDates))
           
        end

        %% fourWeekTuesdays()
        function testFourWeekTuesdays(testCase)
            expDates = [datenum('2016-07-19');
                datenum('2016-08-16');
                datenum('2016-09-13')];
            
            dateRange = datenum('2016-07-08'):datenum('2016-09-18');
            GS = GlobalSettings;
            actDates = fourWeekTuesdays(dateRange, GS.Holidays);
            testCase.verifyTrue(all(expDates == actDates))
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
        % single Treasury
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
        
        %% Treasury array
        function testDispTreasuryArray(testCase)
            objTreasury1 = Treasury('TBill', 4, '2016-04-04');
            objTreasury2 = Treasury('TNote', 3, '2016-04-04');
            treasuryArray = [objTreasury1, objTreasury2];
            disp('\n')
            disp('***********************************************')
            disp('********* Unit test: display method ***********')
            disp('***********************************************')
            disp('')
            disp(treasuryArray)
            disp('\n')
        end
    end
    
end