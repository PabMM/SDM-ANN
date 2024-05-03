%% Validation simulations for 2ndGmCSDM model
% P. Manrique March 25, 2024

clear;
close all;
tStart1 = cputime;

SDMmodel = 'GmC2ndCTSDMParam';
load_system(SDMmodel);
load('GmC2ndOrderCTSDM_GP.mat');

classifier_model = 'GB';
num_iterations = 10;
validation = {'ANN','LUT'};

%% Run simulations for each iteration dataset
for k = 1:2
    val = validation{k};
    data_path = [cd,'/VAL-DS/Multiple-Iterations-',val,'/classifier',classifier_model,'_2ndGmCSDM_val_'];
    variables_filePath = 'GmC2ndOrderCTSDM_GP.mat';
    
    for i = 1:num_iterations
        % Read data
        table = importfile_SC([data_path,num2str(i),'.csv']);
        [rows,~]=size(table);
        %rows = 10;
        
    
        if i == 1
            SNR_asked = table.SNR;
            power_asked = table.Power;
            Bw_asked = table.Bw;
            fom_asked = SNR_asked+10*log10(Bw_asked./power_asked);
        
            SNR_sim = zeros(rows,num_iterations);
            power_sim = SNR_sim;
            fom_sim = SNR_sim;
        end
    
        % Parameters
        Bw = table.Bw;
        osr = table.OSR;
        fs = 2.*Bw.*osr;
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
        fin = Bw./(3*1.01234566); % Input freq. tone
        ts = 1./fs; Ts = ts; %Sampling time

        % Simulations
        SDin(1:rows) = Simulink.SimulationInput(SDMmodel);

        for n = 1:rows
            SDin(n) = SDin(n).setVariable('BW',Bw(n));
            SDin(n) = SDin(n).setVariable('M',osr(n));
            SDin(n) = SDin(n).setVariable('fs',fs(n));
            SDin(n) = SDin(n).setVariable('fin',fin(n));
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
            ps = (n/rows)*100;
            fprintf('Loading Simulations Parameters for %s validation dataset #%d: Progress (%%) = %6.2f\n',val,i,ps)
        end 
        
        disp(cputime - tStart1)

        % Run parallel simulations
        tStart2 = cputime;
        fprintf('Running parallel simulations')
        SDout=parsim(SDin,'ShowProgress','on','TransferBaseWorkspaceVariables','off',...
            'AttachedFiles',variables_filePath,...
            'SetupFcn',@()evalin('base','load GmC2ndOrderCTSDM_GP.mat')); 
        disp(cputime - tStart2)
        fprintf('Saving Data ...')
        
        bw = reshape(arrayfun(@(obj) obj.Variables(1).Value, SDin), [], 1);
        osr = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin), [], 1);
        fs_r = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin), [], 1);
        fin_r = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin), [], 1);
        gm11_r = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDin), [], 1);
        gm12_r = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin), [], 1);
        c1 = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin), [], 1);
        c2 = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDin), [], 1);
        adc11 = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDin), [], 1);
        adc12 = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDin), [], 1);
        r11 = reshape(arrayfun(@(obj) obj.Variables(12).Value, SDin), [], 1);
        r12 = reshape(arrayfun(@(obj) obj.Variables(13).Value, SDin), [], 1);
        gbw1 = reshape(arrayfun(@(obj) obj.Variables(14).Value, SDin), [], 1);
        gbw2 = reshape(arrayfun(@(obj) obj.Variables(15).Value, SDin), [], 1);
        cp1 = reshape(arrayfun(@(obj) obj.Variables(16).Value, SDin), [], 1);
        cp2 = reshape(arrayfun(@(obj) obj.Variables(17).Value, SDin), [], 1);
        iip3_in = reshape(arrayfun(@(obj) obj.Variables(18).Value, SDin), [], 1);
        iip3_12 = reshape(arrayfun(@(obj) obj.Variables(19).Value, SDin), [], 1);
        iip3_a = reshape(arrayfun(@(obj) obj.Variables(20).Value, SDin), [], 1);
        iip3_b = reshape(arrayfun(@(obj) obj.Variables(21).Value, SDin), [], 1);
        iip3_c = reshape(arrayfun(@(obj) obj.Variables(22).Value, SDin), [], 1);
        gm_r = reshape(arrayfun(@(obj) obj.Variables(23).Value, SDin), [], 1);

        power = (gm11_r+gm12_r+gm_r.*fi+gm_r.*f11+gm_r.*f12).*Vr.^2+0.05*gm_r.*(2.^B-1).*Vr.^2;


        snr = zeros(rows,1);
        for n = 1:rows
            try
                out = SDout(1,n).out;
                snr(n) = fsnr(out, 1, N, fs_r(n), fin_r(n), bw(n), 30, 30, 1, 1, 1);
            catch
                snr(n) = 0;
            end
        end
        SNR_sim(:,i) = snr;
        power_sim(:,i) = power;
        fom_sim(:,i) = SNR_sim(:,i)+10*log10(bw./power_sim(:,i));
    end

    save(['VAL-DS/sim_2ndGmCSDM_',val,'_',classifier_model,'_',num2str(num_iterations),'.mat'],"SNR_asked","SNR_sim","power_sim","power_asked","fom_sim","fom_asked")

end


%%

function SNR = try_snr(obj,bandwith,N,fs,fin,n)
    if isempty(obj.ErrorMessage)
        out=obj(1,n).out;
        SNR = fsnr(out,1,N,fs,fin,bandwith,30,30,1,1,1);
    else
        SNR = 0;
    end
end

function SCANN2orGmSDMval1 = importfile_SC(filename, dataLines)
%IMPORTFILE Import data from a text file
%  SCANN2ORGMSDMVAL1 = IMPORTFILE(FILENAME) reads data from text file
%  FILENAME for the default selection.  Returns the data as a table.
%
%  SCANN2ORGMSDMVAL1 = IMPORTFILE(FILE, DATALINES) reads data for the
%  specified row interval(s) of text file FILENAME. Specify DATALINES as
%  a positive scalar integer or a N-by-2 array of positive scalar
%  integers for dis-contiguous row intervals.
%
%  Example:
%  SCANN2orGmSDMval1 = importfile("C:\Users\Jose\Desktop\Pablo\AIHub\VALIDATION\VAL-DS\Multiple-Iterations-SC\SCANN_2orGmSDM_val_1.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 28-Jun-2023 22:46:09

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Set up the Import Options and import the data
numvariables = 15;
opts = delimitedTextImportOptions("NumVariables", numvariables);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SNR", "Bw", "Power", "OSR", "C", "Adc11", "Adc12", "R11", "R12", "GBW1", "GBW2", "Cp1", "Cp2", "IIP3", "gm"];
opts.VariableTypes = repmat("double",1,numvariables);

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
SCANN2orGmSDMval1 = readtable(filename, opts);

end