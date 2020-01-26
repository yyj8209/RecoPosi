function [Array1,Array2,Array3,DataPath] = dataFromFiletoArray(SignalWidth,MaxTargetNum)
    % % 选择数据文件路径
    FolderName = uigetdir('..\OriginDat','请选择数据文件路径。');   
    % FolderName = 'E:\matlab\OriginDat\20190305';    % 调试时用这个默认路径。
    A = dir(fullfile(FolderName,'*.dat'));
    % %列表选择对话框
    AllFileNames = cell(size(A));
    for i=1:size(A,1)
        AllFileNames{i,1} = A(i,1).name;
    end
    [Sel,Ok]=listdlg('liststring',AllFileNames,...
        'listsize',[360 480],'OkString','确定','CancelString','取消',...
        'promptstring','请选择数据文件','name','请选择数据文件（多选）',...
        'selectionmode','multiple');
    if(Ok == 0)
        msgbox('您取消了选择文件。');
        return;
    end
    FileName = A(Sel,1);
    FullName = A(Sel,1);
    FileNumSel = size(FileName,1);
    Array = cell(size(FileName));
    DataPath = [];

    for k=1:FileNumSel
        FullName(k,1).name = strcat(FolderName,'\', FileName(k,1).name);
        DataPath(k).filename = FileName(k,1).name;
        DataPath(k).fullname = FullName(k,1).name;
    end

%     Fpass = 1;   Fstop = 5;  fs = 100; rpL = 1; rsL = 60;
%     [bL,~] = LPFDesign(Fpass,Fstop,fs,rpL,rsL);
    load('.\Settings\LPFParameter.mat');     % 载入滤波器系数。
    count = zeros(size(FileName));
    MeanValue = zeros(3,FileNumSel);
    for i = 1:FileNumSel
    % 1、读取前三行，即三个有效通道的数据；
    % ----------------------------------------------------------------- %
        fid = fopen(FullName(i,1).name);
        fseek(fid,0,'eof');
        filelength = ftell(fid);
        fseek(fid,0,'bof');
        [A,count(i)]=fread(fid,(filelength)/4,'float32');
        fclose(fid);
        A = reshape(A,6,count(i)/6);
        x = ([A(1,:);A(2,:);A(3,:)])*5000/32768;

        y = zeros(size(x));
        for k1 = 3:-1:1     % x 由3个通道的数据向量组成。
            x1 = x(k1,:);
            % 增加一个去除脉冲的函数（假定最多只有一个脉冲）。基本思路是，跳跃大于200时，确定该点为脉冲，去除之。2019.03.19
            [loc] = find(abs(diff(x1))>200);   % 
            if(~isempty(loc))     % 这里去脉冲点。若有多个，可用find函数。
                x1(loc+1) = x1(loc+3);
            end
            x2 = x1 - mean(x1);      % 去直流。

            y1 = [zeros(1,length(bL)),x2,zeros(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
            y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
            y3 = y2(length(bL)+1:length(y2)-length(bL));
            y(k1,:) = y3 - mean(y3) + mean(x1);    % 到这一步已经恢复了信号。
            [~,MeanValue(k1,i),~,~] = peakValue(y(k1,:),SignalWidth,MaxTargetNum);
        end
        Array{i} = {y};
    end
    Array1 = zeros(FileNumSel,max(count)/6);     % 因每次数据长度不一，取最大值作为长度，不足的补零。
    Array2 = Array1;
    Array3 = Array1;
    for i = 1:FileNumSel
        tmp = cell2mat(Array{i,1});
        [n] = size(tmp,2);
        Array1(i,1:n) = tmp(1,:);
        Array1(i,n:end) = MeanValue(1,i);
        Array2(i,1:n) = tmp(2,:);
        Array2(i,n:end) = MeanValue(2,i);
        Array3(i,1:n) = tmp(3,:);
        Array3(i,n:end) = MeanValue(3,i);
    end
end