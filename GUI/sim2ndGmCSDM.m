%% Simulations for 2ndGmCSDM model
% P. Manrique April 8, 2024

tStart1 = cputime;

SDMmodel = 'GmC2ndCTSDMParam';
load_system(SDMmodel);
load('GmC2ndOrderCTSDM_GP.mat');

num_iterations = 10;
table = readtable('vdvars_tab.csv');
load('bw.mat')


variables_filePath = 'GmC2ndOrderCTSDM_GP.mat';


%% Parameters
osr = table.OSR;
fs = 2.*bw.*osr;
gm = table.gm;
gm11 = gm;
gm12 = gm;
C = table.C;
C1 = C;
C2 = C;
Adc11 = table.Adc11;
Adc12 = table.Adc12;
GBW1 = table.GBW1;
GBW2 = table.GBW2;
IIP3 = table.IIP3;
IIP3_in = IIP3; %*(1+(rand-0.5)*0.5); %% IIP3_in
IIP3_12 = IIP3; %*(1+(rand-0.5)*0.5); %% IIP3_12
IIP3_a = IIP3; %% IIP3_a
IIP3_b = IIP3; %% IIP3_b
IIP3_c = IIP3; %% IIP3_c
R11 = table.R11;
R12 = table.R12;
Cp1 = table.Cp1;
Cp2 = table.Cp2;

% Remaining parameters
fin = bw./(3*1.01234566); % Input freq. tone
ts = 1./fs; Ts = ts; %Sampling time

%% Simulations
SDin(1:num_iterations) = Simulink.SimulationInput(SDMmodel);

for n = 1:num_iterations
    SDin(n) = SDin(n).setVariable('BW',bw);
    SDin(n) = SDin(n).setVariable('M',osr(n));
    SDin(n) = SDin(n).setVariable('fs',fs(n));
    SDin(n) = SDin(n).setVariable('fin',fin);
    SDin(n) = SDin(n).setVariable('ts',ts(n));
    SDin(n) = SDin(n).setVariable('gm11',gm11(n));
    SDin(n) = SDin(n).setVariable('gm12',gm12(n));
    SDin(n) = SDin(n).setVariable('C1',C1(n));
    SDin(n) = SDin(n).setVariable('C2',C2(n));
    SDin(n) = SDin(n).setVariable('Adc11',Adc11(n));
    SDin(n) = SDin(n).setVariable('Adc12',Adc12(n));
    SDin(n) = SDin(n).setVariable('R11',R11(n));
    SDin(n) = SDin(n).setVariable('R12',R12(n));
    SDin(n) = SDin(n).setVariable('GBW1',GBW1(n));
    SDin(n) = SDin(n).setVariable('GBW2',GBW2(n));
    SDin(n) = SDin(n).setVariable('Cp1',Cp1(n));
    SDin(n) = SDin(n).setVariable('Cp2',Cp2(n));
    SDin(n) = SDin(n).setVariable('IIP3_in',IIP3_in(n));
    SDin(n) = SDin(n).setVariable('IIP3_12',IIP3_12(n));
    SDin(n) = SDin(n).setVariable('IIP3_a',IIP3_a(n));
    SDin(n) = SDin(n).setVariable('IIP3_b',IIP3_b(n));
    SDin(n) = SDin(n).setVariable('IIP3_c',IIP3_c(n));
    SDin(n) = SDin(n).setVariable('gm',gm(n));
end 
        
disp(cputime - tStart1)

snr_sim = zeros(num_iterations,1);
power_sim = snr_sim;
fom_sim = snr_sim;
bw_sim = fom_sim;

% Run first simulation
SDout1 = sim(SDin(1),'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load GmC2ndOrderCTSDM_GP.mat'));
%'AttachedFiles',variables_filePath,...

gm11_r1 = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDin), [], 1);
gm12_r1 = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin), [], 1);
gm_r1 = reshape(arrayfun(@(obj) obj.Variables(23).Value, SDin), [], 1);

snr1 = fsnr(SDout1(1,1).out, 1, N, fs(1), fin, bw, 30, 30, 1, 1, 1);
snr_sim(1) = snr1;
power_sim(1) = (gm11_r1(1)+gm12_r1(1)+gm_r1(1)*fi+gm_r1(1)*f11+gm_r1(1)*f12)*Vr^2+0.05*gm_r1(1)*(2^B-1)*Vr.^2;

% Run parallel simulations
tStart2 = cputime;
fprintf('Running parallel simulations')
SDinV = SDin(2:num_iterations);
SDout=sim(SDinV,'ShowProgress','on',...%'TransferBaseWorkspaceVariables','off',...
    'SetupFcn',@()evalin('base','load GmC2ndOrderCTSDM_GP.mat')); 
%'AttachedFiles',variables_filePath,...
disp(cputime - tStart2)
fprintf('Saving Data ...')

bw_r = reshape(arrayfun(@(obj) obj.Variables(1).Value, SDinV), [], 1);
osr_r = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDinV), [], 1);
fs_r = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDinV), [], 1);
fin_r = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDinV), [], 1);
gm11_r = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDinV), [], 1);
gm12_r = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDinV), [], 1);
c1 = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDinV), [], 1);
c2 = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDinV), [], 1);
adc11 = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDinV), [], 1);
adc12 = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDinV), [], 1);
r11 = reshape(arrayfun(@(obj) obj.Variables(12).Value, SDinV), [], 1);
r12 = reshape(arrayfun(@(obj) obj.Variables(13).Value, SDinV), [], 1);
gbw1 = reshape(arrayfun(@(obj) obj.Variables(14).Value, SDinV), [], 1);
gbw2 = reshape(arrayfun(@(obj) obj.Variables(15).Value, SDinV), [], 1);
cp1 = reshape(arrayfun(@(obj) obj.Variables(16).Value, SDinV), [], 1);
cp2 = reshape(arrayfun(@(obj) obj.Variables(17).Value, SDinV), [], 1);
iip3_in = reshape(arrayfun(@(obj) obj.Variables(18).Value, SDinV), [], 1);
iip3_12 = reshape(arrayfun(@(obj) obj.Variables(19).Value, SDinV), [], 1);
iip3_a = reshape(arrayfun(@(obj) obj.Variables(20).Value, SDinV), [], 1);
iip3_b = reshape(arrayfun(@(obj) obj.Variables(21).Value, SDinV), [], 1);
iip3_c = reshape(arrayfun(@(obj) obj.Variables(22).Value, SDinV), [], 1);
gm_r = reshape(arrayfun(@(obj) obj.Variables(23).Value, SDinV), [], 1);

c = c1;
iip3 = iip3_in;

dvars_var = horzcat(osr_r,c,adc11,adc12,r11,r12,gbw1,gbw2,cp1,cp2,iip3,gm_r);

power_var = (gm11_r+gm12_r+gm_r.*fi+gm_r.*f11+gm_r.*f12).*Vr.^2+0.05*gm_r.*(2.^B-1).*Vr.^2;

snr_var = zeros(num_iterations-1,1);
for n = 1:num_iterations-1
    try
        out = SDout(1,n).out;
        snr_var(n) = fsnr(out, 1, N, fs_r(n), fin_r(n), bw_r(n), 30, 30, 1, 1, 1);
    catch
        snr_var(n) = 0;
    end
end

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

%% PSD

[snr_max,idx_max] = max(snr_sim);
if idx_max ~= 1
    n = idx_max-1;
    y = SDout(1,n).out;
else
    n = 1;
    y = SDout1(1,1).out;
end

W = hann(N);
X = spdb(y,N,W,fs);

figure;
plot(X);

%[pxx,f] = pwelch(y,[],[],[],fs(n));
%figure;
%plot(f,10*log10(pxx));


xlabel('Frequency (Hz)');
ylabel('PSD (dB)');
title('Power Spectral Density');

figfilename = 'figPSD.png';
saveas(gcf, figfilename);