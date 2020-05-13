/*
 * Copyright (C) 2016 The Qt Company Ltd.
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

#include <mediaplayer.h>

#include <qpa/qplatformnativeinterface.h>
#include <wayland-client.h>
#include "wayland-agl-shell-desktop-client-protocol.h"

#include <unistd.h>

static struct wl_output *
getWlOutput(QScreen *screen)
{
	QPlatformNativeInterface *native = qApp->platformNativeInterface();
	void *output = native->nativeResourceForScreen("output", screen);
	return static_cast<struct ::wl_output*>(output);
}

static void
global_add(void *data, struct wl_registry *reg, uint32_t name,
	   const char *interface, uint32_t version)
{
	struct agl_shell_desktop **shell =
		static_cast<struct agl_shell_desktop **>(data);

	if (strcmp(interface, agl_shell_desktop_interface.name) == 0) {
		*shell = static_cast<struct agl_shell_desktop *>(
			wl_registry_bind(reg, name, &agl_shell_desktop_interface, version)
		);
	}
}

static void global_remove(void *data, struct wl_registry *reg, uint32_t id)
{
	(void) data;
	(void) reg;
	(void) id;
}

static const struct wl_registry_listener registry_listener = {
	global_add,
	global_remove,
};

static void
application_id_event(void *data, struct agl_shell_desktop *agl_shell_desktop,
		const char *app_id)
{
	(void) data;
	(void) app_id;
	(void) agl_shell_desktop;
}

static void
application_state_event(void *data, struct agl_shell_desktop *agl_shell_desktop,
			const char *app_id, const char *app_data,
			uint32_t app_state, uint32_t app_role)
{
	(void) data;
	(void) app_role;
	(void) app_state;
	(void) app_data;
	(void) app_id;
	(void) agl_shell_desktop;
}

static const struct agl_shell_desktop_listener agl_shell_desk_listener = {
	application_id_event,
	application_state_event,
};

static struct agl_shell_desktop *
register_agl_shell_desktop(void)
{
	struct wl_display *wl;
	struct wl_registry *registry;
	struct agl_shell_desktop *shell = nullptr;

	QPlatformNativeInterface *native = qApp->platformNativeInterface();

	wl = static_cast<struct wl_display *>(native->nativeResourceForIntegration("display"));
	registry = wl_display_get_registry(wl);

	wl_registry_add_listener(registry, &registry_listener, &shell);
	// Roundtrip to get all globals advertised by the compositor
	wl_display_roundtrip(wl);
	wl_registry_destroy(registry);

	return shell;
}

static void
setup_window_vertical(int type, const QString &myname)
{
	struct agl_shell_desktop *shell_desktop = nullptr;
	struct wl_output *output;

	if (type == 0)
		return;

	shell_desktop = register_agl_shell_desktop();
	output = getWlOutput(qApp->screens().first());

	// not necessary
	if (shell_desktop)
		agl_shell_desktop_add_listener(shell_desktop,
					       &agl_shell_desk_listener,
					       NULL);

	if (type == 1) {
		agl_shell_desktop_set_app_property(shell_desktop,
				myname.toStdString().c_str(),
				AGL_SHELL_DESKTOP_APP_ROLE_SPLIT_VERTICAL,
				0, 0, output);
		qDebug() << "setting vertical";
	} else {
		agl_shell_desktop_set_app_property(shell_desktop,
				myname.toStdString().c_str(),
				AGL_SHELL_DESKTOP_APP_ROLE_SPLIT_HORIZONTAL,
				0, 0, output);
		qDebug() << "setting horizontal";
	}
}

int main(int argc, char *argv[])
{
    QString graphic_role = QString("music");
    QString myname = QString("mediaplayer");

    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("AGL");

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();

    QCommandLineParser parser;
    parser.addPositionalArgument("port", app.translate("main", "port for binding"));
    parser.addPositionalArgument("secret", app.translate("main", "secret for binding"));
    parser.addPositionalArgument("split", app.translate("main", "split type"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);
    QStringList positionalArguments = parser.positionalArguments();

    if (positionalArguments.length() >= 2) {
        int port = positionalArguments.takeFirst().toInt();
        QString secret = positionalArguments.takeFirst();

	// 0, no split, 1 splitv, 2 splith
	if (positionalArguments.length() == 1) {
		int split_type = positionalArguments.takeFirst().toInt();
		setup_window_vertical(split_type, myname);
	}


        QUrl bindingAddress;
        bindingAddress.setScheme(QStringLiteral("ws"));
        bindingAddress.setHost(QStringLiteral("localhost"));
        bindingAddress.setPort(port);
        bindingAddress.setPath(QStringLiteral("/api"));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("token"), secret);
        bindingAddress.setQuery(query);
        context->setContextProperty(QStringLiteral("bindingAddress"), bindingAddress);

        context->setContextProperty("AlbumArt", "");
        context->setContextProperty("mediaplayer", new Mediaplayer(bindingAddress, context));

        engine.load(QUrl(QStringLiteral("qrc:/MediaPlayer.qml")));
    }

    return app.exec();
}
