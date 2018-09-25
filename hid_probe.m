%% hid_probe.m
% Written by DJK, 2/2007
% This function returns the desired input device for scanning. The HID will
% need to see the buttonbox device for this to work, which often means the
% cable should be plugged into the computer before launching Matlab.

% 2011.09.14
% Modification by Edward Lau <eplau[at]ucla[dot]edu>
% Added the "person_noun" input variable so that the question about which device to use can be phrased correctly

% 2012.02.29
% Modification by Edward Lau <eplau[at]ucla[dot]edu>
% Added "chosen_device_name" output variable to describe the chosen input device.

% 2015.08.09
% Modification by Kevin Japardi <kjapardi[at]gmail[dot]edu>
% Corrected some typos

function [chosen_device chosen_device_name] = hid_probe(person_noun)
 
chosen_device = [];
chosen_device_name = [];
numDevices=PsychHID('NumDevices');
devices=PsychHID('Devices');
candidate_devices = [];
top_candidate = [];

fprintf('-------------------\nProbing for devices\n-------------------\n')
for n=1:numDevices
	if (~(isempty(findstr(devices(n).transport, 'USB'))) || ~isempty(findstr(devices(n).usageName, 'Keyboard')))
		fprintf('Device #%d is a potential input device [%s, %s]\n', n, devices(n).usageName, devices(n).product);
		candidate_devices = [candidate_devices n];
		if (devices(n).productID==16385 || devices(n).vendorID==6171 || devices(n).totalElements==274)
			top_candidate = n;
		end
	end
end

prompt_string = sprintf(['Which device for ', person_noun,' responses (%s)? '], num2str(candidate_devices));

if ~isempty(top_candidate)
	prompt_string = sprintf('%s [Enter for %d]', prompt_string, top_candidate);
end

while isempty(chosen_device)
	chosen_device = input(prompt_string);
	if isempty(chosen_device) && ~isempty(top_candidate)
		chosen_device = top_candidate;
	elseif isempty(find(candidate_devices == chosen_device))
		fprintf('Invalid Response!\n');
		chosen_device = [];
	end
end

chosen_device_name = [devices(n).usageName ', ' devices(n).product];
