import os
import pandas as pd
import numpy as np
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Activation
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.models import load_model
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
import scipy.io as sio
from my_pkg_MLP.Neural_network_function import r2_keras


def draw_loss_function(record, saving=False, name=''):
    font = {'family': 'Times New Roman',
            'weight': 'normal',
            'size': 16}

    epochs = range(len(record.history['loss']))
    plt.figure()
    plt.plot(epochs, record.history['loss'], label='Training loss')
    plt.plot(epochs, record.history['val_loss'], 'r', label='Validation loss')
    plt.title('Training and validation loss', font)
    plt.legend()
    plt.show(block=False)
    if saving:
        plt.savefig(name + 'loss.png')


def load_training_data():
    mat_filename = r'D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\match results\All_training_data_rhorc\total_data.mat'
    matData = sio.loadmat(mat_filename)
    x_input = pd.DataFrame(matData['rhorc'])
    x_input[x_input > 1] = np.nan
    y_true = pd.DataFrame(matData['H'], columns=['true'])
    data = pd.concat([x_input, y_true], axis=1)
    data[data < 0] = np.nan
    data.dropna(axis=0, how='any', inplace=True)
    X = data.iloc[:, :-1]
    y = data.iloc[:, -1]
    return X, y


def training():
    '''
    return: model, record, flag
    '''
    X, y = load_training_data()
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.05, random_state=0)
    # X_train = X
    # y_train = y

    # model structure
    model = Sequential([
        Dense(128, input_dim=np.shape(X)[1]),
        Activation('relu'),
        Dense(32),
        Activation('relu'),
        Dense(16),
        Activation('relu'),
        Dense(1)
    ])

    # descent operator
    adam = Adam(learning_rate=1e-3)
    # compile
    model.compile(optimizer=adam,
                  loss='mean_squared_error',  # loss function
                  metrics=[r2_keras])  # metrics for test in training
    # training
    record = model.fit(X_train, y_train, epochs=2000, batch_size=128, validation_data=(X_test, y_test),
                       verbose=2)

    os.makedirs('./Models', exist_ok=True)
    model.save('./Models/0709_global_depth.h5')
    model.summary()
    draw_loss_function(record, saving=True)
    y_pre = model.predict(X_test)

    y_test = y_test.reset_index().iloc[:, 1]
    output = pd.concat([y_test,
                        pd.DataFrame(y_pre, columns=['y_pre'])],
                       axis=1)
    output.to_excel('testset_of_training_total_0709.xlsx', index=False)


def testing():
    model_name = './Models/all_data_013043.h5'
    model = load_model(model_name, custom_objects={'r2_keras': r2_keras})
    mat_filename = r'D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\match results\Dry\gt1r_20190924163909_process.mat'
    matData = sio.loadmat(mat_filename)
    x_input = matData['rhorc']
    y = model.predict(x_input)
    y = pd.DataFrame(y, columns=['predict'])
    y_true = pd.DataFrame(matData['H'], columns=['true'])
    output = pd.concat([y_true, y], axis=1)
    output.to_excel(
        r'D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\match results\Dry\test.xlsx',
        index=False)


if __name__ == '__main__':
    training()
    # testing()
