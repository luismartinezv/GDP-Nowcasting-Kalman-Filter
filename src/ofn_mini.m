function [fun] = ofn_mini(th)
    % th: theta vector with 7 parameters to be estimated
    global yv filter_mat captst H F K n; 
   
    % 1. Matrix Construction
    [R, Q, H, F] = matrices_mini(th); 
   
    % 2. Initialization (t=0)
    beta00 = zeros(3,1);  % Initial state h_{0|0}
    P00 = eye(3);         % Initial uncertainty matrix P_{0|0}
    like = zeros(captst, 1); % Log-likelihood storage
    
    %% KALMAN FILTER RECURSIVE LOOP
    it = 1; 
    while it <= captst
        
        % --- PREDICTION STEP ---
        beta10 = F * beta00;          % h_{t|t-1} = F * h_{t-1|t-1}
        P10 = F * P00 * F' + Q;       % P_{t|t-1} = F * P_{t-1|t-1} * F' + Q
      
        % --- INNOVATION (FORECAST ERROR) ---
        n10 = yv(it,:)' - (H * beta10); % e_{t|t-1} = y_t - H * h_{t|t-1}
        F10 = H * P10 * H' + R;         % S_t = H * P_{t|t-1} * H' + R
            
        % --- LOG-LIKELIHOOD EVALUATION ---
        like(it) = -0.5 * (log(2*pi*det(F10)) + (n10' / F10 * n10)); 
     
        % --- UPDATE STEP ---
        K = P10 * (H' / F10);         % Kalman Gain: K_t = P_{t|t-1} * H' * S_t^{-1}
      
        beta11 = beta10 + K * n10;    % h_{t|t} = h_{t|t-1} + K_t * e_{t|t-1}
        filter_mat(it,:) = beta11';   % Store updated state
        
        P11 = P10 - K * H * P10;      % P_{t|t} = (I - K_t * H) * P_{t|t-1}
          
        % --- CLOSE LOOP ---
        beta00 = beta11;              
        P00 = P11;      

        it = it + 1;
    end
   
    % Return negative log-likelihood for the minimization algorithm
    fun = -(sum(like)); 
end