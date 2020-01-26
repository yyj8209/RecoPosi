function results = targetRecognize4Table(app,FullName,FileName,SignalWidth,MaxTargetNum)

%% 参数载入与设置。
load(app.FileCoef);
inputps = Coef.inputps;
w1 = Coef.w1;
b1 = Coef.b1;
w2 = Coef.w2;
b2 = Coef.b2;

load(app.FileSettings);
INPUTNUM    = InputLayerNum;
OUTPUTNUM   = OutputLayerNum;     % 分类：4类为大干扰、小干扰、目标、背景；3类为大干扰、小干扰、目标。根据经验，背景可以提前识别。   2019.05.03
FileNumSel = size(FileName,1);

%% 提取特征值
% ----------------- 对每个数据文件完成以下几项工作：----------------- %
% 1、读取前三行，即三个有效通道的数据；
% 2、提取每个通道的第一个极值增量和方差，共8个特征值：'CH1','CH2','CH3','Kr','V1/V3','VAR1','VAR2','VAR3'；
% 3、
% 4、
% ----------------------------------------------------------------- %
%     Fpass = 1;   Fstop = 5;  fs = 100; rpL = 1; rsL = 60;
%     [bL,~] = LPFDesign(Fpass,Fstop,fs,rpL,rsL);
load('.\Settings\LPFParameter.mat');     % 载入滤波器系数。
% Header = {'文件名','CH1','CH2','CH3','Kr','V1/V3','VAR1','VAR2','VAR3'};   % 8个特征值
Data = zeros(FileNumSel,INPUTNUM);


for i = 1:FileNumSel
% 1、读取前三行，即三个有效通道的数据；
% ----------------------------------------------------------------- %
    fid = fopen(FullName);
    fseek(fid,0,'eof');
    filelength = ftell(fid);
    fseek(fid,0,'bof');
    [A,count]=fread(fid,(filelength)/4,'float32');
    fclose(fid);
    A = reshape(A,6,count/6);
    x = ([A(1,:);A(2,:);A(3,:)])*5000/32768;

% 2、提取'通道1峰值V1','通道2峰值V2','通道3峰值V3','Kr=斜率1/斜率2','V1/V3','均值EV1','EV2','方差DV1','DV2'。
% ----------------------------------------------------------------- %
    y = zeros(size(x));
    Sign = 1;
    for k1 = 3:-1:1     % x 由3个通道的数据向量组成。
        x1 = x(k1,:);
        % 增加一个去除脉冲的函数。基本思路是，跳跃大于500时，确定该点为脉冲，去除之。2019.03.19
        [loc] = find(abs(diff(x1))>200);   % 
        if(~isempty(loc))     % 这里去脉冲点。若有多个，可用find函数。
            x1(loc+1) = x1(loc+3);
        end
        x2 = x1 - mean(x1);      % 去直流。

        y1 = [zeros(1,length(bL)),x2,zeros(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
        y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
        y3 = y2(length(bL)+1:length(y2)-length(bL));
        y(k1,:) = y3 - mean(y3) + mean(x1);    % 到这一步已经恢复了信号。

        [Value] = find(y(k1,:) >  mean(x1));
        if(sum(Value)>0.5*length(y(k1,:)))
            Sign = -1;    % 谷的形状，需要反转来求峰值。
        end
    end
    % 以通道1的最大值点，确定为判决用的点。
%     [~,lsor] = findpeaks(Sign*y(1,:),'SortStr','descend');
%     pv = y(1:3,lsor(1));     % 取峰值最大的点。
    [PeakValue,~,~] = peakValue(Sign.*y,SignalWidth,MaxTargetNum);     % leftStart:rightEnd的均值代表向量均值（信号峰除外）。
    Data(i,1:3) = PeakValue';
    Data(i,4) = PeakValue(1)/PeakValue(3);
end

%% 四、BP神经网络分类?
% ?用训练好的BP神经网络分类特征信号，根据分类结果分析BP神经网络分类能力。

% 特征信号分类
input_test = Data';
inputn_test = mapminmax('apply',input_test,inputps);
fore = zeros(OUTPUTNUM,FileNumSel);
for i=1:FileNumSel  %TOTALSAMPLE
    %隐含层输出
    I    = (inputn_test(:,i)'*w1')+ b1';
    Iout =1./(1+exp(-I));

    fore(:,i)=w2'*Iout'+b2;
end
[~,OutputType]=max(fore);

%% 把判别结果输出到主界面函数，再由主界面的函数来实现显示。
% 在Table中显示
res = {'大干扰','小干扰','雷','无目标'};
results = res(OutputType);


