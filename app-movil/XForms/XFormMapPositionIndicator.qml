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

import QtQuick 2.12
import QtLocation 5.12
import QtPositioning 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

MapItemGroup{
    id: positionIndicator

    //--------------------------------------------------------------------------

    property XFormPositionSourceConnection positionSourceConnection
    property real horizontalAccuracy: 0
    property alias showCrosshairs: crosshairs.visible

    //--------------------------------------------------------------------------

    visible: positionSourceConnection.active

    //--------------------------------------------------------------------------

    MapCircle {
        id: accuracyCircle

        color: horizontalAccuracy > 0 ? "#8000b2ff" : "#80ff0000"
        radius: horizontalAccuracy
        border {
            color: "#80ffffff"
            width: 1
        }
    }

    //--------------------------------------------------------------------------

    MapCircle {
        property real s: 40075000 * Math.cos(center.latitude * Math.PI / 180 ) / Math.pow(2, map.zoomLevel + 8)   // S=C*cos(y)/2^(z+8) Pixels per meter
        property real m: s * 10 * AppFramework.displayScaleFactor

        center: accuracyCircle.center
        color: "transparent"
        radius: Math.max(positionIndicator.horizontalAccuracy, m)
        border {
            color: "#00b2ff"
            width: 3 * AppFramework.displayScaleFactor
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite

            ScaleAnimator {
                from: 0.0
                to: 1.1
                duration: 2000
            }

            ScaleAnimator {
                from: 1.1
                to: 0.0
                duration: 2000
            }
        }
    }

    //--------------------------------------------------------------------------

    MapQuickItem {
        id: crosshairs

        visible: false
        coordinate: accuracyCircle.center

        anchorPoint {
            x: crosshairsItem.width / 2
            y: crosshairsItem.height / 2
        }

        sourceItem: Item {
            id: crosshairsItem

            width: 15 * AppFramework.displayScaleFactor
            height: width

            Glow {
                anchors.fill: parent
                source: crosshairsImage

                color: "white"
                radius: 6 * AppFramework.displayScaleFactor
            }

            Item {
                id: crosshairsImage

                anchors.fill: parent

                Rectangle {
                    anchors.centerIn: parent

                    width: parent.width
                    height: 1 * AppFramework.displayScaleFactor
                    color: "black"
                }

                Rectangle {
                    anchors.centerIn: parent

                    width: 1 * AppFramework.displayScaleFactor
                    height: parent.height
                    color: "black"
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            accuracyCircle.center = position.coordinate;

            if (position.horizontalAccuracyValid) {
                positionIndicator.horizontalAccuracy = position.horizontalAccuracy;
            } else {
                positionIndicator.horizontalAccuracy = -1;
            }
        }
    }

    //--------------------------------------------------------------------------
}
