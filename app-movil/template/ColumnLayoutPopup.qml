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
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"

AppPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    default property alias layoutItems: layout.data

    property alias layout: layout
    property alias title: titleText.text
    property alias titleItem: titleText
    property alias titleSeparator: titleSeparator
    property alias icon: iconImage

    //--------------------------------------------------------------------------

    signal titleClicked()
    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    contentHeight: layout.height

    contentItem: Item {
        width: popup.availableWidth

        ColumnLayout {
            id: layout

            width: parent.width
            spacing: 5 * AppFramework.displayScaleFactor

            StyledImage {
                id: iconImage

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                visible: source > ""
            }

            Text {
                id: titleText

                Layout.fillWidth: true

                visible: text.length > 0

                font {
                    family: popup.font.family
                    pointSize: 16
                    bold: true
                }

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        titleClicked();
                    }

                    onPressAndHold: {
                        titlePressAndHold();
                    }
                }
            }

            Rectangle {
                id: titleSeparator

                Layout.fillWidth: true

                visible: titleText.visible
                height: 1 * AppFramework.displayScaleFactor
                color: "#40000000"
            }
        }
    }
    
    //--------------------------------------------------------------------------
}
