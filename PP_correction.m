clc;
clear;
close all;

%% Problem settings
[product,l,m,h,il,im,ih,cl,cm,ch,SP,rm1,rm2,rm3,nProcess] = ProductionPlanningData;
lb = zeros(1,nProcess);
ub = h';

prob = @SKS_ProductionPlanning;     % Fitness function
prob_wc = @SKS_ProductionPlanning_wc;     % Fitness function


%% Algorithm parameters
Np = 50; T = 100;                   % No. of population and iterations
Pc = 0.8; F = 0.85;                 % DE crossover probability & Scaling factor
w = 0.8; c1 = 1.5; c2 = 1.5;        % PSO Inertia weight, Acceleration coefficient

NRuns = 5;

bestfitness = NaN(NRuns,6);
BestFitIter_TLBO = NaN(NRuns,T+1);
BestFitIter_TLBOc = NaN(NRuns,T+1);
BestFitIter_PSO = NaN(NRuns,T+1);
BestFitIter_PSOc = NaN(NRuns,T+1);
BestFitIter_DE = NaN(NRuns,T+1);
BestFitIter_DEc = NaN(NRuns,T+1);






for i = 1:NRuns
    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,1),BestFitIter_TLBO(i,:),~,~] = TLBO(prob,lb,ub,Np,T);

    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,2),BestFitIter_TLBOc(i,:),~,~] = TLBO_wc(prob_wc,lb,ub,Np,T);


    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,3),BestFitIter_PSO(i,:),~,~] = PSO(prob,lb,ub,Np,T,w,c1,c2);

    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,4),BestFitIter_PSOc(i,:),~,~] = PSO_wc(prob_wc,lb,ub,Np,T,w,c1,c2);

    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,5),BestFitIter_DE(i,:),~,~] = DifferentialEvolution(prob,lb,ub,Np,T,Pc,F);

    rng(i,'twister')                % Controlling the random number generator used by rand, randi
    [~,bestfitness(i,6),BestFitIter_DEc(i,:),~,~] = DifferentialEvolution_wc(prob_wc,lb,ub,Np,T,Pc,F);



end

Stat(1,:) = min(bestfitness);          % Determining the best fitness function value
Stat(2,:) = max(bestfitness) ;          % Determining the worst fitness function value
Stat(3,:) = mean(bestfitness)  ;        % Determining the mean fitness function value
Stat(4,:) = median(bestfitness) ;         % Determining the median fitness function value
Stat(5,:) = std(bestfitness);  % Determining the standard deviation

Stat

% Plot
[~,idx1] = min(bestfitness(:,1));
y(:,1) = BestFitIter_TLBO(idx1,:);

[~,idx2] = min(bestfitness(:,2));
y(:,2) = BestFitIter_TLBOc(idx2,:);

[~,idx3] = min(bestfitness(:,3));
y(:,3) = BestFitIter_PSO(idx3,:);

[~,idx4] = min(bestfitness(:,4));
y(:,4) = BestFitIter_PSOc(idx4,:);

[~,idx5] = min(bestfitness(:,5));
y(:,5) = BestFitIter_DE(idx5,:);

[~,idx6] = min(bestfitness(:,6));
y(:,6) = BestFitIter_DEc(idx6,:);


hold on
grid on
plot(0:T,y)
legend('TLBO','TLBOc','PSO','PSOc','DE','DEc')



min(bestfitness(:,1))
min(bestfitness(:,2))
min(bestfitness(:,3))
min(bestfitness(:,4))
min(bestfitness(:,5))
min(bestfitness(:,6))

[~,fval] =  ga(@SKS_ProductionPlanning,nProcess,[],[],[],[],lb,ub,[],[])
