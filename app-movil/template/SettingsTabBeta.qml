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

import "../Controls"
import "../Controls/Singletons"

SettingsTab {

    title: qsTr("Beta")
    description: qsTr("Configure beta features")
    icon: Icons.icon("beta-features-menu")

    //--------------------------------------------------------------------------

    property AppFeatures features: app.features

    property bool restart: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    Item {
        Component.onCompleted: {
            restart = false;
        }

        Component.onDestruction: {
            features.write();
        }

        //--------------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            AppText {
                Layout.fillWidth: true

                visible: restart
                text: qsTr("%1 must be restarted when beta features have been enabled or disabled.").arg(app.info.title)
                color: "#a80000"

                font {
                    pointSize: 16
                    bold: true
                }

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.portalBasemaps
                text: qsTr("Portal basemaps")

                onCheckedChanged: {
                    features.portalBasemaps = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.addIns
                text: qsTr("Add-Ins")

                onCheckedChanged: {
                    features.addIns = checked;
                    restart = true;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.asyncFormLoader
                text: qsTr("Asynchronous form initialization")
                visible: true

                onCheckedChanged: {
                    features.asyncFormLoader = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.listCache
                text: qsTr("Cache lists")
                visible: false

                onCheckedChanged: {
                    features.listCache = checked;
                    restart = true;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.useSharedTheme
                text: qsTr("Use <a href=\"%1\">shared theme</a>").arg("https://www.esri.com/arcgis-blog/products/sharing-collaboration/sharing-collaboration/introducing-shared-theme-a-new-app-styling-capability-in-arcgis-online/")
                visible: true

                onCheckedChanged: {
                    features.useSharedTheme = checked;
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
