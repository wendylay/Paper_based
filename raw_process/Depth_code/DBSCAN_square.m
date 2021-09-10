function [x, y, idx_row] = DBSCAN_square(H, dist_ph)
% filter noisy datapoint base on density
% square filter box
% output:
% x dis_ph
% y H
% idx_raw (left points index)


% set manually (important)
min_points = 7;  % usually use 7, you can chose other


% to do: revise configuration
x = dist_ph;
y = H;
idx_row = 1 : length(x);

% configuration (need to automatically adaptive)
rect_w = 20;
rect_h = 2;
lim_w = rect_w / 2;
lim_h = rect_h / 2;

% filter noisy points
num_points = length(x);  % left points
record = nan(num_points, 1);
% parallel process
parpool(8)
parfor idx = 1 : num_points
    point_x = x(idx);
    point_y = y(idx);
    d_y = abs(y - point_y);
    d_x = abs(x - point_x);
    lim_h_adaptive = lim_h;
    if abs(point_y) < 2
        lim_h_adaptive = lim_h_adaptive / 2;
    end
    flag = (d_x < lim_w) & (d_y < lim_h_adaptive);
    record(idx, 1) = max(0, sum(flag) >= min_points);
end
delete(gcp('nocreate'))
x = x(record == 1);  % delete the x of outer points
y = y(record == 1);  % delete the y of outer points
idx_row = idx_row(record == 1);  % delete the idx row of outer points

end

