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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "MapControls"

Map {
    id: map

    //--------------------------------------------------------------------------

    property XFormPositionSourceConnection positionSourceConnection
    property int positionMode

    readonly property int positionModeOff: -1
    readonly property int positionModeOn: 0
    readonly property int positionModeAutopan: 1

    property alias positionIndicator: positionIndicator
    property alias mapControls: mapControls

    property XFormMapSettings mapSettings

    property color backgroundColor: "#e6e6e6"
    property alias skyColor: skyGradientStop.color

    property LocaleProperties localeProperties: xform.localeProperties

    //--------------------------------------------------------------------------

    signal mapTypeChanged(var mapType)

    //--------------------------------------------------------------------------

    gesture {
        //activeGestures: MapGestureArea.ZoomGesture | MapGestureArea.PanGesture
        enabled: true
    }
    
    activeMapType: supportedMapTypes[0]

    color: tilt > 0 ? "transparent" : backgroundColor

    //--------------------------------------------------------------------------

    gesture.onPinchStarted: {
        positionMode = positionModeOn;
    }

    gesture.onPanStarted: {
        positionMode = positionModeOn;
    }

    gesture.onFlickStarted: {
        positionMode = positionModeOn;
    }

    //--------------------------------------------------------------------------

    onCopyrightLinkActivated: Qt.openUrlExternally(link)

    //--------------------------------------------------------------------------

    onActiveMapTypeChanged: { // TODO Remove force update of min/max zoom levels
        minimumZoomLevel = -1;
        maximumZoomLevel = 9999;
    }

    //--------------------------------------------------------------------------

    Behavior on zoomLevel {
        NumberAnimation {
            easing.type: Easing.OutQuad
            duration: 250
        }
    }

    Behavior on center {
        id: centerBehavior

        enabled: map.mapReady

        CoordinateAnimation {
            easing.type: Easing.OutCubic
        }
    }

    Behavior on tilt {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on bearing {
        RotationAnimation {
            duration: 250
            direction: RotationAnimation.Shortest
            easing.type: Easing.InOutQuad
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(map, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            if (positionMode == positionModeAutopan) { // !positionIndicator.visible) {
                map.center = position.coordinate;
            }
        }
    }

    //--------------------------------------------------------------------------

    RadialGradient {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: map.tilt / 90 * parent.height

        visible: map.tilt > 0
        angle: 270
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(skyGradientStop.color, 1.5)
            }

            GradientStop {
                id: skyGradientStop
                position: 0.5
                color: "#91c7e9"
            }
        }

        z: parent.z - 1
    }

    //--------------------------------------------------------------------------

    XFormMapControls {
        id: mapControls
        
        anchors {
            left: localeProperties.layoutDirection == Qt.RightToLeft ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.LeftToRight ? parent.right : undefined
            margins: 10 * AppFramework.displayScaleFactor
            verticalCenter: parent.verticalCenter
        }
        
        map: parent
        mapSettings: parent.mapSettings
        positionSourceConnection: map.positionSourceConnection
        z: 9999

        onMapTypeChanged: {
            map.mapTypeChanged(mapType);
        }

        onScaleRequested: {
            scaleBar.visible = !scaleBar.visible;
        }
    }

    //--------------------------------------------------------------------------

    NorthArrow {
        anchors {
            left: localeProperties.layoutDirection == Qt.LeftToRight ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.RightToLeft ? parent.right : undefined
            top: parent.top
            margins: 5 * AppFramework.displayScaleFactor
        }
    }

    //--------------------------------------------------------------------------

    MapScaleBar {
        id: scaleBar

        anchors {
            left: localeProperties.layoutDirection == Qt.LeftToRight ? parent.left : undefined
            right: localeProperties.layoutDirection == Qt.RightToLeft ? parent.right : undefined
            bottom: parent.bottom
            margins: 25 * AppFramework.displayScaleFactor
        }

        visible: false
    }

    //--------------------------------------------------------------------------

    XFormMapPositionIndicator {
        id: positionIndicator

        positionSourceConnection: map.positionSourceConnection
        showCrosshairs: positionSourceConnection && positionSourceConnection.active && positionMode == positionModeOn
    }

    //--------------------------------------------------------------------------

    function zoomToDefault() {
        if (mapSettings.zoomLevel > 0) {
            console.log("Zoom to level:", mapSettings.zoomLevel);
            map.zoomLevel = mapSettings.zoomLevel;
        } else if (map.zoomLevel < mapSettings.defaultZoomLevel) {
            console.log("Zoom to default level:", mapSettings.defaultPreviewZoomLevel);
            map.zoomLevel = mapSettings.defaultZoomLevel;
        }

        var coord = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);
        if (coord.isValid) {
            console.log("Zoom to:", coord);
            map.center = coord;
        }
    }

    //--------------------------------------------------------------------------
    // @FIXME : Workaround for crash by using timer

    function zoomToRectangle(rectangle, centerZoomLevel) {
        function doZoom() {
            if (rectangle.width > 0 && rectangle.height > 0) {
                // console.log("zoomToRectangle:", rectangle);

                rectangle.width *= 1.1;
                rectangle.height *= 1.1;

                visibleRegion = rectangle;
            } else {
                // console.log("zoomToRectangle:", rectangle.center, centerZoomLevel);

                center = rectangle.center;
                map.zoomLevel = centerZoomLevel;
            }
        }

        delayTimer.callback = doZoom;
        delayTimer.restart();
    }

    //--------------------------------------------------------------------------

    function zoomToCoordinate(coordinate, zoomLevel) {

        if (typeof zoomLevel === "undefined") {
            zoomLevel = 14;
        }

        function doZoom() {
            center = coordinate;
            map.zoomLevel = zoomLevel;
        }

        delayTimer.callback = doZoom;
        delayTimer.restart();
    }

    Timer {
        id: delayTimer

        property var callback

        interval: 5
        triggeredOnStart: false
        repeat: false

        onTriggered: {
            callback();
        }
    }

    //--------------------------------------------------------------------------
}
