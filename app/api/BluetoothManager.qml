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
    property string apiString: "Bluetooth-Manager"
    property var verbs: []
    property string payloadLength: "9999"

    property string deviceAddress: ""
    property bool connected: false
    property bool av_connected: false

    property int position: 0
    property int duration: 0

    property string artist: ""
    property string title: ""
    property string state: "stopped"

    // AVRCP Target UUID
    property string avrcp_uuid: "0000110e-0000-1000-8000-00805f9b34fb"

    // A2DP Source
    property string a2dp_uuid:  "0000110a-0000-1000-8000-00805f9b34fb"

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
        console.debug("response: " + JSON.stringify(response))
        switch (json[0]) {
            case msgid.call:
                break
            case msgid.retok:
                root.statusString = request.status
                var address = ""

                if (request.info == "BT - Scan Result is Displayed") {
                    for (var i = 0; i < response.length; i++) {
                        var data = response[i]
                        if (data.Connected == "True" && data.UUIDs.indexOf(avrcp_uuid) >= 0) {
                            address = response[i].Address
                            console.debug("Connected Device: " + address)

                            root.connected = true
                            player.pause()

                            //NOTE: This hack is here for when MediaPlayer is started
                            //      with an existing connection.
                            if (data.AVPConnected == "True") {
                                root.av_connected = true
                            }
                        }
                    }
                    root.deviceAddress = address
                    if (!address) {
                        root.connected = false
                    }
                }
                break
            case msgid.reterr:
                root.statusString = "Bad return value, binding probably not installed"
                break
            case msgid.event:
                var payload = JSON.parse(JSON.stringify(json[2]))
                var event = payload.event

                if (event == "Bluetooth-Manager/connection") {
                    sendSocketMessage("discovery_result", 'None')
                } else if (event == "Bluetooth-Manager/device_updated") {
                    var data = payload.data
                    var metadata = data.Metadata

                    if (root.deviceAddress != data.Address)
                        break

                    if (data.Connected == "False") {
                        console.debug("Device Disconnected")
                        sendSocketMessage("discovery_result", 'None')
                        break
                    }
                    root.av_connected = data.AVPConnected == "True"

                    if ('Position' in metadata) {
                        console.debug("Position " + metadata.Position)
                        root.position = metadata.Position
                    }

                    if ('Duration' in metadata) {
                        console.debug("Duration " + metadata.Duration)
                        root.duration = metadata.Duration
                    }

                    if ('Status' in metadata) {
                        console.debug("Status " + metadata.Status)
                        root.state = metadata.Status
                    }

                    if ('Artist' in metadata) {
                        console.debug("Artist " + metadata.Artist)
                        root.artist = metadata.Artist
                    }

                    if ('Title' in metadata) {
                        console.debug("Title " + metadata.Title)
                        root.title = metadata.Title
                    }
                }
                break
        }
    }

    onStatusChanged: {
        switch (status) {
            case WebSocket.Open:
            console.debug("onStatusChanged: Open")
            sendSocketMessage("subscribe", { value : "device_updated" })
            sendSocketMessage("subscribe", { value : "connection" })
            sendSocketMessage("discovery_result", 'None')
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
        root.sendTextMessage(JSON.stringify(requestJson))
    }

    function sendMediaCommand(state) {
        var parameters = { "Address": deviceAddress, "value": state }
        sendSocketMessage("set_avrcp_controls", parameters)
    }

    function connect_profiles() {
        sendSocketMessage("connect", { "value": root.deviceAddress, "uuid": a2dp_uuid })
        sendSocketMessage("connect", { "value": root.deviceAddress, "uuid": avrcp_uuid })
    }

    function disconnect_profiles() {
        sendSocketMessage("disconnect", { "value": root.deviceAddress, "uuid": a2dp_uuid })
        sendSocketMessage("disconnect", { "value": root.deviceAddress, "uuid": avrcp_uuid })
    }
}
