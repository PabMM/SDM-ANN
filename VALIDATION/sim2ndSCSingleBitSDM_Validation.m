%% Validation simulations for 2nd order SC Single Bit SDM model
% P. Manrique March 26, 2024

clear;
close all;
tStart1 = cputime;

SDMmodel = 'SecondOrderSingleBitSC_PMM';
load_system(SDMmodel);
load('2ndSCSDM_GP.mat');

classifier_model = 'GB';
num_iterations = 1;
validation = {'ANN','LUT'};

%% Run simulations for each iteration dataset
for k = 1:1
    val = validation{k};
    data_path = [cd,'/VAL-DS/Multiple-Iterations-',val,'/classifier',classifier_model,'_2ndSCSDM_SingleBit_val_'];
    variables_filePath = '2ndSCSDM_GP.mat';
    
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
        Adc = table.Adc;
        gm = table.gm;
        io = table.Io;
        Vn = table.Vn;
    
        % Remaining parameters
        fin = Bw./5; % Input freq. tone
        ts = 1./fs; Ts = ts; %Sampling time

        % Simulations
        SDin(1:rows) = Simulink.SimulationInput(SDMmodel);

        for n = 1:rows
            SDin(n) = SDin(n).setVariable('M', osr(n));
            SDin(n) = SDin(n).setVariable('Adc', Adc(n));
            SDin(n) = SDin(n).setVariable('gm', gm(n));
            SDin(n) = SDin(n).setVariable('io', io(n));
            SDin(n) = SDin(n).setVariable('Vn', Vn(n));
            SDin(n) = SDin(n).setVariable('ts', ts(n));
            SDin(n) = SDin(n).setVariable('fs', fs(n));
            SDin(n) = SDin(n).setVariable('Bw', Bw(n));
            SDin(n) = SDin(n).setVariable('fin', fin(n));
            ps = (n/rows)*100;
            fprintf('Loading Simulations Parameters for %s validation dataset #%d: Progress (%%) = %6.2f\n',val,i,ps)
        end 
        
        disp(cputime - tStart1)

        % Run parallel simulations
        tStart2 = cputime;
        fprintf('Running parallel simulations')
        SDout=parsim(SDin,'ShowProgress','on','TransferBaseWorkspaceVariables','off',...
            'AttachedFiles',variables_filePath,...
            'SetupFcn',@()evalin('base','load 2ndSCSDM_GP.mat')); 
        disp(cputime - tStart2)
        fprintf('Saving Data ...')
        
        osr_dt = reshape(arrayfun(@(obj) obj.Variables(1).Value, SDin),[],1);
        adc_dt = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin),[],1);
        gm_dt = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin),[],1);
        io_dt = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin),[],1);
        vn_dt = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDin),[],1);
        fs_dt = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin),[],1);
        bw_dt = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin),[],1);
        alfa = 0.05;
        power = 2*io_dt*(1 + alfa);
        snr = reshape(arrayfun(@(obj) obj.SNRArray, SDout,'UniformOutput',false),[],1);
        snr = cell2mat(snr);

        SNR_sim(:,i) = snr;
        power_sim(:,i) = power;
        fom_sim(:,i) = SNR_sim(:,i)+10*log10(bw_dt./power_sim(:,i));
    end

    save(['VAL-DS/sim_2ndSCSBSDM_',val,'_',classifier_model,'_',num2str(num_iterations),'.mat'],"SNR_asked","SNR_sim","power_sim","power_asked","fom_sim","fom_asked")

end

function SCANN2ndSBSDMval29 = importfile_SC(filename, dataLines)


    % If dataLines is not specified, define defaults
    if nargin < 2
        dataLines = [2, Inf];
    end
    
    % Set up the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 8);
    
    % Specify range and delimiter
    opts.DataLines = dataLines;
    opts.Delimiter = ",";
    
    % Specify column names and types
    opts.VariableNames = ["SNR", "Bw", "Power", "OSR", "Adc", "gm", "Io", "Vn"];
    opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double"];
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    % Import the data
    SCANN2ndSBSDMval29 = readtable(filename, opts);
    
    end