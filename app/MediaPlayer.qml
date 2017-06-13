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
import MediaPlayer 1.0
import 'api' as API

ApplicationWindow {
    id: root

    Item {
        id: bluetooth
        property bool connected: false
        property string state

        property string artist
        property string title
        property int duration: 0
        property int position: 0
        property int pos_offset: 0

        function disableBluetooth() {
            bluetooth.artist = ''
            bluetooth.title = ''
            bluetooth.duration = 0
            bluetooth.position = 0
            bluetooth.pos_offset = 0
            bluetooth.connected = false
        }
    }

    API.LightMediaScanner {
        id: binding
        url: bindingAddress
    }

    Connections {
        target: dbus

        onProcessPlaylistHide: {
            playlistview.visible = false
            player.stop()
        }

        onProcessPlaylistShow: {
            playlistview.visible = true
            bluetooth.disableBluetooth()
        }

        onDisplayBluetoothMetadata: {
            if (avrcp_artist)
                bluetooth.artist = avrcp_artist
            if (avrcp_title)
                bluetooth.title = avrcp_title
            bluetooth.duration = avrcp_duration
            bluetooth.pos_offset = 0
        }

        onUpdatePlayerStatus: {
            bluetooth.connected = true
            bluetooth.state = status
        }

        onUpdatePosition: {
            slider.value = current_position
            bluetooth.position = current_position
        }
    }

    MediaPlayer {
        id: player
        audioRole: MediaPlayer.MusicRole
        autoLoad: true
        playlist: playlist

        property bool is_bluetooth: false
        function time2str(value) {
            return Qt.formatTime(new Date(value), 'mm:ss')
        }
        onPositionChanged: slider.value = player.position
    }

    Timer {
        id: timer
        interval: 250
        running: (bluetooth.connected && bluetooth.state == "playing")
        repeat: true
        onTriggered: {
            bluetooth.position = dbus.getCurrentPosition() - bluetooth.pos_offset
            slider.value = bluetooth.position
        }
    }

    Playlist {
        id: playlist
        playbackMode: random.checked ? Playlist.Random : loop.checked ? Playlist.Loop : Playlist.Sequential
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
                source: player.metaData.coverArtImage ? player.metaData.coverArtImage : ''
                visible: bluetooth.connected == false
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
                            ToggleButton {
                                id: random
                                visible: bluetooth.connected == false
                                offImage: './images/AGL_MediaPlayer_Shuffle_Inactive.svg'
                                onImage: './images/AGL_MediaPlayer_Shuffle_Active.svg'
                            }
                            ToggleButton {
                                id: loop
                                visible: bluetooth.connected == false
                                offImage: './images/AGL_MediaPlayer_Loop_Inactive.svg'
                                onImage: './images/AGL_MediaPlayer_Loop_Active.svg'
                            }
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            Label {
                                id: title
                                Layout.alignment: Layout.Center
                                text: bluetooth.title ? bluetooth.title : (player.metaData.title ? player.metaData.title : '')
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                            }
                            Label {
                                Layout.alignment: Layout.Center
                                text: bluetooth.artist ? bluetooth.artist : (player.metaData.contributingArtist ? player.metaData.contributingArtist : '')
                                horizontalAlignment: Label.AlignHCenter
                                verticalAlignment: Label.AlignVCenter
                                font.pixelSize: title.font.pixelSize * 0.6
                            }
                        }
                    }
                    Slider {
                        id: slider
                        Layout.fillWidth: true
                        to: bluetooth.connected ? bluetooth.duration : player.duration
                        enabled: bluetooth.connected == false
                        function getPosition() {
                            if (bluetooth.connected && bluetooth.position) {
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
                            text: bluetooth.connected ? player.time2str(bluetooth.duration) : player.time2str(player.duration)
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
                                if (bluetooth.connected) {
                                    bluetooth.pos_offset = dbus.getCurrentPosition()
                                    dbus.processQMLEvent("Previous")
                                } else {
                                    playlist.previous()
                                }
                            }
                        }
                        ImageButton {
                            id: play
                            offImage: './images/AGL_MediaPlayer_Player_Play.svg'
                            onClicked: {
                                if (bluetooth.connected) {
                                    dbus.processQMLEvent("Play")
                                } else {
                                    player.play()
                                }
                            }
                            states: [
                                State {
                                    when: player.playbackState === MediaPlayer.PlayingState
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: player.pause()
                                    }
                                },
                                State {
                                    when: bluetooth.connected && bluetooth.state == "playing"
                                    PropertyChanges {
                                        target: play
                                        offImage: './images/AGL_MediaPlayer_Player_Pause.svg'
                                        onClicked: dbus.processQMLEvent("Pause")
                                    }
                                }

                            ]
                        }
                        ImageButton {
                            id: forward
                            offImage: './images/AGL_MediaPlayer_ForwardArrow.svg'
                            onClicked: {
                                if (bluetooth.connected) {
                                    dbus.processQMLEvent("Next")
                                } else {
                                    playlist.next()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
 
                        ToggleButton {
                              enabled: false
                              checked: bluetooth.connected
                              offImage: './images/AGL_MediaPlayer_Bluetooth_Inactive.svg'
                              onImage: './images/AGL_MediaPlayer_Bluetooth_Active.svg'
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 407

	    PlaylistWithMetadata {
	        id: playlistmodel
                source: playlist
            }

            ListView {
                anchors.fill: parent
                id: playlistview
                clip: true
                header: Label {
                    x: 50
                    text: 'PLAYLIST'
                    opacity: 0.5
                }
                model: playlistmodel
                currentIndex: playlist.currentIndex

                delegate: MouseArea {
                    id: delegate
                    width: ListView.view.width
                    height: ListView.view.height / 4
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 50
                        anchors.rightMargin: 50
                        Image {
                            source: model.coverArt
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: delegate.height
                            Layout.preferredHeight: delegate.height
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: model.title
                            }
                            Label {
                                Layout.fillWidth: true
                                text: model.artist
                                color: '#66FF99'
                                font.pixelSize: 32
                            }
                        }
                        Label {
                            text: player.time2str(model.duration)
                            color: '#66FF99'
                            font.pixelSize: 32
                        }
                    }
                    onClicked: {
                        playlist.currentIndex = model.index
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
