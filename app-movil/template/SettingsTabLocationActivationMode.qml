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

import QtQuick 2.9
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

SettingsTab {

    title: qsTr("Connection Mode")
    icon: "images/connection_mode.png"
    description: ""

    //--------------------------------------------------------------------------

    property bool initialized

    readonly property bool isTheActiveSensor: deviceName === appSettings.kInternalPositionSourceName || controller.currentName === deviceName
    readonly property string activationModeZeroLabel: qsTr("As needed")
    readonly property string activationModeOneLabel: qsTr("While a survey is open")
    readonly property string activationModeTwoLabel: qsTr("When the app is open")

    signal changed()

    //--------------------------------------------------------------------------

    Item {

        id: _item

        Accessible.role: Accessible.Pane

        Component.onCompleted: {
            initialized = true;
        }

        Component.onDestruction: {
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Mode")

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("The connection mode determines when your location sensor is activated. This may affect accuracy, performance, and battery life. Refer to the documentation for more information.")
                }

                AppRadioButton {
                    id: asNeededButton

                    Layout.fillWidth: true

                    text: activationModeZeroLabel

                    checked: appSettings.knownDevices[deviceName].activationMode === appSettings.kActivationModeAsNeeded

                    onCheckedChanged: {
                        if (initialized && !appSettings.updating && checked) {
                            appSettings.knownDevices[deviceName].activationMode = appSettings.kActivationModeAsNeeded;
                            if (isTheActiveSensor) {
                                appSettings.locationSensorActivationMode = appSettings.kActivationModeAsNeeded;
                            }
                        }
                        changed();
                    }
                }

                AppRadioButton {
                    id: inSurveyButton

                    Layout.fillWidth: true

                    text: activationModeOneLabel
                    checked: appSettings.knownDevices[deviceName].activationMode === appSettings.kActivationModeInSurvey

                    onCheckedChanged: {
                        if (initialized && !appSettings.updating && checked) {
                            appSettings.knownDevices[deviceName].activationMode = appSettings.kActivationModeInSurvey;
                            if (isTheActiveSensor) {
                                appSettings.locationSensorActivationMode = appSettings.kActivationModeInSurvey;
                            }
                        }
                        changed();
                    }
                }

                AppRadioButton {
                    id: alwaysRunningButton

                    Layout.fillWidth: true

                    text: activationModeTwoLabel
                    checked: appSettings.knownDevices[deviceName].activationMode === appSettings.kActivationModeAlways

                    onCheckedChanged: {
                        if (initialized && !appSettings.updating && checked) {
                            appSettings.knownDevices[deviceName].activationMode = appSettings.kActivationModeAlways;
                            if (isTheActiveSensor) {
                                appSettings.locationSensorActivationMode = appSettings.kActivationModeAlways;
                            }

                        }
                        changed();
                    }
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
