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
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"

import "XForm.js" as XFormJS

Map {
    id: map
    
    //--------------------------------------------------------------------------

    property XFormSettings formSettings
    property XFormMapSettings mapSettings

    property bool hasMaps: supportedMapTypes.length > 0
    readonly property bool isOnline: Networking.isOnline
    
    property string nodeset
    readonly property string storedMapName: formSettings.mapName(nodeset)
    property string mapName: formSettings.mapName(nodeset)
    property string styleMapName

    property bool initialized: false

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kPropertyMapName: "styleMapName"

    //--------------------------------------------------------------------------

    plugin: XFormMapPlugin {
        settings: mapSettings
        offline: !isOnline
    }
    
    gesture {
        enabled: false
    }

    copyrightsVisible: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "Initialized nodeset:", nodeset, "mapName:", mapName, "storedMapName:", storedMapName);
        }

        if (mapName > "") {
            selectMapType(mapName);
        } else if (styleMapName > "") {
            selectMapType(styleMapName);
        } else {
            selectMapType("");
        }

        initialized = true;
    }

    //--------------------------------------------------------------------------

    onStyleMapNameChanged: {
        if (debug) {
            console.log("onStyleMapNameChanged:", styleMapName, "initialized:", initialized);
        }

        if (initialized) {
            selectMapType(styleMapName);
        }
    }

    //--------------------------------------------------------------------------

    onActiveMapTypeChanged: { // Force update of min/max zoom levels
        minimumZoomLevel = -1;
        maximumZoomLevel = 9999;
    }

    //--------------------------------------------------------------------------

    onCopyrightLinkActivated: {
        Qt.openUrlExternally(link);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(map, true)
    }

    //--------------------------------------------------------------------------

    function setMapType(mapType) {
        if (!mapType) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "mapType:", JSON.stringify(mapType, undefined, 2));
        }

        selectMapType(mapType.name, true);
    }

    //--------------------------------------------------------------------------

    function selectMapType(name, store) {
        if (mapSettings.selectMapType(map, name)) {
            mapName = map.activeMapType.name;
            if (name > "" && store) {
                formSettings.setMapName(nodeset, name);
            }
        }
    }

    //--------------------------------------------------------------------------
}
