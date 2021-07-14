function [H_cor_geoid, dis_ph, flag_seg_group_ph] = process_IS2_dis_geoid(ph_cnt, seg_length, seg_dist_along_track_ph, seg_geoid, H)
% convert reletive distance of each segment to this region
% (The relative distance of each part does not increase, need '/gt1r/geolocation/segment_ph_cnt')
% Geoid correction of each segment

% wendian Lai
% 2020.10.26

x = zeros(size(seg_length));
x(2:end, :) = seg_length(1 : end - 1, :);  % distance of each segment ~= 20 m
seg_length_cumsum = cumsum(x);

compensatory_along_track = zeros(size(H));  % record the along trach of each photon from the begining (the first photon of the data file)
compensatory_geoid = zeros(size(H));  % record the geoid of each photon
flag_seg_group_ph = zeros(size(H));  % flag group of each photon

idx_ph = 1;
group_num = 1;

cnt_length = length(seg_length_cumsum);
for idx_seg = 1 : cnt_length
    temp_cnt_ph = ph_cnt(idx_seg);
    idx_ph_end = temp_cnt_ph + idx_ph - 1 ;
    temp_at = ones(temp_cnt_ph, 1) * seg_length_cumsum(idx_seg);
    temp_geoid = ones(temp_cnt_ph, 1) * seg_geoid(idx_seg);
    compensatory_along_track(idx_ph : idx_ph_end, 1) = temp_at;
    compensatory_geoid(idx_ph : idx_ph_end, 1) = temp_geoid;
    
    % flag group of each photo(use for calculate sea surface)
    temp_group = ones(temp_cnt_ph, 1) * group_num;
    flag_seg_group_ph(idx_ph : idx_ph_end, 1) = temp_group;
    group_num = group_num + 1;
    
    idx_ph = idx_ph_end + 1;
end

dis_ph = seg_dist_along_track_ph + compensatory_along_track;  % distance combine
H_cor_geoid = H - compensatory_geoid;  % Geoid correction
flag_seg_group_ph = flag_seg_group_ph; % #i-th group of each photon(每一个photo属于第几个group)
end

