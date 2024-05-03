import mlreportgen.report.* 
import mlreportgen.dom.* 
rpt = Report('report','pdf'); 
rpt.Locale = 'english';

tp = TitlePage;
tp.Title = 'SDM-App report';
tp.PubDate = date();
add(rpt,tp);

secspecs = Section; 
secspecs.Title = 'Specifications'; 
secspecs.Numbered = false;

sec1 = Section; 
sec1.Title = 'Input Specifications';
sec1.Numbered = false;
inspecs = readtable('inspecs.csv');
inspecs.Properties.VariableNames = {'FOM (dB)','SNR (dB)','BW (Hz)','Power (W)'};
% formatSpec = '%.6f';
% TFormatted = cellfun(@(x) num2str(x, formatSpec), table2cell(inspecs), 'UniformOutput', false);
% TFormatted = cell2table(TFormatted, 'VariableNames', inspecs.Properties.VariableNames);

tinspecs = Table(inspecs);
tinspecs.BackgroundColor = 'azure';
tinspecs.RowSep = 'solid';


append(sec1,tinspecs) 
append(secspecs,sec1) 

sec2=Section; 
sec2.Title = 'RNN Output Specifications';
sec2.Numbered = false;
total_sims = readtable('total_sims.csv');
rnn_specs = total_sims(1,1:4);
rnn_specs.Properties.VariableNames = {'FOM (dB)','SNR (dB)','BW (Hz)','Power (W)'};
trnn_specs = Table(rnn_specs);
trnn_specs.BackgroundColor = 'azure';
trnn_specs.RowSep = 'solid';
 
append(sec2,trnn_specs) 
append(secspecs,sec2)

sec3 = Section;
sec3.Title = 'FOM Improving Specifications';
sec3.Numbered = false;
[~,maxidx] = max(total_sims.FOM);
best_row = total_sims(maxidx,:);
best_specs = best_row(1,1:4);
best_specs.Properties.VariableNames = {'FOM (dB)','SNR (dB)','BW (Hz)','Power (W)'};
tbest_specs = Table(best_specs);
tbest_specs.BackgroundColor = 'azure';
tbest_specs.RowSep = 'solid';

append(sec3,tbest_specs);
append(secspecs,sec3)

append(rpt,secspecs)

load('arch.mat');

secarch = Section; 
secarch.Title = strcat('Selected Architecture: ',architecture);
secarch.Numbered = false;

figfile = strcat('Figures/',architecture,'.jpg');
imgarch = imread(figfile);
clf;
imagesc(imgarch);
axis off
figarch = Figure(gcf);
figarch.Snapshot.Height = '3in';
figarch.Snapshot.Width = '6in';

append(secarch,figarch)

%para = Paragraph(['The selected architecture by the classifier was ',architecture]);
%append(secarch,para);

append(rpt,secarch); 


secdvars = Section;
secdvars.Title = 'Design Variables';
secdvars.Numbered = false;

% secrnn = Section;
% secrnn.Title = 'RNN Inferred Design Variables';
% secrnn.Numbered = false;
% 
% rnn_dvars = total_sims(1,5:end);
% trnn_dvars = Table(rnn_dvars);
% trnn_dvars.BackgroundColor = 'azure';
% trnn_dvars.RowSep = 'solid';
% 
% append(secrnn,trnn_dvars)
% append(secdvars,secrnn)
% 
% secfom = Section;
% secfom.Title = 'FOM Improved Design Variables';
% secfom.Numbered = false;
% 
% fom_dvars = best_row(1,5:end);
% tfom_dvars = Table(fom_dvars);
% tfom_dvars.BackgroundColor = 'azure';
% tfom_dvars.RowSep = 'solid';
% 
% append(secfom,tfom_dvars)
% append(secdvars,secfom)


rnn_dvars = total_sims(1,5:end);
dvars = vertcat(rnn_dvars,best_row(1,5:end));
dvarscols = rows2vars(dvars);
dvarscols.Properties.VariableNames = {'Design Variables','RNN DVars','Improved FOM DVars'};
tdvars = Table(dvarscols);
tdvars.BackgroundColor = 'azure';
tdvars.ColSep = 'solid';

append(secdvars,tdvars)

append(rpt,secdvars)

secpsd = Section;
secpsd.Title = 'Power Spectral Density Graph';
secpsd.Numbered = false;

figpsdfile = 'figPSD.png';
imgpsd = imread(figpsdfile);
clf;
imagesc(imgpsd);
axis off
figpsd = Figure(gcf);

append(secpsd,figpsd)
append(rpt,secpsd)

delete(gcf) 
close(rpt)
rptview(rpt)