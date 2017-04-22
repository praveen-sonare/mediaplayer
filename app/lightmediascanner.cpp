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

#include "lightmediascanner.h"

LightMediaScanner::LightMediaScanner(const QString& path)
{
    lms = QSqlDatabase::addDatabase("QSQLITE");
    lms.setDatabaseName(path);

    if (!lms.open()) {
        qDebug() << "Cannot open database: " << path;
    } else {
        query = QSqlQuery(lms);
        query.prepare("SELECT files.path FROM files LEFT JOIN audios WHERE audios.id = files.id ORDER BY audios.artist_id, audios.album_id, audios.trackno");
        if (!query.exec())
            qDebug() << "Cannot run SQL query";
    }
}

LightMediaScanner::~LightMediaScanner()
{
    lms.close();
    QSqlDatabase::removeDatabase(lms.connectionName());
}

bool LightMediaScanner::next(QString& item)
{
    if (!query.next())
        return false;

    item = query.value(0).toString();

    return true;
}

QVariantList LightMediaScanner::processLightMediaScanner()
{
    QVariantList mediaFiles;
    QString music;
    LightMediaScanner scanner(QDir::homePath() + "/.config/lightmediascannerd/db.sqlite3");
    while (scanner.next(music)) {
        QFileInfo fileInfo(music);
        // Possible for stale entries due to removable media
        if (!fileInfo.exists())
            continue;
        mediaFiles.append(QUrl::fromLocalFile(music));
    }
    return mediaFiles;
}
