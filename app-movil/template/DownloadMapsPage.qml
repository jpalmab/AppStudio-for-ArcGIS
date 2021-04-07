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
import ArcGIS.AppFramework.Platform 1.0

import "../Portal"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property string surveyPath
    property var surveyInfoPage

    property bool debug: true

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

    readonly property url kDefaultThumbnail: "images/map-thumbnail.png"

    //--------------------------------------------------------------------------

    signal fail(var error)

    //--------------------------------------------------------------------------

    title: qsTr("Offline Maps")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        refreshDataItems(surveyInfo.itemId);
    }

    //--------------------------------------------------------------------------

    onFail: {
    }

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        mapsView.debug = !mapsView.debug;
    }

    //--------------------------------------------------------------------------

    function refreshDataItems(itemId) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemId:", itemId);
        }

        relatedContentRequest.requestRelatedItems(itemId);
    }

    //--------------------------------------------------------------------------

    function addToMapPackages(itemInfo) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "itemInfo:", JSON.stringify(itemInfo, undefined, 2));
        }

        if (kMapItemTypes.indexOf(itemInfo.type) < 0) {
            return;
        }

        var thumbnailUrl = itemInfo.thumbnail > ""
                ? portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + itemInfo.id + "/info/" + itemInfo.thumbnail)
                : kDefaultThumbnail;

        var storeInLibrary = false;
        var localUrl = storeInLibrary
                ? surveyInfo.libraryFolder.fileUrl(itemInfo.id)
                : surveyInfo.mapsFolder.fileUrl(itemInfo.id);

        var areaTitle = itemInfo.areaItemInfo ? itemInfo.areaItemInfo.title : "";

        var packageInfo = {
            "areaTitle": areaTitle,
            "name": areaTitle > "" ? areaTitle : itemInfo.title,
            "description": itemInfo.snippet || "",
            "itemId": itemInfo.id,
            "portalUrl": portal.portalUrl.toString(),
            "localUrl": localUrl.toString(),
            "thumbnailUrl": thumbnailUrl,
            "mapSource": null,
            "storeInLibrary": storeInLibrary
        };

        if (debug) {
            console.log(logCategory, arguments.callee.name, "packageInfo:", JSON.stringify(packageInfo, undefined, 2));
        }

        surveyInfo.mapPackages.append(packageInfo);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo

        path: surveyPath
    }

    //--------------------------------------------------------------------------

    contentItem: MapsView {
        id: mapsView

        mapPackages: surveyInfo.mapPackages
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

    RelatedContentRequest {
        id: relatedContentRequest

        portal: page.portal

        onRelatedItem: {
            addToMapPackages(itemInfo);
        }

        onFailed: {
            fail(error);
        }
    }

    //--------------------------------------------------------------------------
}
