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

#ifndef DBUS_H
#define DBUS_H

#include <QtCore/QDebug>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariant>
#include <QtCore/QVariantList>
#include <QtDBus/QDBusPendingCall>
#include <QtDBus/QDBusPendingReply>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusReply>
#include <QtDBus/QDBusConnection>

#include "lightmediascanner.h"

class DbusService : public QObject {
    Q_OBJECT
public:
    explicit DbusService(QObject *parent = 0);

    bool enableLMS();
    bool enableBluetooth();
    Q_INVOKABLE void processQMLEvent(const QString&);
    Q_INVOKABLE long getCurrentPosition();

private:
    void setBluezPath(const QString& path);
    QString getBluezPath() const;
    bool checkIfPlayer(const QString& path) const;
    bool deviceConnected(const QDBusConnection& system_bus);
    void initialBluetoothData(const QDBusConnection& system_bus);
    QString bluezPath;

signals:
    void processPlaylistUpdate(const QVariantList& mediaFiles);
    void processPlaylistHide();
    void processPlaylistShow();

    void displayBluetoothMetadata(const QString& avrcp_artist, const QString& avrcp_title, const int avrcp_duration);
    void stopPlayback();
    void updatePosition(const int current_position);
    void updatePlayerStatus(const QString status);

private slots:
    void lmsUpdate(const QString&, const QVariantMap&, const QStringList&);
    void mediaRemoved(const QDBusObjectPath&);
    void newBluetoothDevice(const QDBusObjectPath&, const QVariantMap&);
    void removeBluetoothDevice(const QDBusObjectPath&, const QStringList&);
    void processBluetoothEvent(const QString&, const QVariantMap&, const QStringList&);
};

#endif
