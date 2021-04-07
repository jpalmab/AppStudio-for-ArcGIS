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
import ArcGIS.AppFramework.Notifications 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {

    title: qsTr("Accessibility")
    description: qsTr("Configure accessibility settings")
    icon: Icons.icon("person2")

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    Item {
        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: appSettings.boldText
                text: qsTr("Bold text and icons")

                onCheckedChanged: {
                    appSettings.boldText = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: appSettings.plainBackgrounds
                text: qsTr("Plain backgrounds")

                onCheckedChanged: {
                    appSettings.plainBackgrounds = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: appSettings.hapticFeedback
                text: qsTr("Haptic feedback")
                enabled: HapticFeedback.supported

                onCheckedChanged: {
                    appSettings.hapticFeedback = checked;
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
