TEMPLATE = app
TARGET = mediaplayer
QT = qml quickcontrols2
CONFIG += c++11 link_pkgconfig

PKGCONFIG += qtappfw-mediaplayer qtappfw-vehicle-signals

SOURCES = main.cpp

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

target.path = /usr/bin
target.files += $${OUT_PWD}/$${TARGET}
target.CONFIG = no_check_exist executable

INSTALLS += target
