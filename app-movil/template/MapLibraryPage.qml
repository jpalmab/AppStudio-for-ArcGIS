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
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Platform 1.0

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property url defaultMapThumbnail: "images/map-thumbnail.png"

    property bool debug: false

    //--------------------------------------------------------------------------

    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    readonly property bool isEnhancedMap: mapPlugin === app.appSettings.kPluginArcGISRuntime

    readonly property var kPackageSuffixesBasic: ["tpk"]
    readonly property var kPackageSuffixesEnhanced: ["tpk", "vtpk", "mmpk"]
    readonly property var kPackageSuffixes: isEnhancedMap ? kPackageSuffixesEnhanced : kPackageSuffixesBasic

    //--------------------------------------------------------------------------

    title: qsTr("Map Library")

    //--------------------------------------------------------------------------

    actionButton {
        //        visible: Networking.isOnline
        //        source: "images/cloud-download.png"

        //        onClicked: {
        //            showDownloadPage();
        //        }

        visible: false

        menu: Menu {
            MenuItem {
                property bool noColorOverlay: portal.signedIn

                visible: portal.signedIn || Networking.isOnline
                enabled: visible

                text: portal.signedIn ? qsTr("Sign out %1").arg(portal.user ? portal.user.fullName : "") : qsTr("Sign in")
                iconSource: portal.signedIn ? portal.userThumbnailUrl : "images/user.png"

                onTriggered: {
                    if (portal.signedIn) {
                        portal.signOut();
                    } else {
                        portal.signIn(undefined, true);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        findMaps();
    }

    //--------------------------------------------------------------------------

    function findMaps() {

        mapPackages.clear();

        var paths = app.mapLibraryPaths.split(";")

        if (debug) {
            console.log(logCategory, arguments.callee.name, "paths:", JSON.stringify(paths));
        }

        paths.forEach(function (path) {
            path = path.trim();
            if (path > "") {

                var mapLibrary = AppFramework.fileFolder(path);

                if (debug) {
                    console.log(logCategory, arguments.callee.name, "path:", mapLibrary.path);
                }

                kPackageSuffixes.forEach(function (suffix) {
                    var fileNames = mapLibrary.fileNames("*." + suffix);

                    if (debug) {
                        console.log(logCategory, arguments.callee.name, "suffix:", suffix, "fileNames:", JSON.stringify(fileNames, undefined, 2));
                    }

                    fileNames.forEach(function(fileName) {
                        addMap(mapLibrary, fileName);
                    });
                });
            }
        });
    }

    //--------------------------------------------------------------------------

    function addMap(mapLibrary, fileName) {

        var fileInfo = mapLibrary.fileInfo(fileName);

        var mapSource = {
        };

        var packageInfo = {
            "areaTitle": "",
            "name": fileInfo.baseName,
            "description": fileName,
            "itemId": fileInfo.baseName,
            "portalUrl": "http://www.arcgis.com",
            "localUrl": mapLibrary.fileUrl(fileName).toString(),
            "thumbnailUrl": defaultMapThumbnail.toString(),
            "mapSource": mapSource,
            "storeInLibrary": true
        };

        mapPackages.append(packageInfo);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "packageInfo:", JSON.stringify(packageInfo, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    contentItem: MapsView {
        id: mapsView

        showLibraryIcon: false
        mapPackages: ListModel {
            id: mapPackages
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        onVisibleChanged: {
            Platform.stayAwake = visible;
        }
    }

    //--------------------------------------------------------------------------

    ConfirmPanel {
        id: confirmPanel
    }

    //--------------------------------------------------------------------------
}
