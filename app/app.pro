TARGET = mediaplayer
QT = quickcontrols2 websockets

SOURCES = main.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libhomescreen qtappfw-mediaplayer

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

include(app.pri)
