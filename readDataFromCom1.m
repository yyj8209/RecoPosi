function [Value1,Value2,Value3,Lat,Lon] = readDataFromCom1(data,FrameLength)
% [Value1,Value2,Value3,Lat,Lon] = readDataFromCom1(data,FrameLength,Type)
% 输入：data 为从COM2读取的数据，FrameLength 为每一个协议帧的长度，Type为角度输入或坐标输入，LatLon为经纬度输入，Angle为角度半径输入。
% 输出：Value1,Value2,Value3，分别为三个通道的数值。Lat 解析的纬度,Lon 为解析的经度。

Value1 = [];
Value2 = [];
Value3 = [];
Lon = [];
Lat = [];
% Angle = [];
% Radius = [];
HeadLen = 4;
Value1Len = 4;
Value2Len = 4;
Value3Len = 4;
LonLen = 5;
LatLen = 5;
% ReservedLen = 4;
R1 = HeadLen+1;
R2 = Value1Len+R1;
R3 = Value2Len+R2;
R4 = Value3Len+R3;
R5 = LonLen+R4;
R6 = LatLen+R5;

HexData = dec2hex(data);
len = length(data);
HexRow = [];
for i=1:len
    HexRow = strcat(HexRow,HexData(i,:));   % 一个行向量
end
Index = strfind(HexRow,'55AA0120');   % 数据头

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
    Value1 = [Value1;CHValueTransform(HexColumn(R1:R2-1,:),2)];
    Value2 = [Value2;CHValueTransform(HexColumn(R2:R3-1,:),2)];
    Value3 = [Value3;CHValueTransform(HexColumn(R3:R4-1,:),2)];
    Lon = [Lon;LatLon2Double(HexColumn(R4:R5-1,:))];
    Lat = [Lat;LatLon2Double(HexColumn(R5:R6-1,:))];
end

% else
%     Angle = [Angle;LatLonTransform(HexColumn(R4:R5-1,:),2)];
%     Radius = [Radius;LatLonTransform(HexColumn(R5:R6-1,:),2)];
%     Lon = Radius.*sin((pi/2-Angle)*pi/180);     % 假定其格式与数值存储方式一致。实际还要正负变换和加基准量
%     Lat = Radius.*cos((pi/2-Angle)*pi/180);
% end