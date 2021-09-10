clc; clear; close all;

L8_dates = {};
match_folders = dir('E:\Match_Landsat8_IceSat2\013043\');
for idx_folder = 1 : length(match_folders)
    if match_folders(idx_folder).isdir == 1 && ...
            ~isequal(match_folders(idx_folder).name, '.') && ...
            ~isequal(match_folders(idx_folder).name, '..')
        L8_dates = [L8_dates; match_folders(idx_folder).name];
    end
end

for idx = 9 : length(L8_dates)
    
    L8_date = L8_dates{idx};
    
    files_dir = ['E:\Match_Landsat8_IceSat2\013043\' L8_date '\'];
    
    
    L8_filename = dir([files_dir '*.L2_LAC_OC']);
    if isempty(L8_filename)
        disp(['date : ' L8_date '   doesn''t have corresponding L8 image'])
        continue
    end
    L8_filename = L8_filename(1).name;
    L8_filename = [files_dir L8_filename];
    
    try
        [lon_image, lat_image, Rrs_image] = load_Landsat8_Rrs(L8_filename);
        str_time_L8 = ncreadatt(L8_filename, '/', 'time_coverage_start');
        str_time_L8(11) = ' ';
        str_time_L8(end) = [];
        str_time_L8 = datestr(datenum(str_time_L8), 'yyyymmddTHHMMSS');
        str_time_L8(9) = [];
        save_dir = ['.\match results\Bahamas\013043_Rrs\' str_time_L8(1:8) '\'];
        mkdir(save_dir)
    catch
        disp(['L8 image of date : ' L8_date ' are invalid'])
        continue
    end
    
    
    IS2_filenames = dir([files_dir '*.h*']);
    valid_filenames = 'The following data is processed normally: ' ;
    wrong_filenames = 'The following data is invalid: ';
    unmatched_filenames = 'The following data have not matched Rrs/H: ';
    
    for idx_IS2 = 1 : length(IS2_filenames)
        IS2_filename = IS2_filenames(idx_IS2).name;
        IS2_filename = [files_dir IS2_filename];
        
        beam_name = 'gt1r';
        try
            [IS2_lon, IS2_lat, IS2_H, IS2_dist_ph, IS2_group_photon] = load_IceSat2(IS2_filename, beam_name);
            valid_filenames = [valid_filenames 10 IS2_filenames(idx_IS2).name];
        catch
            disp([IS2_filename '  has no data'])
            wrong_filenames = [wrong_filenames 10 IS2_filenames(idx_IS2).name];
            continue
        end
        
        str_time_IS2 = split(IS2_filename, '\');
        str_time_IS2 = str_time_IS2{end};
        str_time_IS2 = split(str_time_IS2, '.');
        str_time_IS2 = str_time_IS2{1};
        str_time_IS2 = str_time_IS2(17 : 30);
        
        % draw location
        figure
        hold on
        m_proj('Mercator','lon',[min(-79.21) max(-75.34)],'lat',[min(23.4) max(28)]);  % Bahamas
        m_pcolor(double(lon_image), double(lat_image), Rrs_image(:, :, 1)); % L8
        m_plot(IS2_lon, IS2_lat, '-r');
        
        m_gshhs_f('patch',[.7 .7 .7],'edgecolor',[.4 .4 .4]);  % Coastline
        m_grid('linestyle','none','tickdir','in','linewidth',1.2,...
            'FontName','Times New Roman','FontSize',12);
        print(gcf, '-dtiffn', '-r300', [save_dir 'map_' beam_name '_' str_time_IS2])
        close all
        
        % point match
        name_append = [save_dir beam_name];
        try
            [Rrs, H, lon, lat] = points_match(lon_image,lat_image, Rrs_image, IS2_lon, IS2_lat, IS2_H, IS2_dist_ph, IS2_group_photon, str_time_IS2, str_time_L8, name_append);
        catch
            disp([IS2_filename '  have not matched Rrs/H'])
            unmatched_filenames = [unmatched_filenames 10 IS2_filenames(idx_IS2).name];
        end
        save([save_dir beam_name '_' str_time_IS2], 'Rrs', 'H', 'lon', 'lat')
        
    end
    
    % send the process results of this date to email
    subject = ['Program running progress ' '[013043/' L8_date ']'];
    content = ['there are ' length(L8_dates) 'of IceSat2 foot print matched this Landsat8 image'...
        10 10 valid_filenames...
        10 10 unmatched_filenames...
        10 10 wrong_filenames];
    email_type = '163';
    send_email(subject, content, email_type)

end
