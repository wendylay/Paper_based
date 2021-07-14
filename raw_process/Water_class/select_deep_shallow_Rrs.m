% select the deep/shallow rho
clc; clear; close all;

L8_filename = 'E:\Match_Landsat8_IceSat2\013043\20181014\013043_20181014.L2_LAC_OC';
[lon, lat, rho] = load_Landsat8_Rrs(L8_filename);

% shallow box 
lonmin = [-78.46, -76.91];
lonmax = [-78.33, -76.85];
latmin = [24.036, 24.51];
latmax = [24.139, 24.56];

Rrs_2d_shallow_total = [];
for i_box = 1 : length(lonmin)
lon_shallow = lon(:);
lat_shallow = lat(:);
Rrs_2d_shallow = reshape(rho, size(rho, 1) * size(rho, 2), size(rho, 3));

flag_lon = lon_shallow >= lonmin(i_box) & lon_shallow <= lonmax(i_box);
flag_lat = lat_shallow >= latmin(i_box) & lat_shallow <= latmax(i_box);
flag_subarea = flag_lon & flag_lat;
lon_shallow = lon_shallow(flag_subarea);
lat_shallow = lat_shallow(flag_subarea);
Rrs_2d_shallow = Rrs_2d_shallow(flag_subarea, :);
Rrs_2d_shallow_total = [Rrs_2d_shallow_total; Rrs_2d_shallow];
end

% deep box 
lonmin = -77.758;
lonmax = -77.566;
latmin = 24.764;
latmax = 24.846;

lon_deep = lon(:);
lat_deep = lat(:);
Rrs_2d_deep = reshape(rho, size(rho, 1) * size(rho, 2), size(rho, 3));

flag_lon = lon_deep >= lonmin & lon_deep <= lonmax;
flag_lat = lat_deep >= latmin & lat_deep <= latmax;
flag_subarea = flag_lon & flag_lat;
lon_deep = lon_deep(flag_subarea);
lat_deep = lat_deep(flag_subarea);
Rrs_2d_deep = Rrs_2d_deep(flag_subarea, :);

% compile dataset
shallow = [Rrs_2d_shallow_total zeros(size(Rrs_2d_shallow_total, 1), 1)];
deep = [Rrs_2d_deep ones(size(Rrs_2d_deep, 1), 1)];

class = [shallow; deep];
save('D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\match results\Bahamas\013043_shallow_deep\class_20181014_Rrs', 'class')
