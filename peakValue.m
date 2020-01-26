function [pv,MeanValue,leftStart,rightEnd] = peakValue(y,SignalWidth,MaxTargetNum)
% function val = peakValue(varargin)
% 求峰值的函数要优化。

    [~,n] = size(y);
    [~,lsor] = findpeaks(y(1,:),'NPeaks',MaxTargetNum,'SortStr','descend');
    leftStart = lsor(1) - SignalWidth - 40;
    leftEnd   = lsor(1) - SignalWidth - 20;
    rightStart= lsor(1) + SignalWidth + 20;
    rightEnd  = lsor(1) + SignalWidth + 40;   % 有用信号为leftStart 到 rightEnd 这一段。
    if(leftStart<0)
        MeanValue = mean(y(:,rightStart:rightEnd),2);
    elseif(rightEnd>n)
        MeanValue = mean(y(:,leftStart:leftEnd),2);
    else
        MeanValue = 0.5*mean(y(:,leftStart:leftEnd),2)+ 0.5*mean(y(:,rightStart:rightEnd),2);
    end
    pv = abs(y(:,lsor(1)) - MeanValue);     % 取峰值最大的点。

end 