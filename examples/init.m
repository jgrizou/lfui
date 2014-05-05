[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(pathstr, '..')));

clear 'pathstr'

% Change default figure stuff
set(0,'DefaultFigurePosition',[200, 300, 700, 700])
set(0,'DefaultAxesFontName', 'Courier')
set(0,'DefaultAxesFontSize', 14)
set(0,'DefaultAxesFontWeight','bold')
set(0,'DefaultAxesLineWidth', 2.5)