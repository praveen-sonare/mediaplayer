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
    property string apiString: "mediaplayer"
    property var verbs: []
    property string payloadLength: "9999"
    property string cover_art: ""
    property string title: ""
    property string artist: ""
    property int duration: 0
    property int position: 0
    property int old_index: -1

    property bool loop_state: false
    property bool running: false

    readonly property var msgid: {
        "call": 2,
        "retok": 3,
        "reterr": 4,
        "event": 5
    }

    onTextMessageReceived: {
        var json = JSON.parse(message)
        console.debug("Raw response: " + message)
        var request = json[2].request
        var response = json[2].response
        //console.debug("response: " + JSON.stringify(response))
        switch (json[0]) {
            case msgid.call:
                break
            case msgid.retok:
                root.statusString = request.status
                var verb = verbs.shift()
                if (verb == "playlist") {
                    console.debug("Media result returned")
                    var media = response.list

                    for (var i = 0; i < media.length; i++) {
                        var item = media[i]
                        playlist.append({ "index": item.index, "artist": item.artist ? item.artist : '', "title": item.title ? item.title : '' })
                        if (item.selected) {
                            playlistview.currentIndex = i
                        }
                    }
                } else if (verb == "controls") {
                    if (response) {
                        root.running = response.playing
                    }
                } else if (verb == "metadata") {
                    root.cover_art = response.image ? response.image : ''
                }
                break
            case msgid.reterr:
                root.statusString = "Bad return value, binding probably not installed"
                var verb = verbs.shift()
                break
            case msgid.event:
                var payload = JSON.parse(JSON.stringify(json[2]))
                var event = payload.event
                if (event == "mediaplayer/playlist") {
                    console.debug("Media playlist is updated")
                    var media = json[2].data.list

                    if (!root.running) {
                        root.clearPlaylist()
                    }

                    playlist.clear()

                    for (var i = 0; i < media.length; i++) {
                        var item = media[i]

                        playlist.append({ "index": item.index, "artist": item.artist ? item.artist : '', "title": item.title ? item.title : '' })
                        if (item.selected) {
                            playlistview.currentIndex = i
                        }
                    }

                } else if (event == "mediaplayer/metadata") {
                    var data = json[2].data

                    if (data.status == "stopped") {
                        root.running = false
                        root.clearPlaylist()
                        break
                    }

                    root.running = true
                    root.position = data.position
                    root.duration = data.duration

                    playlistview.currentIndex = data.index

                    if (playlistview.currentIndex != root.old_index) {
                        sendSocketMessage("metadata", 'None')
                        root.old_index = data.index
                    }

                    root.title = data.title ? data.title : ''
                    root.artist = data.artist ? data.artist : ''
                }
                break
        }
    }

    onStatusChanged: {
        switch (status) {
            case WebSocket.Open:
            console.debug("onStatusChanged: Open")
            sendSocketMessage("subscribe", { value: "metadata" })
            sendSocketMessage("playlist", 'None')
            sendSocketMessage("subscribe", { value: "playlist" })
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

    function loop(value) {
        sendSocketMessage("controls", { "value": "loop", "state": value })
        root.loop_state = value
    }

    function next() {
        sendSocketMessage("controls", { "value": "next" })
    }

    function previous() {
        sendSocketMessage("controls", { "value": "previous" })
    }

    function play() {
        sendSocketMessage("controls", { "value": "play" })
    }

    function pause() {
        sendSocketMessage("controls", { "value": "pause" })
    }

    function pick_track(index) {
        sendSocketMessage("controls", { "value": "pick-track", "index": index })
    }

    function seek(milliseconds) {
        sendSocketMessage("controls", { "value": "seek", "position": milliseconds })
    }

    function stop() {
        sendSocketMessage("controls", { "value": "stop" })
    }

    function clearPlaylist() {
        root.position = ''
        root.duration = ''
        root.title = ''
        root.artist = ''
        root.cover_art = ''
        root.old_index = -1
        playlistview.currentIndex = -1
    }

    function time2str(value) {
        return Qt.formatTime(new Date(value), 'mm:ss')
    }
}
