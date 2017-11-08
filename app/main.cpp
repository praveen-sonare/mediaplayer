/*
 * Copyright (C) 2016 The Qt Company Ltd.
 * Copyright (C) 2017 Toyota Motor Corporation
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
#include <QQuickWindow>
#include <QtQuickControls2/QQuickStyle>
#include "qlibsoundmanager.h"
#include <libhomescreen.hpp>

#include "playlistwithmetadata.h"
#include "qlibwindowmanager.h"

static LibHomeScreen* hs;
static QLibWindowmanager* qwm;
static QLibSoundmanager* smw;
static std::string myname = std::string("MediaPlayer");

using namespace std;
static void onRep(struct json_object* reply_contents);
static void onEv(const std::string& event, struct json_object* event_contents);

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);
    qwm = new QLibWindowmanager();
    hs = new LibHomeScreen();
    QQuickStyle::setStyle("AGL");

    qmlRegisterType<PlaylistWithMetadata>("MediaPlayer", 1, 0, "PlaylistWithMetadata");

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

        /* This is window manager test */
        std::string token = secret.toStdString();

        if(qwm->init(port,token.c_str()) != 0){
            exit(EXIT_FAILURE);
        }

        if (qwm->requestSurface(myname.c_str()) != 0) {
            exit(EXIT_FAILURE);
        }

        // prepare to use homescreen
        hs->init(port, token.c_str());

        hs->set_event_handler(LibHomeScreen::Event_TapShortcut, [qwm](json_object *object){
            const char *appname = json_object_get_string(
                json_object_object_get(object, "application_name"));
            if(myname == appname)
            {
                qDebug("[HS]mediaplayer: activateSurface\n");
                qwm->activateSurface(myname.c_str());
            }
        });

        // prepare to use soundmangaer
        smw = new QLibSoundmanager();
        smw->init(port, secret);
        engine.rootContext()->setContextProperty("smw",smw);

        qwm->set_event_handler(QLibWindowmanager::Event_SyncDraw, [smw, qwm](json_object *object) {
            fprintf(stderr, "[WM]Surface got syncDraw!\n");
            qwm->endDraw(myname.c_str());
            // Something to to if needed
        });
        qwm->set_event_handler(QLibWindowmanager::Event_FlushDraw, [smw, &engine](json_object *object) {
            fprintf(stderr, "[WM]Surface got FlushDraw!\n");
            // Something to to if needed
            QObject *root = engine.rootObjects().first();
            int sourceID = root->property("sourceID").toInt();
            smw->connect(sourceID, "default");
        });
    }
    engine.load(QUrl(QStringLiteral("qrc:/MediaPlayer.qml")));

    QObject *root = engine.rootObjects().first();
    QQuickWindow *window = qobject_cast<QQuickWindow *>(root);
    QObject::connect(window, SIGNAL(frameSwapped()), qwm, SLOT(slotActivateSurface()));
    QObject::connect(smw, SIGNAL(reply(QVariant)),
        root, SLOT(slotReply(QVariant)));
    QObject::connect(smw, SIGNAL(event(QVariant, QVariant)),
        root, SLOT(slotEvent(QVariant, QVariant)));
        
    return app.exec();
}