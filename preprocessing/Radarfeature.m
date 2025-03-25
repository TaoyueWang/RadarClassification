function [radar_feature_matrix_spec] = RadarFeature(filename)
if ~exist(filename,'file')
    radar_feature_matrix_spec = [];
    return
end
load(filename);
masked_spec = rgb2gray(masked_spec);
Data_spec_MTI2 = double(masked_spec)./255;
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
Doppler = linspace(-500,500,size(Data_spec_MTI2,1));
centroid = (Doppler*Data_spec_MTI2)./sum(Data_spec_MTI2);
radar_feature_matrix_spec(3) = nanmean(centroid);
radar_feature_matrix_spec(4) = nanvar(centroid);
% bandwidth: mean and variance
doppler_matrix = repmat(Doppler,size(Data_spec_MTI2,2),1)';
cent_matrix = repmat(centroid,size(Data_spec_MTI2,1),1);
diff_par = (doppler_matrix - cent_matrix).^2;
numerator = sum(diff_par.*Data_spec_MTI2);
bandwidth = numerator./sum(Data_spec_MTI2);
bandwidth = bandwidth.^0.5;
radar_feature_matrix_spec(5) = nanmean(bandwidth);
radar_feature_matrix_spec(6) = nanvar(bandwidth);
% energy curve: mean, variance, and Trapezoidal numerical integration
% Calculate the energy curve by summing the power across frequency bins
energy_curve = sum(Data_spec_MTI2, 1);
radar_feature_matrix_spec(7) = mean(energy_curve);
radar_feature_matrix_spec(8) = var(energy_curve);
radar_feature_matrix_spec(9) = trapz(energy_curve);
% svd: mean and variance of the first three vectors of components
Data_spec_MTI2(Data_spec_MTI2 == 0) = epsilon; % Replace zeros with epsilon
[U,S,V] = svd(Data_spec_MTI2);
radar_feature_matrix_spec(10:12) = mean(U(:,1:3));
radar_feature_matrix_spec(13:15) = var(U(:,1:3));
radar_feature_matrix_spec(16:18) = mean(V(:,1:3));
radar_feature_matrix_spec(19:21) = var(V(:,1:3));

end


