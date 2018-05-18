/*
 * Copyright (C) 2016 The Qt Company Ltd.
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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import AGL.Demo.Controls 1.0

ApplicationWindow {
    id: root

    Item {
        id: player

        property string title: ""
        property string album: ""
        property string artist: ""

        property int duration: 0
        property int position: 0

        property string cover_art: ""
        property string status: ""

        function time2str(value) {
            return Qt.formatTime(new Date(value), 'mm:ss')
        }
    }

    Item {
        id: bluetooth

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

        function connect_profiles() {
            var address = bluetooth.deviceAddress;
            bluetooth_connection.connect(address, "a2dp")
            bluetooth_connection.connect(address, "avrcp")
        }

        function disconnect_profiles() {
            var address = bluetooth.deviceAddress;
            bluetooth_connection.disconnect(address, "a2dp")
            bluetooth_connection.disconnect(address, "avrcp")
        }

        function set_avrcp_controls(cmd) {
            bluetooth_connection.set_avrcp_controls(bluetooth.deviceAddress, cmd)
        }
    }

    Connections {
        target: bluetooth_connection

        onDeviceListEvent: {
            var address = ""
            for (var i = 0; i < data.list.length; i++) {
                var item = data.list[i]
                if (item.Connected == "True" && item.UUIDs.indexOf(bluetooth.avrcp_uuid) >= 0) {
                    address = item.Address

                    bluetooth.connected = true
                    mediaplayer.pause()

                    //NOTE: This hack is here for when MediaPlayer is started
                    //      with an existing connection.
                    bluetooth.av_connected = item.AVPConnected == "True" 
                }
            }
            if (!address)
                bluetooth.connected = false
            else
                bluetooth.deviceAddress = address
        }

        onDeviceUpdatedEvent: {
            var metadata = data.Metadata

            if (data.Connected == "False")
                return

            bluetooth.connected = data.Connected == "True"
            bluetooth.av_connected = data.AVPConnected == "True"
            bluetooth.deviceAddress = data.Address

            if ('Position' in metadata)
                bluetooth.position = metadata.Position

            if ('Duration' in metadata)
                bluetooth.duration = metadata.Duration

            if ('Status' in metadata)
                bluetooth.state = metadata.Status

            if ('Artist' in metadata)
                bluetooth.artist = metadata.Artist

            if ('Title' in metadata)
                bluetooth.title = metadata.Title
        }
    }

    Connections {
        target: mediaplayer

        onPlaylistChanged: {
            playlist_model.clear();

            for (var i = 0; i < playlist.list.length; i++) {
                var item = playlist.list[i]

                playlist_model.append({ "index": item.index, "artist": item.artist ? item.artist : '', "title": item.title ? item.title : '' })

                if (item.selected) {
                    playlistview.currentIndex = i
                }
            }
        }

        onMetadataChanged: {
            player.title = metadata.title
            player.album = metadata.album
            player.artist = metadata.artist

            if (metadata.duration) {
                player.duration = metadata.duration
            }

            if (metadata.position) {
                player.position = metadata.position
            }

            if (metadata.status) {
                player.status = metadata.status
            }

            if (metadata.image) {
                player.cover_art = metadata.image
            }

            playlistview.currentIndex = metadata.index
        }
    }

    Timer {
        id: timer
        interval: 250
        running: (bluetooth.av_connected && bluetooth.state == "playing")
        repeat: true
        onTriggered: {
            bluetooth.position = bluetooth.position + 250
        }
    }

    ListModel {
        id: playlist_model
    }

    ColumnLayout {
        anchors.fill: parent
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 1080
            clip: true
            Image {
                id: albumart
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: sourceSize.height * width / sourceSize.width
                fillMode: Image.PreserveAspectCrop
                source: player.cover_art ? player.cover_art : ''
                visible: bluetooth.av_connected == false
            }

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height :307
                Rectangle {
                    anchors.fill: parent
                    color: 'black'
                    opacity: 0.75
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.width * 0.02
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Row {
                            spacing: 20
                            //ToggleButton {
                            //    id: random
                            //    visible: bluetooth.connected == false
                            //    offImage: './images/AGL_MediaPlayer_Shuffle_Inactive.svg'
                            //    onImage: './images/AGL_MediaPlayer_Shuffle_Active.svg'
                            //}
                            ToggleButton {
                                id: loop
                                visible: bluetooth.connected == false
                                //checked: player.loop_state
                                offImage: './images/AGL_MediaPlayer_Loop_Inactive.svg'
                                onImage: './images/AGL_MediaPlayer_Loop_Active.svg'
                                onClicked: { mediaplayer.loop(checked) }
                            }
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            Label {
                                id: title
                                Layout.alignment: Layout.Center
                                text: bluetooth.av_connected ? bluetooth.title : (player.title ? player.title : '')
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                            }
                            Label {
                                Layout.alignment: Layout.Center
                                text: bluetooth.av_connected ? bluetooth.artist : (player.artist ? player.artist : '')
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                                font.pixelSize: title.font.pixelSize * 0.6
                            }
                        }
                    }
                    Slider {
                        id: slider
                        Layout.fillWidth: true
                        to: bluetooth.av_connected ? bluetooth.duration : player.duration
                        enabled: bluetooth.av_connected == false
                        value: bluetooth.av_connected ? bluetooth.position : player.position
                        function getPosition() {
                            if (bluetooth.av_connected) {
                                return player.time2str(bluetooth.position)
                            }
                            return player.time2str(player.position)
                        }
                        Label {
                            id: position
                            anchors.left: parent.left
                            anchors.bottom: parent.top
                            font.pixelSize: 32
                            text: slider.getPosition()
                        }
                        Label {
                            id: duration
                            anchors.right: parent.right
                            anchors.bottom: parent.top
                            font.pixelSize: 32
                            text: bluetooth.av_connected ? player.time2str(bluetooth.duration) : player.time2str(player.duration)
                        }
                        onPressedChanged: mediaplayer.seek(value)
                    }
                    RowLayout {
                        Layout.fillHeight: true
//                        Image {
//                            source: './images/AGL_MediaPlayer_Playlist_Inactive.svg'
//                        }
//                        Image {
//                            source: './images/AGL_MediaPlayer_CD_Inactive.svg'
//                        }
                        Item { Layout.fillWidth: true }
                        ImageButton {
                            id: previous
                            offImage: './images/AGL_MediaPlayer_BackArrow.svg'
                            onClicked: {
                                if (bluetooth.av_connected) {
                                    bluetooth.set_avrcp_controls("Previous")
                                    bluetooth.position = 0
                                } else {
                                    mediaplayer.previous()
                                }
                            }
                        }
                        ImageButton {
                            id: play
                            offImage: './images/AGL_MediaPlayer_Player_Play.svg'
                            onClicked: {
                                if (bluetooth.av_connected) {
                                    bluetooth.set_avrcp_controls("Play")
                                } else {
                                    mediaplayer.play()
                                }
                            }
                            states: [
                                State {
                                    when: player.status == "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: {
                                            player.status = ""
                                            mediaplayer.pause()
                                        }
                                    }
                                },
                                State {
                                    when: bluetooth.av_connected && bluetooth.state == "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: bluetooth.set_avrcp_controls("Pause")
                                    }
                                }

                            ]
                        }
                        ImageButton {
                            id: forward
                            offImage: './images/AGL_MediaPlayer_ForwardArrow.svg'
                            onClicked: {
                                if (bluetooth.av_connected) {
                                    bluetooth.set_avrcp_controls("Next")
                                } else {
                                    mediaplayer.next()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
 
                        ToggleButton {
                              visible: bluetooth.connected
                              checked: bluetooth.av_connected
                              offImage: './images/AGL_MediaPlayer_Bluetooth_Inactive.svg'
                              onImage: './images/AGL_MediaPlayer_Bluetooth_Active.svg'

                              onClicked: {
                                  if (bluetooth.av_connected) {
                                      bluetooth.disconnect_profiles()
                                  } else {
                                      bluetooth.connect_profiles()
                                  }
                              }
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 407

            ListView {
                anchors.fill: parent
                id: playlistview
                visible: bluetooth.av_connected == false
                clip: true
                header: Label {
                    x: 50
                    text: 'PLAYLIST'
                    opacity: 0.5
                }
                model: playlist_model
                currentIndex: -1

                delegate: MouseArea {
                    id: delegate
                    width: ListView.view.width
                    height: ListView.view.height / 4
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 50
                        anchors.rightMargin: 50
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: model.title
                            }
                            Label {
                                Layout.fillWidth: true
                                text: model.artist
                                color: '#00ADDC'
                                font.pixelSize: 32
                            }
                        }
                        //Label {
                        //    text: player.time2str(model.duration)
                        //    color: '#00ADDC'
                        //    font.pixelSize: 32
                        //}
                    }
                    onClicked: {
                        mediaplayer.picktrack(playlistview.model.get(index).index)
                    }
                }

                highlight: Rectangle {
                    color: 'white'
                    opacity: 0.25
                }
            }
        }
    }
}
