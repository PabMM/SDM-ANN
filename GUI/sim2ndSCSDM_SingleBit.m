%% Simulations for 2nd order SC Single Bit SDM model
% P. Manrique April 10, 2024

tStart1 = cputime;

SDMmodel = 'SecondOrderSingleBitSC';
load_system(SDMmodel);
load('2ndSCSDM_SingleBit_GP.mat');

num_iterations = 10;
table = readtable('vdvars_tab.csv');
load('bw.mat')

%% Run simulations

variables_filePath = '2ndSCSDM_SingleBit_GP.mat';


    
% Parameters
Bw = bw;
osr = table.OSR; M=osr;
fs = 2.*Bw.*osr;
Adc = table.Adc;
gm = table.gm;
io = table.Io;
Vn = table.Vn;

% Remaining parameters
fin = Bw./5; % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time

% Simulations
SDin(1:num_iterations) = Simulink.SimulationInput(SDMmodel);

for n = 1:num_iterations
    SDin(n) = SDin(n).setVariable('M', osr(n));
    SDin(n) = SDin(n).setVariable('Adc', Adc(n));
    SDin(n) = SDin(n).setVariable('gm', gm(n));
    SDin(n) = SDin(n).setVariable('io', io(n));
    SDin(n) = SDin(n).setVariable('Vn', Vn(n));
    SDin(n) = SDin(n).setVariable('ts', ts(n));
    SDin(n) = SDin(n).setVariable('fs', fs(n));
    SDin(n) = SDin(n).setVariable('Bw', Bw);
    SDin(n) = SDin(n).setVariable('fin', fin);
end 

disp(cputime - tStart1)

snr_sim = zeros(num_iterations,1);
power_sim = snr_sim;
fom_sim = snr_sim;
bw_sim = fom_sim;

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 2ndSCSDM_SingleBit_GP.mat'));
%'AttachedFiles',variables_filePath,...

io_dt = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin),[],1);
snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1,'UniformOutput',false),[],1);
snr1 = cell2mat(snr1);
%snr1 = fsnr(SDout1(1,1).out, 1, N, fs(1), fin, bw, 30, 30, 1, 1, 1);
snr_sim(1) = snr1;
alfa = 0.05;
power1 = 2*io_dt(1)*(1 + alfa);
power_sim(1) = power1;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running parallel simulations')
SDinV = SDin(2:num_iterations);
SDout=sim(SDinV,'ShowProgress','on',...%'TransferBaseWorkspaceVariables','on',...
    'SetupFcn',@()evalin('base','load 2ndSCSDM_SingleBit_GP.mat')); 
%'AttachedFiles',variables_filePath,...
disp(cputime - tStart2)
fprintf('Saving Data ...')

osr_dt = reshape(arrayfun(@(obj) obj.Variables(1).Value, SDinV),[],1);
adc_dt = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDinV),[],1);
gm_dt = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDinV),[],1);
io_dt = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDinV),[],1);
vn_dt = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDinV),[],1);
fs_dt = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDinV),[],1);
bw_dt = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDinV),[],1);
fin_dt = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDinV),[],1);
%power = 2*io_dt*(1 + alfa);
snrv = reshape(arrayfun(@(obj) obj.SNRArray, SDout,'UniformOutput',false),[],1);
snr_var = cell2mat(snrv);
%snr_var = zeros(num_iterations-1,1);
%for n = 1:num_iterations-1
%    try
%        out = SDout(1,n).out;
%        snr_var(n) = fsnr(out, 1, N, fs_dt(n), fin_dt(n), bw_dt(n), 30, 30, 1, 1, 1);
%    catch
%        snr_var(n) = 0;
%    end
%end


dvars_var = horzcat(osr_dt,adc_dt,gm_dt,io_dt,vn_dt);

power_var = 2*io_dt.*(1 + alfa);

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