        fid = fopen('..\OriginDat\实扫数据\方向和角度20190606-181216.dat');
        fseek(fid,0,'eof');
        filelength = ftell(fid)-2;
        fseek(fid,2,'bof');
        [data,~]=fread(fid,(filelength),'uint8');
        fseek(fid,2,'bof');
        [A,~]=fread(fid,(filelength)/2,'short');
        fclose(fid);
        
        len = length(data);
        Angle = zeros(1,len/2);
        for i = 1:len/2
            if(data(2*i)>127)
                x = data(2*i)-128-1;
                x = bitxor(x,127);
                Angle(i) = -(x*256 - data(2*i-1));
            else
                Angle(i) = data(2*i)*256 + data(2*i-1);
            end
        end
        Angle = Angle*180/32768;
        figure;plot(1:(filelength)/2,A*180/32768,'*',1:(filelength)/2,Angle,'-');
        legend('计算结果','short转换');