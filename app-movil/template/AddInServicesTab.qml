/* Copyright 2018 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

MainViewTab {
    //--------------------------------------------------------------------------

    property AddInServicesManager manager
    readonly property int count: manager.services.length

    //--------------------------------------------------------------------------

    title: qsTr("Services")
    iconSource: "images/services.png"

    //--------------------------------------------------------------------------

    ListView {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        clip: true
        model: manager.services
        spacing: 0
        delegate: serviceDelegate
    }

    //--------------------------------------------------------------------------

    Component {
        id: serviceDelegate

        Item {
            readonly property AddInTool service: ListView.view.model[index]
            readonly property AddInContainer container: service.container
            readonly property AddIn addIn: service.addIn
            readonly property Item instance: container.instance

            width: ListView.view.width
            height: childrenRect.height + 5 * AppFramework.displayScaleFactor

            RowLayout {
                width: parent.width
                spacing: 5 * AppFramework.displayScaleFactor

                Item {
                    Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 66 * AppFramework.displayScaleFactor

                    Flipable {
                        id: flipable

                        anchors.fill: parent

                        property bool flipped: false

                        front: Loader {
                            anchors.fill: parent

                            sourceComponent: thumbnailIndicator

                            onLoaded: {
                                item.addIn = addIn;
                            }
                        }

                        back: Loader {
                            id: statusLoader

                            anchors.fill: parent

                            active: instance ? instance.statusIndicator !== null : false
                            sourceComponent: statusIndicator

                            onLoaded: {
                                item.container = container;
                            }
                        }

                        transform: Rotation {
                            id: rotation

                            origin {
                                x: flipable.width/2
                                y: flipable.height/2
                            }

                            axis {
                                x: 1
                                y: 0
                                z: 0
                            }
                            angle: 0
                        }

                        states: State {
                            name: "back"
                            when: flipable.flipped

                            PropertyChanges {
                                target: rotation
                                angle: 180
                            }
                        }

                        transitions: Transition {
                            NumberAnimation {
                                target: rotation
                                property: "angle"
                                duration: 1000
                            }
                        }

                        Timer {
                            interval: 3000
                            repeat: true
                            running: statusLoader.status === Loader.Ready

                            onTriggered: {
                                flipable.flipped = !flipable.flipped;
                            }
                        }
                    }

//                    Loader {
//                        anchors.fill: parent

//                        active: statusLoader.status !== Loader.Ready
//                        sourceComponent: thumbnailIndicator

//                        onLoaded: {
//                            item.addIn = addIn;
//                        }
//                    }

//                    Loader {
//                        id: statusLoader

//                        anchors.fill: parent

//                        active: instance ? instance.statusIndicator !== null : false
//                        sourceComponent: statusIndicator

//                        onLoaded: {
//                            item.container = container;
//                        }
//                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 5 * AppFramework.displayScaleFactor
                    spacing: 2 * AppFramework.displayScaleFactor

                    AppText {
                        Layout.fillWidth: true

                        text: container.title
                        font {
                            pointSize: 14
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: addIn.version
                        font {
                            pointSize: 10
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                showAbout(addIn);
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    StyledImageButton {
                        anchors.fill: parent

                        visible: addIn.hasSettingsPage
                        source: "images/gear.png"
                        color: "#7f8183"

                        onClicked: {
                            mainStackView.push(addInSettingsPage,
                                               {
                                                   addIn: addIn,
                                                   instance: service.instance
                                               });
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 1
                color: "#40000000"
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInAboutPage

        AddInAboutPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        AddInSettingsPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: thumbnailIndicator

        Rectangle {
            property AddIn addIn

            border {
                color: "darkgrey"
                width: 1 * AppFramework.displayScaleFactor
            }

            Image {
                anchors {
                    fill: parent
                    margins: parent.border.width
                }

                source: addIn ? addIn.thumbnail : ""
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        showAbout(addIn);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: statusIndicator

        Rectangle {
            property AddInContainer container
            readonly property Item instance: container ? container.instance : null

            color: "lightgrey"
            border {
                color: "darkgrey"
                width: 1 * AppFramework.displayScaleFactor
            }

            /*
            Text {
                anchors.fill: parent

                text: "Running: %1".arg(instance ? "Yes" : "No")

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
            }
            */

            Loader {
                anchors {
                    fill: parent
                    margins: parent.border.width
                }

                sourceComponent: instance.statusIndicator
                asynchronous: true
            }
        }
    }

    //--------------------------------------------------------------------------

    function showAbout(addIn) {
        mainStackView.push(addInAboutPage,
                           {
                               addIn: addIn,
                           });
    }

    //--------------------------------------------------------------------------
}
