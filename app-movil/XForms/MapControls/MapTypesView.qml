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

import ArcGIS.AppFramework 1.0

GridView {
    id: gridView

    //--------------------------------------------------------------------------

    property Map map
    property string token // TODO Should be removed once Image source authentication is handled

    property int referenceWidth: 200 * AppFramework.displayScaleFactor
    property int cells: calcCells(width)
    property bool dynamicSpacing: false
    property int minimumSpacing: 8 * AppFramework.displayScaleFactor
    property int cellSize: 175 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    signal clicked(int index, MapType mapType)
    signal pressAndHold(int index, MapType mapType)

    //--------------------------------------------------------------------------

    cellWidth: width / cells
    cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth


    clip: true

    delegate: mapTypeDelegate

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "supportedMapTypes:", map.supportedMapTypes.length);

        var mapTypes = [];
        var activeIndex = -1;

        for (var i = 0; i < map.supportedMapTypes.length; i++) {
            var supportedMapType = map.supportedMapTypes[i];

            if (!supportedMapType.mobile) {
                console.log(logCategory, "Not a mobile map name:", supportedMapType.name);
                continue;
            }

            var selected = false;
            if (activeIndex < 0 && map.activeMapType.name === supportedMapType.name) {
                activeIndex = mapTypes.length;
                selected = true;
            }

            var mapType = {
                name: supportedMapType.name,
                thumbnailUrl: supportedMapType.metadata.thumbnailUrl,
                index: i,
                selected: selected
            }

            mapTypes.push(mapType);
        }

        model = mapTypes;

        currentIndex = activeIndex;

        console.log(logCategory, "mapTypes:", mapTypes.length);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(gridView, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypeDelegate

        Rectangle {
            width: cellWidth
            height: cellHeight

            color: "transparent"
            //            border {
            //                color: modelData.selected ? "#00b2ff" : "transparent"
            //                width: 2 * AppFramework.displayScaleFactor
            //            }
            //            radius: 5 * AppFramework.displayScaleFactor

            MapTypeDelegate {
                anchors {
                    fill: parent
                    margins: 8 * AppFramework.displayScaleFactor
                }

                dropShadow.color: modelData.selected ? "#00b2ff" : "#12000000"

                onClicked: {
                    gridView.clicked(modelData.index, map.supportedMapTypes[modelData.index]);
                }

                onPressAndHold: {
                    gridView.pressAndHold(modelData.index, map.supportedMapTypes[modelData.index]);
                }

                onInfoClicked: {
                    var popup = mapTypePopup.createObject(gridView,
                                                          {
                                                              mapType: map.supportedMapTypes[modelData.index]
                                                          });

                    popup.open();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function calcCells(w) {
        if (dynamicSpacing) {
            return Math.max(1, Math.floor(w / (cellSize + minimumSpacing)));
        }

        var rw =  referenceWidth;
        var c = Math.max(1, Math.round(w / referenceWidth));

        var cw = w / c;

        if (cw > rw) {
            c++;
        }

        cw = w / c;

        if (c > 1 && cw < (rw * 0.85)) {
            c--;
        }

        cw = w / c;

        if (cw > rw) {
            c++;
        }

        return c;
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypePopup

        MapTypePopup {
            token: gridView.token
        }
    }

    //--------------------------------------------------------------------------
}
