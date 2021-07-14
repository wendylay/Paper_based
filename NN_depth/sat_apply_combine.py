import os

os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
import netCDF4 as nc
import numpy as np
import pandas as pd
from tensorflow.keras.models import load_model
import sys
import matplotlib.pyplot as plt
import scipy.io as sio

from my_pkg_MLP.Neural_network_function import r2_keras

# read nc file
file_dir = 'E:/Bahamas_large_depth/done/012044'
filename = os.path.join(file_dir, 'L8_OLI_2020_12_31_15_32_34_012044_L2W.nc')
filename_albedo = os.path.join(file_dir, '012044_20201231.L2_LAC_OC')
f = nc.Dataset(filename)  # Rrs
f_cloud = nc.Dataset(filename_albedo)
#
# # read data
lat = np.array(f['lat'])
lon = np.array(f['lon'])
#
rhot_443 = np.array(f['rhorc_443'])
rhot_482 = np.array(f['rhorc_483'])
rhot_561 = np.array(f['rhorc_561'])
rhot_655 = np.array(f['rhorc_655'])
rhot_865 = np.array(f['rhorc_865'])
rhot_1609 = np.array(f['rhorc_1609'])
rhot_2201 = np.array(f['rhorc_2201'])

# cloud_albedo = np.array(f_cloud['cloud_albedo'])
cloud_albedo = np.array(f_cloud['geophysical_data']['cloud_albedo'])
(n_row, n_col) = np.shape(rhot_443)

# print('shape of image :', np.shape(Rrs443))


# read mat file
# matData = sio.loadmat(r'E:\Rrs_LAT_LON.mat')
# lon = matData['LON']
# lat = matData['LAT']
# Rrs443 = np.array(matData['Rrs443'])
# Rrs482 = np.array(matData['Rrs482'])
# Rrs561 = np.array(matData['Rrs561'])
# Rrs655 = np.array(matData['Rrs655'])
# (n_row, n_col) = np.shape(Rrs443)
# print('shape of image :', np.shape(Rrs443))

# input data
input1 = rhot_443.flatten()[:, np.newaxis]
input2 = rhot_482.flatten()[:, np.newaxis]
input3 = rhot_561.flatten()[:, np.newaxis]
input4 = rhot_655.flatten()[:, np.newaxis]
input5 = rhot_865.flatten()[:, np.newaxis]
input6 = rhot_1609.flatten()[:, np.newaxis]
input7 = rhot_2201.flatten()[:, np.newaxis]
cloud_albedo = cloud_albedo.flatten()[:, np.newaxis]

X = np.concatenate([input1, input2, input3, input4, input5, input6, input7], axis=1)
# 要把X中小于0的改为np.nan， 需要先
# X = np.concatenate([input1, input2, input3, input4, input5, input6, input7], axis=1).astype('float')
# X[X < 0] = np.nan

x_chs = pd.DataFrame(data=X)
cloud_albedo = pd.DataFrame(cloud_albedo)
x_chs[x_chs < 0] = np.nan  # delete nan
x_chs[x_chs > 1] = np.nan

[n, bins, patches] = plt.hist(cloud_albedo[(cloud_albedo > 0) & (cloud_albedo < 0.04)], 5000, edgecolor='k', alpha=0.35)
plt.show(block=False)
k = bins.copy()[:5000].reshape(-1, 1)
k_cut = k[(k > 0.005) & (k < 0.04)].reshape(-1, 1)
n = n.reshape(-1, 1)
n = n[(k > 0.005) & (k < 0.04)]
threshold = k_cut[np.argmin(n)][0]
x_chs.iloc[cloud_albedo.iloc[:, 0] > threshold, :] = np.nan

Rrs_raw = np.array(x_chs)
x_chs['idx'] = list(range(0, np.size(X[:, 0])))  # flag location of each pixels
x_chs = x_chs.dropna(axis=0, how='any')  # drop nan Rrs

X_chs = x_chs.copy()
X_chs.pop('idx')

depth_model = load_model('./Models/all_data_013043.h5', custom_objects={'r2_keras': r2_keras})
class_model = load_model('./Models/classify_model_global.h5')

X_norm_h = X_chs
y_predict = depth_model.predict(X_norm_h)
y_predict[y_predict < 0] = np.nan
y_predict[np.isinf(y_predict)] = np.nan

#  reshape output
raw = pd.DataFrame(np.hstack([y_predict, x_chs[['idx']]]), columns=['predict', 'idx'])
predict_1 = pd.DataFrame(data=np.arange(0, np.size(X[:, 1])), columns=['idx'])
predict = pd.merge(predict_1, raw, how='outer', on='idx')

depth = np.array(predict['predict']).reshape(n_row, n_col)  # reshape output to image size

# predict class
X_norm_class = X_chs
y_predict = class_model.predict(X_norm_class)
y_predict[y_predict < 0] = np.nan
y_predict[np.isinf(y_predict)] = np.nan

#  reshape output
raw = pd.DataFrame(np.hstack([y_predict, x_chs[['idx']]]), columns=['predict', 'idx'])
predict_1 = pd.DataFrame(data=np.arange(0, np.size(X[:, 1])), columns=['idx'])
predict = pd.merge(predict_1, raw, how='outer', on='idx')

depth_class = np.array(predict['predict']).reshape(n_row, n_col)  # reshape output to image size

# save results, and plot result map with Matlab m_map
# sio.savemat('Depth_class_Mask.mat',
#             mdict={'lon': lon, 'lat': lat, 'h': output})


f_w = nc.Dataset('E:/Bahamas_large_depth/012044.nc', 'w', format='NETCDF4')
# define dimensions
f_w.createDimension('x', size=lon.shape[1])
f_w.createDimension('y', size=lon.shape[0])

# create variables
lat_w = f_w.createVariable('lat', np.float32, ('y', 'x'))
lon_w = f_w.createVariable('lon', np.float32, ('y', 'x'))
H_w = f_w.createVariable('H', np.float32, ('y', 'x'))
# class_w = f_w.createVariable('class', np.float32, ('y', 'x'))

# lon/lat/output are np.array, 1d, 1d, 2d
lon_w[:] = lon
lat_w[:] = lat
# class_w[:] = depth_class
depth[depth_class == 1] = np.nan
H_w[:] = depth


f_w.close()
