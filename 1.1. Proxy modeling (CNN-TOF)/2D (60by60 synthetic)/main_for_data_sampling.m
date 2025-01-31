%%  Main for CNN proxy 
%------------------------------------------%
%---------$   by Joonyi Kim   $------------%
%---------$      190529       $------------%
%---------$   for 2D(60by60)  $------------%
%------------------------------------------%

%%% Run simulation %%%
clear; addpath(pwd); addpath([pwd '/code']);
copyfile('data/*.*', pwd);
global Po Ciw Cpw discount_rate discount_term observed_term ... 
       Cw N N_ens N_iter ...
       nx ny dx dy ...
       area ...
       dtstep pmax ...
       slstep nsteps ...
   

Po  = 60;               % oil price
Ciw = 5;                % water injection cost
Cpw = 3;                % water disposal cost
discount_rate = 0.1;    
discount_term = 365;
observed_term = 30;
Cw = 0E+06;             % drilling cost
N = 14;                 % # of wells
N_ens  = 10;            % # of perm. fields
N_iter = 50;
nx = 60;                % # of grids. x-direction
ny = 60;
dx = 120;               % [ft]
dy = 120;
area = 40;              % [acres]

slstep = 30;            % time for streamline tracing
nsteps = 1;             % # of calculations for obtaining pressure field at slstep
dtstep = 30;             % time step step
pmax = 7200;

load 'PERMX5.mat';
load 'PERMX5_selected_idx.mat';

%% make training set
%%%% parameters %%%%%
global Np ...
       direc_var  direc_fig ...
       posfile constfile

Np = 50;

directory = 'simulation';
direc_var = 'variables';
direc_fig = 'Figures';
ecldata   = '2D_JY_Eclrun';
frsdata   = '2D_JY_Frsrun';   % frontsim datafile name
permfile  = '2D_PERMX';
posfile   = '2D_POSITION';
constfile = '2D_CONSTRAINT';


%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('now initialization');
mkdir(directory); copyfile(fullfile('*.DATA'), directory);
mkdir(direc_var); mkdir(direc_fig);   
copyfile('$convert.bat', directory);
    
gen = 1;

type = [];   % random
for j = 1:N_ens
    [pos{j}] = Initialize(type);
end
wset = [1500, 1500, 5500, 5500];  % Prod. BHP(psi), Inj. BHP(psi)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% Simulate sample data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pos_fit = []; pos_vio = []; pos_tcpu = []; pos_mat = []; pos_mat2 = []; tof_mat = []; total_TOF = cell(1,2); total_P = cell(1,1); t_ecl = []; t_frs = [];
for j = 1:N_ens
    disp(['now iteration ' int2str(j)]);
    
    MakePermxFile(PERMX.original(:,selected(j)), [permfile '.DATA']);
    copyfile([permfile '.DATA'], directory);
    
    tic; [fit, vio, tcpu]  = Evaluate(pos{j}, type, wset, directory, ecldata, permfile, []); t1 = toc;
    tic; [mat1, tof, p, ~] = SLsimulate(pos{j}(:,1:2*N), pos{j}(:,2*N+1:3*N), directory, frsdata, permfile, j); t2 = toc; 
     
    pos_fit  = [pos_fit; fit];
    pos_vio  = [pos_vio; vio];
    pos_tcpu = [pos_tcpu; tcpu];
    pos_mat  = [pos_mat, mat1];
    t_ecl    = [t_ecl, t1];
    t_frs    = [t_frs, t2];

    total_TOF{1} = [total_TOF{1}, tof{1}];
    total_TOF{2} = [total_TOF{2}, tof{2}];
    total_P{1}   = [total_P{1}, p{1}];

    disp(['Ecl time:' num2str(t1) ', Frs time:' num2str(t2)]);
end

nump = length(find(type == 1));
numi = length(find(type == 0));

pos = cell2mat(pos');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rmpath(pwd);

%%
t = datestr(now);
save(['Result_' t(1:11) ' ' t(13:14) t(16:17)]);