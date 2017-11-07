TARGET = mediaplayer
QT = quickcontrols2 qml

HEADERS = qlibwindowmanager.h qlibsoundmanager.h
SOURCES = main.cpp qlibwindowmanager.cpp qlibsoundmanager.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libwindowmanager libsoundmanager libhomescreen

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

include(app.pri)
