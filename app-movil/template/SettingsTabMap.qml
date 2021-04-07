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
import QtQuick.Dialogs 1.2
import QtLocation 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"

SettingsTab {

    title: qsTr("Map")
    description: qsTr("Manage map settings")
    icon: Icons.bigIcon("map")

    //--------------------------------------------------------------------------

    readonly property string kFolderSeparator: ";"
    readonly property bool canModifyMapLibrary: Qt.platform.os !== "ios"

    //--------------------------------------------------------------------------

    property bool showMapPlugins: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        showMapPlugins = true;
    }

    //--------------------------------------------------------------------------

    Item {
        //----------------------------------------------------------------------

        property string mapFoldersText: mapLibraryTextField.text.trim()
        property var mapFolderNames: []

        //----------------------------------------------------------------------

        Component.onDestruction: {
            updateSettings();
        }

        //----------------------------------------------------------------------

        onMapFoldersTextChanged: {
            mapFolderNames = mapFoldersText.split(kFolderSeparator).filter(function (name) {
                return name && name.trim() > "";
            });
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 20 * AppFramework.displayScaleFactor

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                visible: !showMapPlugins

                title: qsTr("Map types")

                AppRadioButton {
                    Layout.fillWidth: true

                    text: qsTr("Basic")
                    checked: appSettings.mapPlugin === appSettings.kPluginAppStudio

                    font {
                        pointSize: 13
                    }

                    onClicked: {
                        appSettings.mapPlugin = appSettings.kPluginAppStudio;
                    }
                }

                AppRadioButton {
                    Layout.fillWidth: true

                    text: qsTr("Standard (Beta)")
                    checked: appSettings.mapPlugin === appSettings.kPluginArcGISRuntime

                    font {
                        pointSize: 13
                    }

                    onClicked: {
                        appSettings.mapPlugin = appSettings.kPluginArcGISRuntime;
                    }
                }
            }

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                visible: showMapPlugins

                title: "Map plugin"

                ComboBox {
                    id: mapPluginComboBox

                    Layout.fillWidth: true

                    property Plugin plugin: Plugin {}

                    model: plugin.availableServiceProviders

                    Component.onCompleted: {
                        currentIndex = model.indexOf(appSettings.mapPlugin);

                        popup.font = font;
                    }

                    onActivated: {
                        appSettings.mapPlugin = currentText;
                    }

                    font {
                        family: app.fontFamily
                        pointSize: 15
                    }
                }
            }

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Map library")

                ColumnLayout {
                    Layout.fillWidth: true

                    visible: canModifyMapLibrary

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("Folders: %1").arg(mapFolderNames.length)

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                        MouseArea {
                            anchors.fill: parent

                            onPressAndHold: {
                                mapFolderNames.forEach(function (name) {
                                    var folder = AppFramework.fileFolder(name);
                                    console.log("Map folder:", folder.path, "exists:", folder.exists);
                                    if (folder.exists) {
                                        Qt.openUrlExternally(folder.url);
                                    }
                                });
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        AppTextField {
                            id: mapLibraryTextField

                            Layout.fillWidth: true

                            text: appSettings.mapLibraryPaths
                        }

                        StyledImageButton {
                            Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                            Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                            source: Icons.icon("folder-plus")
                            color: app.textColor

                            onClicked: {
                                if (mapFolderNames.length > 0) {
                                    var folder = AppFramework.fileFolder(mapFolderNames[0]);
                                    console.log("library:", folder.url);
                                    mapLibraryDialog.folder = folder.url;
                                } else {
                                    mapLibraryDialog.folder = mapLibraryDialog.shortcuts.home;
                                }

                                mapLibraryDialog.open();
                            }

                            onPressAndHold: {
                                storageComboBox.visible = !storageComboBox.visible;
                            }
                        }
                    }

                    ComboBox {
                        id: storageComboBox

                        Layout.fillWidth: true

                        visible: false
                        model: storageInfo.mountedVolumes
                        textRole: "displayName"

                        onActivated: {
                            if (mapLibraryTextField.text.trim() > "") {
                                mapLibraryTextField.text += kFolderSeparator;
                            }

                            mapLibraryTextField.text += storageInfo.mountedVolumes[index].folder.path;
                        }

                        Component.onCompleted: {
                            currentIndex = -1;
                        }

                        StorageInfo {
                            id: storageInfo
                        }
                    }
                }

                AppButton {
                    Layout.fillWidth: true

                    text: qsTr("View map library")

                    onClicked: {
                        if (Networking.isOnline) {
                            showSignInOrMapsPage();
                        } else {
                            showMapsPage();
                        }
                    }

                    function showSignInOrMapsPage() {
                        portal.signInAction(qsTr("Please sign in to manage your map library"), showMapsPage);
                    }

                    function showMapsPage() {
                        updateSettings();
                        app.mainStackView.push(mapLibraryPage);
                    }
                }
            }

            //------------------------------------------------------------------

            Item {
                Layout.fillHeight: true
            }
        }

        //----------------------------------------------------------------------

        FileDialog {
            id: mapLibraryDialog

            title: qsTr("Map Library Folder")
            selectFolder: true
            selectExisting: true

            onAccepted: {
                var fileInfo = AppFramework.fileInfo(folder);

                var folders = mapLibraryTextField.text.trim();
                if (folders > "") {
                    folders += kFolderSeparator + fileInfo.filePath;
                } else {
                    folders = fileInfo.filePath;
                }

                mapLibraryTextField.text = folders;
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: mapLibraryPage

            MapLibraryPage {
            }
        }

        //----------------------------------------------------------------------

        function updateSettings() {
            if (canModifyMapLibrary) {
                var paths = mapLibraryTextField.text.trim();

                if (paths.length <= 0) {
                    paths = appSettings.kDefaultMapLibraryPath;
                }

                appSettings.mapLibraryPaths = paths;
            }
        }

        //----------------------------------------------------------------------
    }
}
