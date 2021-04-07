/* Copyright 2018 Esri
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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0

ListModel {

    id: geocodersModel

    readonly property string kSearchAllFlag: "search_all"

    property bool alwaysIncludeEsriWorldGeocoder: false
    property bool includeSearchAllOption: true
    property var forwardGeocodeDisplayFields: ["attributes.LongLabel", "attributes.Place_addr", "attributes.Match_addr", "attributes.Loc_name", "address"]
    property var reverseGeocodeDisplayFields: ["address.Match_addr"]

    readonly property var esriWorldGeocoder: {
                "name": qsTr("ArcGIS World Geocoder"),
                "suggest": true,
                "url": "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
                }

    signal finalize()
    signal finished()

    //--------------------------------------------------------------------------

    onFinalize: {
        if (count > 1 && includeSearchAllOption) {
            addSearchAllOption();
        }

        finished();
    }

    //--------------------------------------------------------------------------

    onFinished: {
    }

    //--------------------------------------------------------------------------

    function addSearchAllOption() {
        var searchAllEntry = {
            "name": qsTr("All"),
            "url": kSearchAllFlag
        }
        insert(0, searchAllEntry);
    }

    //--------------------------------------------------------------------------

    function addEsriWorldGeocoder(){
        addItem(esriWorldGeocoder);
    }

    //--------------------------------------------------------------------------

    function addItem(item) {

        var listentry = {
            "name": item.name,
            "urlCoordinateFormat": "x,y",
            "url": item.url,
            "acceptsSinglelineInput": true,
            "requiresToken": -1,
            "forward": {
                "url": "%1/findAddressCandidates?f=json&outFields=*&singleline=".arg(item.url),
                "resultsKey": "candidates",
                "displayField": forwardGeocodeDisplayFields,
                "coordinate": {
                    "key": "location",
                    "lat": "y",
                    "lon": "x"
                }
            },
            "reverse": {
                "url": "%1/reverseGeocode?f=json&location=".arg(item.url),
                "resultsKey": "",
                "displayField": reverseGeocodeDisplayFields,
                "coordinate": {
                    "key": "location",
                    "lat": "y",
                    "lon": "x"
                }
            },
            "suggest": {
                "available": false
            }
        }

        if (item.suggest) {
            listentry.suggest = {
                "available": item.suggest,
                "url": "%1/suggest?f=json&text=".arg(item.url),
                "resultsKey": "suggestions",
                "displayField": ["text"]
            }
        }

        if (item.url === esriWorldGeocoder.url) {
            listentry.requiresToken = 0;
        }

        append(listentry);

    }

    //--------------------------------------------------------------------------

    function reset(){
        clear();
    }

    // END /////////////////////////////////////////////////////////////////////
}
