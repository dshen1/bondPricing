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
        TreasuryID
        NominalValue
    end
    
    properties (SetAccess = private)
        CouponRate
        CfDates
        CfValues
        CfTable
    end
    
    methods
        %% constructor
        function obj = Treasury(treasuryType, nTerm, auctionDate, GS, cpRate)
            % preallocation without input
            if nargin == 0
                
            else
                
                if ~exist('GS', 'var')
                    GS = GlobalSettings();
                end
                if ~exist('cpRate', 'var')
                    cpRate = 0.02;
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
                
                obj.CouponRate = cpRate;
                
                % get unique identifier
                obj.TreasuryID = [obj.Name '_' datestr(obj.Maturity, GS.DateIDFormat)];
                
                % determine cash-flows
                [dats, cfVals] = ll_cfs(obj);
                obj.CfDates = dats;
                obj.CfValues = cfVals;
                
                % set up cash-flow table
                nams = repmat({obj.TreasuryID}, length(dats), 1);
                cfs = table(nams, dats, cfVals, ...
                    'VariableNames', {'TreasuryID', 'Date', 'CF'});                
                obj.CfTable = cfs;
                
            end
        end
        
        %% high-level user interface methods

        function obj = modifyCouponRate(obj, cpRate)
            notValid = isempty(cpRate) | isnan(cpRate);
            if notValid
                error('Treasury:modifyCouponRate', 'Invalid coupon rate');
            end
            obj.CouponRate = cpRate;
            
            % determine cash-flows
            [dats, cfVals] = ll_cfs(obj);
            obj.CfDates = dats;
            obj.CfValues = cfVals;
            
            % set up cash-flow table
            nams = repmat({obj.TreasuryID}, length(dats), 1);
            cfs = table(nams, dats, cfVals, ...
                'VariableNames', {'TreasuryID', 'Date', 'CF'});
            obj.CfTable = cfs;
        end
        
        % get cash-flows
        function [dats, cfVals] = ll_cfs(obj)
            % get cash-flow dates
            dats = cfdates(obj.AuctionDate, obj.Maturity, obj.Period, obj.Basis);
            
            % make business days
            dats = makeBusDate(dats, 'follow');
            
            % get cash-flow values
            cfVals = dats;
            cfVals(1:end) = obj.CouponRate .* obj.NominalValue; % coupons
            cfVals(end) = cfVals(end) + obj.NominalValue;
        end
        
        % check whether treasury security is traded at given date
        function inRange = isTraded(obj, thisDate)
            if isscalar(obj)
                inRange = obj.AuctionDate <= thisDate & thisDate <= obj.Maturity;
            else % array of treasuries
                inRange = [obj.AuctionDate]' <= thisDate & thisDate <= [obj.Maturity]';
            end
        end

        % create info-table with main treasury characteristics
        function infoTable = summaryTable(obj)
            % create table with most important information
            allNames = {obj.FullName}';
            allAuctions = [obj.AuctionDate]';
            allMaturs = [obj.Maturity]';
            %allMatursString = cellstr(datestr(allMaturs));
            allCoupons = [obj.CouponRate]';
            %allCoupons = num2str([obj.CouponRate]'*100, '%#5.5u');
            %allCoupons = [allCoupons repmat(' %', nObjs, 1)];
            allMatursInDays = [obj.Maturity]' - [obj.AuctionDate]';
            allIDs = {obj.TreasuryID}';
            allTypes = {obj.Type}';
            allTerms = [obj.NTerm]';
            infoTable = table(allNames, allAuctions, allMaturs, ...
                allCoupons, allMatursInDays, categorical(allIDs), allTypes, allTerms, ...
                'VariableNames', {'TreasuryType', 'AuctionDate', 'Maturity', ...
                'CouponRate', 'MaturityInDays', 'TreasuryID', 'Type', 'NTerm'});
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

