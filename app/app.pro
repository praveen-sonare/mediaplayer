TARGET = mediaplayer
QT = quickcontrols2 multimedia

HEADERS += \
    playlistwithmetadata.h

SOURCES = main.cpp \
    playlistwithmetadata.cpp

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

include(app.pri)
