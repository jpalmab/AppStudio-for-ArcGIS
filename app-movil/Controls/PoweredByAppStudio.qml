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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

Control {
    id: control

    //--------------------------------------------------------------------------

    property url productUrl: "https://appstudio.arcgis.com"

    //--------------------------------------------------------------------------

    signal pressAndHold

    //--------------------------------------------------------------------------

    padding: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Item {
        MouseArea {
            anchors.fill: parent

            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Qt.openUrlExternally(productUrl);
            }

            onPressAndHold: {
                control.pressAndHold()
            }
        }
    }

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        width: control.availableWidth

        Image {
            Layout.preferredHeight: 40 * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            source: "images/AppStudio_for_ArcGIS_128.png"
            fillMode: Image.PreserveAspectFit
        }

        Text {
            Layout.fillWidth: true

            font {
                family: control.font.family
                pointSize: 15
            }

            text: qsTr("Powered by <b>AppStudio for ArcGIS</b>")
            color: "#303030"

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }

    //--------------------------------------------------------------------------
}
