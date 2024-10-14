%Image Data Processing Script
%       for
%   

function [d,p] = proc_runner(inp)

%% Define data
%   Path
fp = 'L:\Alex\Alex Processed Data\20171030 S1 T4 CC EGF AREG Exo Other Plate 1\';
%   File Base Name
bn = '20171030_S1T4_Plate1';
%   XY files to include
xy = [1:60];
%   FRET channels
fc = {};

%% Define processing parameters
%   State sampling interval
tsamp = 6;
%   Declare (new) output channel names
cn = {'S1', 'T4'};
%   Declare matching input channel indices (or descriptors)
%       for ratios list numerator (or FRET Donor) first, x/y => [x,y]
ci = {[5,2],[6,3]}; 
%   Set minimum track length
minL = 25; 
%   Set maximum gap size
maxGap = 2;
%   Set 'start only' flag
sto = false;
%   Set other stuff

%Save flag
savefile = true;


%% Prepare for processing
%If dataproc is not on the path, add a typical path
% if ~exist('ct_dataproc','file')
%     addpath('L:\Code\Cell Trace\');
% end

%Set file prefix, with base name
fa1 = [fp,'\',bn,'_xy'];
%Set file extension
fa2 = '.mat';
%Build set of filenames
dh = '0';   %Spacer for numbers
f_auto = arrayfun(@(x)[fa1, dh(x<10), num2str(x), fa2], xy, ...
    'UniformOutput', false);

%Map any channel descriptors to indices
if any(cellfun(@ischar, [ci,ci{cellfun(@iscell,ci)}]))
    load(f_auto{1}, 'vcorder');     %Load VC Order
    %Check each entry for descriptors
    for sc = 1:length(ci)
        if iscell(ci{sc})   %IF a cell (ratio), look inside
            for scc = 1:length(ci{sc})
                if ischar(ci{sc}{scc})  %IF descriptor, parse
                    ci{sc}{scc} = parsechannel(vcorder, ci{sc}{scc});
                end
            end
            %Re-pack new ratio indices into array
            ci{sc} = [ci{sc}{:}];
        elseif ischar(ci{sc})   %IF descriptor, parse
            ci{sc} = parsechannel(vcorder, ci{sc});
        end
    end
end


if exist('fc','var') && ~isempty(fc)
    %Get MetaData from Global file
    load([fp,'\',bn,'_Global.mat'],'GMD');
    %Calculate power ratio for FRET signals
    prat = iman_powerratio_est(GMD,[],fc);
end

%% Run dataproc with params
[d,p] = ct_dataproc(f_auto, 'name', cn, 'ind', ci,...
'tsamp', tsamp, 'dlengthmin', minL,...
'gapmax', maxGap, 'startonly', sto);   

%Save if desired
if savefile
    svn = [fp,'\',bn,'_proc.mat'];  %Generate save name
    save(svn,'d','p');              %Save processed data
end

% EKARthresh = [0.1,0.8];
% [d0915] = dataFilt(d0915,EKARthresh,'ekar','thresh');
% % clear samplingtime channelnames channelindex minimumlength dh 
% % clear fa* xy_a f_auto prat EKARthresh
% % generate graphs
% [pmd,idx] = iman_readdatasheet('L:\Databases\ImagingExperimentSheets\2017-9-15-nciMEF-KCQN.xlsx');
% plot_by('celltype',d0915,'ekar',pmd)
% plot_by('treatments',d0915,'ekar',pmd)
% plotby_singlecells('treatment',d0915,'ekar',pmd,'lines',1)

end



%%
function id = parsechannel(vc, cdesc)
%Get tags from descriptor
tags = regexpi(cdesc,'_|/s','split');
%Match each tag against VC Order Labels
mtch = cell(1,numel(tags));
for s = 1:numel(tags)
    mtch{s} = ~cellfun(@isempty,regexpi(vc, tags{s}));
end
%Final ID is intersection of all matches
id = find(all([mtch{:}],2));
end




