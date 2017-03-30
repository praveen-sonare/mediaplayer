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

    if (!session_bus.isConnected())
        return false;

    return session_bus.connect(QString("org.lightmediascanner"), QString("/org/lightmediascanner/Scanner1"), "org.freedesktop.DBus.Properties", "PropertiesChanged", this, SLOT(lmsUpdate(QString,QVariantMap,QStringList)));
}

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
