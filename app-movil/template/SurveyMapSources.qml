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

import "../XForms"
import "../Portal"

Item {
    id: surveyMapSources

    //--------------------------------------------------------------------------

    property Portal portal
    property string itemId

    property string filePath
    property FileInfo fileInfo: AppFramework.fileInfo(filePath)

    property var mapSources: []
    property bool cached: false
    property bool sort: true
    property var onlineMapSources: []
    property bool includePortalBasemaps: false

    property bool busy: false

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kFileName: ".cache.json"

    //--------------------------------------------------------------------------

    property string kTypeMapService: "Map Service"

    property var kMapItemTypesBasic: [
        kTypeMapService
    ]

    property var kMapItemTypesStandard: [
        kTypeMapService,
        "Web Map",
        "Image Service",
        "Vector Tile Service",
        "WMTS",
    ]

    property var kMapSourceTypes: {
        "Map Service": "TiledLayer",
        "Web Map": "Webmap",
        "Image Service": "",
        "Vector Tile Service": "VectorTiledLayer",
        "WMTS": "WMTSLayer",
    }

    //--------------------------------------------------------------------------

    property string mapPlugin: app.mapPlugin > "" ? app.mapPlugin : app.appSettings.kDefaultMapPlugin

    readonly property bool isBasicMap: mapPlugin !== app.appSettings.kPluginArcGISRuntime

    readonly property var kPackageSuffixesBasic: ["tpk"]
    readonly property var kPackageSuffixesStandard: ["tpk", "vtpk", "mmpk"]

    readonly property url kDefaultThumbnail: "../XForms/mapThumbnails/default.png"

    //--------------------------------------------------------------------------

    readonly property var kMapItemTypes: isBasicMap ? kMapItemTypesBasic : kMapItemTypesStandard
    readonly property var kPackageSuffixes: isBasicMap ? kPackageSuffixesBasic : kPackageSuffixesStandard

    //--------------------------------------------------------------------------

    signal finished()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "filePath:", filePath);

        readMapSources();
    }

    //--------------------------------------------------------------------------

    function refresh() {
        if (!(portal && Networking.isOnline)) {
            return;
        }

        console.log(logCategory, arguments.callee.name);

        if (busy) {
            console.error(logCategory, arguments.callee.name, "Previous refresh in progress");
            console.trace();
        }

        busy = true;

        onlineMapSources = [];
        var requestsPromises = [];

        function addRequest(promise) {
            if (promise) {
                requestsPromises.push(promise);
            }
        }

        if (includePortalBasemaps) {
            addRequest(refreshPortalBasemaps());
        }

        if (itemId > "") {
            addRequest(refreshRelatedContent(itemId));
        }

        Promise.all(requestsPromises)
        .then(refreshFinished)
        .catch(refreshFailed);
    }

    //--------------------------------------------------------------------------

    function refreshPortalBasemaps() {
        var info = portal.info;
        if (!portal.info) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "basemapGalleryGroupQuery:", info.basemapGalleryGroupQuery);
        console.log(logCategory, arguments.callee.name, "useVectorBasemaps:", info.useVectorBasemaps, "vectorBasemapGalleryGroupQuery:", info.vectorBasemapGalleryGroupQuery);

        if (info.useVectorBasemaps && info.vectorBasemapGalleryGroupQuery > "") {
            return portalContentRequest.start(info.vectorBasemapGalleryGroupQuery);
        } else if (info.basemapGalleryGroupQuery > "") {
            return portalContentRequest.start(info.basemapGalleryGroupQuery);
        }
    }

    //--------------------------------------------------------------------------

    function refreshRelatedContent(itemId) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemId:", itemId);
        }

        return relatedContentRequest.start(itemId);
    }

    //--------------------------------------------------------------------------

    function refreshFinished() {
        console.log(logCategory, arguments.callee.name);

        if (sort) {
            mapSources = onlineMapSources.sort(function (a, b) {
                return a.name > b.name ? 1 : a.name < b.name ? -1 : 0;
            });
        } else {
            mapSources = onlineMapSources;
        }

        cached = false;
        saveMapSources();
        busy = false;

        finished();
    }

    //--------------------------------------------------------------------------

    function refreshFailed() {
        console.error(logCategory, arguments.callee.name);

        busy = false;
    }

    //--------------------------------------------------------------------------

    function readMapSources() {
        var cache = fileInfo.folder.readJsonFile(fileInfo.fileName);

        mapSources = Array.isArray(cache.mapSources)
                ? cache.mapSources
                : [];

        cached = true;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }

        console.log(logCategory, arguments.callee.name, mapSources.length, "cached map sources file:", fileInfo.filePath);
    }

    //--------------------------------------------------------------------------

    function saveMapSources() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSources:", JSON.stringify(mapSources, undefined, 2));
        }

        console.log(logCategory, arguments.callee.name, mapSources.length, "map sources file:", fileInfo.filePath);

        var relatedContent = {
            mapSources: mapSources
        }

        fileInfo.folder.writeJsonFile(fileInfo.fileName, relatedContent);
    }

    //--------------------------------------------------------------------------

    function addOnlineMapSource(itemInfo) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemInfo:", JSON.stringify(itemInfo, undefined, 2));
        }

        if (kMapItemTypes.indexOf(itemInfo.type) < 0) {
            console.warn(logCategory, arguments.callee.name, "type:", itemInfo.type, "title:", itemInfo.title, "not supported by plugin:", mapPlugin);
            return;
        }

        var sourceType = kMapSourceTypes[itemInfo.type];
        if (!sourceType) {
            console.warn(logCategory, arguments.callee.name, "type:", itemInfo.type, "not suppported");
            return;
        }

        var itemUrl = portal.portalUrl + "/home/item.html?id=%1".arg(itemInfo.id);
        var url = itemUrl;

        if (itemInfo.type === kTypeMapService) {
            url = itemInfo.url;
        }

        var mapSource = {
            "style": "CustomMap",
            "name": itemInfo.title,
            "description": itemInfo.description || "",
            "mobile": true,
            "night": false,
            "type": sourceType,
            "url": url,
            "itemUrl": itemUrl,
            "copyrightText": itemInfo.accessInformation || ""
        };

        var thumbnailUrl = kDefaultThumbnail;

        if (itemInfo.thumbnail > "") {
            thumbnailUrl = portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemInfo.id + "/info/" + itemInfo.thumbnail);
        }

        mapSource.thumbnailUrl = thumbnailUrl;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }

        onlineMapSources.push(mapSource);

        console.log(logCategory, arguments.callee.name, "name:", mapSource.name, "type:", sourceType);
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

        if (onlineMapSources.find(checkUrl)) {
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

        onlineMapSources.push(mapSource);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapSource:", JSON.stringify(mapSource, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveyMapSources, true)
    }

    //--------------------------------------------------------------------------

    RelatedContentRequest {
        id: relatedContentRequest

        property string itemId
        property var resolve
        property var reject

        portal: surveyMapSources.portal
        debug: surveyMapSources.debug

        onRelatedItem: {
            addOnlineMapSource(itemInfo);
        }

        onFinished: {
            console.log(logCategory, "Related maps search finished");
            resolve();
        }

        onFailed: {
            console.error(logCategory, "Related maps search failed");
            resolve();
            //reject();
        }

        function start(itemId) {
            console.log(logCategory, arguments.callee.name, "related search itemId:", itemId);

            var promise = new Promise(function (_resolve, _reject) {
                resolve = _resolve;
                reject = _reject;

                requestRelatedItems(itemId);
            });

            return promise;
        }
    }

    //--------------------------------------------------------------------------

    PortalGroupContentRequest {
        id: portalContentRequest

        property var resolve
        property var reject

        portal: surveyMapSources.portal

        onContentItem: {
            addOnlineMapSource(itemInfo);
        }

        onFinished: {
            console.log(logCategory, "Basemaps search finished");
            resolve();
        }

        onFailed: {
            console.error(logCategory, "Basemaps search failed");
            resolve();
            // reject();
        }

        function start(query) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "basemaps query:", query);
            }

            var promise = new Promise(function (_resolve, _reject) {
                resolve = _resolve;
                reject = _reject;

                search(query);
            });

            return promise;
        }
    }

    //--------------------------------------------------------------------------
}
