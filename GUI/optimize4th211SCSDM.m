%% Simulations for 4th order 2-1-1 Cascade SC SDM model
% P. Manrique May 8, 2024


tStart1 = cputime;

SDMmodel = 'umts211_real_PM1';
load_system(SDMmodel);
load('4th211SCSDM_GP.mat');

num_iterations = 9;
table = readtable('vdvars_tab.csv');
table = table(2:end,:);
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


f = waitbar(0,'Running simulations...');
pause(.5)
waitbar(0.1,f,'Running simulations... 1/10')
nsims = 10;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running parallel simulations')


nsims_var = nsims-1;

out = zeros(N,1,num_iterations);


fs_d = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin), [], 1);
osr_d = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin), [], 1);
adc1_d = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin), [], 1);
gm1_d = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDin), [], 1);
io1_d = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDin), [], 1);
adc2_d = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin), [], 1);
gm2_d = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin), [], 1);
io2_d = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDin), [], 1);
adc3_d = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDin), [], 1);
gm3_d = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDin), [], 1);
io3_d = reshape(arrayfun(@(obj) obj.Variables(12).Value, SDin), [], 1);
adc4_d = reshape(arrayfun(@(obj) obj.Variables(13).Value, SDin), [], 1);
gm4_d = reshape(arrayfun(@(obj) obj.Variables(14).Value, SDin), [], 1);
io4_d = reshape(arrayfun(@(obj) obj.Variables(15).Value, SDin), [], 1);
bw_d = reshape(arrayfun(@(obj) obj.Variables(16).Value, SDin), [], 1);

for i = 1:nsims_var
    SDout=sim(SDin(i),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','on',...
        'SetupFcn',@()evalin('base','load 4th211SCSDM_GP.mat')); 
    %'AttachedFiles',variables_filePath,...
    waitbar((i+1)/nsims,f,sprintf('Running simulations... %.f/%.f',i+1,nsims))
    try
       out(:,:,i) = SDout.y4;
       snr_sim(i) = fsnr(out(:,:,i), 1, N, fs_d(i), fin, bw_d(i), 30, 30, 1, 1, 2);
    catch
       snr_sim(i) = 0;
    end
end
disp(cputime - tStart2)
close(f);
fprintf('Saving Data ...')


%snr_d = reshape(arrayfun(@(obj) obj.SNRArray, SDout),[],1);
alfa = 0.05;
B = 3;
io_avg = 0.25*(io1_d+io2_d+io3_d+io4_d);
pq = alfa*(1+1+(2^B - 1))*io_avg;
power = io1_d + io2_d + io3_d + io4_d + pq;


% snr_var = zeros(num_iterations-1,1);
% for n = 1:num_iterations-1
%    try
%        out = SDout(1,n).y4;
%        snr_var(n) = fsnr(out, 1, N, fs_d(n), fin, bw_d(n), 30, 30, 1, 1, 2);
%    catch
%        snr_var(n) = 0;
%    end
% end

dvars_var = horzcat(osr_d,adc1_d,gm1_d,io1_d,adc2_d,gm2_d,io2_d,adc3_d,gm3_d,io3_d,adc4_d,gm4_d,io4_d);

power_sim = power;
fom_sim = snr_sim+10*log10(bw./power_sim);
bw_sim = repmat(bw,num_iterations,1);

opt_sims = horzcat(fom_sim,snr_sim,bw_sim,power_sim,dvars_var);

verification = readtable('verification_results.csv');
variablenames = verification.Properties.VariableNames;

opt_table = array2table(opt_sims,"VariableNames",variablenames);
writetable(opt_table,'optimization_results.csv')

total_sims = vertcat(verification,opt_table);
writetable(total_sims,'total_sims.csv')

%Optimal parameters
opt_row = total_sims(find(max(total_sims.FOM) == total_sims.FOM),:);
% Parameters
Bw = bw;
M = opt_row.OSR;
fs = 2.*Bw.*M;
Adc1 = opt_row.Adc1;
Adc2 = opt_row.Adc2;
Adc3 = opt_row.Adc3;
Adc4 = opt_row.Adc4;
gm1 = opt_row.gm1;
gm2 = opt_row.gm2;
gm3 = opt_row.gm3;
gm4 = opt_row.gm4;
Io1 = opt_row.Io1;
Io2 = opt_row.Io2;
Io3 = opt_row.Io3;
Io4 = opt_row.Io4;

% Remaining parameters
fin = Bw./3; % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time

save('optimal_parameters.mat',"ts","fin","M","fs","Bw","Adc4","Adc3","Adc2","Adc1","gm4","gm3","gm2","gm1","Io1","Io2","Io3","Io4")

%%
[snr_max,idx_max] = max(snr_sim);
n = idx_max;
y = out(:,:,n);


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

figfilename = 'figPSD_optimization.png';
saveas(gcf, figfilename);
