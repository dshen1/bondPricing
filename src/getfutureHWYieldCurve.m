function yieldCurve = getfutureHWYieldCurve(params, todaysZCB, shortRate, maturs, year)
    % get future yield curve
    %
    % Inputs:
    %   params            alpha and sigma of the Hull-White model
    %   todaysZCB         scolumn vector with todays Zero Coupon Bonds
    %   shortRate         Short rate at timepoint year
    %   maturs            vector of maturities
    %   year              future date                      
    %
    % Output
    % yieldCurve          column vector with the future spot interest rate curve

    % make sure params are given 
    assert(size(params,2) == 2)

    % get number of different parameter settings/maturities
    nMaturs = length(maturs);
    yieldCurve = zeros(nMaturs,1);

    % extract parameters
    alpha = params(1);
    sigma = params(2);

    % extract required terms
    ableitungsterm = (log(todaysZCB(year + 1)) - log(todaysZCB(year - 1))) / 2;

    for ii = 1:nMaturs
        % Calculate A and B
        B = (1-exp(-alpha*maturs(ii)));

        xxT = year + maturs(ii);
        xxterm1 = -B*ableitungsterm;
        xxterm2 = sigma^2*(exp(-alpha*xxT) - exp(-alpha*year))^2 *...
            (exp(2*alpha*year) - 1) / (4 * alpha^3);

        A = todaysZCB(xxT) / todaysZCB(year) * exp(xxterm1 - xxterm2); 

        % Calculate yield curve
        yieldCurve(ii) = (B * shortRate - log(A)) / (maturs(ii)); 
    end

end