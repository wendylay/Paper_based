import os

os.environ["CUDA_VISIBLE_DEVICES"] = "-1"

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from sklearn.model_selection import train_test_split
from tensorflow.keras.optimizers import Adam
from tensorflow.keras import models, layers, metrics
import tensorflow as tf
import scipy.io as sio
from tensorflow.keras.models import load_model


def show_loss(history):
    """ drow loss curve """
    history_dict = history.history
    loss_values = history_dict['loss']
    val_loss_values = history_dict['val_loss']
    epochs = range(1, len(loss_values) + 1)
    plt.plot(epochs, loss_values, 'bo', label='Training loss')
    plt.plot(epochs, val_loss_values, 'b', label='Validation loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.legend()
    plt.savefig('loss_class.png')
    plt.show()


def validate_data(model, X, y=''):
    y_pre_prob = np.array(model.predict(X))
    y_pre_label = y_pre_prob.copy()
    y_pre_label[y_pre_label > 0.5] = 1
    y_pre_label[y_pre_label <= 0.5] = 0
    y_insitu = np.array(y).reshape(y.shape[0], 1)
    y_pre_label = y_pre_label.reshape(y_pre_label.shape[0], 1)
    accuracy = sum(y_pre_label == y_insitu) / y_insitu.shape[0]

    y_pre = np.concatenate(
        [y_pre_prob.reshape(len(y_pre_prob), 1),
         y_pre_label.reshape(len(y_pre_label), 1)],
        axis=1)

    y.reset_index(drop=True, inplace=True)

    y_to_save = pd.concat(
        [y, pd.DataFrame(y_pre, columns=['probability', 'label'])],
        axis=1, ignore_index=True
    )

    return y_to_save, accuracy


def train_data(data):
    X = data.iloc[:, :-1]
    y = data.iloc[:, -1]
    # y = to_categorical(y)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.01)  # 随机率random_state=0
    # X_train = X
    # X_test = X
    # y_train = y
    # y_test = y

    model = models.Sequential()
    model.add(layers.Dense(64, activation='relu', input_shape=(X_train.shape[1],)))
    model.add(layers.Dense(16, activation='relu'))
    model.add(layers.Dense(1, activation='sigmoid'))

    adam = Adam(lr=1e-3)
    # compile
    model.compile(optimizer=adam,
                  loss=tf.losses.BinaryCrossentropy(),
                  metrics=[metrics.binary_accuracy]
                  )

    history = model.fit(
        x=X_train, y=y_train, batch_size=128, epochs=1000,
        validation_data=(X_test, y_test), verbose=2
    )

    model.save('Models/classify_model_global.h5')

    model.summary()

    show_loss(history)

    val_train, acc_train = validate_data(model, X_train, y_train)
    val_train.to_excel(
        r'training_results.xlsx',
        index=False
    )
    print('accuracy of training dataset: ', acc_train)

    val_test, acc_test = validate_data(model, X_test, y_test)
    val_test.to_excel(r'testset_of_train_results.xlsx', index=False)
    print('accuracy of testing dataset: ', acc_test)


def load_data():
    mat_file = sio.loadmat(
        r'D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\Optical_shallow_pixel_select\optical_shallow_deep\global_shallow_deep_rhorc.mat')
    data = pd.DataFrame(mat_file['class'])
    data.dropna(axis=0, how='any', inplace=True)
    return data


def testing():
    class_model = load_model('./Models/classify_model_global.h5')
    file_dir = r'D:\OneDrive - stu.xmu.edu.cn\4 Code\1 M File\Shallow_bathymetry_global\H_match\match results\Turks\20201210'
    mat_filename = file_dir + '/gt1l_20201216061746.mat'
    matData = sio.loadmat(mat_filename)
    x_input = matData['rhorc']
    H_class = class_model.predict(x_input)
    H_class[H_class > 0.5] = 1
    H_class[H_class <= 0.5] = 0
    H_class = pd.DataFrame(H_class, columns=['class'])
    H_class.to_excel(
        file_dir + '/class_process_1746_1l.xlsx',
        index=False)


if __name__ == '__main__':
    # load data
    # data = load_data()

    # training
    # train_data(data)

    # test
    testing()
