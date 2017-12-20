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
import QtMultimedia 5.6
import AGL.Demo.Controls 1.0
import 'api' as API

ApplicationWindow {
    id: root

    API.MediaPlayer {
        id: player
        url: bindingAddress
    }

    API.BluetoothManager {
        id: bluetooth
        url: bindingAddress
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
        id: playlist
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
                                checked: player.loop_state
                                offImage: './images/AGL_MediaPlayer_Loop_Inactive.svg'
                                onImage: './images/AGL_MediaPlayer_Loop_Active.svg'
                                onClicked: { player.loop(checked) }
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
                        onPressedChanged: player.seek(value)
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
                                    bluetooth.sendMediaCommand("Previous")
                                    bluetooth.position = 0
                                } else {
                                    player.previous()
                                }
                            }
                        }
                        ImageButton {
                            id: play
                            offImage: './images/AGL_MediaPlayer_Player_Play.svg'
                            onClicked: {
                                if (bluetooth.av_connected) {
                                    bluetooth.sendMediaCommand("Play")
                                } else {
                                    player.play()
                                }
                            }
                            states: [
                                State {
                                    when: player.running === true
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: player.pause()
                                    }
                                },
                                State {
                                    when: bluetooth.av_connected && bluetooth.state == "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: bluetooth.sendMediaCommand("Pause")
                                    }
                                }

                            ]
                        }
                        ImageButton {
                            id: forward
                            offImage: './images/AGL_MediaPlayer_ForwardArrow.svg'
                            onClicked: {
                                if (bluetooth.av_connected) {
                                    bluetooth.sendMediaCommand("Next")
                                } else {
                                    player.next()
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
                model: playlist
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
                        player.pick_track(playlistview.model.get(index).index)
                        player.play()
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
