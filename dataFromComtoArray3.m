function [Array1,Array2,Array3,UTME,UTMN] = dataFromComtoArray3(AreaData,Lat0,Lon0)
% [Array1,Array2,Array3,Deriction,Angle,AccumulateDeltaY] = dataFromComtoArray(AreaData)
% 不是补齐，而是以扫描数据最少的为基准，从两边去除其余扫描数据。
% 输入：AreaData ，cell类型，每个cell是一个结构体，包含 SQNumber、Direction、Angle、Value、AccumulateDeltaY。
% Direction、Angle、AccumulateDeltaY 这三个输入在本函数用不上
% 输出： Array1，CH1数据矩阵,
%       Array2，CH2数据矩阵，
%       Array3，CH3数据矩阵，
%       UTME，  数据的相对坐标X位置，
%       UTMN，  数据的相对坐标Y位置，

    if(~iscell(AreaData))
        error('用来成像的数据格式不正确！');
    end
    AreaData(1) = [];% 第一个是空元组，去掉。
    CellLen = length(AreaData);
    r = 5000/32768;

    load('.\Settings\LPFParameter.mat');     % 载入滤波器系数。
    countValue = zeros(1,CellLen);
    Data = cell(5,CellLen);   % 个人习惯每行为一次数据
%     countAngle = zeros(Rows,Columns);
    ValueLen = zeros(1,CellLen);
%     LocYMin = zeros(1,Columns);     % 数据峰值点的位置
%     LenMin = zeros(1,Columns);     % 数据长度
%     tmpAngle = cell(Rows,Columns);
%     MeanValue = zeros(1,3);   % 增加长度的话，需要用到。
    for i = 1:CellLen
    % 1、读取三个有效通道及位置的数据；
    % ----------------------------------------------------------------- %
        A = double(AreaData{i}.Value)';
        countValue(i) = size(A,2);
        x = A(1:3,:)*r;
        y = zeros(size(x));
        for k1 = 3:-1:1     % x 由3个通道的数据向量组成。
            x1 = x(k1,:);
            % 增加一个去除脉冲的函数（假定最多只有一个脉冲）。基本思路是，跳跃大于200时，确定该点为脉冲，去除之。2019.03.19
            [loc] = find(abs(diff(x1))>200);   % 
            if(~isempty(loc))     % 这里去脉冲点。若有多个，可用find函数。
                x1(loc+1) = x1(loc+3);
            end
            x2 = x1 - mean(x1);      % 去直流。
            y1 = [x2(1)*ones(1,length(bL)),x2,x2(end)*ones(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
            y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
            y3 = y2(length(bL)+1:length(y2)-length(bL));
            y(k1,:) = y3 - mean(y3) + mean(x1);    % 到这一步已经恢复了信号。
        end
%         [~,MeanValue,~,~] = peakValue(y,SignalWidth,MaxTargetNum);
        ValueLen(i) = size(y,2);
        Data{1,i} = y(1,:);  % 个人习惯每行为一次数据
        Data{2,i} = y(2,:);  % 个人习惯每行为一次数据
        Data{3,i} = y(3,:);  % 个人习惯每行为一次数据
%         [Data{4,i},Data{5,i}] = LatLon2UTM(A(4,:),A(5,:),Lat0,Lon0);    % 读取经纬度的情况
        Data{4,i} = A(4,:);  % 个人习惯每行为一次数据  % 读取绝对坐标的情况
        Data{5,i} = A(5,:);  % 个人习惯每行为一次数据
    end

    % ============================= 整理数据 ============================== %
    V = zeros(1,CellLen);
    LocXMin = zeros(1,CellLen);
    LenXMin = zeros(1,CellLen);
    for i = 1:CellLen   % 找出X的最小范围
        [V(i),~] = min(Data{4,i});     % 假设每次探扫的采样速率相同，只需要定下X的一条边位置
    end
    V1max = max(V);      % 每次探扫X的最小值中最大X坐标值
    
    
    for i = 1:CellLen
        [~,LocXMin(i)] = min(abs(V1max - Data{4,i}));   % 最接近于最小矩形左边的数据点
    end
    [~,Locate] = min(LocXMin);
    tLoc = LocXMin - LocXMin(Locate);    % 正Y轴对应点的偏移。
    for i = 1:CellLen
        if(~tLoc(i)) % 不用补的情况，正好对齐。
            continue;
        end
        if(tLoc(i)>length(Data{4,i})/2) % 需要翻转的情况。
            Data{1,i}(1+tLoc(i):end) = [];  % 个人习惯每行为一次数据
            Data{2,i}(1+tLoc(i):end) = [];  % 个人习惯每行为一次数据
            Data{3,i}(1+tLoc(i):end) = [];  % 个人习惯每行为一次数据
            Data{4,i}(1+tLoc(i):end) = [];  % 个人习惯每行为一次数据
            Data{5,i}(1+tLoc(i):end) = [];  % 个人习惯每行为一次数据
            Data{1,i} = fliplr(Data{1,i});
            Data{2,i} = fliplr(Data{2,i});
            Data{3,i} = fliplr(Data{3,i});
            Data{4,i} = fliplr(Data{4,i});
            Data{5,i} = fliplr(Data{5,i});
        else
            Data{1,i}(1:tLoc(i)) = [];  % 个人习惯每行为一次数据
            Data{2,i}(1:tLoc(i)) = [];  % 个人习惯每行为一次数据
            Data{3,i}(1:tLoc(i)) = [];  % 个人习惯每行为一次数据
            Data{4,i}(1:tLoc(i)) = [];  % 个人习惯每行为一次数据
            Data{5,i}(1:tLoc(i)) = [];  % 个人习惯每行为一次数据
        end

    end
    % 补后面的数据和角度。
    for i = 1:CellLen
        LenXMin(i) = length( Data{4,i}); 
    end
    [LenMin,~] = min(LenXMin);    % 最短的那组。
    tLen = LenXMin - LenMin;  
%     tmpAngle = cell(1,Columns);
    for i = 1:CellLen
        if(~tLen(i)) % 不用补的情况。
            continue;
        end
        Data{1,i}(1+LenMin:end) = [];  % 个人习惯每行为一次数据
        Data{2,i}(1+LenMin:end) = [];  % 个人习惯每行为一次数据
        Data{3,i}(1+LenMin:end) = [];  % 个人习惯每行为一次数据
        Data{4,i}(1+LenMin:end) = [];  % 个人习惯每行为一次数据
        Data{5,i}(1+LenMin:end) = [];  % 个人习惯每行为一次数据
    end
    
    % 输出为后期处理需要的格式
    Array1 = zeros(CellLen,LenMin);
    Array2 = Array1;
    Array3 = Array1;
    UTME = Array1;
    UTMN = Array1;
    for i = 1:CellLen
        Array1(i,:) = Data{1,i};
        Array2(i,:) = Data{2,i};
        Array3(i,:) = Data{3,i};
        UTME(i,:)   = Data{4,i};
        UTMN(i,:)   = Data{5,i};
    end
end