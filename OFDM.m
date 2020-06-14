clc;
clear;

N_sc=100;      %ϵͳ���ز�����������ֱ���ز�����number of subcarrierA
N_fft=128;            % FFT ����
N_cp=16;             % ѭ��ǰ׺���ȡ�Cyclic prefix
N_symbo=N_fft+N_cp;        % 1������OFDM���ų���
N_c=53;             % ����ֱ���ز����ܵ����ز�����number of carriers
M=4;               %4PSK����
SNR=0:0.5:25;         %���������?
N_frm=20;            % ÿ��������µķ���֡����frame
Nd=30;               % ÿ֡������OFDM������?
P_f_inter=6;      %��Ƶ���
data_station=[];    %��Ƶλ��
L=7;                %�����Լ������
tblen=12*L;           %Viterbi�������������
stage = 3;          % m���еĽ���?
ptap1 = [1 3];      % m���еļĴ������ӷ�ʽ
regi1 = [1 1 1];    % m���еļĴ�����ʼֵ


%% �����������ݲ���
P_data=randi([0 1],1,N_sc*Nd*N_frm);


%% �ŵ����루����롢��֯����
%����룺ǰ������������
%��֯��ʹͻ����������޶ȵķ�ɢ��
trellis = poly2trellis(7,[133 171]);       %(2,1,7)�������
code_data=convenc(P_data,trellis);


%% qpsk����
data_temp1= reshape(code_data,log2(M),[])';             %��ÿ��2���ؽ��з��飬M=4
data_temp2= bi2de(data_temp1);                             %������ת��Ϊʮ����
modu_data=pskmod(data_temp2,M,pi/M);              % 4PSK����

%% ��Ƶ
%����������������������������������������������������������������������������������������������������������������%
%��Ƶͨ���ź���ռ�е�Ƶ�����Զ����������Ϣ�������С����
%������ũ������Ƶͨ�ž����ÿ�����似������ȡ������ϵĺô����������Ƶͨ�ŵĻ���˼����������ݡ�
%��Ƶ���ǽ�һϵ����������������������ź��ڻ�
%��Ƶ������Ƶ�ʱ����ԭ����m������Ƭ���� = 2����������* m����Ƶϵ����
%����������������������������������������������������������������������������������������������������������������%

code = mseq(stage,ptap1,regi1,N_sc);     % ��Ƶ�������
code = code * 2 - 1;        %��1��0�任Ϊ1��-1
modu_data=reshape(modu_data,N_sc,length(modu_data)/N_sc);
spread_data = spread(modu_data,code);        % ��Ƶ
spread_data=reshape(spread_data,[],1);

%% ���뵼Ƶ��
P_f=3+3*1i;                       %Pilot frequency
P_f_station=[1:P_f_inter:N_fft];%��Ƶλ�ã���Ƶλ�ú���Ҫ��why?��
pilot_num=length(P_f_station);%��Ƶ����

for img=1:N_fft                        %����λ��
    if mod(img,P_f_inter)~=1          %mod(a,b)���������a����b������
        data_station=[data_station,img];
    end
end
data_row=length(data_station);
data_col=ceil(length(spread_data)/data_row);

pilot_seq=ones(pilot_num,data_col)*P_f;%����Ƶ�������
data=zeros(N_fft,data_col);%Ԥ����������
data(P_f_station(1:end),:)=pilot_seq;%��pilot_seq����ȡ

if data_row*data_col>length(spread_data)
    data2=[spread_data;zeros(data_row*data_col-length(spread_data),1)];%�����ݾ����룬��0������Ƶ~
end;

%% ����ת��

data_seq=reshape(data2,data_row,data_col);
data(data_station(1:end),:)=data_seq;%����Ƶ�����ݺϲ�

%% IFFT
ifft_data=ifft(data); 

%% ���뱣�������ѭ��ǰ׺
Tx_cd=[ifft_data(N_fft-N_cp+1:end,:);ifft_data];%��ifft��ĩβN_cp�������䵽��ǰ��
Tx_zero=[zeros(size(ifft_data(N_fft-N_cp+1:end,:)));ifft_data];%�ӱ������

[rx_c_de,Ber,x1,y1] = errorate(Tx_cd,P_f_station,pilot_seq,data_station,spread_data,code,P_data);
[rx_z_de,Ber1,x2,y2] = errorate(Tx_zero,P_f_station,pilot_seq,data_station,spread_data,code,P_data);




figure(1);
 semilogy(SNR,Ber,'r-o');
 hold on
 semilogy(SNR,Ber1,'b-o');
 legend('ѭ��ǰ׺','0ǰ׺');
 xlabel('SNR');
 ylabel('BER');
 title('�����ŵ��������������');
 hold off;

 figure(2)
 subplot(2,1,1);
 x=0:1:50;
 stem(x,P_data(1:51));
 ylabel('amplitude');
 title('�������ݣ���ǰ50������Ϊ��)');
 legend('����ǰ');

 subplot(2,1,2);
 x=0:1:50;
 stem(x,rx_c_de(1:51));
 ylabel('amplitude');
 title('���������ݣ���ǰ50������Ϊ��)');
 legend('�����');