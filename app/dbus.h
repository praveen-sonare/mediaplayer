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
#include <QtDBus/QDBusConnection>

#include "lightmediascanner.h"

class DbusService : public QObject {
    Q_OBJECT
public:
    explicit DbusService(QObject *parent = 0);
    bool enableLMS();

signals:
    void processPlaylistUpdate(const QVariantList& mediaFiles);
    void processPlaylistHide();

private slots:
    void lmsUpdate(const QString&, const QVariantMap&, const QStringList&);
};

#endif
