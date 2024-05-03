%% Simulations for 4th order 2-1-1 Cascade SC SDM model
% P. Manrique April 11, 2024

tStart1 = cputime;

SDMmodel = 'umts211_real_B';
load_system(SDMmodel);
load('4th211SCSDM_GP.mat');

num_iterations = 10;
table = readtable('vdvars_tab.csv');
load('bw.mat')

%% Run simulations

variables_filePath = '4th211SCSDM_GP.mat';
    
% Parameters
Bw = bw;
osr = table.OSR;
fs = 2.*Bw.*osr;
Adc1 = table.Adc1;
Adc2 = table.Adc2;
Adc3 = table.Adc3;
Adc4 = table.Adc4;
gm1 = table.gm1;
gm2 = table.gm2;
gm3 = table.gm3;
gm4 = table.gm4;
io1 = table.Io1;
io2 = table.Io2;
io3 = table.Io3;
io4 = table.Io4;

% Remaining parameters
fin = Bw./3; % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time

% Simulations
SDin(1:num_iterations) = Simulink.SimulationInput(SDMmodel);

for n = 1:num_iterations
    SDin(n) = SDin(n).setVariable('ts', ts(n));
    SDin(n) = SDin(n).setVariable('fs', fs(n));
    SDin(n) = SDin(n).setVariable('M', osr(n));
    SDin(n) = SDin(n).setVariable('Adc1', Adc1(n)); 
    SDin(n) = SDin(n).setVariable('gm1', gm1(n));
    SDin(n) = SDin(n).setVariable('Io1', io1(n));
    SDin(n) = SDin(n).setVariable('Adc2', Adc2(n)); 
    SDin(n) = SDin(n).setVariable('gm2', gm2(n)); 
    SDin(n) = SDin(n).setVariable('Io2', io2(n));
    SDin(n) = SDin(n).setVariable('Adc3', Adc3(n));
    SDin(n) = SDin(n).setVariable('gm3', gm3(n));
    SDin(n) = SDin(n).setVariable('Io3', io3(n));
    SDin(n) = SDin(n).setVariable('Adc4', Adc4(n));
    SDin(n) = SDin(n).setVariable('gm4', gm4(n));
    SDin(n) = SDin(n).setVariable('Io4', io4(n));
    SDin(n) = SDin(n).setVariable('Bw', Bw);
    SDin(n) = SDin(n).setVariable('fin',fin);
end 

disp(cputime - tStart1)

snr_sim = zeros(num_iterations,1);
power_sim = snr_sim;
fom_sim = snr_sim;
bw_sim = fom_sim;

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 4th211SCSDM_GP.mat'));
%'AttachedFiles',variables_filePath,...

snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1),[],1);

alfa = 0.05;
B = 3;
io_avg = 0.25*(io1(1)+io2(1)+io3(1)+io4(1));
pq = alfa*(1+1+(2^B - 1))*io_avg;
power1 = io1(1) + io2(1) + io3(1) + io4(1) + pq;

snr_sim(1) = snr1;
power_sim(1) = power1;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running parallel simulations')
SDinV = SDin(2:num_iterations);
SDout=sim(SDinV,'ShowProgress','on',...%'TransferBaseWorkspaceVariables','on',...
    'SetupFcn',@()evalin('base','load 4th211SCSDM_GP.mat')); 
%'AttachedFiles',variables_filePath,...
disp(cputime - tStart2)
fprintf('Saving Data ...')

fs_d = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDinV), [], 1);
osr_d = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDinV), [], 1);
adc1_d = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDinV), [], 1);
gm1_d = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDinV), [], 1);
io1_d = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDinV), [], 1);
adc2_d = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDinV), [], 1);
gm2_d = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDinV), [], 1);
io2_d = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDinV), [], 1);
adc3_d = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDinV), [], 1);
gm3_d = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDinV), [], 1);
io3_d = reshape(arrayfun(@(obj) obj.Variables(12).Value, SDinV), [], 1);
adc4_d = reshape(arrayfun(@(obj) obj.Variables(13).Value, SDinV), [], 1);
gm4_d = reshape(arrayfun(@(obj) obj.Variables(14).Value, SDinV), [], 1);
io4_d = reshape(arrayfun(@(obj) obj.Variables(15).Value, SDinV), [], 1);
bw_d = reshape(arrayfun(@(obj) obj.Variables(16).Value, SDinV), [], 1);
snr_d = reshape(arrayfun(@(obj) obj.SNRArray, SDout),[],1);
alfa = 0.05;
B = 3;
io_avg = 0.25*(io1_d+io2_d+io3_d+io4_d);
pq = alfa*(1+1+(2^B - 1))*io_avg;
power = io1_d + io2_d + io3_d + io4_d + pq;

snr_var = snr_d;

dvars_var = horzcat(osr_d,adc1_d,gm1_d,io1_d,adc2_d,gm2_d,io2_d,adc3_d,gm3_d,io3_d,adc4_d,gm4_d,io4_d);

power_var = power;

dvars_total = vertcat(dvars_array,dvars_var);

snr_sim(2:num_iterations) = snr_var;
power_sim(2:num_iterations) = power_var;
fom_sim = snr_sim+10*log10(bw./power_sim);
bw_sim = repmat(bw,num_iterations,1);

total_sims = horzcat(fom_sim,snr_sim,bw_sim,power_sim,dvars_total);
new_specs = {'FOM','SNR','Bw','Power'};
total_names = cat(2,new_specs,dvars_names);

total_sims_table = array2table(total_sims,"VariableNames",total_names);
writetable(total_sims_table,'total_sims.csv')

%%
[snr_max,idx_max] = max(snr_sim);
if idx_max ~= 1
    n = idx_max-1;
    y = SDout(1,n).y4;
else
    n = 1;
    y = SDout1(1,1).y4;
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


