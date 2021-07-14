% select the deep/shallow rho
clc; clear; close all;

L8_filename = 'E:\Landsat 8\Coastal water\Yangtze_118038_20201222\L8_OLI_2020_12_22_02_25_20_118038_L2W.nc';
L8_albedo_filename = 'E:\Landsat 8\Coastal water\Yangtze_118038_20201222\118038_20201222.L2_LAC_OC';
cloud_hist_save_dir = '.\cloud_mask_hist\';
mkdir(cloud_hist_save_dir)
[lon, lat, rhorc] = load_Landsat8_rhorc(L8_filename, L8_albedo_filename, [cloud_hist_save_dir 'cloud_hist_' L8_albedo_filename(end-24:end-10)]);

% % shallow box [Bahamas]
% lonmin = [-78.44, -76.91];
% lonmax = [-78.38, -76.81];
% latmin = [24.06, 24.51];
% latmax = [24.13, 24.54];

% deep box [Chesapeake Bay]
% lonmin = [-76.23];
% lonmax = [-76.1];
% latmin = [37.9];
% latmax = [37.98];


% % deep box [Massachusetts Bay]
% lonmin = [-70.82];
% lonmax = [-70.76];
% latmin = [42.3];
% latmax = [42.34];

% deep box [Yangtze river]
lonmin = [122.01];
lonmax = [122.15];
latmin = [31];
latmax = [31.11];

rho_2d_shallow_total = [];
for i_box = 1 : length(lonmin)
lon_shallow = lon(:);
lat_shallow = lat(:);
rho_2d_shallow = reshape(rhorc, size(rhorc, 1) * size(rhorc, 2), size(rhorc, 3));

flag_lon = lon_shallow >= lonmin(i_box) & lon_shallow <= lonmax(i_box);
flag_lat = lat_shallow >= latmin(i_box) & lat_shallow <= latmax(i_box);
flag_subarea = flag_lon & flag_lat;
lon_shallow = lon_shallow(flag_subarea);
lat_shallow = lat_shallow(flag_subarea);
rho_2d_shallow = rho_2d_shallow(flag_subarea, :);
rho_2d_shallow_total = [rho_2d_shallow_total; rho_2d_shallow];
end

% deep box [Bahamas]
% lonmin = [-77.758, -77.1];
% lonmax = [-77.686, -77.0];
% latmin = [24.764, 23.60];
% latmax = [24.846, 23.68];

% rho_2d_deep_total = [];
% for i_box = 1 : length(lonmin)
% lon_deep = lon(:);
% lat_deep = lat(:);
% rho_2d_deep = reshape(rhorc, size(rhorc, 1) * size(rhorc, 2), size(rhorc, 3));
% 
% flag_lon = lon_deep >= lonmin(i_box) & lon_deep <= lonmax(i_box);
% flag_lat = lat_deep >= latmin(i_box) & lat_deep <= latmax(i_box);
% flag_subarea = flag_lon & flag_lat;
% lon_deep = lon_deep(flag_subarea);
% lat_deep = lat_deep(flag_subarea);
% rho_2d_deep = rho_2d_deep(flag_subarea, :);
% rho_2d_deep_total = [rho_2d_deep_total; rho_2d_deep];
% end

% compile dataset
shallow = [rho_2d_shallow_total zeros(size(rho_2d_shallow_total, 1), 1)]; % shallow label 0
% deep = [rho_2d_deep_total ones(size(rho_2d_deep_total, 1), 1)];  % deep label 1

% class = [shallow; deep];
% save('D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\Optical_shallow_pixel_select\optical_shallow_deep\Bahamas_shallow_deep_rhorc.mat', 'class')
save('./optical_shallow_deep/deep_Yangtze_river.mat', 'shallow');

%% location box map
clc; clear; close all
% training shallow/deep  results
filename = 'D:\OneDrive - stu.xmu.edu.cn\4 Code\2 python\Depth_global\rho_rc\class_Bahamas_013043_20200629.nc';
lon = ncread(filename, 'lon');
lat = ncread(filename, 'lat');
class = ncread(filename, 'class');

lonmin = double(min(lon(:)));
lonmax = double(max(lon(:)));
latmin = double(min(lat(:)));
latmax = double(max(lat(:)));

figure('color', 'white','Units', 'normalized','position', [0.06 0.06 0.8 0.8])
% set(gcf, ...);
hold on
m_proj('Mercator','lon',[lonmin lonmax],'lat',[latmin latmax]);

m_pcolor(double(lon), double(lat), class);
lonmin_box = [-78.46, -76.91, -77.758];
lonmax_box = [-78.33, -76.85, -77.566];
latmin_box = [24.036, 24.51, 24.764];
latmax_box = [24.139, 24.56, 24.846];

for i_box = 1 : length(lonmin_box)
    m_line([lonmin_box(i_box) lonmax_box(i_box) lonmax_box(i_box) lonmin_box(i_box) lonmin_box(i_box)], ...
        [latmin_box(i_box) latmin_box(i_box) latmax_box(i_box) latmax_box(i_box) latmin_box(i_box)],...
        'color', 'y', 'linewidth', 2)
end
m_gshhs_h('patch',[.7 .7 .7],'edgecolor',[.4 .4 .4], 'linewidth', 1);  % Coastline
m_grid('linestyle','none','tickdir','in','linewidth',2,...
    'FontName','Times New Roman','FontSize',25);

caxis([0 1])
colormap jet
colorbar
print(gcf, '-dtiffn', '-r300', './optical_shallow_deep/');
% close all 