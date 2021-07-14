function [lon, lat, Rrs_output] = load_Landsat8_Rrs(filename)
% input L8 nc file

lon = double(ncread(filename, 'navigation_data/longitude'));
lat = double(ncread(filename, 'navigation_data/latitude'));

Rrs_443 = double(ncread(filename, 'geophysical_data/Rrs_443'));  
Rrs_482 = double(ncread(filename, 'geophysical_data/Rrs_482'));   
Rrs_561 = double(ncread(filename, 'geophysical_data/Rrs_561'));  
Rrs_655 = double(ncread(filename, 'geophysical_data/Rrs_655'));  
Rrs_865 = double(ncread(filename, 'geophysical_data/Rrs_865')); 

Rrs = cat(3, Rrs_443, Rrs_482, Rrs_561, Rrs_655, Rrs_865);

% 1 cloud mask
% Rrs don't need cloud mask, but need to delete the negative Rrs spectrum

Rrs_2d = reshape(Rrs, size(Rrs, 1)*size(Rrs,2), size(Rrs, 3));

% 2 negative mask
flag_negative = any(Rrs_2d < 0, 2);
Rrs_2d(flag_negative, :) = nan;
Rrs_output = reshape(Rrs_2d, size(Rrs, 1), size(Rrs,2), size(Rrs, 3));

end

