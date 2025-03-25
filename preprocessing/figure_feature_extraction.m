% This file contains the codes used for extracting features from the mask
% Output feature format: 
% perimeter, area, centroid, orientation, eccentricity, majorlength, minorlength, LBF(1x59), figmoment, label
% 
%%
% 
stored_data = [];
for A=1:6
    for P=1:72
        for R = 1:3
            if P <10
                filename = append(num2str(A),'P0',num2str(P),'A0',num2str(A),'R',num2str(R),'_maskedspec.mat');
                filename2 = append(num2str(A),'P0',num2str(P),'A0',num2str(A),'R0',num2str(R),'_maskedspec.mat');
            else
                filename = append(num2str(A),'P',num2str(P),'A0',num2str(A),'R',num2str(R),'_maskedspec.mat');
                filename2 = append(num2str(A),'P',num2str(P),'A0',num2str(A),'R0',num2str(R),'_maskedspec.mat');
            end
            % getSpec(filename);
            vec1 = getMaskedSpecFeature(filename);
            vec2 = getMaskedSpecFeature(filename2);
            stored_data = [stored_data;vec1;vec2];
        end
    end
end
%%
M = stored_data;
M(any(isnan(M), 2), :) = [];
save("Extrated_spec_feature","M")


%%
function vector = getMaskedSpecFeature(filename)
    if exist(filename) ~=2
        vector = NaN(1,69);
        return 
    end
    load(filename)
    data = rgb2gray(masked_spec);
data(data~=0) = 255;
data = data./255;
% imshow(data)
perimeter = regionprops(data,'Perimeter');perimeter = perimeter.Perimeter;
aa = regionprops(data);
area = aa.Area;
centroid = aa.Centroid;
ori = regionprops(data,'Orientation');
orientation = ori.Orientation;
ecc = regionprops(data,'Eccentricity');
eccentricity = ecc.Eccentricity;
axislength = regionprops(data,'MajorAxisLength','MinorAxisLength');
majorlength = axislength.MajorAxisLength; minorlength = axislength.MinorAxisLength;
LBF = extractLBPFeatures(data);
figmoment = moment(data,2,"all");
label = str2double(filename(1));

vector = [perimeter area centroid orientation eccentricity majorlength minorlength LBF figmoment label];
end