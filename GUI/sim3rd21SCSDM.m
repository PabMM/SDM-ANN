%% Simulations for 3rd order SC SDM model
% P. Manrique April 10, 2024
tStart1 = cputime;

SDMmodel = 'ThirdOrderCascadeSingleBitSC';
load_system(SDMmodel);
load('3rd21SCSDM_GP.mat');

num_iterations = 10;
table = readtable('vdvars_tab.csv');
load('bw.mat')

%% Run simulations

variables_filePath = '3rd21SCSDM_GP.mat';

Bw = bw;
osr = table.OSR;
fs = 2.*Bw.*osr;
Adc1 = table.Adc1;
Adc2 = table.Adc2;
gm1 = table.gm1;
gm2 = table.gm2;
io1 = table.Io1;
io2 = table.Io2;

% Remaining parameters
fi = Bw./2; % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time
    

% Simulations
SDin(1:num_iterations) = Simulink.SimulationInput(SDMmodel);

for n = 1:num_iterations
    SDin(n) = SDin(n).setVariable('Ts', ts(n));
    SDin(n) = SDin(n).setVariable('fs', fs(n));
    SDin(n) = SDin(n).setVariable('M', osr(n));
    SDin(n) = SDin(n).setVariable('ao1', Adc1(n));
    SDin(n) = SDin(n).setVariable('gm1', gm1(n));
    SDin(n) = SDin(n).setVariable('io1', io1(n));
    SDin(n) = SDin(n).setVariable('ao2', Adc2(n));
    SDin(n) = SDin(n).setVariable('gm2', gm2(n));
    SDin(n) = SDin(n).setVariable('io2', io2(n));
    SDin(n) = SDin(n).setVariable('Bw', Bw);
    SDin(n) = SDin(n).setVariable('fin',fi);
end 

disp(cputime - tStart1)

snr_sim = zeros(num_iterations,1);
power_sim = snr_sim;
fom_sim = snr_sim;
bw_sim = fom_sim;

%% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 3rd21SCSDM_GP.mat'));
%'AttachedFiles',variables_filePath,...


snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1,'UniformOutput',false),[],1);
snr1 = cell2mat(snr1);
alfa = 0.05;
power1 = (io1(1) + io2(1))*(1 + alfa) + io2(1)*(1+alfa);
snr_sim(1) = snr1;
power_sim(1) = power1;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running parallel simulations')
SDinV = SDin(2:num_iterations);
SDout=sim(SDinV,'ShowProgress','on',...%'TransferBaseWorkspaceVariables','on',...
    'SetupFcn',@()evalin('base','load 3rd21SCSDM_GP.mat')); 
%'AttachedFiles',variables_filePath,...
disp(cputime - tStart2)
fprintf('Saving Data ...')


osr_r = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDinV), [], 1);
adc1 = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDinV), [], 1);
gm1_r = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDinV), [], 1);
io1_r = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDinV), [], 1);
adc2 = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDinV), [], 1);
gm2_r = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDinV), [], 1);
io2_r = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDinV), [], 1);
bw = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDinV), [], 1);
fs_r = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDinV), [], 1);
snr = reshape(arrayfun(@(obj) obj.SNRArray, SDout),[],1);
alfa = 0.05;
power_var = (io1_r + io2_r)*(1 + alfa) + io2_r*(1+alfa);

snrv = reshape(arrayfun(@(obj) obj.SNRArray, SDout,'UniformOutput',false),[],1);
snr_var = cell2mat(snrv);

dvars_var = horzcat(osr_r,adc1,gm1_r,io1_r,adc2,gm2_r,io2_r);

dvars_total = vertcat(dvars_array,dvars_var);

snr_sim(2:num_iterations) = snr_var;
power_sim(2:num_iterations) = power_var;
fom_sim = snr_sim+10*log10(Bw./power_sim);
bw_sim = repmat(Bw,num_iterations,1);

total_sims = horzcat(fom_sim,snr_sim,bw_sim,power_sim,dvars_total);
new_specs = {'FOM','SNR','Bw','Power'};
total_names = cat(2,new_specs,dvars_names);

total_sims_table = array2table(total_sims,"VariableNames",total_names);
writetable(total_sims_table,'total_sims.csv')

%%
[snr_max,idx_max] = max(snr_sim);
if idx_max ~= 1
    n = idx_max-1;
    y = SDout(1,n).y;
else
    n = 1;
    y = SDout1(1,1).y;
end

%[pxx,f] = pwelch(y,[],[],[],fs(n));
%figure;
%plot(f,10*log10(pxx));

W = hann(N);
X = spdb(y,N,W,fs);

figure;
plot(X);
xlabel('Frequency (Hz)');
ylabel('PSD (dB)');
title('Power Spectral Density');

figfilename = 'figPSD.png';
saveas(gcf, figfilename);