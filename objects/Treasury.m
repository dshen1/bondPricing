classdef Treasury
    %Treasury Treasury security
    %   
    
    properties (SetAccess = immutable)
        Type
        AuctionDate
        NTerm
        Name
        FullName
        Maturity
        Period
        Basis
        CouponRate
        ID
        NominalValue
    end
    
    methods
        %% constructor
        function obj = Treasury(treasuryType, nTerm, auctionDate, GS)
            % preallocation without input
            if nargin == 0
                
            else
                
                if ~exist('GS', 'var')
                    GS = GlobalSettings();
                end
                
                % initialize treasury security
                obj.Type = treasuryType;
                obj.AuctionDate = datenum(auctionDate);
                obj.NTerm = nTerm;
                obj.NominalValue = 100;
                
                % get type specific conventions
                res = ll_getTypeConventions(obj);
                
                % set other properties
                obj.Name = [obj.Type '_' num2str(obj.NTerm) '_' res.timeExt];
                obj.FullName = [num2str(obj.NTerm) res.fullName];
                obj.Period = res.period;
                obj.Basis = res.basis;
                obj.Maturity = ll_getMaturity(obj, GS);
                
                % not yet finished
                obj.CouponRate = 0.02;
                
                % get unique identifier
                obj.ID = [obj.Name '_' datestr(obj.Maturity, GS.DateIDFormat)];
                
            end
        end
        
        %% high-level user interface methods

        % get cash-flow dates
        function dats = cfdates(obj)
            dats = cfdates(obj.AuctionDate, obj.Maturity, obj.Period, obj.Basis);
            
            % make business days
            dats = makeBusDate(dats, 'follow');
            
            assert(all(dats <= obj.Maturity))
        end
        
        
        % get cash-flows
        function cfs = cfs(obj)
            % get cash-flow dates
            dats = cfdates(obj);
            
            % get cash-flow values
            cfVals = obj.CouponRate .* obj.NominalValue; % coupons
            cfVals(end) = cfVals + obj.NominalValue;
            
            % make table
            cfs = array2table([dats(:) cfVals(:)], 'VariableNames', {'Date', 'CF'});
        end
        
        % check whether treasury security is traded at given date
        function inRange = isTraded(obj, thisDate)
            if isscalar(obj)
                inRange = obj.AuctionDate <= thisDate && thisDate <= obj.Maturity;
            else % array of treasuries
                inRange = [obj.AuctionDate]' <= thisDate & thisDate <= [obj.Maturity]';
            end
        end

        % create info-table with main treasury characteristics
        function infoTable = summaryTable(obj)
            % create table with most important information
            nObjs = length(obj);
            allTypes = {obj.FullName}';
            allMaturs = [obj.Maturity]';
            allMatursString = cellstr(datestr(allMaturs));
            allCoupons = num2str([obj.CouponRate]'*100);
            allCoupons = [allCoupons repmat(' %', nObjs, 1)];
            allMatursInDays = [obj.Maturity]' - [obj.AuctionDate]';
            infoTable = table(allTypes, allCoupons, ...
                allMatursString, allMatursInDays,...
                'VariableNames', {'TreasuryType', 'CouponRate', ...
                'Maturity', 'MaturityInDays'});
        end

        %% low-level helper functions
        
        % get maturity of treasury security
        function res = ll_getTypeConventions(obj)
            res = struct();
            switch obj.Type
                case 'TBill'
                    % get unit of time
                    res.timeExt = 'W';
                    res.period = 0; % no coupons
                    res.basis = 2; % actual/360
                    res.fullName = '-Week BILL';
                case {'TNote', 'TBond'}
                    % get unit of time
                    res.timeExt = 'Y';
                    res.period = 2; % biannually
                    res.basis = 0; % actual/actual; not verified yet!!
                    if strcmp(obj.Type, 'TNote')
                        res.fullName = '-Year NOTE';
                    else
                        res.fullName = '-Year BOND';
                    end
            end
        end
        
        function endDate = ll_getMaturity(obj, GS)
                
            % get maturity of bond
            switch obj.Type
                case 'TBill'
                    endDate = obj.AuctionDate + obj.NTerm * 7;
                case {'TNote', 'TBond'}
                    endDate = obj.AuctionDate + obj.NTerm * 365;
            end
            % make business day
            endDate = makeBusDate(endDate, 'previous', GS.Holidays, GS.WeekendInd);
        end
        
        %% display method
        function disp(obj)
            if length(obj) == 1 % single object
                % determine frequency
                switch obj.Period
                    case 0
                        couponFreq = 'Zero coupon';
                    case 1
                        couponFreq = 'Annual';
                    case 2
                        couponFreq = 'Biannual';
                end
                
                % determine day count convention
                switch obj.Basis
                    case 0
                        dConvention = 'actual/actual';
                    case 1
                        dConvention = '30/360';
                    case 2
                        dConvention = 'actual/360';
                    case 3
                        dConvention = 'actual/365';
                    case 4
                        dConvention = '30/360';
                end
                
                disp(['********* Treasury: ' obj.FullName ' ***********'])
                disp(['Type:                 ', obj.Type])
                disp(['Auction date:         ', datestr(obj.AuctionDate)])
                disp(['Maturity date:        ', datestr(obj.Maturity)])
                disp(['Maturity in days:     ', num2str(obj.Maturity - obj.AuctionDate) ' days'])
                disp(['Coupon rate:          ', num2str(obj.CouponRate*100) ' %'])
                disp('  ************* Conventions ***************')
                disp(['Coupon frequency:     ', couponFreq])
                disp(['Day count convention: ', dConvention])
            else
                %%
                infoTable = summaryTable(obj);
                disp(infoTable)
                %%
            end
        end
        
    end
    
end

