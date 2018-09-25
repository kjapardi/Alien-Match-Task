%% CREATE ONSET FILES FOR MUSIC TASKS
% Created by Kevin Japardi 20161129

function [] = MusicOnsets(sid)
type = {'jazz', 'scale'};
cond = {'melody', 'improv'; 'scale', 'improv'};

fprintf('===== BIGC_%.f =====\n', sid);

for n = 1:length(type)
    load(['Data/BIGC_', num2str(sid), '_', type{n}, '.mat'], 'design', 'flip');
    
    if ~exist(['onsets/BIGC_', num2str(sid)], 'file')
        mkdir(['onsets/BIGC_', num2str(sid)])
    end
    
    for m = 1:length(cond)
        EVfile = ['onsets/BIGC_', num2str(sid), '/BIGC_', num2str(sid), '_EV_', type{n}, '_', cond{n,m}, '.txt'];

        if ~exist(EVfile, 'file')
            fprintf('Writing EV_%s_%s.txt\n', type{n}, cond{n,m});
            fid = fopen(EVfile, 'w+');

            input = flip.screens(design.trials == m);
            for s = 1:length(input)
                fprintf(fid, '%.1f\t%.1f\t%.1f\n', input(s), 60, 1);
            end
            fclose(fid);
        end
    end
end





