TEMPLATE = app
QMAKE_LFLAGS += "-Wl,--hash-style=gnu -Wl,--as-needed"

DESTDIR = $${OUT_PWD}/../package/root/bin
