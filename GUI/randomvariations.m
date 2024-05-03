%% Perform random variations of inferred design variables
% P. Manrique April 8th, 2024

num_variations = 9;
load('dvars.mat')
dvars_names = dvars.Properties.VariableNames;
dvars_array = table2array(dvars);
l = length(dvars_array);
vdvars = zeros(num_variations,l);

for i = 1:num_variations
    alpha = -0.05 + 0.1*rand(1,l);
    vdvars(i,:) = dvars_array.*(1+alpha);
end

vdvars = vertcat(dvars_array,vdvars);
vdvars_tab = array2table(vdvars,"VariableNames",dvars_names);
writetable(vdvars_tab,'vdvars_tab.csv')