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

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    property alias label: labelText
    property alias text: labelText.text

    default property alias contentItems: contentLayout.data

    property bool collapsed: true
    property bool collapsible: true
    property int layoutDirection: Qt.LeftToRight

    //--------------------------------------------------------------------------

    signal opened()
    signal closed()

    //--------------------------------------------------------------------------

    spacing: 6 * AppFramework.displayScaleFactor
    padding: 6 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: background

        color: "white"
        border {
            width: 1 * AppFramework.displayScaleFactor
            color: "grey"
        }
        radius: 3 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        id: layout

        width: availableWidth

        spacing: 5 * AppFramework.displayScaleFactor

        RowLayout {
            Layout.fillWidth: true

            layoutDirection: control.layoutDirection

            StyledImageButton {
                Layout.preferredWidth: ControlsSingleton.inputTextHeight
                Layout.preferredHeight: Layout.preferredWidth

                source: Icons.icon("caret-down")
                color: labelText.color
                rotation: collapsed ? (layoutDirection === Qt.RightToLeft ? 90 : -90) : 0
                opacity: 0.5

                Behavior on rotation {
                    NumberAnimation {
                        duration: 200
                    }
                }

                onClicked: {
                    toggle();
                }
            }

            Text {
                id: labelText

                Layout.fillWidth: true

                text: groupLabel

                font {
                    family: control.font.family
                    pointSize: 16
                    bold: true
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        toggle();
                    }
                }
            }
        }

        ColumnLayout {
            id: contentLayout

            Layout.fillWidth: true
            Layout.leftMargin: 10 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: !collapsed

            spacing: 5 * AppFramework.displayScaleFactor
        }
    }

    //--------------------------------------------------------------------------

    function toggle() {
        collapsed = !collapsed;

        if (collapsed) {
            closed();
        } else {
            opened();
        }
    }

    //--------------------------------------------------------------------------

    function expand() {
        if (collapsed) {
            toggle();
        }
    }

    //--------------------------------------------------------------------------

    function collapse() {
        if (!collapsed) {
            toggle();
        }
    }

    //--------------------------------------------------------------------------
}
