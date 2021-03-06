function [lon, lat, rhorc_output] = load_Landsat8_rhorc(filename, albedo_filename, cloud_fig_save_name)
% load rho_rc from ACOLITE resutls
% input L8 nc file

lon = double(ncread(filename, 'lon'));
lat = double(ncread(filename, 'lat'));

rho_rc_443 = double(ncread(filename, 'rhorc_443'));
rho_rc_482 = double(ncread(filename, 'rhorc_483'));
rho_rc_561 = double(ncread(filename, 'rhorc_561')); 
rho_rc_655 = double(ncread(filename, 'rhorc_655'));
rho_rc_865 = double(ncread(filename, 'rhorc_865'));
rho_rc_1609 = double(ncread(filename, 'rhorc_1609'));
rho_rc_2201 = double(ncread(filename, 'rhorc_2201'));


rhorc = cat(3, rho_rc_443, rho_rc_482, rho_rc_561, rho_rc_655, rho_rc_865, rho_rc_1609, rho_rc_2201);

% 1 cloud mask
albedo = ncread(albedo_filename,'geophysical_data/cloud_albedo');
albedo = albedo(:);
albedo_valid = albedo(albedo > 0);
[counts, centers] = hist(albedo_valid, 5000);
idx = (centers > 0.005 & centers < 0.04);
centers = centers(idx);
idx = find(counts(idx) == min(counts(idx)));
albedo_threshold = centers(idx);
figure('Renderer', 'painters', 'Position', [100 100 1300 600])
histogram(albedo_valid, 5000)
xlim([0, 0.05])
hold on
plot([albedo_threshold, albedo_threshold], [0, max(counts)], '-r', 'linewidth', 1.5)
hold off
print(gcf, '-dtiffn', '-r100', cloud_fig_save_name)
close all

flag_cloud = albedo > albedo_threshold ;  % if albedo > min albedo, cloud pixel

rhorc_2d = reshape(rhorc, size(rhorc, 1)*size(rhorc,2), size(rhorc, 3));
rhorc_2d(flag_cloud, :) = nan;

% 2 negative mask
flag_negative_large = any(rhorc_2d < 0, 2) | any(rhorc_2d > 1, 2);

rhorc_2d(flag_negative_large, :) = nan;


rhorc_output = reshape(rhorc_2d, size(rhorc, 1), size(rhorc,2), size(rhorc, 3));
end

%% cal rho_rc of SEADAS  (trouble way, need debug) 2021.2.4
% clc; clear; close all
% filename = 'E:\Match_Landsat8_IceSat2\013043\20200629\013043_20200629_rhorc.L2_LAC_OC';
% bands = [443, 482, 561, 655, 865, 1609, 2201];
% 
% F0 = ncread(filename, 'sensor_band_parameters/F0');
% lat = ncread(filename, 'navigation_data/latitude');
% lon = ncread(filename, 'navigation_data/longitude');
% solz = ncread(filename, 'geophysical_data/solz');
% 
% % band * lat* lon => permute(*, [2,3,1]))
% Lr = permute(ncread(filename, 'geophysical_data/Lr'), [2,3,1]);
% Lt = permute(ncread(filename, 'geophysical_data/Lt'), [2,3,1]);
% TLg = permute(ncread(filename, 'geophysical_data/TLg'), [2,3,1]);
% tLf = permute(ncread(filename, 'geophysical_data/tLf'), [2,3,1]);
% t_h2o = permute(ncread(filename, 'geophysical_data/t_h2o'), [2,3,1]);
% t_o2 = permute(ncread(filename, 'geophysical_data/t_o2'), [2,3,1]);
% tg_sen = permute(ncread(filename, 'geophysical_data/tg_sen'), [2,3,1]);
% tg_sol = permute(ncread(filename, 'geophysical_data/tg_sol'), [2,3,1]);
% 
% rho_t = pi.*Lt ./ reshape(F0, 1, 1, 7) ./ cos(solz /180 * pi);
% rho_g = pi.*TLg ./ reshape(F0, 1, 1, 7) ./ cos(solz /180 * pi);
% rho_f = pi.*tLf ./ reshape(F0, 1, 1, 7) ./ cos(solz /180 * pi);
% rho_r = pi.*Lr ./ reshape(F0, 1, 1, 7) ./ cos(solz /180 * pi);
% 
% rho_rc = rho_t ./ (tg_sol.*tg_sen.*t_h2o.*t_o2) - rho_g - rho_f - rho_r;
% rho_rc(isinf(rho_rc)) = nan;
% 
% rho_rc_443 = rho_rc(:, :, 1);
% rho_rc_482 = rho_rc(:, :, 2);
% rho_rc_561 = rho_rc(:, :, 3);
% rho_rc_655 = rho_rc(:, :, 4);
% rho_rc_865 = rho_rc(:, :, 5);
% rho_rc_1609 = rho_rc(:, :, 6);
% rho_rc_2201 = rho_rc(:, :, 7);
% 
% %% save nc file
% %??????NetCDF file
% %'CLOBBER'????????????????????? 'NOCLOBBER'???????????????????????? 'SHARE'?????????????????????
% % cid=netcdf.create('D:/rho_rc_test.nc', 'CLOBBER'); 
% cid = netcdf.create('D:/rho_rc_test.nc','NC_64BIT_OFFSET');  % large file
% 
% %???????????????
% 
% [m, n]=size(lon);
% 
% 
% %????????????
% dimidlon=netcdf.defDim(cid,'x',m);
% dimidlat=netcdf.defDim(cid,'y',n);
% 
% 
% %????????????
% varid_lon=netcdf.defVar(cid,'lon','double',[dimidlon dimidlat]);         %2d
% varid_lat=netcdf.defVar(cid,'lat','double',[dimidlon dimidlat]);          %2d
% 
% varid_rho_rc_443=netcdf.defVar(cid,'rho_rc_443','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_482=netcdf.defVar(cid,'rho_rc_482','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_561=netcdf.defVar(cid,'rho_rc_561','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_655=netcdf.defVar(cid,'rho_rc_655','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_865=netcdf.defVar(cid,'rho_rc_865','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_1609=netcdf.defVar(cid,'rho_rc_1609','double',[dimidlon dimidlat]);  %2d
% varid_rho_rc_2201=netcdf.defVar(cid,'rho_rc_2201','double',[dimidlon dimidlat]);  %2d
% 
% %??????NetCDF file????????????
% netcdf.endDef(cid);
% %????????????
% netcdf.putVar(cid,varid_lon,lon);
% netcdf.putVar(cid,varid_lat,lat);
% netcdf.putVar(cid,varid_rho_rc_443, rho_rc_443);
% netcdf.putVar(cid,varid_rho_rc_482, rho_rc_482);
% netcdf.putVar(cid,varid_rho_rc_561, rho_rc_561);
% netcdf.putVar(cid,varid_rho_rc_655, rho_rc_655);
% netcdf.putVar(cid,varid_rho_rc_865, rho_rc_865);
% netcdf.putVar(cid,varid_rho_rc_1609, rho_rc_1609);
% netcdf.putVar(cid,varid_rho_rc_2201, rho_rc_2201);
% 
% %??????NetCDF file
% netcdf.close(cid);
