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
import QtQuick.Controls 2.4
import QtLocation 5.9
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0

Item {
    id: scale

    //--------------------------------------------------------------------------

    property font font: Qt.application.font
    property var locale: Qt.locale()

    property Map map: parent

    property real length
    property color textColor: "#004EAE"
    property bool showZoomLevel: false

    readonly property variant kScaleLengths: [
        1, 2,
        5, 10, 20, 50, 100, 200,
        500, 1000, 2000, 5000, 10000, 20000,
        50000, 100000, 200000, 500000, 1000000, 2000000
    ]

    //--------------------------------------------------------------------------

    visible: length > 0

    height: scaleText.height * 2
    width: barImage.width
    z: map.z + 1

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        calculateScale();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: map

        onMapReadyChanged: {
            calculateScale();
        }

        onZoomLevelChanged: {
            calculateScale();
        }
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        onPressAndHold: {
            showZoomLevel = !showZoomLevel;
        }
    }

    //--------------------------------------------------------------------------

    Image {
        id: leftEndImage

        anchors {
            bottom: parent.bottom
            right: barImage.left
        }

        source: "images/scalebar-end.png"
    }

    Image {
        id: barImage

        anchors {
            bottom: parent.bottom
            right: rightEndImage.left
        }

        source: "images/scalebar-line.png"
    }

    Image {
        id: rightEndImage

        anchors {
            bottom: parent.bottom
            right: parent.right
        }

        source: "images/scalebar-end.png"
    }

    Label {
        id: scaleText

        anchors.centerIn: parent

        color: textColor
        text: formatDistance(length)

        font {
            family: scale.font.family
            pointSize: 13
        }
    }

    //--------------------------------------------------------------------------

    Label {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: barImage.bottom
        }

        visible: showZoomLevel
        color: textColor
        text: Math.round(map.zoomLevel * 100) / 100

        font {
            family: scale.font.family
            pointSize: 9
        }
    }

    //--------------------------------------------------------------------------

    function calculateScale()
    {
        if (!map.mapReady) {
            length = 0;
            return;
        }

        var f = 0;
        var coord1 = map.toCoordinate(Qt.point(0, scale.y));
        var coord2 = map.toCoordinate(Qt.point(0 + barImage.sourceSize.width, scale.y));
        var dist = Math.round(coord1.distanceTo(coord2));

        if (dist > 0) {
            for (var i = 0; i < kScaleLengths.length-1; i++) {
                if (dist < (kScaleLengths[i] + kScaleLengths[i+1]) / 2 ) {
                    f = kScaleLengths[i] / dist;
                    dist = kScaleLengths[i];
                    break;
                }
            }
            if (f === 0) {
                f = dist / kScaleLengths[i];
                dist = kScaleLengths[i];
            }
        }

        barImage.width = (barImage.sourceSize.width * f) - 2 * leftEndImage.sourceSize.width;
        length = Math.round(dist);
    }

    //--------------------------------------------------------------------------

    function formatDistance(meters)
    {
        var dist = Math.round(meters)
        if (dist > 1000) {
            if (dist > 100000) {
                dist = Math.round(dist / 1000)
            }
            else{
                dist = Math.round(dist / 100)
                dist = dist / 10
            }
            dist = dist + " km"
        }
        else{
            dist = dist + " m"
        }
        return dist
    }

    //--------------------------------------------------------------------------
}
