/*
 * Copyright (c) 2017 TOYOTA MOTOR CORPORATION
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
#ifndef QLIBSOUNDMANAGER_H
#define QLIBSOUNDMANAGER_H

 #include <QObject>
 #include <QVariant>
 #include <QtCore/QJsonObject>
 #include <libsoundmanager.hpp>
 #include <QString>
 #include <string>


class QLibSoundmanager : public QObject
{
    Q_OBJECT
public: // method
    explicit QLibSoundmanager(QObject *parent = nullptr);
    ~QLibSoundmanager();
    int init(int port, const QString& token);

    using sm_event_handler = std::function<void(int sourceid, int handle)>;

    void subscribe(const QString event_name);
    void unsubscribe(const QString event_name);

    void emit_event(const QString &event, const QJsonObject &msg);
    void emit_reply(const QJsonObject &msg);

public:

    Q_INVOKABLE int call(const QString &verb, const QJsonObject &arg);
    Q_INVOKABLE int connect(int sourceID, const QString& sinkName);
    Q_INVOKABLE int disconnect(int connectionID);
    Q_INVOKABLE int ackSetSourceState(int handle, int errorcode);
    Q_INVOKABLE int registerSource(const QString& name);

signals:
    void reply(const QVariant &msg);
    void event(const QVariant &event, const QVariant &msg);

private:
    LibSoundmanager* libsm;
};


#endif /*QLIBSOUNDMANAGER_H*/
