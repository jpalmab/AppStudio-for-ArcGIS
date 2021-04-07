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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Portal"

Item {
    id: mapPackage

    //--------------------------------------------------------------------------

    property Portal portal
    property var info: null

    property alias itemId: packageItem.itemId
    property alias progress: packageItem.progress
    property alias folder: mapFolder
    property string name
    property string description
    property string packageName
    property string packageType
    readonly property string packageSuffix: kPackageSuffixes[packageType]

    property bool canDownload: Networking.isOnline && onlineAvailable
    property bool isLocal: localSize != 0
    property var localItemInfo
    property var localSize: 0
    property bool onlineAvailable
    property bool updateAvailable
    property date updateDate
    property var updateSize: 0
    property string errorText

    //--------------------------------------------------------------------------

    readonly property var kSupportedSpatialReferences: [
        "WGS_1984_Web_Mercator_Auxiliary_Sphere",
        "GCS_WGS_1984"
    ]

    readonly property string kSuffixItemInfo: ".iteminfo"
    readonly property string kSuffixMapTypeInfo: ".maptype"
    readonly property string kSuffixThumbnail: ".thumbnail"

    readonly property url kDefaultThumbnail: "images/map-thumbnail.png"

    //--------------------------------------------------------------------------

    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    readonly property bool isEnhancedMap: mapPlugin === app.appSettings.kPluginArcGISRuntime


    readonly property var kMapItemTypesBasic: [
        "Tile Package",
    ]

    readonly property var kMapItemTypesEnhanced: [
        "Tile Package",
        "Vector Tile Package",
        "Mobile Map Package"
    ]

    readonly property var kMapItemTypes: isEnhancedMap
                                         ? kMapItemTypesEnhanced
                                         : kMapItemTypesBasic

    readonly property var kPackageSuffixes: {
        "Tile Package": ".tpk",
        "Vector Tile Package": ".vtpk",
        "Mobile Map Package": ".mmpk"
    }

    //--------------------------------------------------------------------------

    signal downloaded()
    signal failed(var error)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("Package info:", JSON.stringify(info, undefined, 2));
    }

    //--------------------------------------------------------------------------

    onInfoChanged: {
        if (!info) {
            return;
        }

        var urlInfo = AppFramework.urlInfo(info.localUrl);
        var fileInfo = AppFramework.fileInfo(urlInfo.localFile);

        itemId = info.itemId;
        packageName = fileInfo.baseName;
        mapFolder.path = fileInfo.folder.path;

        if (info.name > "") {
            name = info.name;
        }

        if (info.description > "") {
            description = info.description;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapPackage, true)
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: mapFolder

        onPathChanged: {
            checkLocal();
        }
    }

    //--------------------------------------------------------------------------

    PortalItem {
        id: packageItem

        portal: mapPackage.portal

        onItemInfoDownloaded: {
            console.log(logCategory, "Online itemInfo:", JSON.stringify(itemInfo, undefined, 2));

            if (info.areaTitle > "") {
                itemInfo.title = info.areaTitle;
            }

            if (itemInfo.thumbnail > "") {
                info.thumbnailUrl = portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemId + "/info/" + itemInfo.thumbnail);
            } else {
                info.thumbnailUrl = kDefaultThumbnail;
            }

            updateInfo(itemInfo);

            updateAvailable = localItemInfo ? itemInfo.modified > localItemInfo.modified : false;
            updateDate = new Date(itemInfo.modified);
            updateSize = itemInfo.size;
            localItemInfo = itemInfo;

            onlineAvailable = kMapItemTypes.indexOf(itemInfo.type) >= 0;

            if (kMapItemTypes.indexOf(itemInfo.type) < 0) {
                errorText = qsTr("Unsupported type: %1").arg(itemInfo.type);
            } else if (kSupportedSpatialReferences.indexOf(itemInfo.spatialReference) < 0) {
                errorText = qsTr("Unsupported spatial reference: %1").arg(itemInfo.spatialReference);
            }

            checkLocal();
        }

        onThumbnailRequestComplete: {
            if (path !== null) {
                info.thumbnailUrl = AppFramework.fileInfo(path).url;
            }
            download(mapFolder.filePath(packageName + packageSuffix));
        }

        onDownloaded: {
            var mapTypeInfo = {
                "style": info.style,
                "name": info.name,
                "description": info.description > "" ? info.description : "",
                "mobile": info.mobile,
                "night": info.night,
                "copyrightText": info.copyrightText
            };


            mapFolder.writeJsonFile(packageName + kSuffixItemInfo, localItemInfo);

            var mapTypeFileName = packageName + kSuffixMapTypeInfo;
            if (removeEmpty(mapTypeInfo)) {
                mapFolder.writeJsonFile(mapTypeFileName, mapTypeInfo);
            } else {
                console.log(logCategory, "Removing empty maptype info:", mapTypeFileName);
                mapFolder.removeFile(mapTypeFileName);
            }

            isLocal = true;
            updateAvailable = false;
            localSize = mapFolder.fileInfo(packageName + packageSuffix).size;

            mapPackage.downloaded();
        }

        onFailed: {
            mapPackage.failed(error);
        }

        function removeEmpty(o) {
            var keys = Object.keys(o);

            keys.forEach(function(key) {
                var value = o[key]
                if (typeof value === "undefined" || value === null || value === "" ) {
                    // delete o[key];
                    o[key] = undefined;
                }
            });

            return Object.keys(o).length > 0;
        }
    }

    //--------------------------------------------------------------------------

    function requestItemInfo() {
        packageItem.requestInfo();
    }

    //--------------------------------------------------------------------------

    function requestDownload() {
        mapFolder.makeFolder();

        if (!packageItem.downloadThumbnail(mapFolder.filePath(packageName + kSuffixThumbnail))) {
            packageItem.download(mapFolder.filePath(packageName + packageSuffix));
        }
    }

    //--------------------------------------------------------------------------

    function checkLocal() {

        //console.log(logCategory, arguments.callee.name, "checkLocal:", mapFolder.path, packageName);

        var itemInfoFileName = packageName + kSuffixItemInfo;

        if (mapFolder.fileExists(itemInfoFileName)) {
            localItemInfo = mapFolder.readJsonFile(itemInfoFileName);

            //console.log(logCategory, arguments.callee.name, "Local itemInfo:", JSON.stringify(localItemInfo, undefined, 2));

            updateInfo(localItemInfo);
        }

        var thumbnailFileName = packageName + kSuffixThumbnail;
        if (mapFolder.fileExists(thumbnailFileName)) {
            info.thumbnailUrl = mapFolder.fileUrl(thumbnailFileName).toString();
            //console.log(logCategory, arguments.callee.name, "local thumbnail:", info.thumbnailUrl);
        }

        if (mapFolder.fileExists(packageName + packageSuffix)) {
            localSize = mapFolder.fileInfo(packageName + packageSuffix).size;
        }
    }

    //--------------------------------------------------------------------------

    function updateInfo(itemInfo) {
        packageType = itemInfo.type;
        name = itemInfo.title;
        description = itemInfo.description > "" ? info.description : "";

        console.log(logCategory, arguments.callee.name, "info:", JSON.stringify(info, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function deleteLocal() {
        console.log(logCategory, arguments.callee.name, "path:", mapFolder.path);

        var result = deleteLocalFile(packageSuffix);
        result = result && deleteLocalFile(kSuffixItemInfo);
        result = result && deleteLocalFile(kSuffixThumbnail);
        result = result && deleteLocalFile(kSuffixMapTypeInfo);

        if (result) {
            localSize = 0;
        } else {
            console.error(logCategory, arguments.callee.name, "Error removing:", mapFolder.filePath(packageName));
        }
    }

    //--------------------------------------------------------------------------

    function deleteLocalFile(suffix) {
        var result = mapFolder.removeFile(packageName + suffix);
        if (!result) {
            console.warn(logCategory, arguments.callee.name, "Error deleting:", mapFolder.filePath(packageName + suffix))
        }

        return result;
    }

    //--------------------------------------------------------------------------
}
