TARGET = mediaplayer
QT = quickcontrols2 websockets gui-private

SOURCES = main.cpp

CONFIG += link_pkgconfig wayland-scanner
PKGCONFIG += qtappfw wayland-client

RESOURCES += \
    mediaplayer.qrc \
    images/images.qrc

WAYLANDCLIENTSOURCES += \
    protocol/agl-shell-desktop.xml

include(app.pri)
