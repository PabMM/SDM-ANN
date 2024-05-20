%% Simulation for 2nd order SC Multi Bit SDM model
% P. Manrique May 9, 2024

tStart1 = cputime;

SDMmodel = 'SecondOrderMultibitSC';
load_system(SDMmodel);
load('2ndSCSDM_MultiBit_GP.mat');

table = readtable('dvars.csv');
load('bw.mat')

%% Run simulation

variables_filePath = '2ndSCSDM_MultiBit_GP.mat';
    
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
SDin = Simulink.SimulationInput(SDMmodel);

SDin = SDin.setVariable('M', osr);
SDin = SDin.setVariable('Adc', Adc);
SDin = SDin.setVariable('gm', gm);
SDin = SDin.setVariable('io', io);
SDin = SDin.setVariable('Vn', Vn);
SDin = SDin.setVariable('ts', ts);
SDin = SDin.setVariable('fs', fs);
SDin = SDin.setVariable('Bw', Bw);
SDin = SDin.setVariable('fin', fin);


disp(cputime - tStart1)

%f = waitbar(0,'Running simulations...');

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load 2ndSCSDM_MultiBit_GP.mat'));
%'AttachedFiles',variables_filePath,...

%waitbar(0.1,f,sprintf('Running simulations... 1/%.f',nsims))
%close(f)

%snr1 = reshape(arrayfun(@(obj) obj.SNRArray, SDout1),[],1);
sndr = fsnr(SDout1(1,1).y,1,N,fs(1),fin,bw,30,10,1,1,2);

B = 3;
alfa = 0.05;
power = 2*io*(1 + alfa*(2^B - 1));
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