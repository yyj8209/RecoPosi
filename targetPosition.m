function  [x, y, Xm, Yn] = targetPosition(X,Y,Z,CH1Threshold,MaxTargetNum,SignalWidth)
%　X，Y 构成坐标平面，Z 是三个通道的数据。
% 输出为峰值所在的(x，y)坐标值，（Xm, Yn）为坐标序号
% 实际上定位只需要 CH1 的数据就可以了。

z = Z(:,:,1);
[~,MeanValue,~,~] = peakValue(z,SignalWidth,MaxTargetNum);   % 每一次扫描时，基准信号强度。
z = z - MeanValue;     % 因每次强度不一致，需要爱次去除。2019.11.19

BW = imregionalmax(abs(z));

[Xm,Yn] = find(BW);    %　找出不为零的点。
mLen = length(Xm);
tmp = zeros(1,mLen);  % 临时存储未达到门限的峰值。
k = 0;
for i = 1:mLen
    v = abs(z(Xm(i),Yn(i)));
    if(v < CH1Threshold)    % 未达到门限的值，标记。
        k = k + 1;
        tmp(k) = i;
    end
end
forDelete = tmp(1:k);
Xm(forDelete) = [];   % 把未达到门限的点删除。此时仍为坐标序号，非坐标值。
Yn(forDelete) = [];
%% 增加一段用于判断是否为边界引起的虚报的目标点。过于密集为虚报的点。
xx = diff(Xm);
yy = diff(Yn);
Distance = sqrt(xx.^2+yy.^2);
forDelete = find(Distance<2);
if(~isempty(forDelete))
    Xm(forDelete+1) = [];   % 把未达到门限的点删除。此时仍为坐标序号，非坐标值。
    Yn(forDelete+1) = [];
end
%%

len = length(Xm);
if(len == 0)
    msgbox('区域内无目标！');
    x = [];
    y = [];
    return;
else
    x = zeros(1,len);  %存储峰值坐标。
    y = x;
    for i = 1:len
        x(i) = X(Xm(i),Yn(i));
        y(i) = Y(Xm(i),Yn(i));
    end
end

