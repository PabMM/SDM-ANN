clear;
modulators = {'2ndGmCSDM','2ndSCMBSDM','2ndSCSBSDM','3rdSCSDM','4th211SCSDM'};
model_names = {'ANN_GB','LUT_GB'};
num_iterations = [1,10];
i = 1;

for modulator = modulators
    summ = zeros(7,4);
    for model = model_names
        for it = num_iterations
            data_path = strcat('stats/',modulator,'_',model,'_',num2str(it),'.csv');
            tab = readtable(data_path{1});
            row = cell2table(tab.Row, 'VariableNames',{modulator{1}});
            summ(:,i) = arrayfun(@(x) round(x,5),tab.FOM);
            i = i+1;
        end
    end
    
    summ = array2table(summ,'VariableNames',{'FOM_ANN_1','FOM_ANN_10','FOM_LUT_1','FOM_LUT_10'});
    %summ.FOM_ANN_1 = sprintf('%.5f',summ.FOM_ANN_1);
    %summ.FOM_ANN_10 = sprintf('%.5f',summ.FOM_ANN_10);
    %summ.FOM_LUT_1 = sprintf('%.5f',summ.FOM_LUT_1);
    %summ.FOM_LUT_10 = sprintf('%.5f',summ.FOM_LUT_10);
    sum = horzcat(row,summ);
    fprintf('-----------------------------------\n')
    fprintf(modulator{1})
    fprintf('\n-----------------------------------\n')
    disp(sum)
    writetable(sum,['stats_sum_',modulator{1},'.csv'])
    i = 1;
end
            