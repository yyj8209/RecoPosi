function [Array1,Array2,Array3,Direction,Angle,AccumulateDeltaY] = dataFromComtoArray2(AreaData,SignalWidth,MaxTargetNum)
% [Array1,Array2,Array3,Deriction,Angle,AccumulateDeltaY] = dataFromComtoArray(AreaData)
% 不是补齐，而是以扫描数据最少的为基准，从两边去除其余扫描数据。
% 输入：AreaData ，cell类型，每个cell是一个结构体，包含 SQNumber、Direction、Angle、Value、AccumulateDeltaY。
% 输出： Array1，CH1数据矩阵,
%       Array2，CH2数据矩阵，
%       Array3，CH3数据矩阵，
%       Direction，方向向量，0 表示顺时针，1 表示逆时针，
%       Angle，角度数据矩阵，已插值完毕，
%       AccumulateDeltaY，当前Y 轴偏移向量。

    if(~iscell(AreaData))
        error('用来成像的数据格式不正确！');
    end
    AreaData(1) = [];% 第一个是空元组，去掉。
    [Rows,Columns] = size(AreaData);
    Direction = zeros(Rows,Columns);
    AccumulateDeltaY = zeros(Rows,Columns);
    y0 = cell(3,Columns);

%     Fpass = 1;   Fstop = 5;  fs = 100; rpL = 1; rsL = 60;
%     [bL,~] = LPFDesign(Fpass,Fstop,fs,rpL,rsL);
    load('.\Settings\LPFParameter.mat');     % 载入滤波器系数。
    countValue = zeros(Rows,Columns);
    countAngle = zeros(Rows,Columns);
    ValueLen = zeros(1,Columns);
    LocYMin = zeros(1,Columns);     % 数据峰值点的位置
    LenMin = zeros(1,Columns);     % 数据长度
    tmpAngle = cell(Rows,Columns);
    MeanValue = zeros(3,Columns);
    for i = 1:Columns
    % 2、读取方向数据；
    % ----------------------------------------------------------------- %
        Direction(i) = AreaData{i}.Direction;
    % 1、读取三个有效通道的数据；
    % ----------------------------------------------------------------- %
        A = AreaData{i}.Value;
        countValue(i) = size(A,2);
        A = reshape(A,6,countValue(i)/6);   % 共6路数据，只有前三个通道有信号。
        x = ([A(1,:);A(2,:);A(3,:)])*5000/32768;
        y = zeros(size(x));
        for k1 = 3:-1:1     % x 由3个通道的数据向量组成。
            x1 = x(k1,:);
            % 增加一个去除脉冲的函数（假定最多只有一个脉冲）。基本思路是，跳跃大于200时，确定该点为脉冲，去除之。2019.03.19
            [loc] = find(abs(diff(x1))>500);   % 
            if(~isempty(loc))     % 这里去脉冲点。若有多个，可用find函数。
                x1(loc+1) = x1(loc+3);
            end
            x2 = x1 - mean(x1);      % 去直流。
            y1 = [zeros(1,length(bL)),x2,zeros(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
            y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
            y3 = y2(length(bL)+1:length(y2)-length(bL));
            y(k1,:) = y3 - mean(y3) + mean(x1);    % 到这一步已经恢复了信号。
            [~,MeanValue(k1,i),~,~] = peakValue(y,SignalWidth,MaxTargetNum);
            if(Direction(i) == 0 )
                y0{k1,i} = y(k1,:);
            else
                y0{k1,i} = flip(y(k1,:));
            end
        end
        ValueLen(i) = size(y,2);
    % 3、读取Y轴偏移数据；
    % ----------------------------------------------------------------- %
        AccumulateDeltaY(i) = AreaData{i}.AccumulateDeltaY;
    % 4、读取角度数据；
    % 为了去除启动和停止时的角度抖动
    % ----------------------------------------------------------------- %
        yAngle = AreaData{i}.Angle;
        countAngle(i) = length(yAngle);
        xAngle = 1:countAngle(i);
        xi = linspace(xAngle(1),xAngle(end),ValueLen(i));
        VibrateAngle = interp1(xAngle,yAngle,xi,'spline');   % 插值到与数据长度一致。  
        x2 = [VibrateAngle(1)*ones(1,length(bL)),VibrateAngle,...
            VibrateAngle(end)*ones(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
        y1 = x2 - mean(x2);      % 去直流。
        y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
        y3 = y2(length(bL)+1:length(y2)-length(bL));
        NoneVibrateAngle = y3 - mean(y3) + mean(x2);    % 到这一步已经恢复了信号。
        % 角度的延迟处理
        [loc] = find(abs(diff(NoneVibrateAngle))>0.05);   % 
        Delay = loc(1)-0;
        Padding = ones(1,Delay-1)*NoneVibrateAngle(end);
        NoneDelayAngle = [NoneVibrateAngle(Delay:end),Padding];
        if(Direction(i) == 0 )
            tmpAngle{i} = NoneDelayAngle;   % 输出备用。
        else
            tmpAngle{i} = flip(NoneDelayAngle);   % 输出备用。
        end
    end

    % ============================= 整理数据 ============================== %
    y1 = cell(3,Columns);   % 补前得到的数据
    y2 = cell(3,Columns);   % 补后得到的数据
%     CHMean = [CH1Mean CH2Mean CH3Mean];
    % 以Y轴方向为基准，去掉前面的数据和角度。
    for i = 1:Columns
        [~,LocYMin(i)] = min(abs(tmpAngle{i}-90));   % 最接近于Y方向的数据点
    end
    [~,Locate] = min(LocYMin);
    tLoc = LocYMin - LocYMin(Locate);    % 正Y轴对应点的偏移。
    for i = 1:Columns
        if(~tLoc(i)) % 不用补的情况，正好对齐。
            for k1 = 1:3     % x 由3个通道的数据向量组成。
                y1{k1,i} = y0{k1,i};
            end
            continue;
        end
        for k1 = 1:3     % x 由3个通道的数据向量组成。
% %             vPaddingPre = mean(y0{k1,i})*ones(1,tLoc(i));
%             vPaddingPre = CHMean(k1)*ones(1,tLoc(i));
%             vPaddingPre(1) = vPaddingPre(1) + 1;
%             vPaddingPre(2) = vPaddingPre(2) - 1;
% %             vPaddingPre = nan*ones(1,tLoc(i));
            tmp = y0{k1,i};
            tmp = tmp((1+tLoc(i)):end);
            y1{k1,i} = tmp;
        end
        tmp = tmpAngle{i};
% %         tPaddingPre = tmp(1)*ones(1,tLoc(i));
%         tPaddingPre = tmp(1)*ones(1,tLoc(i));
        tmp(1:tLoc(i)) = [];
        tmpAngle{i} = tmp;
    end
    % 补后面的数据和角度。
    for i = 1:Columns
        LenMin(i) = length(tmpAngle{i});
    end
    [~,Len] = min(LenMin);
    tLen = LenMin - LenMin(Len);  
%     tmpAngle = cell(1,Columns);
    for i = 1:Columns
        if(~tLen(i)) % 不用补的情况。
            for k1 = 1:3     % x 由3个通道的数据向量组成。
                y2{k1,i} = y1{k1,i};
            end
            continue;
        end
        for k1 = 1:3     % x 由3个通道的数据向量组成。
%             vPaddingPro = CHMean(k1)*ones(1,tLen(i));
%             vPaddingPro(1) = vPaddingPro(1) + 1;
%             vPaddingPro(2) = vPaddingPro(2) - 1;
% %             vPaddingPro = nan*ones(1,tLen(i));
%             y2{k1,i} = [y1{k1,i},vPaddingPro];
            tmp = y1{k1,i};
            tmp = tmp(1:LenMin(Len));
            y2{k1,i} = tmp;
        end
        tmp = tmpAngle{i};
        tmp = tmp(1:LenMin(Len));
        tmpAngle{i} = tmp;
%         tPaddingPro = tmp(end)*ones(1,tLen(i));
%         tmpAngle{i} = [tmp,tPaddingPro];
    end
    
    % 输出为后期处理需要的格式
    Array1 = zeros(Columns,min(LenMin));
    Array2 = Array1;
    Array3 = Array1;
    Angle = Array1;
    for i = 1:Columns
        Array1(i,:) = y2{1,i};
        Array2(i,:) = y2{2,i};
        Array3(i,:) = y2{3,i};
        Angle(i,:) = tmpAngle{i};
    end
end