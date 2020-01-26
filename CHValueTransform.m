function [output] = CHValueTransform(input,inv)
% [output] = AngleTransform(input,inv)
% 在串口传输中，通道信号的幅度占4个字节。此函数用于转换成/出串口的格式。
% inv = 1时，表示幅度转字节，inv=2时表示4字节转幅度

switch inv
    case 1
        output = ['00';'00';'00';'00'];
        tmpHex = sprintf('%tX',single(input));
        if(length(tmpHex)<8)
            tmpHex = strcat('0',tmpHex);
        end
%         for i = 1:4
%             output(i,:) = tmpHex(2*i-1:2*i);
%         end
        output(1,:) = tmpHex(7:8);
        output(2,:) = tmpHex(5:6);
        output(3,:) = tmpHex(3:4);
        output(4,:) = tmpHex(1:2);
    case 2
        tmpHex = ['00','00','00','00'];
%         for i = 1:4
%             tmpHex(2*i-1:2*i) = input(i,:);
%         end
        tmpHex(7:8) = input(1,:);
        tmpHex(5:6) = input(2,:);
        tmpHex(3:4) = input(3,:);
        tmpHex(1:2) = input(4,:);
        output = double(typecast(uint32(hex2dec(tmpHex)),'single'));
    otherwise
end
