function [Lat,Lon,Angle,Status] = readDataFromCom2(data,DeltaLatA,DeltaLatB,FrameLength)
% [Lat,Lon,Angle,Status] = readDataFromCom2(data)
% 输入：data 为从COM2读取的数据，FrameLength 为每一个协议帧的长度。
% 输出：Lat 解析的纬度,Lon 为解析的经度,Angle 为返回的当前（前进）角度（）,
% Status 为自动探扫时，机器人返回的状态 00：无动作；01：单次探扫启动；02：单次探扫停止；03：区域探扫结束。

Lat = [];
Lon = [];
Angle = [];
Status = [];
HeadLen = 4;
LonLen = 5;
LatLen = 5;
AngleLen = 4;
% StatursLen = 1;
% ReservedLen = 4;
R1 = HeadLen+1;
R2 = LonLen+R1;
R3 = LatLen+R2;
R4 = AngleLen+R3;
% R5 = StatursLen+R4;
% R6 = ReservedLen+R5;

HexData = dec2hex(data);
len = length(data);
HexRow = [];
for i=1:len
    HexRow = strcat(HexRow,HexData(i,:));   % 一个行向量
end
 
Index = strfind(HexRow,'55AA0319');   % 数据头
for k = 1:length(Index)
    if(len*2<Index(k)+FrameLength*2-1)
        continue;
    end
    c = HexRow(Index(k):Index(k)+FrameLength*2-1);   
    HexColumn = [];
    for i = 1:FrameLength
        HexColumn = vertcat(HexColumn,c(2*i-1:2*i));     % 
    end
    DecColumn = hex2dec(HexColumn);
    DecLen = length(DecColumn);
    [~,CRC16] = CRC16_MODBUS(DecColumn(1:DecLen-2));
    if(~strcmp(CRC16,HexColumn(DecLen-1:DecLen,:)))
        continue;
    end

    Lon = [Lon;LatLon2Double(HexColumn(R1:R2-1,:))];
    Lat = [Lat;LatLon2Double(HexColumn(R2:R3-1,:))];
    Angle = [Angle;AngleTransform(HexColumn(R3:R4-1,:),2)];
    Status = [Status;hex2dec(HexColumn(R4,:))];
    [Lon,Lat] = myRotate(Lon,Lat,Lon,Lat+DeltaLatA,-Angle(1));  % 把定位天线的坐标换算为横臂中心坐标（O点）
    [Lon,Lat] = myRotate(Lon,Lat,Lon,Lat+DeltaLatB,270-Angle(1));  % 换算为机器摇臂固定点中心坐标（A点）
end
