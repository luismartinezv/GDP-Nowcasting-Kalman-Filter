clear
clc

% 1. Global Variables Specification
global yv filter_mat n vfq captst H F K;          

%% 2. Data Input & Preprocessing
yv = xlsread('rawdata2.xls', 1, 's87:t854');     
[T, n] = size(yv); % T = months, n = 2 observable variables

yv = standard(yv); % Standardization (Mean = 0, Std = 1)
vfq = 1;           % Identification constraint (sigma_w^2 = 1)

%% 3. Initial Guesses for the Optimizer
B = [0.9; 0.8];             % Factor loadings (lambda_1, lambda_2)
phif = 0.3;                 % Common factor AR(1) persistence
phiy = [0.3; 0.3];          % Idiosyncratic errors AR(1) persistence
v = std(yv)';               % Initial standard deviations

startval = [B; phif; phiy; v]; 
nth = size(startval,1);        

captst = T;                           
filter_mat = zeros(captst, 3);     % State vector storage: h_t = [f_t, e1_t, e2_t]' 

%% 4. Maximum Likelihood Estimation
options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');
[x_opt, lf, EXITFLAG, OUTPUT, GRAD, HESS] = fminunc(@ofn_mini, startval, options);

% Cramer-Rao Lower Bound (Standard Errors)
cramerrao = inv(HESS);             
std_err = sqrt(diag(cramerrao));   
disp('Estimated Parameters and Standard Errors:');
disp([x_opt std_err]);

%% 5. Common Factor Extraction & Temporal Aggregation
factor_monthly = filter_mat(:, 1); 

% Mariano-Murasawa Approximation (Monthly to Quarterly smoothing)
factor_quarterly = 1/3*factor_monthly(5:end) + 2/3*factor_monthly(4:end-1) + factor_monthly(3:end-2) + ...
                   2/3*factor_monthly(2:end-3) + 1/3*factor_monthly(1:end-4);

% Discrete sampling (End of quarter)
i = 1;
fact_gdp = [];
while i < captst - 4
    fact_gdp = [fact_gdp; factor_quarterly(i)];
    i = i + 3;
end

gdp_historical = xlsread('rawdata2.xls', 1, 'f33:f287');  

%% 6. Dynamic Forecasting (Markov Chain Projection)
last_state = filter_mat(end, :); % h_{T|T}

% Project states into the future using optimal Transition Matrix F
kk1 = F * last_state';       
kk2 = F * F * last_state';   
kk3 = F * F * F * last_state';
kk4 = F * F * F * F * last_state';
kk5 = F * F * F * F * F * last_state';

% Append forecasted factor values
factor_extended = [factor_monthly; kk1(1); kk2(1); kk3(1); kk4(1); kk5(1)];

% Mariano-Murasawa for extended series
factorq_ext = 1/3*factor_extended(5:end) + 2/3*factor_extended(4:end-1) + factor_extended(3:end-2) + ...
              2/3*factor_extended(2:end-3) + 1/3*factor_extended(1:end-4);
llo = size(factorq_ext,1);
i = 1;
fact_gdp_ext = [];
while i <= llo
    fact_gdp_ext = [fact_gdp_ext; factorq_ext(i)];
    i = i + 3;
end

%% 7. Bridge Equation (OLS Translation to GDP)
y_obs = gdp_historical;
n_obs = size(y_obs, 1);
X_mat = [ones(n_obs, 1), fact_gdp]; 

% OLS Estimator: beta = (X'X)^(-1) X'Y
beta_ols = inv(X_mat' * X_mat) * X_mat' * y_obs; 

% Final GDP Nowcasting
yhat_Q1 = beta_ols(1) + beta_ols(2) * fact_gdp_ext(end-1);
yhat_Q2 = beta_ols(1) + beta_ols(2) * fact_gdp_ext(end);

%% 8. Results Visualization & Automated Export
if ~exist('results', 'dir')
    mkdir('results'); % Create directory for outputs automatically
end

% Plot 1: Latent Factor vs Historical GDP
fig1 = figure('Name', 'Business Cycle: Latent Factor vs GDP');
gdp_st = (gdp_historical - mean(gdp_historical)) / std(gdp_historical);
fact_st = (fact_gdp - mean(fact_gdp)) / std(fact_gdp);
plot(gdp_st, 'b-', 'LineWidth', 1.5); hold on;
plot(fact_st, 'r--', 'LineWidth', 1.5);
title('Latent Common Factor vs Real GDP Growth');
legend('Historical GDP', 'Estimated Factor', 'Location', 'best');
grid on; hold off;
saveas(fig1, 'results/factor_vs_gdp.png');

% Plot 2: Nowcasting Projection
fig2 = figure('Name', 'GDP Nowcasting');
gdp_zoom = gdp_historical(end-20:end); 
x_hist = 1:length(gdp_zoom); 

x_pred = [x_hist(end), x_hist(end)+1, x_hist(end)+2]; 
y_pred = [gdp_historical(end); yhat_Q1; yhat_Q2];

plot(x_hist, gdp_zoom, 'b-o', 'LineWidth', 1.5); hold on;
plot(x_pred, y_pred, 'r--*', 'LineWidth', 2);
title('Nowcasting: 2-Quarter GDP Projection');
legend('Observed GDP', 'Kalman Prediction', 'Location', 'best');
grid on; hold off;
saveas(fig2, 'results/gdp_nowcasting.png');

disp('Execution complete. Results saved in /results folder.');