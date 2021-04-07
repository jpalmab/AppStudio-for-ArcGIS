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

    property LocaleProperties localeProperties: app.localeProperties
    readonly property bool accent: action.checked && !action.checkable

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    palette {
        button: "white"
        buttonText: "black"

        highlight: "#ecfbff"
        highlightedText: "black"

        mid: "#e1f0fb"
        dark: "lightgrey"
        light: "#f0fff0"
    }

    leftPadding: 6 * AppFramework.displayScaleFactor
    rightPadding: leftPadding
    topPadding: 10 * AppFramework.displayScaleFactor
    bottomPadding: topPadding

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        id: layout

        Item {
            implicitHeight: 50 * AppFramework.displayScaleFactor
            implicitWidth: 0
        }

        layoutDirection: localeProperties.layoutDirection
        spacing: 5 * AppFramework.displayScaleFactor

        Item {
            Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            StyledImage {
                id: image

                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor
                }

                source: action.icon.source
                color: accent ? _text.color : action.icon.color
                rotation: typeof action.iconRotation === "number" ? action.iconRotation : 0
            }
        }

        AppText {
            id: _text

            Layout.fillWidth: true
            Layout.fillHeight: true

            text: action.text
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

    //--------------------------------------------------------------------------

    background: Rectangle {
        color: mouseArea.pressed
               ? palette.mid
               : mouseArea.containsMouse
                 ? palette.highlight
                 : accent
                   ? palette.light
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
                control.clicked();
                action.trigger();
            }

            onPressAndHold: {
                control.pressAndHold();
                action.toggle();
            }
        }
    }

    //--------------------------------------------------------------------------
}
