function result = isPeaksUp(data)
% 判断二维数据是峰值向上，还是谷值向下？

result = true;
[m,n] = size(data);
if((m == 1)||(n == 1))    % 一维数组的情况。
    [Value] = find(data >  mean(data));
    if(length(Value)>0.5*length(data))
        result = false;    % 谷的形状，需要反转来求峰值。
    end
else
    [Value] = find(data >  mean(mean(data)));
    if(length(Value)>0.5*m*n)
        result = false;    % 谷的形状，需要反转来求峰值。
    end
end
