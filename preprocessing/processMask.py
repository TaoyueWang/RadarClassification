## This code extract the features from the grayscale image masked phase and masked unwrap phase
## Output format: [perimeter,area,cx,cy,orientation,eccentricity,major_axis_length,minor_axis_length,hist,moment]
# %%

import cv2 as cv
import numpy as np
import scipy.io
import scipy
import skimage as ski
from skimage import feature
from pathlib import Path


# %%
def getMaskedPhase(filename): 
    path = Path(filename)
    if not path.exists():
        return np.full((1, 69), np.nan)
    
    data = scipy.io.loadmat(filename)
    d = data['masked_phase']
    c = d[:,0:-1]
    contours, _ = cv.findContours(c, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
    cnt = max(contours, key=cv.contourArea)

# Calculate the moments
    M = cv.moments(cnt)

# The centroid of the ROI
    cx = int(M['m10'] / M['m00'])
    cy = int(M['m01'] / M['m00'])
    centroid = (cx, cy)
    perimeter = cv.arcLength(cnt, True)
    area = cv.contourArea(cnt)

    (x, y), (major_axis_length, minor_axis_length), orientation = cv.fitEllipse(cnt)
    a = max(major_axis_length,minor_axis_length)
    b = min(major_axis_length,minor_axis_length)
    major_axis_length = a 
    minor_axis_length = b
# The eccentricity of the ROI
    eccentricity = np.sqrt(1 - (minor_axis_length / major_axis_length)**2)
    # moment = cv.moments(d)
    radius = 3  # Radius of circularly symmetric neighbor set
    n_points = 8 * radius
    n_points = 56  # Number of circularly symmetric neighbor set points
    method = 'uniform'  # LBP method
    lbp = feature.local_binary_pattern(c, n_points, radius, method)
    hist, _ = np.histogram(lbp.ravel(), bins=n_points + 3, range=(0, n_points + 3))

# Normalize the histogram
    hist = hist.astype("float")
    hist /= hist.sum()

    moment = np.var(d/255)
    v = np.array([perimeter,area,cx,cy,orientation,eccentricity,major_axis_length,minor_axis_length])
    vector = np.concatenate((v,hist,np.array([moment,int(filename[0])])),axis=0)
    vector = np.reshape(vector,(1,69))
    return vector

# %%
# Process masked phase plot

stored_value = np.empty((0, 69))

for A in range(1,6+1):
    for P in range(1,72+1):
        for R in range(1,3+1):
            if P < 10:
                filename = str(A) + 'P0' + str(P) + 'A0' + str(A) + 'R' + str(R) + '_maskedphase.mat'
                filename2 = str(A) + 'P0' + str(P) + 'A0' + str(A) + 'R0' + str(R) + '_maskedphase.mat'
            else:
                filename = str(A) + 'P' + str(P) + 'A0' + str(A) + 'R' + str(R) + '_maskedphase.mat'
                filename2 = str(A) + 'P' + str(P) + 'A0' + str(A) + 'R0' + str(R) + '_maskedphase.mat'
            vec1 = getMaskedPhase(filename)
            vec2 = getMaskedPhase(filename2)
            # stored_value = np.hstack((stored_value,vec1,vec2))
            stored_value = np.append(stored_value,vec1,axis=0)
            stored_value = np.append(stored_value,vec2,axis=0)


#%%
# Remove NaN
stored_phase = stored_value[~np.isnan(stored_value).any(axis=1)]

# Store value
scipy.io.savemat('Extracted_masked_phase.mat',{'stored_phase':stored_phase})


# %%
def getMaskedUnwrap(filename): 
    path = Path(filename)
    if not path.exists():
        return np.full((1, 69), np.nan)
    
    data = scipy.io.loadmat(filename)
    d = data['masked_unwrap']
    c = d[:,0:-1]
    contours, _ = cv.findContours(c, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
    cnt = max(contours, key=cv.contourArea)

# Calculate the moments
    M = cv.moments(cnt)

# The centroid of the ROI
    cx = int(M['m10'] / M['m00'])
    cy = int(M['m01'] / M['m00'])
    centroid = (cx, cy)
    perimeter = cv.arcLength(cnt, True)
    area = cv.contourArea(cnt)

    (x, y), (major_axis_length, minor_axis_length), orientation = cv.fitEllipse(cnt)
    a = max(major_axis_length,minor_axis_length)
    b = min(major_axis_length,minor_axis_length)
    major_axis_length = a 
    minor_axis_length = b
# The eccentricity of the ROI
    eccentricity = np.sqrt(1 - (minor_axis_length / major_axis_length)**2)
    # moment = cv.moments(d)
    radius = 3  # Radius of circularly symmetric neighbor set
    n_points = 8 * radius
    n_points = 56  # Number of circularly symmetric neighbor set points
    method = 'uniform'  # LBP method
    lbp = feature.local_binary_pattern(c, n_points, radius, method)
    hist, _ = np.histogram(lbp.ravel(), bins=n_points + 3, range=(0, n_points + 3))

# Normalize the histogram
    hist = hist.astype("float")
    hist /= hist.sum()

    moment = np.var(d/255)
    v = np.array([perimeter,area,cx,cy,orientation,eccentricity,major_axis_length,minor_axis_length])
    vector = np.concatenate((v,hist,np.array([moment,int(filename[0])])),axis=0)
    vector = np.reshape(vector,(1,69))
    return vector

#%%
# Process unwrapped phase plot and save data
stored_value = np.empty((0, 69))

for A in range(1,6+1):
    for P in range(1,72+1):
        for R in range(1,3+1):
            if P < 10:
                filename = str(A) + 'P0' + str(P) + 'A0' + str(A) + 'R' + str(R) + '_maskedunwrap.mat'
                filename2 = str(A) + 'P0' + str(P) + 'A0' + str(A) + 'R0' + str(R) + '_maskedunwrap.mat'
            else:
                filename = str(A) + 'P' + str(P) + 'A0' + str(A) + 'R' + str(R) + '_maskedunwrap.mat'
                filename2 = str(A) + 'P' + str(P) + 'A0' + str(A) + 'R0' + str(R) + '_maskedunwrap.mat'
            vec1 = getMaskedUnwrap(filename)
            vec2 = getMaskedUnwrap(filename2)
            # stored_value = np.hstack((stored_value,vec1,vec2))
            stored_value = np.append(stored_value,vec1,axis=0)
            stored_value = np.append(stored_value,vec2,axis=0)

stored_unwrap = stored_value[~np.isnan(stored_value).any(axis=1)]
scipy.io.savemat('Extracted_masked_unwrap.mat',{'stored_unwrap':stored_unwrap})