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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    property Action action
    property url icon: action.icon.source
    property string text: action.text
    property LocaleProperties localeProperties: app.localeProperties
    property bool showCheck: false

    readonly property bool isSeparator: action && !action.text
    property url checkIcon: Icons.icon("check")

    property bool updatesAvailable: action ? !!action.updatesAvailable : false

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    implicitHeight: (isSeparator ? 1 : 50) * AppFramework.displayScaleFactor

    palette {
        button: "white"
        buttonText: "black"

        highlight: "#ecfbff"
        highlightedText: "black"

        mid: "#e1f0fb"
        dark: "lightgrey"
    }

    enabled: action ? action.enabled: true

    leftPadding: 6 * AppFramework.displayScaleFactor
    rightPadding: leftPadding
    topPadding: 10 * AppFramework.displayScaleFactor
    bottomPadding: topPadding

    //--------------------------------------------------------------------------

    contentItem: Item {
        visible: !isSeparator

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            enabled: !isSeparator
            hoverEnabled: control.enabled
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (action) {
                    action.trigger();
                }

                control.clicked();
            }

            onPressAndHold: {
                control.pressAndHold();
            }
        }

        RowLayout {
            id: layout

            anchors {
                fill: parent
                leftMargin: 10 * AppFramework.displayScaleFactor
                rightMargin: 10 * AppFramework.displayScaleFactor
            }

            layoutDirection: localeProperties.layoutDirection
            spacing: 5 * AppFramework.displayScaleFactor

            Item {
                Layout.preferredHeight: layout.height
                Layout.preferredWidth: Layout.preferredHeight

                visible: showCheck || action.checkable

                StyledImage {
                    anchors {
                        fill: parent
                        margins: 3 * AppFramework.displayScaleFactor
                    }

                    visible: action.checked
                    source: checkIcon
                    color: _text.color
                }
            }

            Item {
                Layout.preferredHeight: layout.height
                Layout.preferredWidth: Layout.preferredHeight

                UpdateIndicator {
                    anchors {
                        right: layout.layoutDirection == Qt.LeftToRight ? parent.left : undefined
                        left: layout.layoutDirection == Qt.RightToLeft ? parent.right : undefined
                        verticalCenter: parent.verticalCenter
                    }

                    visible: updatesAvailable
                }

                StyledImage {
                    anchors {
                        fill: parent
                        margins: 3 * AppFramework.displayScaleFactor
                    }

                    source: icon
                    color: _text.color
                }
            }

            AppText {
                id: _text

                Layout.fillWidth: true
                Layout.fillHeight: true

                text: control.text
                horizontalAlignment: localeProperties.textAlignment
                verticalAlignment: Text.AlignVCenter
                color: mouseArea.pressed
                       ? palette.highlightedText
                       : mouseArea.containsMouse
                         ? palette.highlightedText
                         : palette.buttonText

                font {
                    pointSize: 15
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        color: isSeparator
               ? palette.dark
               : mouseArea.pressed
                 ? palette.mid
                 : mouseArea.containsMouse
                   ? palette.highlight
                   : palette.button

        border {
            color: isSeparator
                   ? "transparent"
                   : mouseArea.pressed
                     ? palette.dark
                     : mouseArea.containsMouse
                       ? palette.mid
                       : "transparent"
        }
    }

    //--------------------------------------------------------------------------
}
