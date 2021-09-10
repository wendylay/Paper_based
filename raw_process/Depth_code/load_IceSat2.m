function [lon, lat, H, dist_ph, group_photon] = load_IceSat2(filename, beam_name)
% This function is to process raw IceSat2 data
% steps:
% 1 H correction Geoid
% 2 filter outline point()
% 3 H refraction corrected (only photo below sea surface)
% 4 Earth curve corrected (pass)
% 5 local tide 
% doing..... (in order to save processing time, part of the steps were put into m script "point_match")

% Reading
% beam_name = 'gt1l';
raw_H = h5read(filename, ['/' beam_name '/heights/h_ph']);
raw_lon = h5read(filename, ['/' beam_name '/heights/lon_ph']);
raw_lat = h5read(filename, ['/' beam_name '/heights/lat_ph']);

raw_conf = h5read(filename, ['/' beam_name '/heights/signal_conf_ph']);  % the 5 rows indicate signal finding for each surface type
                                                                       % land, ocean, sea ice, land ice and inland water                                                                   
dist_along_track_segment  = h5read(filename, ['/' beam_name '/heights/dist_ph_along']);  % use for DBSCAN
geoid = h5read(filename, ['/' beam_name '/geophys_corr/geoid']);  % geoid H of each segment
segment_length = h5read(filename, ['/' beam_name '/geolocation/segment_length']);
segment_ph_cnt = h5read(filename, ['/' beam_name '/geolocation/segment_ph_cnt']);

% 1 H correction Geoid / distance combine each segment
[H_corGeoid, dist_ph, flag_seg_num_ph] = process_IS2_dis_geoid(segment_ph_cnt, segment_length, dist_along_track_segment, geoid, raw_H);

% 2 filter outline point(retain the confident of photo = 4 (high))

% retain confident range between 0 to 4. Refer: Ma et al., 2020
idx_high_cf = (raw_conf(2, :)' ~= -2 & raw_conf(2, :)' ~= -1);  % -1 = not ocean type, -2 Events evaluated as TEP(I don't know), 4 = hight

H_corGeoid = H_corGeoid(idx_high_cf);
dist_ph = dist_ph(idx_high_cf);
flag_seg_num_ph = flag_seg_num_ph(idx_high_cf);
raw_lon = raw_lon(idx_high_cf);
raw_lat = raw_lat(idx_high_cf);

lon = raw_lon;
lat = raw_lat;
H = H_corGeoid;
dist_ph = dist_ph;
group_photon = flag_seg_num_ph;
end

