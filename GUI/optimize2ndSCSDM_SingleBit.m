%% Simulations for 2nd order SC SDM Single Bit
% P. Manrique May 9, 2024


tStart1 = cputime;

SDMmodel = 'SecondOrderSingleBitSC';
load_system(SDMmodel);
load('2ndSCSDM_SingleBit_GP.mat');

num_iterations = 9;
table = readtable('vdvars_tab.csv');
table = table(2:end,:);
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


f = waitbar(0,'Running simulations...');
pause(.5)
waitbar(0.1,f,'Running simulations... 1/10')
nsims = 10;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running simulations')


nsims_var = nsims-1;

out = zeros(N,1,num_iterations);

osr_dt = reshape(arrayfun(@(obj) obj.Variables(1).Value, SDin),[],1);
adc_dt = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin),[],1);
gm_dt = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin),[],1);
io_dt = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin),[],1);
vn_dt = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDin),[],1);
fs_dt = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin),[],1);
bw_dt = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin),[],1);
fin_dt = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDin),[],1);

for i = 1:nsims_var
    SDout=sim(SDin(i),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','on',...
        'SetupFcn',@()evalin('base','load 2ndSCSDM_SingleBit_GP.mat')); 
    %'AttachedFiles',variables_filePath,...
    waitbar((i+1)/nsims,f,sprintf('Running simulations... %.f/%.f',i+1,nsims))
    try
       out(:,:,i) = SDout.y;
       snr_sim(i) = fsnr(out(:,:,i), 1, N, fs_dt(i), fin_dt, bw_dt(i), 30, 30, 1, 1, 2);
    catch
       snr_sim(i) = 0;
    end
end
disp(cputime - tStart2)
close(f);
fprintf('Saving Data ...')


%snr_d = reshape(arrayfun(@(obj) obj.SNRArray, SDout),[],1);
alfa = 0.05;
power = 2*io_dt.*(1 + alfa);


% snr_var = zeros(num_iterations-1,1);
% for n = 1:num_iterations-1
%    try
%        out = SDout(1,n).y4;
%        snr_var(n) = fsnr(out, 1, N, fs_d(n), fin, bw_d(n), 30, 30, 1, 1, 2);
%    catch
%        snr_var(n) = 0;
%    end
% end

dvars_var = horzcat(osr_dt,adc_dt,gm_dt,io_dt,vn_dt);

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
osr = opt_row.OSR; M=osr;
fs = 2.*Bw.*M;
Adc = opt_row.Adc;
gm = opt_row.gm;
io = opt_row.Io;
Vn = opt_row.Vn;

% Remaining parameters
fin = Bw./5; % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time

save('optimal_parameters.mat',"ts","fin","M","fs","Bw","Adc","gm","io","Vn")

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
