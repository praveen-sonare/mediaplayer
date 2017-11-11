TEMPLATE = app
QMAKE_LFLAGS += "-Wl,--hash-style=gnu -Wl,--as-needed"

load(configure)
qtCompileTest(libhomescreen)

config_libhomescreen {
    CONFIG += link_pkgconfig
    PKGCONFIG += homescreen
    DEFINES += HAVE_LIBHOMESCREEN
}

packagesExist(dbus-1) {
    DEFINES += HAVE_DBUS
    QT += dbus
}

DESTDIR = $${OUT_PWD}/../package/root/bin
