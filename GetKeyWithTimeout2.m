    %% GetKeyWithTimeout2
    function [secs, key, RT] = GetKeyWithTimeout2(DEVICE, allowedKeys, maxTime)
        % Based on GetKeyWithTimeout from the matlablib written by
        % ddrucker@psych.upenn.edu
        % Modifications added by EPL
        baseTime = GetSecs;
        gotgood = false;
        allowedKeys = [allowedKeys 'q'];

        while ~gotgood
            % while no key is pressed, wait a bit, then check again
            if( GetSecs-baseTime > maxTime )
                secs = baseTime + maxTime;
                RT = maxTime;
                key = 'T'; % Capitalized
                return;
            end
            WaitSecs(0.001);

            % got here? a key is down! retrieve the key and RT
            [keyIsDown, secs, keyCode] = KbCheck(DEVICE);
            key = KbName(keyCode);
            if( ~isempty(key) )
                % if they pressed two keys at the same time, just take first one
                if( iscell(key) )
                    key = key{1};
                end
                if( ismember(key(1), allowedKeys) )  % Only looking at the first option of that key
                    gotgood=true;
                elseif( strcmp(key, 'ESCAPE') )
                    gotgood=true;
                end
            end
        end
        RT = secs-baseTime;

        % do not pass control back until the key has been released
        while KbCheck(DEVICE)
            WaitSecs(0.001);
        end
    end
    % End "GetKeyWithTimeout"

