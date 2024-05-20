clear;clc
modulators = {'2ndSCMBSDM','2ndSCSBSDM','3rdSCSDM','4th211SCSDM'};
model_names = {'ANN_GB','LUT_GB'};
num_iterations = [1,10];
n_mod = 5;
n_model = 2;


for j=1:n_model
    for i =1:n_mod
        for iter = num_iterations
        
        Stats_calculator(modulators{i},model_names{j},iter)
        
        end
        
    end
end

function Stats_calculator(modulator_name,model_name,num_iterations)

data_path = strcat('VAL-DS/sim_',modulator_name,'_',model_name,'_10.mat');

load(data_path)

fom_sim = fom_sim(:,1:num_iterations);


SNDR_sim = SNDR_sim(:,1:num_iterations);
power_sim = power_sim(:,1:num_iterations);


[fom_sim,J] = max(fom_sim,[],2);



aux = fom_sim;
auy = aux;
 i = 1;
for j =1:length(J)

    aux(i,1) = SNDR_sim(i,J(j));
    auy(i,1) = power_sim(i,J(j));
    i = i+1;
end
SNDR_sim = aux; clear aux
power_sim = auy; clear auy


err_fom = real((fom_sim-fom_asked)./fom_asked);
err_SNR = double((SNDR_sim-SNDR_asked)./SNDR_asked);
err_power = double((power_sim-power_asked)./power_asked);


T = zeros(7,3);
T(:,1) = Stats(err_fom);
T(:,2) = Stats(err_SNR);
T(:,3) = Stats(err_power);
T = array2table(T,'VariableNames',{'FOM','SNR','Power'},'RowName',{'Mean','P(E>0)','p(0.05)',...
    'p(0.25)','p(0.50)','p(0.75)','p(0.95)'});
printbar
fprintf([modulator_name, ', ' , model_name, ', num_iterations = ',num2str(num_iterations),'\n'])
printbar
disp(T)

writetable(T,['stats/',modulator_name,'_',model_name,'_',num2str(num_iterations),'.csv'],'WriteRowNames',true)

end

function c = Stats(err)

m = mean(err);

P = mean(err>-.0);


alpha = [0.05,0.25,0.50,0.75,0.95];

c = zeros(2+length(alpha),1);

c(1) = m;
c(2) = P;
for i = 1:length(alpha)
c(i+2) = quantile(err,alpha(i));
end

end

function printbar
fprintf('---------------------------------\n')
end

function p = processdata(x,n)
    if round(x,n) == 0
        p = x;
    else
        p = round(x,n);
    end
end
