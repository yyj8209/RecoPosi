function [output] = AngleTransform(input,inv)
% [output] = AngleTransform(input,inv)
% 在串口传输中，角度占4个字节。此函数用于转换成/出串口的格式。
% inv = 1时，表示角度转字节，inv=2时表示4字节转角度

switch inv
    case 1
        output = ['00';'00';'00';'00'];
        tmpDec = fix(input*1e2);  % 小数点移动9位后取整
        tmpHex = dec2hex(tmpDec);
        while(length(tmpHex)<8)
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
        output = hex2dec(tmpHex)*1e-2;
    otherwise
end
