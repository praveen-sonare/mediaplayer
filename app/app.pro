TARGET = mediaplayer
QT = quickcontrols2

HEADERS = qlibwindowmanager.h
SOURCES = main.cpp qlibwindowmanager.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libwindowmanager

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

include(app.pri)
