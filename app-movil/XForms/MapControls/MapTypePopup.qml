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
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls"
import "../../Controls/Singletons"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property var mapType
    property string token // TODO Should be removed once Image source authentication is handled

    //--------------------------------------------------------------------------

    width: Math.min(parent.width * 0.95, 250 * AppFramework.displayScaleFactor)

    contentHeight: 250 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    contentItem: ScrollView {
        id: scrollView

        padding: 10 * AppFramework.displayScaleFactor
        clip: true

        contentWidth: availableWidth

        ColumnLayout {

            width: scrollView.availableWidth
            spacing: 5 * AppFramework.displayScaleFactor

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth * 133/200

                source: mapType.metadata.thumbnailUrl
                fillMode: Image.PreserveAspectFit

                Rectangle {
                    anchors {
                        fill: parent
                        margins: -1 * AppFramework.displayScaleFactor
                    }

                    color: "transparent"
                    border {
                        color: "#80000000"
                        width: 1 * AppFramework.displayScaleFactor
                    }
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: mapType.name

                font {
                    pointSize: 18
                    bold: true
                }

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            XFormText {
                Layout.fillWidth: true

                text: mapType.description
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                onLinkActivated: {
                    Qt.openUrlExternally(link);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
