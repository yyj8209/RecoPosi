function [output] = LatLon2Bytes(input)
% [output] = LatLon2Bytes(input)
% 在串口传输中，经/纬度占5个字节。此函数用于转换成/出串口的格式。
% inv = 1时，表示经/纬度转字节，inv=2时表示5字节转经/纬度，同时承担角度和半径的转换任务。

% output =0;
% 
% switch inv
%     case 1
        output = ['00';'00';'00';'00';'00'];
        tmpDec = fix(input*1e9);  % 小数点移动9位后取整
        tmpHex = dec2hex(tmpDec);
        while(length(tmpHex)<10)
            tmpHex = ['0',tmpHex];
        end
%         for i = 1:5
%             output(i,:) = tmpHex(2*i-1:2*i);
%         end
        output(1,:) = tmpHex(9:10);
        output(2,:) = tmpHex(7:8);
        output(3,:) = tmpHex(5:6);
        output(4,:) = tmpHex(3:4);
        output(5,:) = tmpHex(1:2);
%  output =0;
%     case 2
%         tmpHex = ['00','00','00','00','00'];
% %         for i = 1:5
% %             tmpHex(2*i-1:2*i) = input(i,:);
% %         end
%         tmpHex(9:10) = input(1,:);
%         tmpHex(7:8) = input(2,:);
%         tmpHex(5:6) = input(3,:);
%         tmpHex(3:4) = input(4,:);
%         tmpHex(1:2) = input(5,:);
%         output = hex2dec(tmpHex)*1e-9;
%     otherwise
% end
