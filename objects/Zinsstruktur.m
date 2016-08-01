classdef Zinsstruktur
    %Zinsstruktur
    
    properties (SetAccess = immutable)
        paramsSv                        %Svensson Parameters
    end
    
    methods
        %%constructor
        function obj = Zinsstruktur(paramsSv)
            if nargin == 0
            
            else
                obj.paramsSv = paramsSv;
            end
        end
        
        
        %% Helper Functions
        
        % get spot Rates for specific maturities 
        function spotRates = getSpotRates(obj, maturs)
            xxspotRates = svenssonYields(obj.paramsSv, maturs);
            names = {'Maturity','SpotRate'};
            spotRates = table(maturs',xxspotRates','VariableNames',names); 
        end
        
        % get Zero Bond Prices for specific maturities
        function zeroBP = getZeroBondPrices(obj, maturs)
            %get spotRates
            spotRates = getSpotRates(obj, maturs);
            
            %Calculate Zero Bond Prices
            xxzeroBP = exp((-spotRates.SpotRate/100)' .* maturs);
            names = {'Maturity','ZBP'};
            zeroBP = table(maturs',xxzeroBP','VariableNames',names);
        end
    end

end

