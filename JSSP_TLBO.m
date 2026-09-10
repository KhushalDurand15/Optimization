% script
clear; clc; close all;

% --- Data for Problem 5 (20 Orders, 5 Machines) ---
r = [2, 3, 4, 5, 10, 1, 2, 4, 10, 1, 5, 2, 4, 6, 2, 3, 3, 7, 6, 0];
d = [33, 34, 31, 33, 34, 34, 33, 25, 38, 37, 30, 20, 32, 20, 25, 34, 37, 38, 32, 30];

C = [10 6 8 9 9; 8 5 7 6 7; 12 7 11 10 10; 10 6 8 9 8; 8 5 7 6 7; 
    12 7 10 11 10; 12 10 11 12 11; 9 5 7 9 8; 10 6 8 9 8; 8 5 7 6 6; 
    15 9 12 14 13; 13 7 10 12 11; 9 5 6 8 7; 10 6 10 8 9; 8 5 6 7 7; 
    9 5 7 9 8; 10 6 8 9 8; 8 5 7 6 6; 15 9 14 12 13; 13 7 10 12 11];

 P = [10 14 12 11 13; 6 8 7 6 7; 11 16 13 11 12; 6 12 8 7 8; 10 16 12 12 13; 
     7 12 10 8 9; 10 13 10 11 12; 4 10 8 5 6; 2 4 3 2 3; 7 14 11 8 10; 
     8 16 12 10 11; 3 6 5 4 5; 4 10 7 5 6; 2 4 4 3 3; 7 14 13 10 11; 
    3 8 7 5 6; 6 12 10 7 8; 3 8 6 13 4; 4 7 6 5 6; 5 6 5 4 5];

% P = [5 7 6 5 6; 3 4 3 3 4; 2 4 3 2 3; 3 6 4 3 4; 2 4 3 2 2;
%      1 3 2 2 2; 1 2 1 1 1; 2 5 4 3 3; 4 6 6 5 5; 2 5 3 2 3;
%      2 3 2 2 2; 2 6 4 3 3; 3 3 3 2 2; 2 5 5 2 3; 4 7 6 4 5;
%      2 4 3 2 3; 3 6 4 3 4; 2 4 3 4 2; 3 3 2 2 2; 3 4 3 2 3];

I = 20;
M = 5;


% --- 2. Run TLBO ---
Np = 50; 
T = 2500; 
lb = [ones(1, I), zeros(1, I)]; 
ub = [(M + 0.99) * ones(1, I), max(d) * ones(1, I)]; 

fun_S1 = @(x) obj_fun(x, r, d, C, P);
[tlbo_S1, conv_tlbo_S1] = TLBO(fun_S1, lb, ub, Np, T)


% --- Plot Gantt Chart ---

mach = floor(tlbo_S1(1:I));
start = tlbo_S1(I+1:2*I);

figure;
hold on;

for i = 1:I
    m = mach(i);
    duration = P(i,m);

    rectangle('Position',[start(i), m-0.4, duration, 0.8], ...
        'FaceColor',[0.3 0.6 0.9]);

    text(start(i)+duration/2, m, sprintf('J%d',i), ...
        'HorizontalAlignment','center');
end

xlabel('Time');
ylabel('Machine');
yticks(1:M);
title('TLBO Gantt Chart - P5S1');
grid on;
hold off;

-----------------------------------------------------------------------------------

% objective function
function f = obj_fun(x, r, d, C, P)
I = length(r);

% Extract variables
mach_assign = floor(x(1:I)); 
start_times = x(I+1:2*I); % Fixed: 2*I instead of 2I

base_cost = 0;
infeas_penalty = 0;

% Evaluate Costs and Boundaries
for i = 1:I
    m = mach_assign(i);
    base_cost = base_cost + C(i, m);
    completion = start_times(i) + P(i, m);

    if start_times(i) < r(i) || completion > d(i)
        infeas_penalty = infeas_penalty + 1000;
    end
end

% Evaluate Machine Overlaps
for i = 1:I
    for j = i+1:I
        if mach_assign(i) == mach_assign(j)
            m = mach_assign(i);
            comp_i = start_times(i) + P(i, m);
            comp_j = start_times(j) + P(j, m);

            % Check for temporal overlap
            if ~(comp_i <= start_times(j) || comp_j <= start_times(i))
                infeas_penalty = infeas_penalty + 1000;
            end
        end
    end
end

f = base_cost + infeas_penalty;
end

-----------------------------------------------------------------------------------

% TLBO

function [bestsol,bestfitness,BestFitIter,P,f] = TLBO(prob,lb,ub,Np,T)

%% Starting of TLBO
f = NaN(Np,1);                      % Vector to store the fitness function value of the population members
BestFitIter = NaN(T+1,1);           % Vector to store the best fitness function value in every iteration

D = length(lb);                     % Determining the number of decision variables in the problem

P = repmat(lb,Np,1) + repmat((ub-lb),Np,1).*rand(Np,D);   % Generation of the initial population

for p = 1:Np
    f(p) = prob(P(p,:));            % Evaluating the fitness function of the initial population
end

BestFitIter(1) = min(f);

%% Iteration loop
for t = 1: T

    for i = 1:Np
        %% Teacher Phase
        Xmean = mean(P);            % Determining mean of the population

        [~,ind] = min(f);           % Detemining the location of the teacher
        Xbest = P(ind,:);           % Copying the solution acting as teacher

        TF = randi([1 2],1,1);      % Generating either 1 or 2 randomly for teaching factor

        Xnew = P(i,:) + rand(1,D).*(Xbest - TF*Xmean);  % Generating the new solution

        Xnew = min(ub, Xnew);       % Bounding the violating variables to their upper bound
        Xnew = max(lb, Xnew);       % Bounding the violating variables to their lower bound

        fnew = prob(Xnew);          % Evaluating the fitness of the newly generated solution

        if (fnew < f(i))            % Greedy selection
            P(i,:) = Xnew;          % Include the new solution in population
            f(i) = fnew;            % Include the fitness function value of the new solution in population
        end


        %% Learner Phase

        p = randi([1 Np],1,1);      % Selection of random parter

        %% Ensuring that the current member is not the partner
        while i == p
            p = randi([1 Np],1,1);  % Selection of random parter
        end

        if f(i)< f(p)    % Select the appropriate equation to be used in Learner phase
            Xnew = P(i,:) + rand(1, D).*(P(i,:) - P(p,:));  % Generating the new solution
        else
            Xnew = P(i,:) - rand(1, D).*(P(i,:) - P(p,:));  % Generating the new solution
        end

        Xnew = min(ub, Xnew);       % Bounding the violating variables to their upper bound
        Xnew = max(lb, Xnew);       % Bounding the violating variables to their lower bound

        fnew = prob(Xnew);          % Evaluating the fitness of the newly generated solution

        if (fnew < f(i))            % Greedy selection
            P(i,:) = Xnew;          % Include the new solution in population
            f(i) = fnew;            % Include the fitness function value of the new solution in population
        end

    end

    BestFitIter(t+1) = min(f);      % Storing the best value of each iteration
end

[bestfitness,ind] = min(f);
bestsol = P(ind,:);


