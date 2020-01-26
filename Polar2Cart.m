function [X,Y,Z] = Polar2Cart(Array,R,THETA,DeltaY)
% 应用在myContour中
% [X,Y,Z] = Polar2Cart(Array,R,THETA,DeltaY)
% 输入：
% Array 是m次扫描数据，
% R是扫描半径，
% THETA是一个n维的向量，与n个点对应，
% DeltaY是一个m维的向量，与m-1次移动对应。

    [m,n] = size(Array);
    [m1,~] = size(THETA);
    X = zeros(m,n);
    Y = X;
    Z = Array;
    for i = 1:m
        if(m1 == 1)
            [X(i,:),y] = pol2cart(THETA,R);
        else
            [X(i,:),y] = pol2cart(THETA(i,:),R);
        end
        Y(i,:) = y + DeltaY(i);
    end
end
