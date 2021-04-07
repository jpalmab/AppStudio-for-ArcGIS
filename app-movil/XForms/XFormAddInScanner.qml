/* Copyright 2019 Esri
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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property string addInName
    property var addInView
    readonly property var addInInstance: addInView ? addInView.instance : null

    property string title: "Add-In Scanner"

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.75)

    property string appearance

    property bool debug: !isSupported

    readonly property bool isSupported: true

    //--------------------------------------------------------------------------

    signal codeScanned(string code)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var properties = {
        };

        addInView = xform.addIns.createView(addInName, viewContainer, properties);
    }

    //--------------------------------------------------------------------------

    onCodeScanned: {
        closeControl();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: addInInstance

        onScanned: {
            console.log(logCategory, "scanned:", code);
            page.codeScanned(code);
        }
    }

    //--------------------------------------------------------------------------

    Item {
        anchors.fill: parent

        z: 88

        Rectangle {
            anchors.fill: parent

            color: "black"

            ColumnLayout {
                anchors.fill: parent

                Rectangle {
                    id: titleBar

                    Layout.fillWidth: true

                    property int buttonHeight: 35 * AppFramework.displayScaleFactor

                    height: columnLayout.height + 5 * AppFramework.displayScaleFactor
                    //color: barBackgroundColor //"#80000000"
                    color: "transparent"

                    ColumnLayout {
                        id: columnLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 2 * AppFramework.displayScaleFactor
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledImageButton {
                                Layout.fillHeight: true
                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.preferredWidth: titleBar.buttonHeight

                                source: ControlsSingleton.backIcon
                                padding: ControlsSingleton.backIconPadding
                                color: xform.style.titleTextColor

                                onClicked: {
                                    closeControl();
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                text: title
                                color: xform.style.titleTextColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                elide: Text.ElideRight

                                font {
                                    pixelSize: parent.height * 0.75
                                    family: xform.style.fontFamily
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    onPressAndHold: {
                                        debug = !debug;
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.preferredWidth: titleBar.buttonHeight
                            }
                        }
                    }
                }

                Rectangle {
                    id: viewContainer

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    color: "#fffffd"
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function closeControl() {
        parent.pop();
    }

    //--------------------------------------------------------------------------
}
