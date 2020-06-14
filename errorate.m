function [rx_c_de,Ber,Rx_data2,De_Bit] = errorate(Tx_cd,P_f_station,pilot_seq,data_station,spread_data,code,P_data)
SNR=0:0.5:25;
N_fft=128;
N_cp=16;
N_sc=100;
M=4;
tblen=84;
%% ����ת��
Tx_data=reshape(Tx_cd,[],1);%���ڴ�����Ҫ

%% �ŵ���ͨ���ྭ�����ŵ������źž���AWGN�ŵ���
Ber=zeros(1,length(SNR));
fs = 2000;                % Sample rate (Hz)
pathDelays = [0 0.0001];  % Path delays (s)
pathPower = [0 -6];       % Path power (dB)
fD = 5;                   % Maximum Doppler shift (Hz)
rchan = comm.RayleighChannel('SampleRate',fs, ...
'PathDelays',pathDelays,'AveragePathGains',pathPower, ...
'MaximumDopplerShift',fD,'Visualization','Impulse and frequency responses');
for jj=1:length(SNR)
    rx_channel=awgn(Tx_data,SNR(jj),'measured');%�л������ŵ�
     rx_channel=rchan(rx_channel);

%% ����ת��
    Rx_data1=reshape(rx_channel,N_fft+N_cp,[]);

%% ȥ�����������ѭ��ǰ׺
    Rx_data2=Rx_data1(N_cp+1:end,:);

%% FFT
    fft_data=fft(Rx_data2);

%% �ŵ��������ֵ�����⣩
    data3=fft_data(1:N_fft,:);
    Rx_pilot=data3(P_f_station(1:end),:); %���յ��ĵ�Ƶ
    h=Rx_pilot./pilot_seq;
    H=interp1( P_f_station(1:end)',h,data_station(1:end)','linear','extrap');%�ֶ����Բ�ֵ����ֵ�㴦����ֵ�����������ڽ������������Ժ���Ԥ�⡣�Գ�����֪�㼯�Ĳ�ֵ����ָ����ֵ�������㺯��ֵ

%% �ŵ�У��
    data_aftereq=data3(data_station(1:end),:)./H;
%% ����ת��
    data_aftereq=reshape(data_aftereq,[],1);
    data_aftereq=data_aftereq(1:length(spread_data));
    data_aftereq=reshape(data_aftereq,N_sc,length(data_aftereq)/N_sc);

%% ����
    demspread_data = despread(data_aftereq,code);       % ���ݽ���

%% QPSK���
    demodulation_data=pskdemod(demspread_data,M,pi/M);
    De_data1 = reshape(demodulation_data,[],1);
    De_data2 = de2bi(De_data1);
    De_Bit = reshape(De_data2',1,[]);

%% ���⽻֯��
%% �ŵ����루ά�ر����룩
    trellis = poly2trellis(7,[133 171]);
    rx_c_de = vitdec(De_Bit,trellis,tblen,'trunc','hard');   %Ӳ�о�

%% ����������
    [err, Ber(jj)] = biterr(rx_c_de(1:length(P_data)),P_data);%������������
end
