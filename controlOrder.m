function [Order] = controlOrder(Lon,Lat,AngleV,Step,OrderType,Radius,SequenceNumber,TotalNumber)
%[Order] = controlOrder(Lat,Lon,OrderType)
%   此处显示详细说明
% 输入：Lon表示经度，Lat表示纬度，OrderType表示命令类型
% 输出：Order 为带CRC16校验码的命令。

    HeadLen = 4;
    LonLen = 5;
    LatLen = 5;
    AngleVLen = 1;
    StepLen = 1;
    RadiusLen = 4;
    TypeLen = 1;
    SNLen = 1;
    TNLen = 1;
    ReservedLen = 4;
    R1 = HeadLen+1;
    R2 = LonLen+R1;
    R3 = LatLen+R2;
    R4 = AngleVLen+R3;
    R5 = StepLen+R4;
    R6 = RadiusLen+R5;
    R7 = TypeLen+R6;
    R8 = SNLen+R7;
    R9 = TNLen+R8;
    R10 = ReservedLen+R9;

% 控制命令格式，请参看协议。
    InitialOrder = ['55';'AA';'02';'1D';...    % 字节头
        '00';'00';'00';'00';'00';...           % 经度
        '00';'00';'00';'00';'00';...           % 纬度
        '00';'00';'00';'00';'00';'00';...      % 角速度1、步进1、半径4
        '00';'00';'00';...                     % 命令类型、坐标序号/总数
        '00';'00';'00';'00'];                  % 备用4 .
    
    InitialOrder(R1:R2-1,:) = Lon;
    InitialOrder(R2:R3-1,:) = Lat;
    InitialOrder(R3:R4-1,:) = AngleV;
    InitialOrder(R4:R5-1,:) = Step;
    InitialOrder(R5:R6-1,:) = Radius;
    InitialOrder(R6,:) = OrderType;
    InitialOrder(R7,:) = SequenceNumber;
    InitialOrder(R8,:) = TotalNumber;
    
    [Order,~] = CRC16_MODBUS(hex2dec(InitialOrder));
    Order = hex2dec(Order);
end

