%=========================================================================================
% Create LBL header for EST in the form of a key-value (kv) list.
% 
% Combines information from one or two LBL file headers.
% to produce information for new combined header (without writing to file).
% 
% ASSUMES: The two label files have identical keys on identical positions (line numbers).
%=========================================================================================
function kv_new = createLBL_create_EST_LBL_header(an_tabindex_record, index)
% PROPOSAL: Change to only accept a "an_tabindex_record" instead, i.e. effectively an_tabindex{i_ant, :}.
% PROPOSAL: Change to accept LBL_file_path instead of "index".

    %N_src_files = length(an_tabindex{i_ant, 3});
    N_src_files = length(an_tabindex_record{3});
    if ~ismember(N_src_files, [1,2])
        error('Wrong number of TAB file paths.');
    end

    kv_list = {};
    START_TIME_list = {};
    STOP_TIME_list = {};
    for i_index = 1:N_src_files
        %file_path = index(an_tabindex{i_ant, 3}(i_index)).lblfile;            
        file_path = index(an_tabindex_record{3}(i_index)).lblfile;            
        kv = createLBL_read_LBL_header(file_path);

        kv_list{end+1} = kv;            
        START_TIME_list{end+1} = createLBL_read_kv_value(kv, 'START_TIME');
        STOP_TIME_list{end+1}  = createLBL_read_kv_value(kv, 'STOP_TIME');
    end

    %TAB_file_info = dir(an_tabindex{i_ant, 1});
    TAB_file_info = dir(an_tabindex_record{1});
    kv_set.keys   = {};
    kv_set.values = {};
    %kv_set = createLBL_add_new_kv_pair(kv_set, 'FILE_NAME',           strrep(an_tabindex{i_ant, 2}, '.TAB', '.LBL'));
    kv_set = createLBL_add_new_kv_pair(kv_set, 'FILE_NAME',           strrep(an_tabindex_record{2}, '.TAB', '.LBL'));
    %kv_set = createLBL_add_new_kv_pair(kv_set, '^TABLE',              an_tabindex{i_ant, 2});
    kv_set = createLBL_add_new_kv_pair(kv_set, '^TABLE',              an_tabindex_record{2});
    %kv_set = createLBL_add_new_kv_pair(kv_set, 'FILE_RECORDS',        num2str(an_tabindex{i_ant, 4}));
    kv_set = createLBL_add_new_kv_pair(kv_set, 'FILE_RECORDS',        num2str(an_tabindex_record{4}));
    kv_set = createLBL_add_new_kv_pair(kv_set, 'PRODUCT_TYPE',        'DDR');
    %kv_set = createLBL_add_new_kv_pair(kv_set, 'PRODUCT_ID',          sprintf('"%s"', strrep(an_tabindex{i_ant, 2}, '.TAB', '')));
    kv_set = createLBL_add_new_kv_pair(kv_set, 'PRODUCT_ID',          sprintf('"%s"', strrep(an_tabindex_record{2}, '.TAB', '')));
    kv_set = createLBL_add_new_kv_pair(kv_set, 'PROCESSING_LEVEL_ID', '5');
    kv_set = createLBL_add_new_kv_pair(kv_set, 'DESCRIPTION',         '"Best estimates of physical quantities based on sweeps."');
    kv_set = createLBL_add_new_kv_pair(kv_set, 'RECORD_BYTES',        num2str(TAB_file_info.bytes));

    %--------------------------------------------------------------------------------------------
    % TEMPORARY BUGFIX.
    % -----------------
    % Different LBL files may have the same variable ("key") but with two different values.
    % This causes a problem since LBL files can only have one variable (with the same name) with only ONE value.
    %
    % Example (data generated 2015-01-08):
    % RO-C-RPCLAP-5-1412-DERIV-V0.3/2014/DEC/D02/RPCLAP_20141202_000002_515_A1S.LBL:ROSETTA:LAP_INITIAL_SWEEP_SMPLS  = "0x0003"
    % RO-C-RPCLAP-5-1412-DERIV-V0.3/2014/DEC/D02/RPCLAP_20141202_000002_515_A2S.LBL:ROSETTA:LAP_INITIAL_SWEEP_SMPLS  = "0x0004"    
    %
    % Example (data generated 2015-01-08):
    % RO-C-RPCLAP-5-1412-DERIV-V0.3/2014/DEC/D09/RPCLAP_20141209_010259_614_A1S.LBL:ROSETTA:LAP_SWEEP_PLATEAU_DURATION  = "0x0200"
    % RO-C-RPCLAP-5-1412-DERIV-V0.3/2014/DEC/D09/RPCLAP_20141209_010259_614_A2S.LBL:ROSETTA:LAP_SWEEP_PLATEAU_DURATION  = "0x0100"
    % 
    % Example (data generated 2015-01-12)
    % RO-C-RPCLAP-5-1501-DERIV-V0.3/2015/JAN/D02/RPCLAP_20150102_012211_204_A1S.LBL:ROSETTA:LAP_SWEEP_STEPS  = "0x00f0"
    % RO-C-RPCLAP-5-1501-DERIV-V0.3/2015/JAN/D02/RPCLAP_20150102_012211_204_A2S.LBL:ROSETTA:LAP_SWEEP_STEPS  = "0x00d0"
    %
    % Example (data generated 2015-01-12)
    % RO-C-RPCLAP-5-1501-DERIV-V0.3/2015/JAN/D02/RPCLAP_20150102_012211_204_A1S.LBL:ROSETTA:LAP_SWEEP_START_BIAS  = "0x00f8"
    % RO-C-RPCLAP-5-1501-DERIV-V0.3/2015/JAN/D02/RPCLAP_20150102_012211_204_A2S.LBL:ROSETTA:LAP_SWEEP_START_BIAS  = "0x00e8"
    %
    % TODO: Find out correct value or procedure for this situation.
    %--------------------------------------------------------------------------------------------
    temp_bugfix_key_value = '<Does not yet know how to set this value since the variable has different values for probe 1 and probe 2.>';
    kv_set = createLBL_add_new_kv_pair(kv_set, 'ROSETTA:LAP_INITIAL_SWEEP_SMPLS',    temp_bugfix_key_value);
    kv_set = createLBL_add_new_kv_pair(kv_set, 'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', temp_bugfix_key_value);
    kv_set = createLBL_add_new_kv_pair(kv_set, 'ROSETTA:LAP_SWEEP_STEPS',            temp_bugfix_key_value);
    kv_set = createLBL_add_new_kv_pair(kv_set, 'ROSETTA:LAP_SWEEP_START_BIAS',       temp_bugfix_key_value);
    

    % Set start time.
    [junk, i_sort] = sort(START_TIME_list);
    i_start = i_sort(1);
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'START_TIME');
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'SPACECRAFT_CLOCK_START_COUNT');

    % Set stop time.
    [junk, i_sort] = sort(STOP_TIME_list);
    i_stop = i_sort(end);
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'STOP_TIME');
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'SPACECRAFT_CLOCK_STOP_COUNT');

    %===================
    % Handle collisions
    %===================
    kv1 = kv_list{1};
    if (N_src_files == 1)
        kv_new = kv1;
    else
        kv_new = [];
        kv_new.keys = {};
        kv_new.values = {};
        kv2 = kv_list{2};
        for i1 = 1:length(kv1.keys)             % For every key in kv1...

            if strcmp(kv1.keys{i1}, kv2.keys{i1})     % If key collision...

                key = kv1.keys{i1};
                kvset_has_key = ~isempty(find(strcmp(key, kv_set.keys)));
                if kvset_has_key                                    % If kv_set contains information on how to set value...
                    % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                    kv_new.keys  {end+1, 1} = key;
                    kv_new.values{end+1, 1} = '<Temporary - This value should be overwritten automatically.>';

                elseif strcmp(kv1.values{i1}, kv2.values{i1})       % If key AND value collision... (No problem)
                    kv_new.keys  {end+1, 1} = kv1.keys  {i1};
                    kv_new.values{end+1, 1} = kv1.values{i1};

                else                                      % If has no information on how to resolve collision...
                    error_msg = sprintf('ERROR: Does not know what to do with LBL/ODL key collision for key="%s".\n', key);
                    error_msg = [error_msg, sprintf('with two different values: value="%s", value="%s".', kv1.values{i1}, kv2.values{i1})];
                    error(error_msg)
                end            

            else  % If not key collision....
                kv_new.keys  {end+1,1} = kv1.keys  {i1};
                kv_new.values{end+1,1} = kv1.values{i1};
                kv_new.keys  {end+1,1} = kv2.keys  {i1};
                kv_new.values{end+1,1} = kv2.values{i1};
            end
        end
    end

    kv_new = createLBL_set_values_for_selected_preexisting_keys(kv_new, kv_set);
end
