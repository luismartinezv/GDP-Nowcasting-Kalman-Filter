function [Rs, Qs, Hs, Fs] = matrices_mini(z)
    % z: Column vector containing 7 structural parameters
    global n vfq; % n = 2 observables, vfq = 1 (identification restriction)
    
    %% 1. Measurement Error Variance Matrix (R)
    Rs = zeros(n, n); 
    
    %% 2. Observation Matrix (H)
    % z(1:2) contains the factor loadings (lambda_1, lambda_2)
    h2 = eye(n);             
    Hs = [z(1:n) h2];        % Concatenation: Resulting matrix is 2x3
    
    %% 3. Transition Matrix (F)
    phi_f = z(n+1);          % z(3): Common factor AR(1) persistence
    phi_y = z(n+2:n+3);      % z(4:5): Idiosyncratic errors AR(1) persistence
    
    Fs = diag([phi_f; phi_y]); % 3x3 Diagonal Matrix
    
    %% 4. State Shocks Variance Matrix (Q)
    sigmas_sq = z(n+4:n+5).^2;   % z(6:7): Standard deviations squared (variances)
    Qs = diag([vfq; sigmas_sq]); % 3x3 Diagonal Matrix
end