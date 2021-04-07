/* Copyright 2020 Esri
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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    property int updatesAvailable: 0
    property bool busy: false

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    visible: updatesAvailable > 0

    padding: 6 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    palette {
        button: "#eee"
        buttonText: "black"

        highlight: "#ecfbff"
        highlightedText: "black"

        mid: "#e1f0fb"
        dark: "lightgrey"
        light: "#f0fff0"
    }

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        id: layout

        layoutDirection: app.localeProperties.layoutDirection

        spacing: 5 * AppFramework.displayScaleFactor

        Item {
            Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            StyledImage {
                id: refreshImage

                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor
                }

                source: Icons.bigIcon("refresh")
                color: caption.color

                RotationAnimator {
                    target: refreshImage
                    from: 0
                    to: 360
                    duration: 2000
                    running: busy
                    loops: Animation.Infinite

                    onFinished: {
                        target.rotation = from;
                    }
                }
            }
        }

        AppText {
            id: caption

            Layout.fillWidth: true

            text: qsTr("Updates available: %1").arg(updatesAvailable)
            horizontalAlignment: app.localeProperties.textAlignment

            font {
                pointSize: 15
            }
        }

        Item {
            Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            StyledImage {
                id: image

                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor
                }

                source: Icons.bigIcon("chevron-right")
                color: caption.color

                rotation: app.localeProperties.isRightToLeft ? 180 : 0
            }
        }
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        color: mouseArea.pressed
               ? palette.mid
               : mouseArea.containsMouse
                 ? palette.highlight
                 : palette.button

        border {
            color: mouseArea.pressed
                   ? palette.dark
                   : mouseArea.containsMouse
                     ? palette.mid
                     : "transparent"
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            hoverEnabled: control.enabled
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                control.clicked()
            }

            onPressAndHold: {
                control.pressAndHold();
            }
        }

        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------
}
