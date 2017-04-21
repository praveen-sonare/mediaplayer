/*
 * Copyright (C) 2017 Konsulko Group
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "dbus.h"


DbusService::DbusService(QObject *parent) : QObject(parent)
{
}

/*
 * Light Media Scanner
 */

bool DbusService::enableLMS()
{
    QDBusConnection session_bus = QDBusConnection::sessionBus();
    QDBusConnection system_bus = QDBusConnection::systemBus();
    bool ret;

    if (!session_bus.isConnected())
        return false;

    if (!system_bus.isConnected())
        return false;

    ret = session_bus.connect(QString("org.lightmediascanner"), QString("/org/lightmediascanner/Scanner1"), "org.freedesktop.DBus.Properties", "PropertiesChanged", this, SLOT(lmsUpdate(QString,QVariantMap,QStringList)));
    if (!ret)
        return false;

    /* Only subscribe to DeviceRemoved events, since we need lms scan to complete on insert */
    return system_bus.connect(QString("org.freedesktop.UDisks"), QString("/org/freedesktop/UDisks"), "org.freedesktop.UDisks", "DeviceRemoved", this, SLOT(mediaRemoved(QDBusObjectPath)));
}

void DbusService::mediaRemoved(const QDBusObjectPath&)
{
        emit stopPlayback();
}

#if defined(HAVE_LIGHTMEDIASCANNER)
void DbusService::lmsUpdate(const QString&, const QVariantMap& map, const QStringList&)
{
    QVariantList mediaFiles;
    QString music;

    if (!map.contains("IsScanning") && !map.contains("WriteLocked"))
        return;

    if (map["IsScanning"].toBool() || map["WriteLocked"].toBool())
        return;

    mediaFiles = LightMediaScanner::processLightMediaScanner();

    if (!mediaFiles.isEmpty())
        emit processPlaylistUpdate(mediaFiles);
    else
        emit processPlaylistHide();
}
#else
void DbusService::lmsUpdate(const QString&, const QVariantMap&, const QStringList&)
{
}
#endif

/*
 * Bluetooth
 */

void DbusService::setBluezPath(const QString& path)
{
    this->bluezPath = path;
}

QString DbusService::getBluezPath() const
{
    return this->bluezPath;
}

bool DbusService::enableBluetooth()
{
    QDBusConnection system_bus = QDBusConnection::systemBus();
    QString interface = "org.freedesktop.DBus.ObjectManager";
    bool ret;

    if (!system_bus.isConnected())
        return false;

    if (deviceConnected(system_bus))
        initialBluetoothData(system_bus);

    ret = system_bus.connect(QString("org.bluez"), QString("/"), interface, "InterfacesAdded", this, SLOT(newBluetoothDevice(QDBusObjectPath,QVariantMap)));

    if (!ret)
        return false;

    ret = system_bus.connect(QString("org.bluez"), QString("/"), interface, "InterfacesRemoved", this, SLOT(removeBluetoothDevice(QDBusObjectPath,QStringList)));

    /*
     * Unregister InterfacesAdded on error condition
     */
    if (!ret)
        system_bus.disconnect(QString("org.bluez"), QString("/"), interface, "InterfacesAdded", this, SLOT(newBluetoothDevice(QString,QVariantMap)));

    return ret;
}

bool DbusService::checkIfPlayer(const QString& path) const
{
    QRegExp regex("^.*/player\\d$");
    if (regex.exactMatch(path))
        return true;

    return false;
}

bool DbusService::deviceConnected(const QDBusConnection& system_bus)
{
    QDBusInterface interface("org.bluez", "/", "org.freedesktop.DBus.ObjectManager", system_bus);
    QDBusMessage result = interface.call("GetManagedObjects");
    const QDBusArgument argument = result.arguments().at(0).value<QDBusArgument>();
    bool ret = false;

    if (argument.currentType() != QDBusArgument::MapType)
        return false;

    argument.beginMap();

    while (!argument.atEnd()) {
        QString key;

        argument.beginMapEntry();
        argument >> key;
        argument.endMapEntry();

        ret = checkIfPlayer(key);

        if (ret) {
            newBluetoothDevice(QDBusObjectPath(key), QVariantMap());
            break;
        }
    }

    argument.endMap();

    return ret;
}

void DbusService::initialBluetoothData(const QDBusConnection& system_bus)
{
    QDBusInterface interface("org.bluez", getBluezPath(), "org.freedesktop.DBus.Properties", system_bus);

    QDBusMessage result = interface.call("GetAll", "org.bluez.MediaPlayer1");
    const QDBusArgument argument = result.arguments().at(0).value<QDBusArgument>();
    QString status, artist, title;
    int position = 0, duration = 0;

    if (argument.currentType() != QDBusArgument::MapType)
        return;

    argument.beginMap();

    while (!argument.atEnd()) {
        QString key;
        QVariant value;

        argument.beginMapEntry();
        argument >> key >> value;

        if (key == "Position") {
            position = value.toInt();
        } else if (key == "Status") {
            status = value.toString();
        } else if (key == "Track") {
            const QDBusArgument argument1 = qvariant_cast<QDBusArgument>(value);
            QString key1;
            QVariant value1;

            argument1.beginMap();

            while (!argument1.atEnd()) {
                argument1.beginMapEntry();
                argument1 >> key1 >> value1;
                if (key1 == "Artist")
                    artist = value1.toString();
                else if (key1 == "Title")
                    title = value1.toString();
                else if (key1 == "Duration")
                    duration = value1.toInt();
                argument1.endMapEntry();
            }
            argument1.endMap();
        }
        argument.endMapEntry();
    }
    argument.endMap();

    emit processPlaylistHide();
    emit displayBluetoothMetadata(artist, title, duration);
    emit updatePlayerStatus(status);
    emit updatePosition(position);
}

void DbusService::newBluetoothDevice(const QDBusObjectPath& item, const QVariantMap&)
{
    QString path = item.path();
    if (!checkIfPlayer(path))
        return;

    if (!getBluezPath().isEmpty()) {
        qWarning() << "Another Bluetooth Player already connected";
        return;
    }

    emit processPlaylistHide();

    QDBusConnection system_bus = QDBusConnection::systemBus();
    system_bus.connect(QString("org.bluez"), path, "org.freedesktop.DBus.Properties", "PropertiesChanged", this, SLOT(processBluetoothEvent(QString,QVariantMap,QStringList)));

    setBluezPath(path);
}

void DbusService::removeBluetoothDevice(const QDBusObjectPath& item, const QStringList&)
{
    QString path = item.path();
    if (!checkIfPlayer(path))
        return;

    if (getBluezPath().isEmpty()) {
        qWarning() << "No Bluetooth Player connected";
        return;
    }

    QDBusConnection system_bus = QDBusConnection::systemBus();
    system_bus.disconnect(QString("org.bluez"), path, "org.freedesktop.DBus.Properties", "PropertiesChanged", this, SLOT(processBluetoothEvent(QString,QVariantMap,QStringList)));

    setBluezPath(QString());
    emit processPlaylistShow();
}

void DbusService::processBluetoothEvent(const QString&, const QVariantMap& map, const QStringList&)
{
    if (map.contains("Track")) {
        QVariantMap track;
        map["Track"].value<QDBusArgument>() >> track;
        emit displayBluetoothMetadata(track["Artist"].toString(), track["Title"].toString(), track["Duration"].toInt());
    }

    if (map.contains("Position"))
        emit updatePosition(map["Position"].toInt());

    if (map.contains("Status"))
        emit updatePlayerStatus(map["Status"].toString());
}

void DbusService::processQMLEvent(const QString& state)
{
    QDBusInterface interface("org.bluez", getBluezPath(), "org.bluez.MediaPlayer1", QDBusConnection::systemBus());
    interface.call(state);
}

long DbusService::getCurrentPosition()
{
    QDBusInterface interface("org.bluez", getBluezPath(), "org.bluez.MediaPlayer1", QDBusConnection::systemBus());
    return interface.property("Position").toInt();
}
