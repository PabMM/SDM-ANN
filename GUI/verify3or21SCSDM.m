%% Simulation for 3rd order SC SDM model
% P. Manrique May 9, 2024

tStart1 = cputime;

SDMmodel = 'ThirdOrderCascadeSingleBitSC';
load_system(SDMmodel);
load('3rd21SCSDM_GP.mat');

table = readtable('dvars.csv');
load('bw.mat')

%% Run simulation

variables_filePath = '3rd21SCSDM_GP.mat';
    
% Parameters
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
SDin = Simulink.SimulationInput(SDMmodel);

SDin = SDin.setVariable('Ts', ts);
SDin = SDin.setVariable('fs', fs);
SDin = SDin.setVariable('M', osr);
SDin = SDin.setVariable('ao1', Adc1);
SDin = SDin.setVariable('gm1', gm1);
SDin = SDin.setVariable('io1', io1);
SDin = SDin.setVariable('ao2', Adc2);
SDin = SDin.setVariable('gm2', gm2);
SDin = SDin.setVariable('io2', io2);
SDin = SDin.setVariable('Bw', Bw);
SDin = SDin.setVariable('fin',fi);


disp(cputime - tStart1)

%f = waitbar(0,'Running simulations...');

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 3rd21SCSDM_GP.mat'));
%'AttachedFiles',variables_filePath,...

%waitbar(0.1,f,sprintf('Running simulations... 1/%.f',nsims))
%close(f)

%snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1),[],1);
sndr = fsnr(SDout1(1,1).y,1,N,fs(1),fi,bw,30,10,1,1,2);

alfa = 0.05;
power = (io1 + io2)*(1 + alfa) + io2*(1+alfa);
fom = sndr + 10*log10(bw/power); 

specs = [fom,sndr,bw,power];
dvars = table2array(table);

variablenames = table.Properties.VariableNames;
specnames = {'FOM','SNDR','Bw','Power'};
names = [specnames, variablenames];

verification_results = [specs, dvars];
verification_results_table = array2table(verification_results,"VariableNames",names);
writetable(verification_results_table,'verification_results.csv')

%%
y = SDout1(1,1).y;

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