TEMPLATE = app

load(configure)
qtCompileTest(libhomescreen)

config_libhomescreen {
    CONFIG += link_pkgconfig
    PKGCONFIG += homescreen
    DEFINES += HAVE_LIBHOMESCREEN
}

packagesExist(sqlite3 lightmediascanner) {
    DEFINES += HAVE_LIGHTMEDIASCANNER
}

packagesExist(dbus-1) {
    DEFINES += HAVE_DBUS
    QT += dbus
}

DESTDIR = $${OUT_PWD}/../package/root/bin
