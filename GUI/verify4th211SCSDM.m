%% Simulation for 4th order 2-1-1 Cascade SC SDM model
% P. Manrique May 8, 2024

tStart1 = cputime;

SDMmodel = 'umts211_real_PM1';
load_system(SDMmodel);
load('4th211SCSDM_GP.mat');

table = readtable('dvars.csv');
load('bw.mat')

%% Run simulation

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
SDin = Simulink.SimulationInput(SDMmodel);


SDin = SDin.setVariable('ts', ts);
SDin = SDin.setVariable('fs', fs);
SDin = SDin.setVariable('M', osr);
SDin = SDin.setVariable('Adc1', Adc1); 
SDin = SDin.setVariable('gm1', gm1);
SDin = SDin.setVariable('Io1', io1);
SDin = SDin.setVariable('Adc2', Adc2); 
SDin = SDin.setVariable('gm2', gm2); 
SDin = SDin.setVariable('Io2', io2);
SDin = SDin.setVariable('Adc3', Adc3);
SDin = SDin.setVariable('gm3', gm3);
SDin = SDin.setVariable('Io3', io3);
SDin = SDin.setVariable('Adc4', Adc4);
SDin = SDin.setVariable('gm4', gm4);
SDin = SDin.setVariable('Io4', io4);
SDin = SDin.setVariable('Bw', Bw);
SDin = SDin.setVariable('fin',fin);


disp(cputime - tStart1)

%f = waitbar(0,'Running simulations...');

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 4th211SCSDM_GP.mat'));
%'AttachedFiles',variables_filePath,...

%waitbar(0.1,f,sprintf('Running simulations... 1/%.f',nsims))
%close(f)

%snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1),[],1);
sndr = fsnr(SDout1(1,1).y4,1,N,fs(1),fin,bw,30,10,1,1,2);

alfa = 0.05;
B = 3;
io_avg = 0.25*(io1(1)+io2(1)+io3(1)+io4(1));
pq = alfa*(1+1+(2^B - 1))*io_avg;
power = io1(1) + io2(1) + io3(1) + io4(1) + pq;

fom = sndr + 10*log10(bw/power); 

specs = [fom,sndr,bw,power];
dvars = table2array(table);

verification_results = [specs, dvars];
verification_results_table = array2table(verification_results,"VariableNames",{'FOM','SNDR','Bw','Power','OSR','Adc1','gm1','Io1','Adc2','gm2','Io2','Adc3','gm3','Io3','Adc4','gm4','Io4'});
writetable(verification_results_table,'verification_results.csv')

%%
y = SDout1(1,1).y4;

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

figfilename = 'figPSD_verification.png';
saveas(gcf, figfilename);