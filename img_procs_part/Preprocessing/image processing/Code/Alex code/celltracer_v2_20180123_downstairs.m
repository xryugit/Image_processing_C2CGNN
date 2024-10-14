%CELLTRACER_V2_SCRIPT
%   


function [ip, op] = celltracer_v2_20180123_downstairs()
%Initialize Celltracer Parameter Structures
[ip, op] = celltracer_v2_partner('initialize');


%% Define Imaging Parameters
%   --------- EDIT THIS SECTION TO DEFINE THE IMAGE DATA ---------
%Data locations:
%Target imaging data file name (must include path)
fpath = './';  %<- This assumes it is in current folder
fname = '20180123 MCF10 EKAR Fra T4 ratio expt downstairs.nd2';
%   Assemble complete path for data file
dd = dir([fpath, fname]);
ip.fname = fullfile(dd.folder, dd.name); 
%Target save name for processed data files (include path)
spath = '../Processed Data/'; %<- Assumes a parallel folder
sname = '20180123_Downstairs';
%   Assemble complete path for save file
dd = dir([spath, sname]);
ip.sname = fullfile(dd.folder, dd.name);   

%Data - basic statistics
%   Provide the expected size of imaging data
ip.indsz.xy = [61];   %Number of XY positions
ip.indsz.z  = [1];   %Number of Z positions
ip.indsz.t  = [228];   %Number of Time points
ip.indsz.c  = [4];   %Number of color Channels
ip.tsamp    = [7];   %Time between samples (MUST BE FILLED)

%Data - detailed definitions
%   Provide the baseline image intensity value (from Camera)
ip.bval = 100;
%   Initialize the properly sized bkg structure
ip.bkg(ip.indsz.xy) = ip.bkg; 
[ip.bkg.fix]    = deal(false);  %Default fix is false
[ip.bkg(1:61).dyn]    = deal(true);   %Default dyn is true
[ip.bkg(61).bkonly] = deal(true);  %Default bkonly is false 
%   Provide background regions or values for each XY position
ip.bkg(61).reg    = [788, 25; 948, 161];     %Region (or fixed values)
[ip.bkg([1:60]).altxy]  = deal(61);     	%Index of alternate XY to 

%   Provide expected (or measured) frame-shift events
ip.xyshift.frame = [];      %Time indices of first shifted frames
ip.xyshift.dx    = [];      %x magnitude of shift (omit for tracking)
ip.xyshift.dy    = [];      %y magnitude of shift (omit for tracking)
ip.xyshift.trackwell = [];  %XY index for use in tracking
ip.xyshift.trackchan = [];  %Channel to use in tracking
ip.xyshift.badtime   = [];  %Time points bad for tracking (optional)
ip.xyshift.shifttype = 'translation';  %Type of shift to perform

%   Provide backup imaging MetaData:
%       (** = Critical for all runs, ++ = Only for objbias)
    %   Parameters of the objective
    %   ---------------------------------------------------------------
    ip.bkmd.obj.Desc       =   'Apo_20x';  %Description of Objective
    ip.bkmd.obj.Mag        =   20;         %Magnification ++
    ip.bkmd.obj.WkDist     =   1;          %Working Distance (mm) ++
    ip.bkmd.obj.RefIndex   =   1;          %Index of Refraction ++
    ip.bkmd.obj.NA         =   0.75;       %Numerical Aperture ++
    %   Parameters of the camera
    %   ---------------------------------------------------------------
    ip.bkmd.cam.Desc       =   'Zyla5';    %Descriptor of camera
    ip.bkmd.cam.PixSizeX   =   0.65;       %Pixel horizontal size (um) **
    ip.bkmd.cam.PixSizeY   =   0.65;       %Pixel vertical size (um) **
    ip.bkmd.cam.PixNumX    =   1280;       %Number of Pixels in X **
    ip.bkmd.cam.PixNumY    =   1080;       %Number of Pixels in Y **
    ip.bkmd.cam.BinSizeX   =   2;          %Number of Pixels per bin, X
    ip.bkmd.cam.BinSizeY   =   2;          %Number of Pixels per bin, Y
    %   Parameters of the exposures
    %   ---------------------------------------------------------------
    %   Declare here names for the color channels, in proper order.  
    %       All other entries in ip.bkmd.exp must be in the same order.
    ip.bkmd.exp.Channel    =   {'DAPI', 'EKAR_CFP', 'EKAR_YFP', 'Fra1_RFP'};  %Name(s) of Channel(s)
    
    %   ----- OPTIONAL - Only for use with Spectral Unmixing -----
    %   Declare the Filters for each Channel ++
    ip.bkmd.exp.Filter     =   {'Filter_DAPI', 'Filter_CFP', 'Filter_YFP', 'Filter_Cherry2'};
    %   Declare the target Fluorophores for each Channel ++
    ip.bkmd.exp.FPhore     =   {'DAPI', 'CFP', 'YFP', 'RFP'};
    %       -> See iman_naming for valid Filter and Fluorophore Names    
    %   Declare the Channel names associate with each FRET pair
    %       (only needed for pixel-by-pixel spectral unmixing of FRET)
    ip.bkmd.exp.FRET       =   {};% struct('EKAR', {{'CFP','YFP'}}); % {[1,2]}
    ip.bkmd.exp.Light      =   'SOLA';           %Light source name ++
    ip.bkmd.exp.Exposure   =   {100, 150, 100, 500};  %Exposure times (ms) ++
    ip.bkmd.exp.ExVolt     =   {10, 14, 15, 40};     %Relative voltage (0-100) ++
    %   IF using the SPECTRAX light source, also define the following:
%     ip.bkmd.exp.ExLine     =   {[],[],[]};   %Excitation line
%     ip.bkmd.exp.ExWL       =   {[],[],[]};   %Wavelength
    %   ----- ----------------------------------------------- -----


%Show final image parameters (Comment out the following to avoid printing)
display(ip);
fprintf('\nip.indsz = \n\n');  display(ip.indsz); 
fprintf('\nip.bkmd = \n\n');   display(ip.bkmd);
%   ------ ------ END OF IMAGE DATA DEFINITION SECTION ------ ------


%% Define Operation Parameters
%   -------- EDIT THIS SECTION TO SETUP THE PROCESSING RUN --------
%Procedure scope - target ranges of the data to process
op.cind     = [1:4];       %Indices of Channels to process (names or indices)
op.xypos    = [1:61];       %Indices of XY positions to process
op.trng     = [1:228];       %Start and End indices of Time to process
op.nW       = 10;        %Number of parallel workers to use
%   Optional procedures
op.flatten = false;
op.objbias  = true;     %Correct for objective view bias
op.unmix    = false;  	%Linearly unmix color channel cross-talk
op.fixshift = false;  	%Correct any indicated frameshifts

%   Indicate which fields of bkmd should override any other MetaData source
%   (use when recorded MetaData are corrupted)
op.mdover   = {'exp', 'ExVolt'; 'exp', 'Exposure';'exp','Filter'; ...
    'exp','Channel'; 'exp','FPhore'};

%Procedure settings ***CRITICAL - Review carefully
%   Segmentation settings
op.seg.chan = [4];       %Color channel on which to segment
op.seg.cyt  = false; 	%Segment on cytoplasmic signal
%       The following defaults are typical of MCF10As at 20x magnification
op.seg.maxD = 35;       %Maximum nuclear diameter (um)
op.seg.minD = 9;      	%Minimum nuclear diameter (um)
%       It is recommended to scale imaging for nuclei (segmentation
%       targets) to be greater than 10 pixels in diameter.
op.seg.maxEcc = 0.9;    %Maximum eccentricity [0-1] (opposite of circularity)
op.seg.Extent = [0.65, 0.85]; %Minimum fraction of bounding box filled 
%   Extent range is [0-1], value for a cirlce is PI/4
op.seg.sigthresh = []; %[Optional] Minimum intensity of 'good' signal
%   If you use sigthresh, pre-subtract any camera baseline
op.seg.hardsnr = false;  %Typically kept to FALSE.  TRUE makes the signal 
%   threshold 'hard', enforcing cutoff of any pixels below it.

%    Masking settings
op.msk.rt = {};             %Pre-averaging channel ratios to take {{'',''}}
op.msk.storemasks = false;  %Save all segmentation masks
op.msk.saverawvals = true;  %Save all raw valcube entries (pre-tracking)
%   IF additional aggregation functions are desired, define here
%       For example:
%           op.msk.aggfun.name = 'var';
%           op.msk.aggfun.chan = {'CNAME1', 'CNAME2', ...};
%           op.msk.aggfun.loc = {'Nuc','Cyt'};
%           op.msk.aggfun.fun = @var;

% Tracking settings (for utrack)
op.trk.movrad = 25;     % Radius (in um) to consider for cell movement
op.trk.linkwin = 75;    % Time window (in min) to consider for tracking

%   Display settings - select which options to show while running
op.disp.meta     = false;       %Final MetaData to be used
op.disp.samples  = false;       %Sparse samples of segmentation
op.disp.shifts   = false;       %Shifted images
op.disp.warnings = true;       %Procedural warning messages

%Show final operation parameters (uncomment to show)
% display(op);
% fprintf('\nop.seg = \n\n');  display(op.seg); 
% fprintf('\nop.disp = \n\n');  display(op.disp); 
%   ------ ------ END OF PROCESSING RUN SETUP SECTION ------ ------

%   Do NOT edit the following parameter transfers
op.cname    = ip.bkmd.exp.Channel;  %Copy channel names to op
op.msk.fret = ip.bkmd.exp.FRET;     %Copy FRET channel names to op


%% Run image analysis procedure
%Pre-Run validation
[ip, op] = celltracer_v2_partner('validate', ip, op);

%Segmentation test:
% pst = [];
% pst = iman_segcheck(ip, op, 'xy', 1, 't', 1, 'pastinfo', pst);

%Main procedure
[dao, GMD, dmx] = iman_celltracer(ip, op);



end





