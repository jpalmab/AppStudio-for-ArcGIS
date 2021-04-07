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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

SettingsTab {

    title: qsTr("Units")
    description: qsTr("Configure measurement units")
    icon: "images/units.png"

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    ScrollView {
        id: scrollView

        clip: true

        padding: 10 * AppFramework.displayScaleFactor

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Flickable {
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            contentHeight: layout.height

            ColumnLayout {
                id: layout

                width: scrollView.availableWidth

                spacing: 10 * AppFramework.displayScaleFactor

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Length/Distance")
                    minorLabel: qsTr("Short lengths")
                    majorLabel: qsTr("Long lengths")
                    thresholdLabel: qsTr("Short to long lengths threshold")

                    minorUnitsModel: unitModels.linear
                    majorUnitsModel: unitModels.linear

                    collapsed: false
                }

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Area")

                    minorLabel: qsTr("Small areas")
                    majorLabel: qsTr("Large areas")
                    thresholdLabel: qsTr("Small to large area threshold")

                    minorUnitsModel: unitModels.area
                    majorUnitsModel: unitModels.area

                    collapsed: false
                }

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Height")

                    minorLabel: qsTr("Low heights")
                    majorLabel: qsTr("High heights")
                    thresholdLabel: qsTr("Low to high heights threshold")

                    minorUnitsModel: unitModels.linear
                    majorUnitsModel: unitModels.linear
                }

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Speed")

                    minorLabel: qsTr("Slow speeds")
                    majorLabel: qsTr("Fast speeds")
                    thresholdLabel: qsTr("Slow to fast speeds threshold")

                    minorUnitsModel: unitModels.speed
                    majorUnitsModel: unitModels.speed
                }

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Horizontal accuracy")

                    minorLabel: qsTr("High accuracy")
                    majorLabel: qsTr("Low accuracy")
                    thresholdLabel: qsTr("High to low accuracy threshold")

                    minorUnitsModel: unitModels.linear
                    majorUnitsModel: unitModels.linear
                }

                UnitsGroup {
                    Layout.fillWidth: true

                    groupLabel: qsTr("Vertical accuracy")

                    minorLabel: qsTr("High accuracy")
                    majorLabel: qsTr("Low accuracy")
                    thresholdLabel: qsTr("High to low accuracy threshold")

                    minorUnitsModel: unitModels.linear
                    majorUnitsModel: unitModels.linear
                }
            }
        }
        //----------------------------------------------------------------------

        UnitsModels {
            id: unitModels
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------
}
