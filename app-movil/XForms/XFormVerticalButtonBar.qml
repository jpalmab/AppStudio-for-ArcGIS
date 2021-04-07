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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    default property alias content: layout.data
    readonly property alias visibleItemsCount: layout.visibleItemsCount

    property XFormStyle style: xform.style

    property alias border: background.border
    property alias fader: fader

    //--------------------------------------------------------------------------

    spacing: 6 * AppFramework.displayScaleFactor
    padding: ControlsSingleton.inputTextPadding

    //--------------------------------------------------------------------------

    background: Item {
        DropShadow {
            id: dropShadow

            anchors.fill: source

            horizontalOffset: 3 * AppFramework.displayScaleFactor
            verticalOffset: horizontalOffset

            radius: 5 * AppFramework.displayScaleFactor
            samples: 9
            color: "#40000000"
            source: background
        }

        Rectangle {
            id: background

            anchors.fill: parent

            color: style.buttonBarBackgroundColor
            border {
                width: style.buttonBarBorderWidth
                color: style.buttonBarBorderColor
            }

            radius: width / 2

            MouseArea {
                anchors.fill: parent

                enabled: control.enabled
                hoverEnabled: enabled

                //acceptedButtons: Qt.NoButton

                onPositionChanged: {
                    fader.start();
                }

                onClicked: {
                    fader.start();
                }
            }
        }

        Fader {
            id: fader
        }
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        id: layout

        property int visibleItemsCount

        spacing: control.spacing

        onHeightChanged: {
            Qt.callLater(countVisible);
        }

        function countVisible() {
            var count = 0;

            for (var i = 0; i < children.length; i++) {
                if (children[i].visible) {
                    count ++;
                }
            }

            visibleItemsCount = count;
        }
    }

    //--------------------------------------------------------------------------
}

