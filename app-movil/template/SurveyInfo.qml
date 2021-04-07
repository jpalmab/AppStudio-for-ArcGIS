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

import "../template/SurveyHelper.js" as Helper
import "../XForms/XForm.js" as XFormJS

Item {
    id: surveyInfo

    //--------------------------------------------------------------------------

    property alias folder: fileInfo.folder
    property alias path: fileInfo.filePath
    property alias fileInfo: fileInfo
    property var itemInfo: null
    property var info: null
    property var xformInfo: ({})

    readonly property alias name: fileInfo.baseName
    readonly property string itemId: itemInfo ? itemInfo.id || "" : ""
    readonly property string title: (itemInfo && itemInfo.title > "") ? itemInfo.title : fileInfo.baseName
    readonly property string description: (itemInfo && itemInfo.description) ? itemInfo.description : ""
    readonly property string snippet: (itemInfo && itemInfo.snippet) ? itemInfo.snippet : ""
    readonly property url thumbnail: Helper.findThumbnail(fileInfo.folder, fileInfo.baseName, "images/form-thumbnail.png", (itemInfo ? itemInfo.thumbnail : undefined)) //fileInfo.folder.fileUrl(fileInfo.baseName + ".png")
    readonly property string owner: (itemInfo  && itemInfo.owner) ? itemInfo.owner : ""
    readonly property date created: new Date((itemInfo  && itemInfo.created) ? itemInfo.created : undefined)
    readonly property date modified: new Date((itemInfo  && itemInfo.modified) ? itemInfo.modified : undefined)
    readonly property var version: xformInfo.version

    property alias mapPackages: mapPackages
    property url defaultMapThumbnail: "images/map-thumbnail.png"
    readonly property bool isPublished: itemInfo ? itemInfo.id > "" : false
    readonly property bool isPublic: itemInfo ? itemInfo.access === "public" : false
    property var queryInfo: info && info.queryInfo ? info.queryInfo : {}
    property var sentInfo: info && info.sentInfo ? info.sentInfo : {}
    property var notificationsInfo: info && info.notificationsInfo ? info.notificationsInfo : {}

    property alias libraryFolder: libraryFolder
    property FileFolder mapsFolder

    property bool includeDefaultMaps: true
    property bool updateXFormInfo: false

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveyInfo, true)
    }
    
    FileInfo {
        id: fileInfo

        onFilePathChanged: {
            mapsFolder = fileInfo.folder.folder("Maps");
            read();
        }
    }

    FileFolder {
        id: libraryFolder

        path: "~/ArcGIS/My Surveys/Maps" // TODO Needs review of usage and initializeation //app.kDefaultMapLibraryPath
    }

    ListModel {
        id: mapPackages
    }

    //--------------------------------------------------------------------------

    function readInfo() {
        itemInfo = fileInfo.folder.readJsonFile(fileInfo.baseName + ".itemInfo");
        info = fileInfo.folder.readJsonFile(fileInfo.baseName + ".info");

        console.log("surveyInfo:", JSON.stringify(info, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function read() {
        readInfo();

        updateMapPackages();

        if (updateXFormInfo) {
            readXFormInfo();
        }
    }

    //--------------------------------------------------------------------------

    function write() {
        info.serviceInfo = undefined;

        fileInfo.folder.writeJsonFile(fileInfo.baseName + ".info", info);
    }

    //--------------------------------------------------------------------------

    function updateMapPackages() {
        console.log(arguments.callee.name);

        var paths = app.mapLibraryPaths.split(";");
        if (paths.length > 0 && paths[0] > "") {
            libraryFolder.path = paths[0];
        }

        console.log(arguments.callee.name, "Primary library path:", libraryFolder.path);

        libraryFolder.makeFolder();

        mapPackages.clear();

        if (!info.displayInfo || !info.displayInfo.map) {
            return;
        }

        var mapInfo = info.displayInfo.map;

        includeDefaultMaps = XFormJS.toBoolean(mapInfo.includeDefaultMaps, true);

        console.log(arguments.callee.name, "includeDefaultMaps:", includeDefaultMaps);

        if (!mapInfo.mapTypes || !mapInfo.mapTypes.mapSources) {
            return;
        }

        var mapTypes = mapInfo.mapTypes;
        var mapSources = mapTypes.mapSources;
        var includeLibrary = true;
        if (mapTypes.hasOwnProperty("includeLibrary")) {
            includeLibrary = Boolean(mapTypes.includeLibrary);
        }

        if (!Array.isArray(mapSources)) {
            return;
        }

        mapSources.forEach(function (mapSource) {
            var urlInfo = AppFramework.urlInfo(mapSource.url);
            var query = urlInfo.queryParameters;
            var itemId = query.id;

            if (urlInfo.fileName === "item.html" && itemId > "") {

                urlInfo.path = "";
                urlInfo.query = "";
                urlInfo.userInfo = "";
                urlInfo.fragment = "";

                var name = mapSource.name;
                if (!(name > "")) {
                    name = "";
                }

                var description = mapSource.description;
                if (!(description > "")) {
                    description = "";
                }

                var storeInLibrary = includeLibrary;
                if (includeLibrary && mapSource.hasOwnProperty("storeInLibrary")) {
                    storeInLibrary = Boolean(mapSource.storeInLibrary);
                }

                var localUrl = storeInLibrary
                        ? libraryFolder.fileUrl(itemId)
                        : mapsFolder.fileUrl(itemId);

                var packageInfo = {
                    "name": name,
                    "description": description,
                    "itemId": itemId,
                    "portalUrl": urlInfo.url.toString(),
                    "localUrl": localUrl.toString(),
                    "thumbnailUrl": defaultMapThumbnail.toString(),
                    "mapSource": mapSource,
                    "storeInLibrary": storeInLibrary
                };

                mapPackages.append(packageInfo);
            }
        });
    }

    //--------------------------------------------------------------------------

    function componentFilePath(suffix) {
        return folder.filePath(fileInfo.baseName + "." + suffix);
    }

    //--------------------------------------------------------------------------

    function componentFileExists(suffix) {
        return folder.fileExists(fileInfo.baseName + "." + suffix);
    }

    //--------------------------------------------------------------------------

    function log() {

    }

    //--------------------------------------------------------------------------

    function readXFormInfo(json) {
        if (!json) {
            var xml = fileInfo.folder.readTextFile(fileInfo.baseName + ".xml");
            json = AppFramework.xmlToJson(xml);
        }

        var title = json.head ? json.head.title : "";
        var instances = XFormJS.asArray(json.head.model.instance);

        var instanceName;
        var instance = instances[0];

        var elements = instance["#nodes"];
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].charAt(0) !== '#') {
                instanceName = elements[i];
                break;
            }
        }

        instance = instances[0]; //json.head.model.instance[instanceName];

        var version = (((instance || {} )[instanceName] || {})["@version"]) || "";

        xformInfo = {
            title: title,
            version: version
        }

        console.log(arguments.callee.name, "xformInfo:", JSON.stringify(xformInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------
}
