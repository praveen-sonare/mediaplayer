TEMPLATE = app
QMAKE_LFLAGS += "-Wl,--hash-style=gnu -Wl,--as-needed"

load(configure)
qtCompileTest(libhomescreen)

packagesExist(sqlite3 lightmediascanner) {
    DEFINES += HAVE_LIGHTMEDIASCANNER
}

packagesExist(dbus-1) {
    DEFINES += HAVE_DBUS
    QT += dbus
}

DESTDIR = $${OUT_PWD}/../package/root/bin
