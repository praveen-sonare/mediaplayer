TEMPLATE = app

load(configure)
qtCompileTest(libhomescreen)

config_libhomescreen {
    CONFIG += link_pkgconfig
    PKGCONFIG += homescreen
    DEFINES += HAVE_LIBHOMESCREEN
}

packagesExist(sqlite3 lightmediascanner) {
    HEADERS += lightmediascanner.h
    SOURCES += lightmediascanner.cpp
    DEFINES += HAVE_LIGHTMEDIASCANNER
    QT += sql
}

DESTDIR = $${OUT_PWD}/../package/root/bin
