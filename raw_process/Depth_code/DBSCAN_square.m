function [x, y, idx_row] = DBSCAN_square(H, dist_ph)
% filter noisy datapoint base on density
% square filter box
% output: 
    % x dis_ph 
    % y H
    % idx_raw (left points index)

% to do: revise configuration
x = dist_ph;
y = H;
idx_row = 1 : length(x);

% configuration (need to automatically adaptive)
rect_w = 20;
rect_h = 2;
lim_w = rect_w / 2;
lim_h = rect_h / 2;
min_points = 7;  % 7


%% filter only onece

num_points = length(x);  % left points
record = nan(num_points, 1);
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


%% beta (wrong)
% matrix way (Creation of arrays greater than this limit)
% idx_row = [];
% num_points = length(H);
% batch = 1000;
% sub_data_num = ceil(num_points / 10000);
% 
% for idx = 1 : sub_data_num
%     if idx ~= sub_data_num
%         start_row = (idx - 1) * batch + 1;
%         end_row = idx * batch;
%     else
%         start_row = (idx - 1) * batch + 1;
%         end_row = start_row + mod(sub_data_num, batch);
%     end
%     
%     x = dist_ph(start_row: end_row, :);
%     y = H(start_row: end_row, :);
%     dx = pdist2(x, dist_ph); % euclidean dist
%     dy = pdist2(y, H);
%     
%     dx_box = dx <= lim_w;
%     dy_box = dy <= lim_h;
%     
%     npoints_box = sum((dx_box & dy_box), 2);
%     idx_row_sub = find(npoints_box >= min_points);
%     idx_row = [idx_row; idx_row_sub];
% end
% 
% x = dist_ph(idx_row);
% y = H(idx_row);

%% beta 
% % Cannibalization (蚕食)
% % filter noisy point gradually
% 
% 
% while true
%     num_points = length(x);  % left points
%     record = nan(num_points, 1);
%     
%     for idx = 1 : num_points
%         point_x = x(idx);
%         point_y = y(idx);
%         d_y = abs(y - point_y);
%         d_x = abs(x - point_x);
%         lim_h_adaptive = lim_h;
%         if abs(point_y) < 2
%             lim_h_adaptive = lim_h_adaptive / 2;
%         end
%         flag = (d_x < lim_w) & (d_y < lim_h_adaptive);
%         record(idx, 1) = max(0, sum(flag) >= min_points);
%     end
%     
%     if sum(record) == num_points  % no noisy points
%         break
%     end
%     
%     x = x(record == 1);  % delete the x of outer points
%     y = y(record == 1);  % delete the y of outer points
%     idx_row = idx_row(record == 1);  % delete the idx row of outer points
%     min_points = max(3, min_points - 1);  % shrink the minPoints
% end

end

