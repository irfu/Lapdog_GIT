% ~EXPERIMENTAL
%
% Collect Lapdog LBL constants. Must instantiate.
%
%
% IMPLEMENTATION NOTE
% ===================
% Reasons for using a singleton class (instead of static methods & fields):
% 1) Can use properties/instance variables for "caching" values. Do not want to use persistent variables since they
% cause trouble when testing. NOTE: There are no proper static variables in MATLAB.
% 2) Can split up (structure, organize) configuration and validation code in methods.
% 3) The constructor can be used as initialization code which must be run before using the class/constants.
%
%
% DESIGN INTENT
% =============
% Should not take values from anywhere (through execution). ==> Should not read "global" constants (variables declared as
% "global". Ex: SATURATION_CONSTANT, N_FINAL_PRESWEEP_SAMPLES
%
%
% Initially created 2018-08-22 by Erik P G Johansson, IRF Uppsala
%
classdef constants < handle
    % PROPOSAL: Merge COTLF_HEADER_OPTIONS and INDENTATION_LENGTH (modify write_OBJTABLE_LBL_FILE accordingly).
    %   CON: Indentation length is more fundamental. Could pop up somewhere else.
    %   PROPOSAL: Modify write_OBJTABLE_LBL_FILE to merge header options into settings and copy the indentation length from
    %           the separate constant INDENTATION_LENGTH.
    %
    % NOTE: Used by non-Lapdog code: ./+erikpgjohansson/+ro/+delivery/+geom/create_geom_TAB_LBL_from_EOG.m
    %       Might be used by future standalone, "Lapdogish" code (same git repo) for e.g. separately regenerating LBL files.
    %
    % PROPOSAL: Separately hard-code constant values just as Lapdog code does (duplication).
    %   PROPOSAL: Somehow check that constants set by Lapdog (lapdog, edder_lapdog, main) use the same constant values as "constants".
    %       PROPOSAL: (1) Internal hard-coded default values (MISSING_CONSTANT, and analogous if any). Constructor which accepts the
    %                 same variables/constants as arguments and checks them (assertion) against the internal (hard-coded) values. 
    %                 (2) Constructor call that just uses internally defined values.
    % 
    
    properties(Access=public)
        ROSETTA_NAIF_ID          = -226;     % Used by SPICE.
        INDENTATION_LENGTH       = 4;
        MISSING_CONSTANT         = -1000;    % Defined here so that it can be used by code that is not run via Lapdog.
        N_FINAL_PRESWEEP_SAMPLES = 16;
        
        % Used by createLBL.create_OBJTABLE_LBL_file
        COTLF_HEADER_OPTIONS   % Set in constructor
    end
    
    
    
    methods(Access=public)

        % Constructor
        % 
        % ARGUMENTS
        % =========
        % alt 1: No arguments
        % alt 2: MISSING_CONSTANT
        %        N_FINAL_PRESWEEP_SAMPLES
        function obj = constants(varargin)
            if nargin == 0
                ;   % Do nothing. Everything OK.
            elseif nargin == 2
                % ASSERTIONS
                if obj.MISSING_CONSTANT ~= varargin{1}
                    error('Submitted MISSING_CONSTANT value inconsistent with internally hard-coded value.')
                end
                if obj.N_FINAL_PRESWEEP_SAMPLES ~= varargin{2}
                    error('Submitted N_FINAL_PRESWEEP_SAMPLES value inconsistent with internally hard-coded value.')
                end
                
            else
                error('Wrong number of arguments.')
            end
            
            %==================================================================
            % LBL Header keys which should preferably come in a certain order.
            % Not all of them are required to be present.
            %==================================================================
            % Keywords which are quite independent of type of file.
            GENERAL_KEY_ORDER_LIST = { ...
                'PDS_VERSION_ID', ...    % The PDS standard requires this to be first, I think.
                ...
                'RECORD_TYPE', ...
                'RECORD_BYTES', ...
                'FILE_RECORDS', ...
                'FILE_NAME', ...
                '^TABLE', ...
                'DATA_SET_ID', ...
                'DATA_SET_NAME', ...
                'DATA_QUALITY_ID', ...
                'MISSION_ID', ...
                'MISSION_NAME', ...
                'MISSION_PHASE_NAME', ...
                'PRODUCER_INSTITUTION_NAME', ...
                'PRODUCER_ID', ...
                'PRODUCER_FULL_NAME', ...
                'LABEL_REVISION_NOTE', ...
                'PRODUCT_ID', ...
                'PRODUCT_TYPE', ...
                'PRODUCT_CREATION_TIME', ...
                'INSTRUMENT_HOST_ID', ...
                'INSTRUMENT_HOST_NAME', ...
                'INSTRUMENT_NAME', ...
                'INSTRUMENT_ID', ...
                'INSTRUMENT_TYPE', ...
                'INSTRUMENT_MODE_ID', ...
                'INSTRUMENT_MODE_DESC', ...
                'TARGET_NAME', ...
                'TARGET_TYPE', ...
                'PROCESSING_LEVEL_ID', ...
                'START_TIME', ...
                'STOP_TIME', ...
                'SPACECRAFT_CLOCK_START_COUNT', ...
                'SPACECRAFT_CLOCK_STOP_COUNT', ...
                'DESCRIPTION'};
            % Keywords which refer to very specific settings.
            RPCLAP_KEY_ORDER_LIST = { ...
                'ROSETTA:LAP_TM_RATE', ...
                'ROSETTA:LAP_BOOTSTRAP', ...
                ...
                'ROSETTA:LAP_FEEDBACK_P1', ...
                'ROSETTA:LAP_P1_ADC20', ...
                'ROSETTA:LAP_P1_ADC16', ...
                'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
                'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
                'ROSETTA:LAP_P1_RX_OR_TX', ...
                'ROSETTA:LAP_P1_ADC16_FILTER', ...
                'ROSETTA:LAP_IBIAS1', ...
                'ROSETTA:LAP_VBIAS1', ...
                'ROSETTA:LAP_P1_BIAS_MODE', ...
                'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
                'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
                'ROSETTA:LAP_P1_SWEEP_STEPS', ...
                'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
                'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
                'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
                'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
                'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
                'ROSETTA:LAP_P1_DENSITY_FIX_DURATION', ...
                ...
                'ROSETTA:LAP_FEEDBACK_P2', ...
                'ROSETTA:LAP_P2_ADC20', ...
                'ROSETTA:LAP_P2_ADC16', ...
                'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
                'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
                'ROSETTA:LAP_P2_RX_OR_TX', ...
                'ROSETTA:LAP_P2_ADC16_FILTER', ...
                'ROSETTA:LAP_IBIAS2', ...
                'ROSETTA:LAP_VBIAS2', ...
                'ROSETTA:LAP_P2_BIAS_MODE', ...
                'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
                'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
                'ROSETTA:LAP_P2_SWEEP_STEPS', ...
                'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
                'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
                'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
                'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
                'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
                'ROSETTA:LAP_P2_DENSITY_FIX_DURATION', ...
                ...
                'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
                'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
                'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE'
                };
            KEY_ORDER_LIST = [GENERAL_KEY_ORDER_LIST, RPCLAP_KEY_ORDER_LIST];
            
            % Give error if encountering any of these keys.
            % Useful for obsoleted keys that should not exist anymore.
            FORBIDDEN_KEYS = { ...
                'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
                'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
                'ROSETTA:LAP_SWEEP_STEPS', ...
                'ROSETTA:LAP_SWEEP_START_BIAS', ...
                'ROSETTA:LAP_SWEEP_FORMAT', ...
                'ROSETTA:LAP_SWEEP_RESOLUTION', ...
                'ROSETTA:LAP_SWEEP_STEP_HEIGHT'};
            
            %         ADD_QUOTES_KEYS = { ...
            %             'DESCRIPTION', ...
            %             'SPACECRAFT_CLOCK_START_COUNT', ...
            %             'SPACECRAFT_CLOCK_STOP_COUNT', ...
            %             'INSTRUMENT_MODE_DESC', ...
            %             'ROSETTA:LAP_TM_RATE', ...
            %             'ROSETTA:LAP_BOOTSTRAP', ...
            %             'ROSETTA:LAP_FEEDBACK_P1', ...
            %             'ROSETTA:LAP_FEEDBACK_P2', ...
            %             'ROSETTA:LAP_P1_ADC20', ...
            %             'ROSETTA:LAP_P1_ADC16', ...
            %             'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
            %             'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
            %             'ROSETTA:LAP_P1_RX_OR_TX', ...
            %             'ROSETTA:LAP_P1_ADC16_FILTER', ...
            %             'ROSETTA:LAP_P1_BIAS_MODE', ...
            %             'ROSETTA:LAP_P2_ADC20', ...
            %             'ROSETTA:LAP_P2_ADC16', ...
            %             'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
            %             'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
            %             'ROSETTA:LAP_P2_RX_OR_TX', ...
            %             'ROSETTA:LAP_P2_ADC16_FILTER', ...
            %             'ROSETTA:LAP_P2_BIAS_MODE', ...
            %             'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
            %             'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
            %             'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE', ...
            %             'ROSETTA:LAP_VBIAS1', ...
            %             'ROSETTA:LAP_VBIAS2', ...
            %             ...
            %             'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
            %             'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
            %             'ROSETTA:LAP_P1_SWEEP_STEPS', ...
            %             'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
            %             'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
            %             'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
            %             'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
            %             'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
            %             'ROSETTA:LAP_SWEEPING_P1', ...
            %             ...
            %             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET', ...
            %             'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
            %             'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
            %             'ROSETTA:LAP_P2_SWEEP_STEPS', ...
            %             'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
            %             'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
            %             'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
            %             'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
            %             'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
            %             'ROSETTA:LAP_SWEEPING_P2', ...
            %             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET'};
            
            % Keys for which quotes are added to the value if the values does not already have quotes.
            FORCE_QUOTE_KEYS = {...
                'DESCRIPTION', ...
                'SPACECRAFT_CLOCK_START_COUNT', ...
                'SPACECRAFT_CLOCK_STOP_COUNT'};
            
            obj.COTLF_HEADER_OPTIONS = struct(...
                'keyOrderList',        {KEY_ORDER_LIST}, ...
                'forbiddenKeysList',   {FORBIDDEN_KEYS}, ...
                'forceQuotesKeysList', {FORCE_QUOTE_KEYS});
        end
        
        
        
    %end    % methods
    
    %methods(Static)
    
    
        
        % Construct list of key-value pairs to use for all LBL files.
        % -----------------------------------------------------------
        % Keys must not collide with keys set for specific file types.
        % For file types that read CALIB LBL files, must overwrite old keys(!).
        %
        % NOTE: Only keys that already exist in the CALIB files that are read (otherwise intentional error)
        %       and which are thus overwritten.
        % NOTE: Might not be complete.
        % NOTE: Contains many hardcoded constants, but not only.
        %
        % NOTE: Will not correctly assign all values, since they are overwritten in delivery code anyway. Simplifies
        % this code, and reduces the number of arguments. This however increases the number of errors if validating
        % DERIV1 LBL files with e.g. "pvv label".
        
        function LblAllKvpl = get_LblAllKvpl(obj, LABEL_REVISION_NOTE)
            % PROPOSAL: Rewrite to use EJ_lapdog_shared.utils.KVPL.create.
            % PROPOSAL: Use generate_PDS_data?

            % ASSERTION
            if ~isempty(regexp(LABEL_REVISION_NOTE, '"', 'once'))
                error('Argument LABEL_REVISION_NOTE contains quote(s).')
            end
            
            
            LblAllKvpl = [];
            LblAllKvpl.keys = {};
            LblAllKvpl.values = {};
            
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PDS_VERSION_ID',            'PDS3');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'DATA_QUALITY_ID',           '"1"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PRODUCT_CREATION_TIME',     datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PRODUCT_TYPE',              '"DDR"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PROCESSING_LEVEL_ID',       '"5"');
            %
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'DATA_SET_ID',               ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'DATA_SET_NAME',             ['"', strrep(datasetname, sprintf( '3 %s CALIB', shortphase), sprintf( '5 %s DERIV', shortphase)), '"']);
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"', lbltime, lbleditor, lblrev));
            %             %LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'NOTE',                      '"... Cheops Reference Frame."');  % Include?!!
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PRODUCER_ID',               producershortname);
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'INSTRUMENT_HOST_ID',        'RO');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'INSTRUMENT_ID',             'RPCLAP');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'TARGET_TYPE',               sprintf('"%s"', targettype));
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'MISSION_ID',                'ROSETTA');
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
            %             LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(LblAllKvpl, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));

            LblAllKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pairs(LblAllKvpl, {...
                'PDS_VERSION_ID',            'PDS3'; ...
                'DATA_QUALITY_ID',           '"<UNSET>"'; ...
                'PRODUCT_CREATION_TIME',     datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'); ...
                'PRODUCT_TYPE',              '"<UNSET>"'; ...
                'PROCESSING_LEVEL_ID',       '"<UNSET>"'; ...
                ...
                'DATA_SET_ID',               ['"<UNSET>"']; ...
                'DATA_SET_NAME',             ['"<UNSET>"']; ...
                'LABEL_REVISION_NOTE',       ['"', LABEL_REVISION_NOTE, '"']; ...
            %    'NOTE',                      '"... Cheops Reference Frame."');  % Include?!!
                'PRODUCER_FULL_NAME',        '"<UNSET>"'; ...
                'PRODUCER_ID',               '<UNSET>'; ...
                'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"'; ...
                'INSTRUMENT_HOST_ID',        'RO'; ...
                'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"'; ...
                'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"'; ...
                'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"'; ...
                'INSTRUMENT_ID',             'RPCLAP'; ...
                'TARGET_NAME',               '"<UNSET>"'; ...
                'TARGET_TYPE',               '"<UNSET>"'; ...
                'MISSION_ID',                'ROSETTA'; ...
                'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'); ...
                'MISSION_PHASE_NAME',        '"<UNSET>"'}...
            );
        end
    end    % methods
end    % classdef
