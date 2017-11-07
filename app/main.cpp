/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2016, 2017 Toyota Motor Corporation
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

#include <QtCore/QCommandLineParser>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtCore/QUrlQuery>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/qqml.h>
#include <QtQuickControls2/QQuickStyle>

#include <QQuickWindow>
#include "qlibwindowmanager.h"
#include "qlibsoundmanager.h"

static QLibWindowmanager* qwm;
static QLibSoundmanager* smw;
static std::string myname = std::string("MediaPlayer");

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("AGL");

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();

    QCommandLineParser parser;
    parser.addPositionalArgument("port", app.translate("main", "port for binding"));
    parser.addPositionalArgument("secret", app.translate("main", "secret for binding"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);
    QStringList positionalArguments = parser.positionalArguments();

    if (positionalArguments.length() == 2) {
        int port = positionalArguments.takeFirst().toInt();
        QString secret = positionalArguments.takeFirst();
        QUrl bindingAddress;
        bindingAddress.setScheme(QStringLiteral("ws"));
        bindingAddress.setHost(QStringLiteral("localhost"));
        bindingAddress.setPort(port);
        bindingAddress.setPath(QStringLiteral("/api"));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("token"), secret);
        bindingAddress.setQuery(query);
        context->setContextProperty(QStringLiteral("bindingAddress"), bindingAddress);
        qwm = new QLibWindowmanager();
        smw = new QLibSoundmanager();

        // WindowManager
        if(qwm->init(port,secret) != 0){
            exit(EXIT_FAILURE);
        }
        if (qwm->requestSurface(myname.c_str()) != 0) {
            exit(EXIT_FAILURE);
        }
        qwm->set_event_handler(QLibWindowmanager::Event_SyncDraw, [qwm](json_object *object) {
            fprintf(stderr, "Surface got syncDraw!\n");
            qwm->endDraw(myname.c_str());
            });
        qwm->set_event_handler(QLibWindowmanager::Event_FlushDraw, [&engine, smw](json_object *object) {
            fprintf(stderr, "Surface got flushDraw!\n");
            QObject *root = engine.rootObjects().first();
            int sourceID = root->property("sourceID").toInt();
            smw->connect(sourceID, "default");
        // SoundManager, event handler is set inside smw
        smw->init(port, secret);

        engine.rootContext()->setContextProperty("smw",smw);

    }

    engine.load(QUrl(QStringLiteral("qrc:/MediaPlayer.qml")));
        QObject *root = engine.rootObjects().first();
        QQuickWindow *window = qobject_cast<QQuickWindow *>(root);
        QObject::connect(window, SIGNAL(frameSwapped()),
            qwm, SLOT(slotActivateSurface()));  // This should be disconnected, but when...
        QObject::connect(smw, SIGNAL(reply(QVariant)),
            root, SLOT(slotReply(QVariant)));
        QObject::connect(smw, SIGNAL(event(QVariant, QVariant)),
            root, SLOT(slotEvent(QVariant, QVariant)));

    return app.exec();
}
