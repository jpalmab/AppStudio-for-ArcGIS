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
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"
import "../Portal"

import "SurveyHelper.js" as Helper

Item {
    id: view

    //--------------------------------------------------------------------------

    property bool showLibraryIcon: true
    property ListModel mapPackages
    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    property bool debug: false

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            fill: parent
        }

        visible: mapPackages.count <= 0
        active: visible

        sourceComponent: ColumnLayout {
            AppText {
                Layout.fillWidth: true

                text: qsTr("No compatible maps found")

                font {
                    pointSize: 16
                }

                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            fill: parent
        }

        visible: mapPackages.count > 0
        active: visible

        sourceComponent: ScrollView {
            id: scrollView

            ListView {
                width: scrollView.availableWidth
                height: scrollView.availableHeight

                model: mapPackages

                spacing: AppFramework.displayScaleFactor * 5
                clip: true

                delegate: mapPackageDelegate
            }
        }
    }

    Component {
        id: mapPackageDelegate

        SwipeLayoutDelegate {
            id: delegate

            width: ListView.view.width

            Component.onCompleted: {
                if (Networking.isOnline) {
                    mapPackage.requestItemInfo();
                }
            }

            Image {
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth * 133/200

                source: thumbnailUrl
                fillMode: Image.PreserveAspectFit

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border {
                        width: 1
                        color: "#20000000"
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: -3 * AppFramework.displayScaleFactor
                    }

                    width: 30 * AppFramework.displayScaleFactor
                    height: width

                    radius: 3
                    color: accentColor
                    border {
                        width: 1
                        color: "white"
                    }

                    visible: storeInLibrary && showLibraryIcon

                    StyledImage {
                        id: libraryImage

                        anchors {
                            fill: parent
                            margins: 3
                        }

                        source: "images/maps-folder.png"
                        color: "white"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.name > "" ? mapPackage.name : mapPackage.itemId
                    font {
                        bold: true
                        pointSize: 14
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                }

                AppText {
                    id: descriptionText

                    Layout.fillWidth: true

                    text: mapPackage.description
                    font {
                        pointSize: 12
                    }
                    elide: Text.ElideRight
                    color: textColor
                    visible: text > ""

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            descriptionText.elide = descriptionText.elide == Text.ElideNone ? Text.ElideRight : Text.ElideNone
                        }
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    text: Helper.displaySize(mapPackage.localSize)
                    font {
                        pointSize: 12
                    }
                    color: textColor
                    visible: mapPackage.isLocal
                }

                HorizontalSeparator {
                    Layout.fillWidth: true
                    visible: mapPackage.canDownload
                }

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.updateAvailable
                          ? qsTr("Update available %1").arg(mapPackage.updateDate.toLocaleString(undefined, Locale.ShortFormat))
                          : qsTr("Update not required")
                    font {
                        pointSize: 12
                    }
                    color: textColor
                    visible: mapPackage.canDownload && mapPackage.isLocal
                }

                AppText {
                    Layout.fillWidth: true

                    text: Helper.displaySize(mapPackage.updateSize)
                    font {
                        pointSize: 12
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                    visible: mapPackage.canDownload && (mapPackage.updateAvailable || !mapPackage.isLocal)
                }

                AppText {
                    Layout.fillWidth: true

                    text: mapPackage.errorText
                    visible: text > ""
                    color: "red"
                    font {
                        bold: true
                    }
                }
            }

            StyledImageButton {
                Layout.preferredWidth: delegate.buttonSize
                Layout.preferredHeight: delegate.buttonSize

                visible: mapPackage.canDownload
                source: Icons.icon(mapPackage.isLocal ? "refresh" : "download")

                onClicked: {
                    progressPanel.title = qsTr("Downloading map package");
                    progressPanel.message = mapPackage.name;
                    progressPanel.open();

                    mapPackage.requestDownload();
                }
            }

            behindLayout: SwipeBehindLayout {
                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: debug

                    image {
                        source: Icons.bigIcon(portal.isPortal ? "portal" : "arcgis-online")
                    }

                    onClicked: {
                        var mapInfo = mapPackages.get(index);
                        console.log("mapInfo:", JSON.stringify(mapInfo, undefined, 2));

                        var url = portal.portalUrl + "/home/item.html?id=" + mapPackage.itemId;

                        console.log(url);
                        Qt.openUrlExternally(url);
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: debug && mapPackage.isLocal

                    image {
                        source: Icons.bigIcon("folder-open")
                    }

                    onClicked: {
                        var mapInfo = mapPackages.get(index);
                        console.log("mapInfo:", JSON.stringify(mapInfo, undefined, 2));

                        Qt.openUrlExternally(mapPackage.folder.url);
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }
                    backgroundColor: "tomato"

                    onClicked: {
                        confirmPanel.clear();
                        confirmPanel.icon = Icons.bigIcon("exclamation-mark-triangle");
                        confirmPanel.title = qsTr("Delete map package");
                        confirmPanel.text = qsTr("This action will delete the map package <b>%1</b> from this device.").arg(mapPackage.name);
                        confirmPanel.question = qsTr("Are you sure you want to delete the map package?");

                        confirmPanel.show(mapPackage.deleteLocal);
                    }
                }
            }

            MapPackage {
                id: mapPackage

                portal: app.portal
                info: mapPackages.get(index)
                mapPlugin: view.mapPlugin

                onProgressChanged: {
                    progressPanel.progressBar.value = progress;
                }

                onDownloaded: {
                    progressPanel.close();
                }

                onFailed: {
                    progressPanel.closeError(qsTr("Download map package error"));
                }

                Connections {
                    target: mapPackage.portal

                    onSignedInChanged: {
                        if (portal.signedIn) {
                            mapPackage.requestItemInfo();
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
