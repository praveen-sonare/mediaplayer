TARGET = mediaplayer
QT = quickcontrols2

HEADERS = qlibwindowmanager.h qlibsoundmanager.h
SOURCES = main.cpp qlibwindowmanager.cpp qlibsoundmanager.cpp

CONFIG += link_pkgconfig
PKGCONFIG += libwindowmanager libsoundmanager

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

include(app.pri)
