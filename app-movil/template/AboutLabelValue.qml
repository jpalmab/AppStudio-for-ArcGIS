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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

RowLayout {
    id: labelValue

    //--------------------------------------------------------------------------

    Layout.fillWidth: true

    //--------------------------------------------------------------------------

    property alias label: labelText.text
    property alias value: valueText.text
    property alias font: valueText.font
    property alias color: labelText.color
    property alias valueColor: valueText.color

    //--------------------------------------------------------------------------

    signal clicked
    signal pressAndHold

    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    AppText {
        id: labelText

        font {
            pointSize: valueText.font.pointSize
            bold: !valueText.font.bold
        }

        text: "Label"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                labelValue.clicked();
            }

            onPressAndHold: {
                labelValue.pressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------

    AppText {
        id: valueText

        Layout.fillWidth: true

        font {
            pointSize: 9
            bold: true
        }

        color: labelText.color

        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 1
        text: "-"

        onLinkActivated: {
            Qt.openUrlExternally(link);
        }
    }

    //--------------------------------------------------------------------------
}
