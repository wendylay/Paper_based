function [rho, H, lon, lat] = points_match(S2_lon,S2_lat, rho_image, IS2_lon, IS2_lat, H, dist_ph, IS2_group_photon, str_time_IS2, str_time_L8, name_append)
% to do: match the points of IceSat2 to Sentinel2
% output Rrs and H
% steps:
% 1.1 delete IceSat2 outrange points  findout IceSat2 outrange points 
% 1.2 Filter  
% 1.3 surface & bottom classification (threshold: lowest histogram)
% 1.4 water column correction 
% 1.5 local tide 
% 1.6 medfit1   -----------------------------------------------(I didn't apply this, because neural network are good at process it)
% 2 match the Rrs/rhorc spectrum
% 3 unique Rrs/rhorc spectrum 
% 4 quality control: delete nan value (cloud or land)

% 1.1 delete IceSat2 outrange points
lon_max = max(S2_lon(:));
lon_min = min(S2_lon(:));
lat_max = max(S2_lat(:));
lat_min = min(S2_lat(:));

flag_lon = IS2_lon >= lon_min & IS2_lon <= lon_max;
flag_lat = IS2_lat >= lat_min & IS2_lat <= lat_max;
[counts, centers] = hist(H, 1000);
upper_h = centers(counts == max(counts)) + 2;
flag_inrange = H <= upper_h & H >= -40;
flag_IS2 = flag_lon & flag_lat & flag_inrange;

IS2_lon = IS2_lon(flag_IS2);
IS2_lat = IS2_lat(flag_IS2);
H = H(flag_IS2);
dist_ph = dist_ph(flag_IS2);
IS2_group_photon = IS2_group_photon(flag_IS2);

figure('Renderer', 'painters', 'Position', [100 100 1000 600])
plot(dist_ph, H, 'o', 'markersize', .5)
hold on
% threshold = input('please input the surface and bottom threshold (manually):  ');
threshold = -1;
plot(dist_ph, ones(size(dist_ph)) * threshold, 'r', 'LineWidth', 1);
print(gcf, '-dtiffn', '-r300', [name_append str_time_IS2 '_raw']);
hold off
close all

% 1.1 findout IceSat2 outrange points (_signal: means signal photon)
% idx_row means the signal row of surface and bottom photons
[dist_ph_signal, H_signal, idx_row] = DBSCAN_square(H, dist_ph);

% plot and save the filter results
figure('Renderer', 'painters', 'Position', [100 100 1000 600])
scatter(dist_ph, H, 0.5)
hold on
plot(dist_ph_signal, H_signal, 'ro', 'markersize', .5)
plot(dist_ph, ones(size(dist_ph)) * threshold, ':', 'LineWidth', 1);
hold off
title(str_time_IS2)
set(gca, 'FontSize', 12, 'FontName', 'times', 'LineWidth', 1)
xlabel('Along track (m)', 'FontSize', 12)
ylabel('Elevation (m)', 'FontSize', 12)
print(gcf, '-dtiffn', '-r300', [name_append str_time_IS2])
close all


% 1.3 surface & bottom classification
[H_depth, dis_ph_signal_depth, idx_row_depth] = IS2_photon_separa(H_signal,dist_ph_signal, idx_row, IS2_group_photon, threshold);
print(gcf, '-dtiffn', '-r300', [name_append str_time_IS2 '_hist_afterfilter'])
close all

% 1.4 water column correction & delete h of tide
H = H_depth * (1 - 0.25416); 
IS2_lon = IS2_lon(idx_row_depth);  % select the depth row of lon
IS2_lat = IS2_lat(idx_row_depth);  % select the depth row of lat

% 1.5 local tide 
lon_middle = lon_min + (lon_max - lon_min) / 2;
lat_middle = lat_min + (lat_max - lat_min) / 2;
h_local_tide_IS2 = cal_tide(lon_middle, lat_middle, str_time_IS2);
h_local_tide_L8  = cal_tide(lon_middle, lat_middle, str_time_L8);
H = H - h_local_tide_IS2 + h_local_tide_L8;

% 2 match the Rrs spectrum
% 2.1 delete S2 redundant pixel reshape S2_lon, S2_lat to 1D and rho to 2D
S2_lon = S2_lon(:);
S2_lat = S2_lat(:);
rho_2d = reshape(rho_image, size(rho_image, 1) * size(rho_image, 2), size(rho_image, 3));

flag_lon = S2_lon >= min(IS2_lon(:)) & S2_lon <= max(IS2_lon(:));
flag_lat = S2_lat >= min(IS2_lat(:)) & S2_lat <= max(IS2_lat(:));
flag_subarea = flag_lon & flag_lat;
S2_lon = S2_lon(flag_subarea);
S2_lat = S2_lat(flag_subarea);
rho_2d = rho_2d(flag_subarea, :);

% 2.1 delete IS2 outrange sub S2(delete location point)
lon_max = max(S2_lon(:));
lon_min = min(S2_lon(:));
lat_max = max(S2_lat(:));
lat_min = min(S2_lat(:));

flag_lon = IS2_lon >= lon_min & IS2_lon <= lon_max;
flag_lat = IS2_lat >= lat_min & IS2_lat <= lat_max;
flag_IS2 = flag_lon & flag_lat;

IS2_lon = IS2_lon(flag_IS2);
IS2_lat = IS2_lat(flag_IS2);
H = H(flag_IS2);

% 2.2 one IceSat2 point match one S2 point
n_H_points = length(H);
rho = nan(n_H_points, size(rho_image, 3));  % [rho_band1, rho_band2, ...]
rho_lon = nan(n_H_points, 1);
rho_lat = nan(n_H_points, 1);
parpool(8)
parfor idx_laser_points = 1 : n_H_points
    lon_temp = IS2_lon(idx_laser_points);
    lat_temp = IS2_lat(idx_laser_points);
    min_matrix = sqrt((S2_lon - lon_temp).^2 + (S2_lat - lat_temp).^2);  % Euclidean distance(mini)
    flag = (min_matrix == min(min_matrix(:)));
    rho(idx_laser_points, :) = rho_2d(flag, :);
    rho_lon(idx_laser_points) = S2_lon(flag);  % rho_lon: the match S2 lon
    rho_lat(idx_laser_points) = S2_lat(flag);
end
delete(gcp('nocreate'))

% validate match results
% plot([min(rho_lon), max(rho_lon)], [min(IS2_lon), max(IS2_lon)], 'o')
% hold on
% plot([min(rho_lon), max(rho_lon)], [min(rho_lon), max(rho_lon)], '-r')


% 3 unique Rrs spectrum / delete duplicate IceSat2 points
[b, ~, n] = unique(rho_lon);  % one pixel of S2 contain many IceSat2 points

n_unique = length(b);
H_unique = nan(n_unique, 1);
lon_unique = nan(n_unique, 1);
lat_unique = nan(n_unique, 1);
rho_unique = nan(n_unique, size(rho_image, 3));
for idx = 1 : length(b)
    
    H_unique(idx) = 1./(mean(1./(H(n == idx, :))));  % if one pixel have many IS2 points, use IS2 depth means value
    
    % Take the first one of repeated rho, lon and lat.
    % If taking the average, there will be few 极小的
    % errors,主要是由于程序数值的精度，例如float32与float64的取值范围决定
    temp = rho(n == idx, :);
    rho_unique(idx, :) = temp(1, :);
    
    temp = rho_lon(n == idx, :);
    lon_unique(idx, :) = temp(1, :);
    
    temp = rho_lat(n == idx, :);
    lat_unique(idx, :) = temp(1, :);
    
    clear temp
end

% 4 quality control: delete nan value
[nan_row, ~] = find(any(isnan(rho_unique), 2));
if ~isempty(nan_row)
    rho_unique(nan_row, :) = [];
    H_unique(nan_row, :) = [];
    lon_unique(nan_row, :) = [];
    lat_unique(nan_row, :) = [];
end

% plot results figure
figure('Renderer', 'painters', 'Position', [100 100 1000 600])
plot(IS2_lat, H, 'o', 'markersize', .5)
hold on 
plot(lat_unique, H_unique, 'ro', 'markersize', 1)
hold off
title(str_time_IS2)
set(gca, 'FontSize', 12, 'FontName', 'times', 'LineWidth', 1)
print(gcf, '-dtiffn', '-r300', [name_append str_time_IS2 '_result'])
close all

% result
rho = rho_unique;
H = H_unique;
lon = lon_unique;
lat = lat_unique;

end

