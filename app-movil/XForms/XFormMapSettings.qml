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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS


Item {
    id: mapSettings

    //--------------------------------------------------------------------------

    property string provider: app.mapPlugin > "" ? app.mapPlugin : kPluginAppStudio
    property string name
    property real zoomLevel: defaultZoomLevel
    property real latitude: kDefaultLatitude
    property real longitude: kDefaultLongitude
    property real previewZoomLevel: defaultPreviewZoomLevel
    property string previewCoordinateFormat: "dm"
    property real positionZoomLevel: zoomLevel
    property string coordinateFormat: "dmss"
    property var mapSources: []
    property bool appendMapTypes: false//true
    property bool includeDefaultMaps: true
    property bool sortMapTypes: false
    property bool includeLibrary: true
    property string libraryPath: "~/ArcGIS/My Surveys/Maps"
    property bool mobileOnly: true
    property url defaultMapConfig: "XFormMapSettings-%1.json".arg(provider)
    property bool debug: false
    property int horizontalAccuracyPrecisionLow: 1
    property int horizontalAccuracyPrecisionHigh: 2
    property int verticalAccuracyPrecisionLow: 1
    property int verticalAccuracyPrecisionHigh: 2

    property var externalMapSources

    property alias logCategory: logCategory

    //--------------------------------------------------------------------------

    readonly property real defaultZoomLevel: 15
    readonly property real defaultPreviewZoomLevel: 14

    readonly property real kDefaultLatitude: 34.056223110283184
    readonly property real kDefaultLongitude: -117.19532583406398

    //--------------------------------------------------------------------------

    readonly property string kPluginAppStudio: "AppStudio"
    readonly property string kPluginArcGISRuntime: "ArcGISRuntime"

    readonly property bool isEnhancedMap: provider === kPluginArcGISRuntime

    readonly property var kPackageSuffixesBasic: ["tpk"]
    readonly property var kPackageSuffixesEnhanced: ["tpk", "vtpk", "mmpk"]
    readonly property var kPackageSuffixes: isEnhancedMap ? kPackageSuffixesEnhanced : kPackageSuffixesBasic

    readonly property var kThumbnailSuffixes: ["thumbnail", "png", "jpg"]

    //--------------------------------------------------------------------------

    signal refreshed()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "mapPlugin:", provider);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapSettings, true)
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: thumbnailsFolder

        url: "mapThumbnails"
    }

    //--------------------------------------------------------------------------

    function selectMapType(map, mapName) {
        var mapType;

        if (mapName > "") {
            mapType = findMapType(map, mapName);
        }

        if (!mapType && name > "") {
            mapType = findMapType(map, name);
        }

        if (mapType) {
            map.activeMapType = mapType;
        }

        return !!mapType;
    }

    //--------------------------------------------------------------------------

    function findMapType(map, name) {
        if (!name) {
            return;
        }

        for (var i = 0; i < map.supportedMapTypes.length; i++) {
            var mapType = map.supportedMapTypes[i];

            if (mapType.name === name) {
                return mapType;
            }
        }
    }

    //--------------------------------------------------------------------------

    function refresh(surveyPath, mapInfo) {
        if (!mapInfo) {
            mapInfo = {};
        }

        console.log(logCategory, arguments.callee.name, "Refreshing map settings surveyPath:", surveyPath, "info:", JSON.stringify(mapInfo, undefined, 2));

        function isNumber(value) {
            return isFinite(Number(value));
        }

        function isBool(value) {
            return typeof value === "boolean";
        }

        if (mapInfo.coordinateFormat > "") {
            coordinateFormat = mapInfo.coordinateFormat;
        }

        // includeDefaultMaps = XFormJS.toBoolean(mapInfo.includeDefaultMaps, true);

        var defaultType = mapInfo.defaultType;
        if (defaultType) {
            if (defaultType.name > "") {
                name = defaultType.name;
            }
        }

        var homeInfo = mapInfo.home;
        if (homeInfo) {
            if (isNumber(homeInfo.latitude) && isNumber(homeInfo.longitude)) {
                var homeCoordinate = QtPositioning.coordinate(homeInfo.latitude, homeInfo.longitude);
                if (homeCoordinate.isValid) {
                    latitude = homeCoordinate.latitude;
                    longitude = homeCoordinate.longitude;
                }
            }

            if (isNumber(homeInfo.zoomLevel)) {
                var zoom = Number(homeInfo.zoomLevel);
                if (zoom > 0) {
                    zoomLevel = zoom;
                } else {
                    zoomLevel = defaultZoomLevel;
                }
            }
        }

        var previewInfo = mapInfo.preview;
        if (previewInfo) {
            if (isNumber(previewInfo.zoomLevel)) {
                zoom = Number(previewInfo.zoomLevel);
                if (zoom > 0) {
                    previewZoomLevel = zoom;
                } else {
                    previewZoomLevel = defaultPreviewZoomLevel;
                }
            }

            if (previewInfo.coordinateFormat > "") {
                previewCoordinateFormat = previewInfo.coordinateFormat;
            }
        }

        if (!Array.isArray(mapSources)) {
            mapSources = [];
        }

        if (includeDefaultMaps) {
            addDefaultMapSources();
        }

        var mapTypes = mapInfo.mapTypes;
        if (mapTypes) {
            if (isBool(mapTypes.append)) {
                //appendMapTypes = mapTypes.append;
                if (!mapTypes.append) {
                    mapSources = [];
                }
            }

            if (isBool(mapTypes.sort)) {
                sortMapTypes = mapTypes.sort;
            }

            if (isBool(mapTypes.includeLibrary)) {
                includeLibrary = mapTypes.includeLibrary;
            }

            if (Array.isArray(mapTypes.mapSources)) {
                mapTypes.mapSources.forEach(function (mapSource) {
                    var urlInfo = AppFramework.urlInfo(mapSource.url);

                    if (urlInfo.fileName === "item.html") {
                        console.log("Map package item source:", JSON.stringify(mapSource, undefined, 2));
                    } else {
                        mapSources.push(mapSource);
                    }
                });
            }
        }

        var surveyPathInfo = AppFramework.fileInfo(surveyPath);
        var surveyFolder = AppFramework.fileFolder(surveyPath);

        var mapFolderNames = [
                    surveyPathInfo.baseName + "-media",
                    "media",
                    "Maps",
                    "maps"
                ];

        if (debug) {
            console.log(logCategory, arguments.callee.name, "Map folders:", JSON.stringify(mapFolderNames, undefined, 2));
        }

        mapFolderNames.forEach(function (folderName) {
            var mapsFolder = surveyFolder.folder(folderName);

            if (mapsFolder.exists) {
                /*
                var privateSource = {
                    "url": mapsFolder.url.toString(),
                    "recursive": true
                };

                mapSources.push(privateSource);

                console.log(logCategory, arguments.callee.name, "Adding private maps folder:", JSON.stringify(privateSource, undefined, 2));
                */

                addFolder(mapsFolder.url);
            }
        });


        if (includeLibrary && libraryPath > "") {
            var paths = libraryPath.split(";");

            if (debug) {
                console.log(logCategory, arguments.callee.name, "library paths:", JSON.stringify(paths));
            }

            paths.forEach(function (path) {
                path = path.trim();
                if (path > "") {
                    var libraryFolder = AppFramework.fileFolder(path);

                    if (libraryFolder.exists) {
                        addFolder(libraryFolder.url);
                    }

                    /*
                    var librarySource = {
                        "url": libraryFolder.url.toString(),
                        "recursive": true
                    };

                    mapSources.push(librarySource);

                    console.log(logCategory, arguments.callee.name, "Adding maps library folder:", JSON.stringify(librarySource, undefined, 2));
                    */
                }
            });
        }

        if (Array.isArray(externalMapSources)) {
            externalMapSources.forEach(function (mapSource) {
                mapSources.push(mapSource);
            });
        }

        mapSources.forEach(function (mapSource) {
            if (!mapSource.thumbnailUrl) {
                mapSource.thumbnailUrl = thumbnailsFolder.fileUrl("default.png");
            }
        });
    }

    //--------------------------------------------------------------------------

    function addDefaultMapSources() {
        var fileInfo = AppFramework.fileInfo(defaultMapConfig);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "Reading default map sources:", defaultMapConfig);
        }

        var config = fileInfo.folder.readJsonFile(fileInfo.fileName);

        if (Array.isArray(config.mapSources)) {
            config.mapSources.forEach(function (mapSource, index) {
                mapSource.thumbnailUrl = thumbnailsFolder.fileUrl("mapType-%1.png".arg(index));
            });

            mapSources = mapSources.concat(config.mapSources);
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function addFolder(url) {
        var mapFolder = AppFramework.fileFolder(url);

        kPackageSuffixes.forEach(function (suffix) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "suffix:", suffix, "mapFolder:", mapFolder.path)
            }

            var fileNames = mapFolder.fileNames("*." + suffix);

            fileNames.forEach(function(fileName) {
                addMap(mapFolder, fileName);
            });
        });
    }

    //--------------------------------------------------------------------------

    function addMap(mapFolder, fileName) {

        var fileInfo = mapFolder.fileInfo(fileName);
        var url = fileInfo.url.toString();



        function checkUrl(mapSource) {
            return mapSource.url.toLowerCase() === url.toLowerCase();
        }

        if (mapSources.find(checkUrl)) {
            console.log(logCategory, arguments.callee.name, "Found mapSource url:", url);
            return;
        }

        var itemInfo = mapFolder.readJsonFile(fileInfo.baseName + ".iteminfo");
        var name = itemInfo.title || fileInfo.fileName;
        var description = itemInfo.description || fileInfo.fileName;
        var copyrightText = itemInfo.accessInformation || "";

        var mapSource = {
            "style": "CustomMap",
            "name": name,
            "description": description,
            "mobile": true,
            "night": false,
            "url": url,
            "copyrightText": copyrightText
        };

        kThumbnailSuffixes.forEach(function (suffix) {
            var thumbnailInfo = mapFolder.fileInfo(fileInfo.baseName + "." + suffix);

            if (thumbnailInfo.exists) {
                mapSource.thumbnailUrl = thumbnailInfo.url;
            }
        });

        mapSources.push(mapSource);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------
}
