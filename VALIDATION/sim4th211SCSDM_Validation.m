%% Validation simulations for 4th order 2-1-1 Cascade SC SDM model
% P. Manrique March 26, 2024

clear;
close all;
tStart1 = cputime;

SDMmodel = 'umts211_real_PM';
load_system(SDMmodel);
load('211CascadeSDM_GP.mat');

classifier_model = 'GB';
num_iterations = 10;
validation = {'ANN','LUT'};

%% Run simulations for each iteration dataset
for k = 1:1
    val = validation{k};
    data_path = [cd,'/VAL-DS/Multiple-Iterations-',val,'/classifier',classifier_model,'_4th211SCSDM_val_'];
    variables_filePath = '211CascadeSDM_GP.mat';
    
    for i = 1:num_iterations
        % Read data
        table = importfile_SC([data_path,num2str(i),'.csv']);
        [rows,~]=size(table);
        rows = 10;
    
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
        SDin(1:rows) = Simulink.SimulationInput(SDMmodel);

        for n = 1:rows
            SDin(n) = SDin(n).setVariable('ts', ts(n));
            SDin(n) = SDin(n).setVariable('fs', fs(n));
            SDin(n) = SDin(n).setVariable('OSR', osr(n));
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
            SDin(n) = SDin(n).setVariable('Bw', Bw(n));
            SDin(n) = SDin(n).setVariable('fin',fin(n));
            ps = (n/rows)*100;
            fprintf('Loading Simulations Parameters for %s validation dataset #%d: Progress (%%) = %6.2f\n',val,i,ps)
        end 
        
        disp(cputime - tStart1)

        % Run parallel simulations
        tStart2 = cputime;
        fprintf('Running parallel simulations')
        SDout=parsim(SDin,'ShowProgress','on','TransferBaseWorkspaceVariables','off',...
            'AttachedFiles',variables_filePath,...
            'SetupFcn',@()evalin('base','load 211CascadeSDM_GP.mat')); 
        disp(cputime - tStart2)
        fprintf('Saving Data ...')
        
        fs_d = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin), [], 1);
        osr = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin), [], 1);
        adc1 = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin), [], 1);
        gm1 = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDin), [], 1);
        io1 = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDin), [], 1);
        adc2 = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin), [], 1);
        gm2 = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin), [], 1);
        io2 = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDin), [], 1);
        adc3 = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDin), [], 1);
        gm3 = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDin), [], 1);
        io3 = reshape(arrayfun(@(obj) obj.Variables(12).Value, SDin), [], 1);
        adc4 = reshape(arrayfun(@(obj) obj.Variables(13).Value, SDin), [], 1);
        gm4 = reshape(arrayfun(@(obj) obj.Variables(14).Value, SDin), [], 1);
        io4 = reshape(arrayfun(@(obj) obj.Variables(15).Value, SDin), [], 1);
        bw = reshape(arrayfun(@(obj) obj.Variables(16).Value, SDin), [], 1);
        snr = reshape(arrayfun(@(obj) obj.SNRArray1, SDout),[],1);
        alfa = 0.05;
        B = 3;
        io_avg = 0.25*(io1+io2+io3+io4);
        pq = alfa*(1+1+(2^B - 1))*io_avg;
        power = io1 + io2 + io3 + io4 + pq;

        SNR_sim(:,i) = snr;
        power_sim(:,i) = power;
        fom_sim(:,i) = SNR_sim(:,i)+10*log10(bw./power_sim(:,i));
    end

    %save(['VAL-DS/sim_4th211SCSDM_',val,'_',classifier_model,'_',num2str(num_iterations),'.mat'],"SNR_asked","SNR_sim","power_sim","power_asked","fom_sim","fom_asked")

end

function classifierGB211CascadeSDMval6 = importfile_SC(filename, dataLines)
%IMPORTFILE Import data from a text file
%  CLASSIFIERGB211CASCADESDMVAL6 = IMPORTFILE(FILENAME) reads data from
%  text file FILENAME for the default selection.  Returns the data as a
%  table.
%
%  CLASSIFIERGB211CASCADESDMVAL6 = IMPORTFILE(FILE, DATALINES) reads
%  data for the specified row interval(s) of text file FILENAME. Specify
%  DATALINES as a positive scalar integer or a N-by-2 array of positive
%  scalar integers for dis-contiguous row intervals.
%
%  Example:
%  classifierGB211CascadeSDMval6 = importfile("C:\Users\Jose\Desktop\Pablo\AIHub\VALIDATION\VAL-DS\Multiple-Iterations-C\classifierGB_211CascadeSDM_val_6.csv", [2, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 27-Jul-2023 14:25:20

% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 16);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SNR", "Bw", "Power", "OSR", "Adc1", "gm1", "Io1", "Adc2", "gm2", "Io2", "Adc3", "gm3", "Io3", "Adc4", "gm4", "Io4"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
classifierGB211CascadeSDMval6 = readtable(filename, opts);

end