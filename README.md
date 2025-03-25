# RadarClassification

This page describes the course EE 4675: Object Classification with Radar project. The aim of this project is to classify six activities of 
human subjects using an FMCW radar. 

Code files: 

basic_ml.ipynb: load feature matrices, feature standardization, feature selection, cross-validation, training and test with SVM, KNN, Random Forest model

CNN.ipynb: load images, hyperparameter tuning, training and test with CNN model, including ConvNet and ConvSE

Data files: 

feature matrices used for machine learning models:

Extracted_spec_feature.mat: extracted 68 image features from the mask (the last column is the label)

Extracted_masked_phase.mat: extracted 68 image features from masked phase (the last column is the label)

Extracted_masked_unwrap.mat: extracted 68 features from masked unwrapped phase (the last column is the label)

Radar_feature_spec.mat: extracted 21 radar features from spectrogram

Radar_feature_maskedspec.mat: extracted 21 radar features from masked spectrogram

images used for CNN models:

spectrogram.zip: spectrogram images, used for CNN models

masked_spectrogram.zip: masked spectrogram images, used for CNN models

Models: 

saved machine learning models using python joblib library:

model/best_model_RF.pkl: random forest model

model/best_model_knn.pkl: K-th nearest neighbour model

model/best_model_tree.pkl: SVM using feature selected from decision tree

model/best_model_sfs.pkl: SVM using feature selected from sequential feature selection

# sample python code for loading the saved model
clf = joblib.load("best_model_sfs.pkl")
clf.predict(X)

saved CNN models using pytorch:

model/Spec_cnn.pth: the ConvNet model with spectrogram input

model/spec_ConvSE.pth: the ConvSE model with spectrogram input

model/Maskedspec_cnn.pth: the ConvNet model with masked spectrogram input

model/Maskedspec_ConvSE.pth: the ConvSE model with masked spectrogram input

# sample python code for loading the saved model
loaded_model = convnet(num_classes=6)
or loaded_model = ConvSE(num_classes=6)
loaded_model.load_state_dict(torch.load(save_path))
loaded_model.eval()

Data preprocessing codes:

preprocessing/getSpec.m: function to process the .dat files to obtain range-time, doppler-time magnitude/phase/unwrapped phase plots

preprocessing/process_spectrogram.mlx: sample code to run the getSpec.m function

preprocessing/getMask.mlx: obtain the mask according to the spectrogram obtained, than stored the masked spectrogram, phase and unwrapped phase plots in .mat file. The masked spectrogram is in RGB format, while the other two are in grayscale. 

preprocessing/figure_feature_extraction.m: Extract the features from the mask. 

preprocessing/processMask.py: Extract the features from masked phase and masked unwrapped plots. 

preprocessing/Radarfeature.m: Function to extract radar feature from raw data
preprocessing/extractRadarFeature.m: Function to extract radar feature from masked spectrogram
preprocessing/getRadarfeature_maskespec.mlx: Sample code to run extractRadarFeature function, store the data in .mat file.
