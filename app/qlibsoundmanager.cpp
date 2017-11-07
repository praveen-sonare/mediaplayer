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

#include "qlibsoundmanager.h"
#include <QJsonDocument>
using namespace std;

static int create_json_object(const QJsonObject& obj, struct json_object* jobj);
static bool put_val_to_jobj(const char* key, const QJsonValue& val, struct json_object* jobj);
QLibSoundmanager* me;

static void cbEvent_static(const std::string& event, struct json_object* event_contents)
{
    const QString event_name = QString(event.c_str());
    QString str = QString(json_object_get_string(event_contents));
    QJsonParseError error;
    QJsonDocument jdoc = QJsonDocument::fromJson(str.toUtf8(), &error);
    const QJsonObject jobj = jdoc.object();
    emit me->event(event_name, jobj);
}

static void cbReply_static(struct json_object* replyContents)
{
    if(me == nullptr){
        return;
    }
    QString str = QString(json_object_get_string(replyContents));
    QJsonParseError error;
    QJsonDocument jdoc = QJsonDocument::fromJson(str.toUtf8(), &error);
    QJsonObject jobj = jdoc.object();
    emit me->reply(jobj);
}

QLibSoundmanager::QLibSoundmanager(QObject *parent) :
    QObject(parent)
{
    /* This is not enabled */
    libsm = new LibSoundmanager();
}

QLibSoundmanager::~QLibSoundmanager()
{
    delete libsm;
}

int QLibSoundmanager::init(int port, const QString& token)
{
    if(libsm == nullptr){
        return -1;
    }
    string ctoken = token.toStdString();
    int rc = libsm->init(port, ctoken);
    if(rc != 0){
        return rc;
    }
    me = this;

    libsm->register_callback(
        cbEvent_static,
        cbReply_static);
    return rc;
}

int QLibSoundmanager::call(const QString &verb, const QJsonObject &arg)
{
    // translate QJsonObject to struct json_object
    struct json_object* jobj = json_object_new_object();
    int ret = create_json_object(arg, jobj);
    if(ret < 0)
    {
        return -1;
    }
    return libsm->call(verb.toStdString().c_str(), jobj);
}

int QLibSoundmanager::connect(int sourceID, const QString& sinkName){
    string str = sinkName.toStdString();
    return libsm->connect(sourceID, str);
}
int QLibSoundmanager::disconnect(int connectionID){
    return libsm->disconnect(connectionID);
}
int QLibSoundmanager::ackSetSourceState(int handle, int errorcode){
    return libsm->ackSetSourceState(handle, errorcode);
}
int QLibSoundmanager::registerSource(const QString& name){
    string str = name.toStdString();
    return libsm->registerSource(str);
}

static int create_json_object(const QJsonObject& obj, struct json_object* jobj)
{
    try{
        for(auto itr = obj.begin(); itr != obj.end();++itr)
        {
            string key = itr.key().toStdString();
            //const char* key = itr.key().toStdString().c_str(); // Do not code like this. string is removed if size is over 16!!

            bool ret = put_val_to_jobj(key.c_str(), itr.value(),jobj);
            if(!ret){
                /*This is not implemented*/
                qDebug("JsonArray can't parse for now");
                return -1;
            }
        }
    }
    catch(...){
        qDebug("Json parse error occured");
        return -1;
    }
    return 0;
}

static bool put_val_to_jobj(const char* key, const QJsonValue& val, struct json_object* jobj)
{
    if(val.isArray()){
        return false;  // Array can't input
    }
    if(val.isString()){
        string value = val.toString().toStdString();
        json_object_object_add(jobj, key, json_object_new_string(value.c_str()));
    }
    else{
        const int value = val.toInt();     
        json_object_object_add(jobj, key, json_object_new_int(value));   
    }
    return true;
}


void QLibSoundmanager::subscribe(const QString event_name)
{
    std::string str = event_name.toStdString();
    libsm->subscribe(str);
}

void QLibSoundmanager::unsubscribe(const QString event_name)
{
    std::string str = event_name.toStdString();
    libsm->unsubscribe(str);
}
