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
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "MapControls"

import "XForm.js" as XFormJS

XFormVerticalButtonBar {
    id: buttonBar

    //--------------------------------------------------------------------------

    property Map map: null
    property XFormMapSettings mapSettings
    property XFormPositionSourceConnection positionSourceConnection

    property real size: 40
    property real zoomRatio: 2
    property real zoomStep: 0.5

    readonly property int buttonSize: xform.style.buttonBarSize

    property alias homeButton: homeButton

    property Component mapTypesPopup: defaultMapTypesPopup

    property bool showZoomLevel: false

    //--------------------------------------------------------------------------

    signal positionRequested()
    signal homeRequested()
    signal scaleRequested()
    signal mapTypeChanged(var mapType)

    //--------------------------------------------------------------------------

    spacing: 15 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            positionButton.position = position;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize * 0.75
        Layout.preferredHeight: Layout.preferredWidth
        Layout.topMargin: 10 * AppFramework.displayScaleFactor

        source: Icons.icon("basemap")

        onClicked: {
            fader.start();

            var popup = mapTypesPopup.createObject(buttonBar);
            popup.open();
        }

        onPressAndHold: {
            showZoomLevel = !showZoomLevel;

            fader.start();
        }
    }

    //--------------------------------------------------------------------------

    Text {
        Layout.preferredWidth: buttonSize

        visible: showZoomLevel
        text: "%1".arg(Math.round(map.zoomLevel * 10) / 10)

        color: xform.style.buttonColor
        fontSizeMode: Text.HorizontalFit
        font {
            pointSize: 16
            bold: true
            family: xform.style.fontFamily
        }
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onClicked: {
                fader.start();
                scaleRequested();
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        source: Icons.icon("plus")
        enabled: map.zoomLevel < map.maximumZoomLevel

        onClicked: {
            fader.start();
            //map.zoomToScale (map.mapScale / zoomRatio);
            map.zoomLevel += zoomStep;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: homeButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize * 0.8
        Layout.preferredHeight: Layout.preferredWidth

        source: Icons.icon("home")

        onClicked: {
            homeRequested();

            fader.start();

            map.positionMode = 0;

            if (mapSettings.zoomLevel > 0) {
                console.log("Zoom to level:", mapSettings.zoomLevel);
                map.zoomLevel = mapSettings.zoomLevel;
            } else if (map.zoomLevel < mapSettings.defaultZoomLevel) {
                console.log("Zoom to default level:", mapSettings.defaultZoomLevel);
                map.zoomLevel = mapSettings.defaultPreviewZoomLevel;
            }

            var coord = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);
            if (coord.isValid) {
                console.log("Zoom to:", coord);
                map.center = coord;
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        source: Icons.icon("minus")
        enabled: map.zoomLevel > map.minimumZoomLevel

        onClicked: {
            fader.start();

            //            map.zoomToScale (map.mapScale * zoomRatio);
            map.zoomLevel -= zoomStep;
        }
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: positionButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: Layout.preferredWidth

        property bool isActive: positionSourceConnection && positionSourceConnection.active
        property int maxModes: 2 //map.positionDisplay.isCompassAvailable ? 4 : 3;
        property var position: ({})

        visible: positionSourceConnection && positionSourceConnection.valid

        source: Icons.icon(isActive ? modeImage(map.positionMode) : "gps-off")
        padding: modePadding(isActive ? map.positionMode : -1)

        onPressAndHold: {
            if (positionSourceConnection.active) {
                positionSourceConnection.stop();
            }

            fader.start();
            map.bearing = 0;
        }

        onClicked: {

            positionRequested();

            if (positionSourceConnection.active) {
                var mode = map.positionMode + 1;
                if (mode >= positionButton.maxModes) {
                    map.positionMode = map.positionModeOn;
                    positionSourceConnection.stop();
                } else {
                    map.positionMode = mode;
                    if (positionButton.position.longitudeValid && positionButton.position.latitudeValid) {
                        map.center = position.coordinate;
                    }
                }

                //                    map.positionDisplay.mode = (map.positionDisplay.mode + 1) % positionButton.maxModes;
            } else {
                map.positionMode = map.positionModeAutopan;
                map.bearing = 0;
                positionSourceConnection.start();
            }

            fader.start();
        }

        function modeImage(mode) {
            switch (mode) {
            case -1 :
                return "gps-off";

            case 0 :
                return "gps-on";

            case 1 :
                return "compass";

            case 2 :
                return "compass-north";

            case 3 :
                return "compass-needle";
            }
        }

        function modePadding(mode) {
            switch (mode) {
            case -1 :
            case 0 :
                return 2 * AppFramework.displayScaleFactor;

            case 1 :
            case 2 :
            case 3 :
                return 4 * AppFramework.displayScaleFactor;
            }
        }
    }

    //--------------------------------------------------------------------------

    Text {
        Layout.preferredWidth: buttonSize
        Layout.topMargin: -buttonBar.spacing
        Layout.bottomMargin: buttonBar.spacing * 0.75

        property alias position: positionButton.position

        visible: positionButton.isActive && map.positionMode >= 0 && !!position.horizontalAccuracyValid
        text: isFinite(position.horizontalAccuracy)
              ? /*±*/ "%1 m".arg(XFormJS.round(position.horizontalAccuracy, position.horizontalAccuracy < 1
                                           ? mapSettings.horizontalAccuracyPrecisionHigh
                                           : mapSettings.horizontalAccuracyPrecisionLow))
              : ""

        color: xform.style.buttonColor
        fontSizeMode: Text.HorizontalFit
        minimumPointSize: 8
        font {
            pointSize: 12
            bold: true
            family: xform.style.fontFamily
        }
        horizontalAlignment: Text.AlignHCenter
    }

    //--------------------------------------------------------------------------

    Component {
        id: defaultMapTypesPopup

        MapTypesPopup {
            parent: buttonBar.map.parent

            map: buttonBar.map
            token: app.portal.token // TODO Should be removed once Image source authentication is handled

            onMapTypeChanged: {
                buttonBar.mapTypeChanged(mapType);
            }
        }
    }

    //--------------------------------------------------------------------------
}
