function [H_depth, dis_ph_signal_depth, idx_row_depth] = IS2_photon_separa(H_signal,dis_ph_signal, idx_row, IS2_group_photon, threshold)

% Filter the group of each photon, input it to "IS2_photon_separa"
% function to get the "idx_row_depth", select the lon & lat by it directly
IS2_group_photon_signal = IS2_group_photon(idx_row); 

% separate photon of IS2: sea surface & bathymetry
% separate method: histogram(artifical)
[counts, centers] = hist(H_signal, 2000);
idx = (centers > -3 & centers < 1);
centers = centers(idx);
idx = find(counts(idx) == min(counts(idx)));
% threshold = centers(idx);
% threshold = -1;  % not excat threshold, need to define it manually
figure
histogram(H_signal)
hold on
plot([threshold, threshold], [0, max(counts)], '-r', 'linewidth', 1.5)
hold off


H_surface = H_signal(H_signal >= threshold);
ph_group_surface = IS2_group_photon_signal(H_signal >= threshold);

H_bottom = H_signal(H_signal < threshold);
ph_group_bottom = IS2_group_photon_signal(H_signal < threshold);
dis_ph_signal_bottom = dis_ph_signal(H_signal < threshold);
idx_row_bottom = idx_row(H_signal < threshold);


H_depth = nan(size(H_bottom));  
group_surface = 0;

for n_group = min(ph_group_bottom) : max(ph_group_bottom)
    % group_surface
    if sum(ph_group_bottom == n_group) == 0
        continue
    end
    
    if (sum(ph_group_surface == n_group) == 0) && (group_surface == 0)
        continue
    end
    group_surface = mean(H_surface(ph_group_surface == n_group));
    H_depth(ph_group_bottom == n_group) = group_surface - H_bottom(ph_group_bottom == n_group);
end
% left nan value are no surface value or bottom value
flag_valid_depth = ~isnan(H_depth);

dis_ph_signal_depth = dis_ph_signal_bottom(flag_valid_depth);
idx_row_depth = idx_row_bottom(flag_valid_depth);
H_depth = H_depth(flag_valid_depth);
end

