TARGET = mediaplayer
QT = quickcontrols2 multimedia qml

HEADERS += \
    playlistwithmetadata.h qlibsoundmanager.h  \
    qlibwindowmanager.h

SOURCES = main.cpp \
    playlistwithmetadata.cpp qlibsoundmanager.cpp \
    qlibwindowmanager.cpp
CONFIG += link_pkgconfig
PKGCONFIG += libsoundmanager libwindowmanager libhomescreen

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc
include(app.pri)
