function [radar_feature_matrix_spec] = extractRadarFeature(filename)

fileID = fopen(filename, 'r');
if fileID == -1
    radar_feature_matrix_spec = [];
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
% figure
% colormap(jet)
% % imagesc([1:10000],range_axis,20*log10(abs(Data_range_MTI)))
% imagesc(20*log10(abs(Data_range_MTI)))
% xlabel('No. of Sweeps')
% ylabel('Range bins')
% title('Range Profiles after MTI filter')
% clim = get(gca,'CLim'); axis xy; ylim([1 100])
% set(gca, 'CLim', clim(2)+[-60,0]);
% drawnow

%% Spectrogram processing for 2nd FFT to get Doppler
% This selects the range bins where we want to calculate the spectrogram
% bin_indl = 10
% bin_indu = 30
bin_indl = 3;
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
Data_spec2=0;
for RBin=bin_indl:1:bin_indu
    Data_MTI_temp = fftshift(spectrogram(Data_range_MTI(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
    Data_spec_MTI2=Data_spec_MTI2+abs(Data_MTI_temp);                                
    Data_temp = fftshift(spectrogram(Data_range(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
    Data_spec2=Data_spec2+abs(Data_temp);
end
MD.TimeAxis=linspace(0,MD.WholeDuration,size(Data_spec_MTI2,2));

Data_spec_MTI2=flipud(Data_spec_MTI2);

% figure
% imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,20*log10(abs(Data_spec_MTI2))); colormap('jet'); axis xy
% ylim([-6 6]); 
% colorbar
% colormap; %xlim([1 9])
% clim = get(gca,'CLim');
% set(gca, 'CLim', clim(2)+[-40,0]);
% xlabel('Time[s]', 'FontSize',16);
% ylabel('Velocity [m/s]','FontSize',16)
% set(gca, 'FontSize',16)
% title(filename)

% DirectoryPath ='D:\taoyue\TUD Master\Quarter 4\EE4675 Object classification with radar\project\dataset\data\spectrogram\';
% 
% tempImg = squeeze(mat2gray(20*log10(abs(Data_spec_MTI2))));
% img = imresize(tempImg,  [224,224]);
% imwrite(img, [DirectoryPath,'test.png'] )

%exportgraphics(gca,'D:\taoyue\TUD Master\Quarter 4\EE4675 Object classification with radar\project\dataset\data\spectrogram\image6.png','Resolution',1000);
% I0 = getframe;
% imwrite(I0.cdata, fullfile('image2.png'))

%% extract radar features from spectrogram
radar_feature_matrix_spec = zeros(1,21);
% entropy
Data_spec_MTI2_norm = Data_spec_MTI2 ./ sum(Data_spec_MTI2(:));
epsilon = 1e-12; % Small constant to avoid log(0)
Data_spec_MTI2_norm(Data_spec_MTI2_norm == 0) = epsilon; % Replace zeros with epsilon
radar_feature_matrix_spec(1) = -sum(Data_spec_MTI2_norm(:) .* log2(Data_spec_MTI2_norm(:)));
% skewness across all elements
radar_feature_matrix_spec(2) = skewness(Data_spec_MTI2,0,'all');
% centroid: mean and variance
Doppler = MD.DopplerAxis;
centroid = (Doppler*Data_spec_MTI2)./sum(Data_spec_MTI2);
radar_feature_matrix_spec(3) = mean(centroid);
radar_feature_matrix_spec(4) = var(centroid);
% bandwidth: mean and variance
doppler_matrix = repmat(Doppler,size(Data_spec_MTI2,2),1)';
cent_matrix = repmat(centroid,size(Data_spec_MTI2,1),1);
diff_par = (doppler_matrix - cent_matrix).^2;
numerator = sum(diff_par.*Data_spec_MTI2);
bandwidth = numerator./sum(Data_spec_MTI2);
bandwidth = bandwidth.^0.5;
radar_feature_matrix_spec(5) = mean(bandwidth);
radar_feature_matrix_spec(6) = var(bandwidth);
% energy curve: mean, variance, and Trapezoidal numerical integration
% Calculate the energy curve by summing the power across frequency bins
energy_curve = sum(Data_spec_MTI2, 1);
radar_feature_matrix_spec(7) = mean(energy_curve);
radar_feature_matrix_spec(8) = var(energy_curve);
radar_feature_matrix_spec(9) = trapz(energy_curve);
% svd: mean and variance of the first three vectors of components
[U,S,V] = svd(Data_spec_MTI2);
radar_feature_matrix_spec(10:12) = mean(U(:,1:3));
radar_feature_matrix_spec(13:15) = var(U(:,1:3));
radar_feature_matrix_spec(16:18) = mean(V(:,1:3));
radar_feature_matrix_spec(19:21) = var(V(:,1:3));

end