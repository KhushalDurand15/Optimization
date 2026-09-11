% Script

clc
clear
close all

% Problem settings
[product,l,m,h,il,im,ih,cl,cm,ch,SP,rm1,rm2,rm3,nProcess] = ProductionPlanningData;
lb = zeros(1,nProcess);
ub = h';

% Define two separate fitness functions using anonymous functions
% true = apply unique constraint, false = do not apply
prob_without = @(x) SKS_ProductionPlanning(x, false); 
prob_with    = @(x) SKS_ProductionPlanning(x, true);

% Algorithm parameters
Np = 10;                                
T = 20;                                 
NRuns = 25;                              % Set to 25 for quiz requirements

% Initialize storage arrays
bestsol_without = NaN(NRuns,length(lb));
bestfitness_without = NaN(NRuns,1);
BestFitIter_without = NaN(NRuns,T+1);

bestsol_with = NaN(NRuns,length(lb));
bestfitness_with = NaN(NRuns,1);
BestFitIter_with = NaN(NRuns,T+1);

% 1. Run Optimization WITHOUT Unique Constraint
fprintf('Running 25 iterations WITHOUT Unique Process Constraint...\n');
for i = 1:NRuns
    rng(i,'twister')                     
    [bestsol_without(i,:), bestfitness_without(i), BestFitIter_without(i,:),~,~] = TLBO(prob_without,lb,ub,Np,T);
end

% 2. Run Optimization WITH Unique Constraint
fprintf('Running 25 iterations WITH Unique Process Constraint...\n');
for i = 1:NRuns
    rng(i,'twister')                     
    [bestsol_with(i,:), bestfitness_with(i), BestFitIter_with(i,:),~,~] = TLBO(prob_with,lb,ub,Np,T);
end

% 3. Identify the best run for each case
[best_val_without, best_idx_without] = min(bestfitness_without);
[best_val_with, best_idx_with]       = min(bestfitness_with);

fprintf('Best Fitness (Without Constraint): %f\n', best_val_without);
fprintf('Best Fitness (With Constraint): %f\n', best_val_with);
fprintf('Incorporating the unique-process constraint improves solution feasibility and practical quality by preventing multiple processes from being selected for the same product. \n However, the added constraint reduces the feasible search space, which may slow convergence initially, but ultimately guides the optimizer toward more realistic and constraint-compliant solutions. \n');

% 4. Plot Convergence Curves
figure;
plot(0:T, BestFitIter_without(best_idx_without, :), 'b-', 'LineWidth', 2, 'DisplayName', 'Without Unique Constraint');
hold on;
plot(0:T, BestFitIter_with(best_idx_with, :), 'r-', 'LineWidth', 1, 'DisplayName', 'With Unique Constraint');
xlabel('Number of Iterations');
ylabel('Objective Value (Negative Profit)');
title('Convergence Comparison: Best Run of 25 Independent Trials');
legend('Location', 'best');
grid on;








----------------------------------------------------------------------------

% Objective function

function f = SKS_ProductionPlanning(x, apply_unique_constraint)
% Reference: https://link.springer.com/chapter/10.1007/978-3-030-26458-1_13
[product,l,m,h,il,im,ih,cl,cm,ch,SalePrice,rm1,rm2,rm3] = ProductionPlanningData; 
nProcess = length(l);                        
Budget = 1000;                              
AvailRaw1 = 500;                            
AvailRaw2 = 500;                            
PC = zeros(nProcess,1);                     
IC = zeros(nProcess,1);                     
R1Reqd = zeros(nProcess,1);                 
R2Reqd = zeros(nProcess,1);                 
Revenue = zeros(nProcess,1);                
penalty_domain = zeros(nProcess,1);         

for j = 1: nProcess
    if x(j) >= l(j) && x(j) <= m(j)             
        PC(j) = ((cm(j) - cl(j))/(m(j) - l(j)))*(x(j) - l(j)) + cl(j);  
        IC(j) = ((im(j) - il(j))/(m(j) - l(j)))*(x(j) - l(j)) + il(j);  
        R1Reqd(j) = x(j)*rm1(j);                
        R2Reqd(j) = x(j)*rm2(j);                
        Revenue(j) = SalePrice(j)*x(j);         
    elseif x(j) > m(j) && x(j) <= h(j)          
        PC(j) = ((ch(j) - cm(j))/(h(j) - m(j)))*(x(j) - m(j)) + cm(j);  
        IC(j) = ((ih(j) - im(j))/(h(j) - m(j)))*(x(j) - m(j)) + im(j);  
        R1Reqd(j) = x(j)*rm1(j);                 
        R2Reqd(j) = x(j)*rm2(j);                 
        Revenue(j) = SalePrice(j)*x(j);         
    elseif 0 < x(j) &&  x(j)< l(j)              
        penalty_domain(j) = 10^5;               
    end
end

TotalInvRed = sum(IC);
penalty_IC = 0;
if  TotalInvRed > Budget                         
    penalty_IC = (TotalInvRed - Budget)^2;       
end

TotalR1Reqd = sum(R1Reqd);
penalty_R1 = 0;
if TotalR1Reqd > AvailRaw1                       
    penalty_R1 = (TotalR1Reqd  - AvailRaw1)^2;   
end

TotalR2Reqd = sum(R2Reqd);
penalty_R2 = 0;
if TotalR2Reqd > AvailRaw2                       
    penalty_R2 = (TotalR2Reqd  - AvailRaw2)^2;   
end

% NEW: Unique Process Constraint Penalty Logic
penalty_unique = 0;
if apply_unique_constraint
    num_products = max(product);
    for k = 1:num_products
        % Count how many processes mapped to product 'k' have a production value > 0
        % (Using 1e-4 instead of 0 ensures floating point safety)
        active_count = sum(x(product == k) > 1e-4); 

        if active_count > 1
            % Adds penalty multiplier for every extra process used beyond the allowed 1
            penalty_unique = penalty_unique + (active_count - 1); 
        end
    end
end

profit = sum(Revenue) - sum(PC);                 

% Include the new unique penalty in the final fitness calculation (scaled massively to act as a hard constraint)
f = -profit + 10^15*(penalty_IC + penalty_R1 + penalty_R2 + sum(penalty_domain) + penalty_unique);   
end
