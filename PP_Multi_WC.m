% OBJ 

function f = SKS_ProductionPlanning(x)

% % Reference: https://link.springer.com/chapter/10.1007/978-3-030-26458-1_13

[~,l,m,h,il,im,ih,cl,cm,ch,SalePrice,~,~,~] = ProductionPlanningData; % Accessing the data from the function

nProcess = length(l);                        % determing the number of processes


PC = zeros(nProcess,1);                     % Initialization of variable to store the production cost for each process
IC = zeros(nProcess,1);                     % Initialization of variable to store the investment cost for each process
Revenue = zeros(nProcess,1);                % Initialization of variable to store the revenue genereated for each process

for j = 1: nProcess
    
    if x(j) >= l(j) && x(j) <= m(j)             % if the production is in between low and medium level
        
        PC(j) = ((cm(j) - cl(j))/(m(j) - l(j)))*(x(j) - l(j)) + cl(j);  % Determining the production cost for the range l to m
        IC(j) = ((im(j) - il(j))/(m(j) - l(j)))*(x(j) - l(j)) + il(j);  % Determining the investment cost  for the range l to m
        Revenue(j) = SalePrice(j)*x(j);         % Determining the revenue genereated by selling the product from the process j
       
    elseif x(j) > m(j) && x(j) <= h(j)          % if the production is in between medium and high level
        
        PC(j) = ((ch(j) - cm(j))/(h(j) - m(j)))*(x(j) - m(j)) + cm(j);  % Determining the production cost
        IC(j) = ((ih(j) - im(j))/(h(j) - m(j)))*(x(j) - m(j)) + im(j);  % Determining the investment cost
        Revenue(j) = SalePrice(j)*x(j);          % Determining the revenue genereated by selling the product from the process j
    end
    
end

profit = sum(Revenue) - sum(PC);                 % Determining the profit (objective)
TotalInvRed = sum(IC);

f = [-profit,TotalInvRed];

end

% NONLCON

function [C, Ceq] = nonlcon(x)

[~,l,m,h,il,im,ih,cl,cm,ch,SalePrice,rm1,rm2,~,nProcess] = ProductionPlanningData; % Accessing the data from the function

Budget = 1000;                              % Budget available
AvailRaw1 = 500;                            % Amount of raw material 1 available
AvailRaw2 = 500;                            % Amount of raw material 2 available
IC = zeros(nProcess,1);                     % Initialization of variable to store the investment cost for each process

for j = 1: nProcess

    if x(j) >= l(j) && x(j) <= m(j)           
        
        IC(j) = ((im(j) - il(j))/(m(j) - l(j)))*(x(j) - l(j)) + il(j);  % Determining the investment cost  for the range l to m

    elseif x(j) > m(j) && x(j) <= h(j)      

        IC(j) = ((ih(j) - im(j))/(h(j) - m(j)))*(x(j) - m(j)) + im(j);  % Determining the investment cost
    else
       x(j) = 0;
    end
end

R1Reqd = x(:).*rm1(:);
R2Reqd = x(:).*rm2(:);

C = [
    sum(R1Reqd)-AvailRaw1;
    sum(R2Reqd)-AvailRaw2;
    sum(IC)-Budget;
];

Ceq = [];
end


% SCRIPT

clc
clear
close all

%% Problem settings
[product,l,m,h,il,im,ih,cl,cm,ch,SP,rm1,rm2,rm3,nProcess] = ProductionPlanningData;
lb = zeros(1,nProcess);
ub = h';



optionga = optimoptions('gamultiobj','PopulationSize',7500,'MaxTime',30,'ParetoFraction',0.4,'PlotFcn',@gaplotpareto,'Display','off');
[x,f] = gamultiobj(@SKS_ProductionPlanning,nProcess,[],[],[],[],lb,ub,@nonlcon,optionga);

for j = 1:nProcess
    if x(j) >0 && x(j)<l
        x(j)=0;
    end
end

figure;
hold on;
grid on;
plot(f(:,1),f(:,2),'*r')
xlabel('f1');
ylabel('f2');
legend('gamultiobj');
title('pareto front');
