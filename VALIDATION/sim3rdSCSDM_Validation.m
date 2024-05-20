%% Validation simulations for 3rd order SC SDM model
% P. Manrique March 26, 2024

clear;
close all;
tStart1 = cputime;

SDMmodel = 'ThirdOrderCascadeSingleBitSC';
load_system(SDMmodel);
load('3rd21SCSDM_GP.mat');

classifier_model = 'GB';
num_iterations = 10;
validation = {'ANN','LUT'};

%% Run simulations for each iteration dataset
for k = 1:2
    val = validation{k};
    data_path = [cd,'/VAL-DS/Multiple-Iterations-',val,'/classifier',classifier_model,'_3or21SCSDM_val_'];
    variables_filePath = '3rd21SCSDM_GP.mat';
    
    for i = 1:num_iterations
        % Read data
        table = importfile_SC([data_path,num2str(i),'.csv']);
        [rows,~]=size(table);
        %rows = 10;
    
        if i == 1
            SNDR_asked = table.SNDR;
            power_asked = table.Power;
            Bw_asked = table.Bw;
            fom_asked = SNDR_asked+10*log10(Bw_asked./power_asked);
        
            SNDR_sim = zeros(rows,num_iterations);
            power_sim = SNDR_sim;
            fom_sim = SNDR_sim;
        end
    
        % Parameters
        Bw = table.Bw;
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
        SDin(1:rows) = Simulink.SimulationInput(SDMmodel);

        for n = 1:rows
            SDin(n) = SDin(n).setVariable('Ts', ts(n));
            SDin(n) = SDin(n).setVariable('fs', fs(n));
            SDin(n) = SDin(n).setVariable('M', osr(n));
            SDin(n) = SDin(n).setVariable('ao1', Adc1(n));
            SDin(n) = SDin(n).setVariable('gm1', gm1(n));
            SDin(n) = SDin(n).setVariable('io1', io1(n));
            SDin(n) = SDin(n).setVariable('ao2', Adc2(n));
            SDin(n) = SDin(n).setVariable('gm2', gm2(n));
            SDin(n) = SDin(n).setVariable('io2', io2(n));
            SDin(n) = SDin(n).setVariable('Bw', Bw(n));
            SDin(n) = SDin(n).setVariable('fin',fi(n));
            ps = (n/rows)*100;
            fprintf('Loading Simulations Parameters for %s validation dataset #%d: Progress (%%) = %6.2f\n',val,i,ps)
        end 
        
        disp(cputime - tStart1)

        % Run parallel simulations
        tStart2 = cputime;
        fprintf('Running parallel simulations')
        SDout=parsim(SDin,'ShowProgress','on','TransferBaseWorkspaceVariables','on',...
            'AttachedFiles',variables_filePath,...
            'SetupFcn',@()evalin('base','load 3rd21SCSDM_GP.mat')); 
        disp(cputime - tStart2)
        fprintf('Saving Data ...')
        
        osr = reshape(arrayfun(@(obj) obj.Variables(3).Value, SDin), [], 1);
        adc1 = reshape(arrayfun(@(obj) obj.Variables(4).Value, SDin), [], 1);
        gm1_r = reshape(arrayfun(@(obj) obj.Variables(5).Value, SDin), [], 1);
        io1_r = reshape(arrayfun(@(obj) obj.Variables(6).Value, SDin), [], 1);
        adc2 = reshape(arrayfun(@(obj) obj.Variables(7).Value, SDin), [], 1);
        gm2_r = reshape(arrayfun(@(obj) obj.Variables(8).Value, SDin), [], 1);
        io2_r = reshape(arrayfun(@(obj) obj.Variables(9).Value, SDin), [], 1);
        bw = reshape(arrayfun(@(obj) obj.Variables(10).Value, SDin), [], 1);
        fs_r = reshape(arrayfun(@(obj) obj.Variables(2).Value, SDin), [], 1);
        fin_r = reshape(arrayfun(@(obj) obj.Variables(11).Value, SDin), [], 1);
        %SNDR = reshape(arrayfun(@(obj) obj.SNDRArray, SDout),[],1);
        alfa = 0.05;
        power = (io1_r + io2_r)*(1 + alfa) + io2_r*(1+alfa);
        
        sndr = zeros(rows,1);

        for n = 1:rows
            sndr(n) = fsnr(SDout(1,n).y, 1, N, fs_r(n), fin_r(n), bw(n), 30, 30, 1, 1, 2);
        end

        SNDR_sim(:,i) = sndr;
        power_sim(:,i) = power;
        fom_sim(:,i) = SNDR_sim(:,i)+10*log10(bw./power_sim(:,i));
    end

    save(['VAL-DS/sim_3rdSCSDM_',val,'_',classifier_model,'_',num2str(num_iterations),'.mat'],"SNDR_asked","SNDR_sim","power_sim","power_asked","fom_sim","fom_asked")

end

function SCANN3orCascadeSDMval29 = importfile_SC(filename, dataLines)


% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 10);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SNDR", "Bw", "Power", "OSR", "Adc1", "gm1", "Io1", "Adc2", "gm2", "Io2"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
SCANN3orCascadeSDMval29 = readtable(filename, opts);

end