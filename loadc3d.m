function [output] = loadc3d(filename)% [output] = loadc3d(filename) Load in .c3d files.%%   inputs      - filename, full filepath to .c3d file%%   output      - output, structure containing c3d file information and%                 data%                   - FILE_HEADER - pp. 31%                   - FILE_INFO - pp. 39%                   - MARKERS - pp. 55%                   - ANALOG - pp. 62%% Remarks% - This code will load .c3d files according to the standard described in% "The C3D File Format User Guide" by Motion Lab Systems, which can be% found here: https://www.c3d.org/pdf/c3dformat_ug.pdf.%% Future Work% - None%% MAY 2019 - Created by Will Denton, 21denton@gmail.com%%   Last checked for an update: 01-Jan-2000 00:00:00%%   VERSION 1.0.0%   - Added updates/patching.%   - Added usage tracking to allow the Department of Biomechanics at the%   University of Omaha see which codes and versions are being used.%   - Added error reporting to allow the Department of Biomechanics at the%   University of Omaha to make improvements to this code.%% Copyright 2020 Movement Analysis Core, Center for Human Movement% Variability, University of Nebraska at Omaha%% Redistribution and use in source and binary forms, with or without % modification, are permitted provided that the following conditions are % met:%% 1. Redistributions of source code must retain the above copyright notice,%    this list of conditions and the following disclaimer.%% 2. Redistributions in binary form must reproduce the above copyright %    notice, this list of conditions and the following disclaimer in the %    documentation and/or other materials provided with the distribution.%% 3. Neither the name of the copyright holder nor the names of its %    contributors may be used to endorse or promote products derived from %    this software without specific prior written permission.%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS % IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR % PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR % CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, % EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, % PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR % PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF % LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING % NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS % SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.%%dbstop if errorfid = fopen(filename);output.FILE_HEADER = read_c3d_header;output.FILE_INFO = read_c3d_parameter;read_c3d_data;%%===================================================================%%    function FILE_HEADER = read_c3d_header        %A single 512 byte header section                       See page 32        FILE_HEADER = cell(256,1);        FILE_HEADER{1} = fread(fid,2,'int8');                              %Word 1        for i = 2:6, FILE_HEADER{i} = fread(fid,1,'int16'); end            %Words 2-6        for i = 8, FILE_HEADER{i} = fread(fid,1,'float'); end              %Words 7-8        for i = 9:10, FILE_HEADER{i} = fread(fid,1,'int16'); end           %Words 9-10        for i = 12, FILE_HEADER{i} = fread(fid,1,'float'); end             %Words 11-12        for i = 13:152, FILE_HEADER{i} = fread(fid,1,'int16'); end         %Words 13-152        for i = 154:2:188, FILE_HEADER{i} = fread(fid,1,'float'); end      %Words 153-188        for i = 189:197, FILE_HEADER{i} = fread(fid,2,'int8'); end         %Words 189-197        FILE_HEADER{198} = fread(fid,1,'int16');                           %Work 198        for i = 199:234, FILE_HEADER{i} = char(fread(fid,2,'int8')); end   %Words 199-234        for i = 235:256, FILE_HEADER{i} = fread(fid,1,'int16'); end        %Words 235-256    end    function [STRUCT,RAW] = read_c3d_parameter        RAW = read_FILE_INFO;        STRUCT.HEADER = RAW;        while 1            %Number of characters in group/parameter name; Group ID number            for i = 1:2, RAW(end+1) = {fread(fid,1,'int8')}; end            GROUP_ID = RAW{end};            %Group ID numbers are negative for group and positive for            %parameter            if ~exist('NUM_PARAMETER_BLOCKS','var')                NUM_PARAMETER_BLOCKS=0;            end            if RAW{end} < 0                %_________________________ GROUP _________________________%                %Group Name                GROUP_NAME = '';                for n = 1:RAW{end-1}                    RAW(end+1) = {char(fread(fid,1,'int8'))};                    GROUP_NAME = [GROUP_NAME RAW{end}];                end                STRUCT.(GROUP_NAME).ID = GROUP_ID;                %Offset pointing to start of next group/parameter, number                %of characters in Group Description                for i = 1:3, RAW(end+1) = {fread(fid,1,'int8')};   end                STRUCT.(GROUP_NAME).BYTEOFFSET = [RAW{end-2} RAW{end-1}];                %Group Description                GROUP_DESCRIPTION = '';                for m = 1:RAW{end-1}                    RAW(end+1) = {char(fread(fid,1,'int8'))};                    GROUP_DESCRIPTION = [GROUP_DESCRIPTION RAW{end}];                end                STRUCT.(GROUP_NAME).DESCRIPTION = GROUP_DESCRIPTION;            elseif RAW{end} > 0                %_______________________ Parameter _______________________%                %Parameter Name                PARAMETER_NAME = '';                for n = 1:RAW{end-1}                    RAW(end+1) = {char(fread(fid,1,'int8'))};                    PARAMETER_NAME = [PARAMETER_NAME RAW{end}];                end                GROUP_NAME = find_group(GROUP_ID);                STRUCT.(GROUP_NAME).(PARAMETER_NAME).ID = GROUP_ID;                %Offset pointing to the start of the next group/parameter,                %size of data elements (i.e. char, int8, int16, float),                %number of dimensions                for i = 1:4, RAW(end+1) = {fread(fid,1,'int8')};   end                STRUCT.(GROUP_NAME).(PARAMETER_NAME).BYTEOFFSET = [RAW{end-3} RAW{end-2}];                switch RAW{end-1}                    case -1                        DATA_TYPE = 'char';                    case 1                        DATA_TYPE = 'int8';                    case 2                        DATA_TYPE = 'int16';                    case 4                        DATA_TYPE = 'float';                end                STRUCT.(GROUP_NAME).(PARAMETER_NAME).DATATYPE = DATA_TYPE;                STRUCT.(GROUP_NAME).(PARAMETER_NAME).NDIMENSIONS = RAW{end};                %Parameter Dimensions                T = 1;                DIMENSIONS = '';                D = RAW{end}; %if D == 0, D = 1; end                        %Parameter is scalar if D == 0                for d = 1:D                    RAW(end+1) = {fread(fid,1,'int8')};                    DIMENSIONS = [DIMENSIONS num2str(RAW{end}) 'x'];                    T = T*RAW{end};                end                STRUCT.(GROUP_NAME).(PARAMETER_NAME).DIMENSIONS = DIMENSIONS(1:end-1);                %Parameter Data                clear VALUE;                for t = 1:T                    switch DATA_TYPE                        case 'char'                            RAW(end+1) = {char(fread(fid,1,'int8'))};                        case 'int8'                            RAW(end+1) = {fread(fid,1,'int8')};                        case 'int16'                            RAW(end+2) = {fread(fid,1,'int16')};                        case 'float'                            RAW(end+4) = {fread(fid,1,'float')};                    end                    VALUE(t) = RAW{end};                end                if exist('VALUE','var')                    STRUCT.(GROUP_NAME).(PARAMETER_NAME).VALUE = VALUE; %*** THIS NEEDS TO BE CHANGED TO ACCOUNT FOR MULTIPLE DIMENSIONS                else                    STRUCT.(GROUP_NAME).(PARAMETER_NAME).VALUE = 0; %*** MIGHT BE [];                end                %Number of characters in Parameter Description                RAW(end+1) = {fread(fid,1,'int8')};                %Parameter Description                PARAMETER_DESCRIPTION = '';                for m = 1:RAW{end}                    RAW(end+1) = {char(fread(fid,1,'int8'))};                    PARAMETER_DESCRIPTION = [PARAMETER_DESCRIPTION RAW{end}];                end                STRUCT.(GROUP_NAME).(PARAMETER_NAME).DESCRIPTION = PARAMETER_DESCRIPTION;            elseif 512*NUM_PARAMETER_BLOCKS - length(RAW) == 1                RAW(end+1) = {fread(fid,1,'int8')};                break;            elseif length(RAW)/512 > NUM_PARAMETER_BLOCKS                break;            end        end        display_group_parameter('VALUE');        function PARAMETER_HEADER = read_FILE_INFO            for i = 1:4, PARAMETER_HEADER{i} = fread(fid,1,'int8'); end            NUM_PARAMETER_BLOCKS = PARAMETER_HEADER{3};            fprintf('Numer of parameter blocks to follow: %d\r',NUM_PARAMETER_BLOCKS);            switch PARAMETER_HEADER{4}                case 84                    PROCESSOR_TYPE = 'Intel';                case 85                    PROCESSOR_TYPE = 'DEC (VAX, PDP-11)';                case 86                    PROCESSOR_TYPE = 'MIPS processor (SGI/MIPS)';            end            fprintf('Processor type: %s\r',PROCESSOR_TYPE)        end        function GROUP_NAME = find_group(GROUP_ID)            FIELDS = fieldnames(STRUCT);            for i = 1:length(FIELDS)                try                    if abs(STRUCT.(FIELDS{i}).ID) == GROUP_ID                        GROUP_NAME = FIELDS{i};                        return;                    end                catch                                    end            end        end        function display_group_parameter(DISPLAY_FIELD)            GROUP_FIELDS = fieldnames(STRUCT);            for i = 1:length(GROUP_FIELDS)                GROUP_FIELD = GROUP_FIELDS{i};                try                    PARAMETER_FIELDS = fieldnames(STRUCT.(GROUP_FIELD));                    for j = 1:length(PARAMETER_FIELDS)                        PARAMETER_FIELD = PARAMETER_FIELDS{j};                        try                            TEMP = STRUCT.(GROUP_FIELD).(PARAMETER_FIELD).(DISPLAY_FIELD);                            if ~ischar(TEMP)                                DISPLAY = '';                                for k = 1:length(TEMP)                                    DISPLAY = [DISPLAY sprintf('%d ',TEMP(k))];                                end                            else                                DISPLAY = TEMP;                            end                            fprintf('%s:%s = %s\r',GROUP_FIELD,PARAMETER_FIELD,DISPLAY);                        catch                                                    end                    end                catch                                    end            end        end    end    function read_c3d_data        output.HZ = output.FILE_INFO.POINT.RATE.VALUE;        %Read marker+analog data        if output.FILE_INFO.POINT.SCALE.VALUE   < 0            DATA_TYPE = 'float';            FOURTH_WORD_DATA_TYPE = 'int16';            NUM_CAMERA_BYTES = 16;            POINT_SCALE = 1;        elseif output.FILE_INFO.POINT.SCALE.VALUE > 0            DATA_TYPE = 'int16';            FOURTH_WORD_DATA_TYPE = 'int8';            NUM_CAMERA_BYTES = 8;            POINT_SCALE = abs(output.FILE_INFO.POINT.SCALE.VALUE);        end        DATA = fread(fid,DATA_TYPE);        ANALOG_SAMPLES_PER_3D_FRAME = output.FILE_INFO.ANALOG.RATE.VALUE/output.FILE_INFO.POINT.RATE.VALUE;        NUM_ANALOG_CHANNELS = output.FILE_INFO.ANALOG.USED.VALUE;        VALUES_PER_FRAME = ANALOG_SAMPLES_PER_3D_FRAME*NUM_ANALOG_CHANNELS+output.FILE_INFO.POINT.USED.VALUE*4;        MARKER_NAMES = strsplit(output.FILE_INFO.POINT.LABELS.VALUE,' '); MARKER_NAMES = MARKER_NAMES(1:end-1)';        ANALOG_NAMES = strsplit(output.FILE_INFO.ANALOG.LABELS.VALUE,' '); ANALOG_NAMES = ANALOG_NAMES(1:end-1)';        ui = 0;        ni = 0;        for i = 1:output.FILE_INFO.POINT.USED.VALUE            if contains(MARKER_NAMES{i,1},'U') && sum(isletter(MARKER_NAMES{i,:})) == 1                ui=ui+1;                output.MARKERS.(['U' num2str(ui)]).NAME = MARKER_NAMES{i,:};                output.MARKERS.(['U' num2str(ui)]).X = DATA(i*4-3:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                output.MARKERS.(['U' num2str(ui)]).Y = DATA(i*4-2:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                output.MARKERS.(['U' num2str(ui)]).Z = DATA(i*4-1:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                temp = typecast(single(DATA(i*4:VALUES_PER_FRAME:length(DATA))),FOURTH_WORD_DATA_TYPE);                temp = reshape(temp,2,length(temp)/2)';                output.MARKERS.(['U' num2str(ui)]).C = cellfun(@(x) find(x),num2cell(de2bi(temp(:,1),NUM_CAMERA_BYTES),2),'UniformOutput',0);                output.MARKERS.(['U' num2str(ui)]).E = temp(:,2)/abs(output.FILE_INFO.POINT.SCALE.VALUE);            else                ni=ni+1;                output.MARKERS.(['M' num2str(ni)]).NAME = MARKER_NAMES{i,:};                output.MARKERS.(['M' num2str(ni)]).X = DATA(i*4-3:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                output.MARKERS.(['M' num2str(ni)]).Y = DATA(i*4-2:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                output.MARKERS.(['M' num2str(ni)]).Z = DATA(i*4-1:VALUES_PER_FRAME:length(DATA))/POINT_SCALE;                temp = typecast(single(DATA(i*4:VALUES_PER_FRAME:length(DATA))),FOURTH_WORD_DATA_TYPE);                temp = reshape(temp,2,length(temp)/2)';                output.MARKERS.(['M' num2str(ni)]).C = cellfun(@(x) find(x),num2cell(de2bi(temp(:,1),NUM_CAMERA_BYTES),2),'UniformOutput',0);                output.MARKERS.(['M' num2str(ni)]).E = temp(:,2)/abs(output.FILE_INFO.POINT.SCALE.VALUE);            end        end        x1 = find(mod(1:length(DATA),4*output.FILE_INFO.POINT.USED.VALUE+output.FILE_INFO.ANALOG.RATE.VALUE/output.FILE_INFO.POINT.RATE.VALUE*output.FILE_INFO.ANALOG.USED.VALUE) == 1)+4*output.FILE_INFO.POINT.USED.VALUE; %109   397   685   973        x2 = find(mod(1:output.FILE_INFO.ANALOG.USED.VALUE*output.FILE_INFO.ANALOG.RATE.VALUE/output.FILE_INFO.POINT.RATE.VALUE,output.FILE_INFO.ANALOG.USED.VALUE) == 1)-1; %1    19    37    55    73    91   109   127   145   163        ind = reshape(bsxfun(@plus,x1,x2.'),1,[]);        for i = 1:output.FILE_INFO.ANALOG.USED.VALUE            output.ANALOG.(['A' num2str(i)]).NAME = ANALOG_NAMES{i,:};            output.ANALOG.(['A' num2str(i)]).VALUE = DATA(ind);            ind = ind+1;        end    endend