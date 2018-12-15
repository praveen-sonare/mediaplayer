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

    width: container.width * container.scale
    height: container.height * container.scale

    Item {
        id: player

        property string title: ""
        property string album: ""
        property string artist: ""

        property bool av_connected: false

        property int duration: 0
        property int position: 0

        property string cover_art: ""
        property string status: "stopped"

        function time2str(value) {
            return Qt.formatTime(new Date(value), 'mm:ss')
        }
    }

    Connections {
        target: mediaplayer

        onMetadataChanged: {
            var track = metadata.track

            if ('status' in metadata) {
                player.status = metadata.status
            }

            if ('connected' in metadata) {
                player.av_connected = metadata.connected
            }

            if (track) {
                if ('image' in track) {
                     player.cover_art = track.image
                }

                player.title = track.title
                player.album = track.album
                player.artist = track.artist
                player.duration = track.duration

                if ('index' in track) {
                     playlistview.currentIndex = track.index
                }
            }

            if ('position' in metadata) {
                player.position = metadata.position
            }
        }
    }

    Timer {
        id: timer
        interval: 250
        running: player.av_connected && player.status == "playing"
        repeat: true
        onTriggered: {
            player.position = player.position + 250
        }
    }

    Item {
        id: container
        anchors.centerIn: parent
        width: 1080
        height: 1487
        scale: screenInfo.scale_factor()

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
                visible: player.av_connected === false
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
                                visible: player.av_connected === false
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
                                text: player.title
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                            }
                            Label {
                                Layout.alignment: Layout.Center
                                text: player.artist
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                                font.pixelSize: title.font.pixelSize * 0.6
                            }
                        }
                    }
                    Slider {
                        id: slider
                        Layout.fillWidth: true
                        to: player.duration
                        enabled: player.av_connected === false
                        value: player.position
                        Label {
                            id: position
                            anchors.left: parent.left
                            anchors.bottom: parent.top
                            font.pixelSize: 32
                            text: player.time2str(player.position)
                        }
                        Label {
                            id: duration
                            anchors.right: parent.right
                            anchors.bottom: parent.top
                            font.pixelSize: 32
                            text: player.time2str(player.duration)
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
                                mediaplayer.previous()
                            }
                        }
                        ImageButton {
                            id: play
                            states: [
                                State {
                                    when: player.status == "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: {
                                            mediaplayer.pause()
                                        }
                                    }
                                },
                                State {
                                    when: player.status != "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Play.svg'
                                        onClicked: mediaplayer.play()
                                    }
                                }
                            ]
                        }
                        ImageButton {
                            id: forward
                            offImage: './images/AGL_MediaPlayer_ForwardArrow.svg'
                            onClicked: {
                                mediaplayer.next()
                            }
                        }

                        Item { Layout.fillWidth: true }
 
                        ToggleButton {
                              visible: true
                              checked: player.av_connected
                              onClicked: {
                                if (checked)
                                        mediaplayer.connect()
                                else
                                        mediaplayer.disconnect()
                              }
                              contentItem: Image {
                                source: player.av_connected ? './images/AGL_MediaPlayer_Bluetooth_Active.svg' : './images/AGL_MediaPlayer_Bluetooth_Inactive.svg'
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
                visible: player.av_connected === false
                clip: true
                header: Label {
                    x: 50
                    text: 'PLAYLIST'
                    opacity: 0.5
                }
                model: MediaplayerModel
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
                        mediaplayer.picktrack(playlistview.model[index].index)
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
}
