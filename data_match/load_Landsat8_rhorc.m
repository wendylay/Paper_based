function [lon, lat, rhorc_output] = load_Landsat8_rhorc(filename, albedo_filename)
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


flag_cloud = albedo > 0.03 ;  % if albedo > min albedo, cloud pixel,Threshold in SeaDAS is 0.18

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
% %创建NetCDF file
% %'CLOBBER'：覆盖现有文件 'NOCLOBBER'：不覆盖现有文件 'SHARE'：更新现有文件
% % cid=netcdf.create('D:/rho_rc_test.nc', 'CLOBBER'); 
% cid = netcdf.create('D:/rho_rc_test.nc','NC_64BIT_OFFSET');  % large file
% 
% %待写入数据
% 
% [m, n]=size(lon);
% 
% 
% %定义维度
% dimidlon=netcdf.defDim(cid,'x',m);
% dimidlat=netcdf.defDim(cid,'y',n);
% 
% 
% %创建变量
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
% %结束NetCDF file定义模式
% netcdf.endDef(cid);
% %写入变量
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
% %关闭NetCDF file
% netcdf.close(cid);
