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

import QtQuick 2.6
import QtWebSockets 1.0

WebSocket {
    id: root
    active: true
    url: bindingAddress

    property string statusString: "waiting..."
    property string apiString: "media-manager"
    property var verbs: []
    property var items: []
    property string payloadLength: "9999"

    readonly property var msgid: {
        "call": 2,
        "retok": 3,
        "reterr": 4,
        "event": 5
    }

    function validateItem(media) {
        for (var i = 0; i < media.length; i++) {
            var item = media[i]
            if (root.items.indexOf(item) < 0) {
                playlist.addItem(item)
                root.items.push(item)
            }
        }
    }

    onTextMessageReceived: {
        var json = JSON.parse(message)
        console.debug("Raw response: " + message)
        var request = json[2].request
        var response = json[2].response
        console.debug("response: " + JSON.stringify(response))
        switch (json[0]) {
            case msgid.call:
                break
            case msgid.retok:
                root.statusString = request.status
                var verb = verbs.shift()
                if (verb == "media_result") {
                    console.debug("Media result returned")
                    validateItem(response.Media)
                }
                break
            case msgid.reterr:
                root.statusString = "Bad return value, binding probably not installed"
                break
            case msgid.event:
                var payload = JSON.parse(JSON.stringify(json[2]))
                var event = payload.event
                if (event == "media-manager/media_added") {
                    console.debug("Media is inserted")
                    validateItem(json[2].data.Media)
                } else if (event == "media-manager/media_removed") {
                    var removed = 0
                    console.debug("Media is removed")
                    player.stop()

                    for (var i = 0; i < root.items.length; i++) {
                        if (root.items[i].startsWith(json[2].data.Path)) {
                            playlist.removeItem(i - removed++)
                        }
                    }
                    root.items = root.items.filter(function (item) { return !item.startsWith(json[2].data.Path) })
                }
                break
        }
    }

    onStatusChanged: {
        switch (status) {
            case WebSocket.Open:
            console.debug("onStatusChanged: Open")
            sendSocketMessage("subscribe", { value: "media_added" })
            sendSocketMessage("subscribe", { value: "media_removed" })
            root.populateMediaPlaylist()
            break
            case WebSocket.Error:
            root.statusString = "WebSocket error: " + root.errorString
            break
        }
    }

    function sendSocketMessage(verb, parameter) {
        var requestJson = [ msgid.call, payloadLength, apiString + '/'
        + verb, parameter ]
        console.debug("sendSocketMessage: " + JSON.stringify(requestJson))
        verbs.push(verb)
        sendTextMessage(JSON.stringify(requestJson))
    }

    function populateMediaPlaylist() {
        sendSocketMessage("media_result", 'None')
    }
}
