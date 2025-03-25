function getSpec(filename)
% Function for plotting range time plot, spectrogram of the data

fileID = fopen(filename, 'r');
if fileID == -1
    return
end
dataArray = textscan(fileID, '%f');
fclose(fileID);
radarData = dataArray{1};
clearvars fileID dataArray ans;
fc = radarData(1); % Center frequency
Tsweep = radarData(2); % Sweep time in ms
Tsweep=Tsweep/1000; %then in sec
NTS = radarData(3); % Number of time samples per sweep
Bw = radarData(4); % FMCW Bandwidth. For FSK, it is frequency step;
% For CW, it is 0.
Data = radarData(5:end); % raw data in I+j*Q format
fs=NTS/Tsweep; % sampling frequency ADC
record_length=length(Data)/NTS*Tsweep; % length of recording in s
nc=record_length/Tsweep; % number of chirps

%% Reshape data into chirps and plot Range-Time
Data_time=reshape(Data, [NTS nc]);
win = ones(NTS,size(Data_time,2));
%Part taken from Ancortek code for FFT and IIR filtering
tmp = fftshift(fft(Data_time.*win),1);
Data_range(1:NTS/2,:) = tmp(NTS/2+1:NTS,:);
ns = oddnumber(size(Data_range,2))-1;
Data_range_MTI = zeros(size(Data_range,1),ns);
[b,a] = butter(4, 0.0075, 'high');
[h, f1] = freqz(b, a, ns);
for k=1:size(Data_range,1)
  Data_range_MTI(k,1:ns) = filter(b,a,Data_range(k,1:ns));
end
freq =(0:ns-1)*fs/(2*ns); 
range_axis=(freq*3e8*Tsweep)/(2*Bw);
Data_range_MTI=Data_range_MTI(2:size(Data_range_MTI,1),:);
Data_range=Data_range(2:size(Data_range,1),:);
name = append(filename,'_rangetime.jpg');
figure
colormap(jet)
% imagesc([1:10000],range_axis,20*log10(abs(Data_range_MTI)))
imagesc(20*log10(abs(Data_range_MTI)))
% xlabel('No. of Sweeps')
% ylabel('Range bins')
% title('Range Profiles after MTI filter')
clim = get(gca,'CLim'); axis xy; ylim([1 60])
set(gca, 'CLim', clim(2)+[-60,0]);
I0 = getframe;
imwrite(I0.cdata, fullfile(name))
% drawnow

%% Spectrogram processing for 2nd FFT to get Doppler
% This selects the range bins where we want to calculate the spectrogram
bin_indl = 5;
bin_indu = 60;

MD.PRF=1/Tsweep;
MD.TimeWindowLength = 200;
MD.OverlapFactor = 0.95;
MD.OverlapLength = round(MD.TimeWindowLength*MD.OverlapFactor);
MD.Pad_Factor = 4;
MD.FFTPoints = MD.Pad_Factor*MD.TimeWindowLength;
MD.DopplerBin=MD.PRF/(MD.FFTPoints);
MD.DopplerAxis=-MD.PRF/2:MD.DopplerBin:MD.PRF/2-MD.DopplerBin;
MD.WholeDuration=size(Data_range_MTI,2)/MD.PRF;
MD.NumSegments=floor((size(Data_range_MTI,2)-MD.TimeWindowLength)/floor(MD.TimeWindowLength*(1-MD.OverlapFactor)));

Data_spec_MTI2=0;
Phase_spec = 0;
Phase_unwrap = 0;
Data_spec2=0;
for RBin=bin_indl:1:bin_indu
    Data_MTI_temp = fftshift(spectrogram(Data_range_MTI(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
    Data_spec_MTI2=Data_spec_MTI2+abs(Data_MTI_temp);    
    Phase_spec = Phase_spec + angle(Data_MTI_temp);
    Phase_unwrap = Phase_unwrap + unwrap(angle(Data_MTI_temp));
    Data_temp = fftshift(spectrogram(Data_range(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
    Data_spec2=Data_spec2+abs(Data_temp);
end
MD.TimeAxis=linspace(0,MD.WholeDuration,size(Data_spec_MTI2,2));

Data_spec_MTI2=flipud(Data_spec_MTI2);

hh = figure;
imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,20*log10(abs(Data_spec_MTI2)));
% imagesc(20*log10(abs(Data_spec_MTI2))); 
colormap('jet'); %axis xy
ylim([-6 6]); 
axis off;
%colorbar
% colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
% xlabel('Time[s]', 'FontSize',16);
% ylabel('Velocity [m/s]','FontSize',16)
% set(gca, 'FontSize',16)
% title(filename)
name = append(filename,'_spec.jpg');
% name = '1P38A01R01_spec.jpg';
% saveas(gcf,name,'jpg')
% exportgraphics(gcf, name, 'Resolution', 300);
I0 = getframe;
imwrite(I0.cdata, fullfile(name))

%% 

figure
imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,flipud(Phase_spec- min(Phase_spec))); colormap('jet'); axis off

% ylim([-6 6]); 
% colorbar
% colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-150,0]);
I0 = getframe;
name = append(filename,'_phase.jpg');
imwrite(I0.cdata, fullfile(name))
% xlabel('Time[s]', 'FontSize',16);
% ylabel('Velocity [m/s]','FontSize',16)
% set(gca, 'FontSize',16)
%% 
figure
imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,flipud(Phase_unwrap- min(Phase_unwrap))); colormap('jet'); axis off
I0 = getframe;
name = append(filename,'_unwrap.jpg');
imwrite(I0.cdata, fullfile(name))
% clim = get(gca,'CLim');
end