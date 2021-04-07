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
import QtQuick.Controls 1.4
import QtQml 2.12
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as JS
import "MapControls"
import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: geopointCapture

    //--------------------------------------------------------------------------

    property string title
    property string subTitle

    property real editLatitude
    property real editLongitude
    property real editAltitude
    property real editHorizontalAccuracy: Number.NaN
    property real editVerticalAccuracy: Number.NaN
    property var editLocation
    property bool showAltitude: false

    property var lastPositionSourceReading: ({})

    property bool latLonDidntChangeViaCoordEdit: false

    property alias map: map
    property XFormMapSettings mapSettings: xform.mapSettings
    property alias positionSourceManager: positionSourceConnection.positionSourceManager
    property string mapName

    property bool initializing: true

    property bool editingCoords: false

    readonly property bool isEditValid: editLatitude != 0 && editLongitude != 0 &&
                                        !isNaN(editLatitude) && !isNaN(editLongitude)

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: accentColor //AppFramework.alphaColor(accentColor, 0.9)
    property real coordinatePointSize: 12 * xform.style.textScaleFactor
    property real locationZoomLevel: 16
    property bool singleLineLatLon: true

    property int buttonHeight: xform.style.titleButtonSize

    property bool isOnline: Networking.isOnline
    property bool reverseGeocodeEnabled: true
    readonly property bool canReverseGeocode: isOnline && reverseGeocodeEnabled

    property string reverseGeocodeErrorText: ""
    property string forwardGeocodeErrorText: ""

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated, 4=Position source

    property bool debug: false

    property var mgrsOptions: {
        "precision": 10,
                "spaces": true
    }

    property var parseOptions: {
        "mgrs": {
            "spaces": true
        }
    }

    property bool enableGeocoder: true

    //--------------------------------------------------------------------------

    property XFormMapMarker marker
    property url markerImage

    //--------------------------------------------------------------------------

    signal accepted
    signal rejected

    //--------------------------------------------------------------------------

    Component.onCompleted: {

        app.settings.setValue("enableGeocoder", true); // temporary

        if (debug) {
            console.log(mapSettings.zoomLevel, JSON.stringify(map.supportedMapTypes, undefined, 2));
            console.log("map isEditValid:", isEditValid, "editLatitude:", editLatitude, "editLongitude:", editLongitude);
        }

        if (isEditValid) {

            if (debug) {
                console.log("edit:", editLatitude, editLongitude, editAltitude, editHorizontalAccuracy, editVerticalAccuracy);
            }

            map.zoomLevel = mapSettings.previewZoomLevel;
            map.center.latitude = editLatitude;
            map.center.longitude = editLongitude;
            map.centerHorizontalAccuracy = editHorizontalAccuracy;
            map.centerVerticalAccuracy = editVerticalAccuracy;

            if (map.zoomLevel < map.positionZoomLevel) {
                map.zoomLevel = map.positionZoomLevel;
            }
        }
        else {
            if (debug) {
                console.log("Default map location:", mapSettings.latitude, mapSettings.longitude);
            }

            map.zoomLevel = mapSettings.zoomLevel;
            map.center = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);

            map.positionMode = map.positionModeAutopan;
            positionSourceConnection.start();
        }

        geopointCapture.changeReason = 0;

        if (debug) {
            console.log(logCategory, "mapName:", mapName);
        }

        mapSettings.selectMapType(map, mapName);

        if (marker) {
            geopointMarker.initialize(marker);
        } else if (markerImage > "") {
            geopointMarker.image.source = markerImage;
        }

        initializing = false;
    }


    //--------------------------------------------------------------------------

    Stack.onStatusChanged: {
        if (Stack.status == Stack.Activating) {
            enabled = true;
        }

        if (Stack.status == Stack.Deactivating) {
            enabled = false;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(geopointCapture, true)
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: header

        anchors {
            fill: headerLayout
            margins: -headerLayout.anchors.margins
        }

        color: barBackgroundColor //"#80000000"
    }

    ColumnLayout {
        id: headerLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: 0

        ColumnLayout {
            id: columnLayout

            Layout.fillWidth: true
            Layout.margins: 2 * AppFramework.displayScaleFactor

            spacing: 0

            RowLayout {
                Layout.fillWidth: true

                XFormImageButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    source: ControlsSingleton.backIcon
                    padding: ControlsSingleton.backIconPadding
                    color: xform.style.titleTextColor

                    onClicked: {
                        rejected();
                        geopointCapture.parent.pop();
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    visible: locationSensorButton.visible
                }

                XFormText {
                    Layout.fillWidth: true

                    text: title
                    font {
                        pointSize: xform.style.titlePointSize
                        family: xform.style.titleFontFamily
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    fontSizeMode: Text.HorizontalFit
                    elide: Text.ElideRight
                }

                XFormLocationSensorButton {
                    id: locationSensorButton

                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    positionSourceManager: geopointCapture.positionSourceManager
                }

                /*
                XFormMenuButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    menuPanel: mapMenuPanel
                }
                */
            }

            XFormText {
                Layout.fillWidth: true

                text: subTitle
                visible: text > ""
                font {
                    pointSize: 12
                }
                horizontalAlignment: Text.AlignHCenter
                color: barTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4 * AppFramework.displayScaleFactor

            visible: enableGeocoder
            spacing: 5 * AppFramework.displayScaleFactor

            GeocoderSearch {
                id: geocoderSearch

                Layout.fillWidth: true

                parseOptions: geopointCapture.parseOptions
                map: geopointCapture.map
                referenceCoordinate: map.center
                fontFamily: xform.style.fontFamily
                centerImage: geopointMarker.image.source

                onMapCoordinate: {

                    geopointCapture.changeReason = 1; // User altered the values

                    if (!coordinateInfo.coordinate.isValid) {
                        return;
                    }

                    var _editLat = editLatitude.toFixed(6)
                    var _cordLat = coordinateInfo.coordinate.latitude.toFixed(6);
                    var _editLong = editLongitude.toFixed(6)
                    var _cordLong = coordinateInfo.coordinate.longitude.toFixed(6);

                    if (debug) {
                        console.log("_editLat:", _editLat.toString());
                        console.log("_cordLat: ", _cordLat.toString());
                        console.log("_editLong:", _editLong.toString());
                        console.log("_cordLong: ", _cordLong.toString());
                        console.log("_cordLat === _editLat && _cordLong === _editLong: ", _cordLat === _editLat && _cordLong === _editLong);
                        console.log("editAltitude: ", editAltitude);
                        console.log("coordinateInfo.coordinate.altitude: ",  coordinateInfo.coordinate.altitude)
                    }

                    if (editingCoords) {
                        if (_cordLat === _editLat && _cordLong === _editLong) {
                            editAltitude = coordinateInfo.coordinate.altitude !== null ? coordinateInfo.coordinate.altitude : Number.NaN;
                            latLonDidntChangeViaCoordEdit = true;
                        }
                        else {
                            editAltitude = Number.NaN;
                            latLonDidntChangeViaCoordEdit = false;
                        }
                    }
                    else {
                        editAltitude = Number.NaN;
                    }

                    panTo(coordinateInfo.coordinate);
                }

                onLocationCommittedChanged: {
                    geopointCapture.changeReason = 1;
                    if (!locationCommitted) {
                        editLocation = undefined;
                    }
                }

                onLocationClicked: {
                    // zoomToLocation(location);
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    panTo(location.coordinate);
                    selectLocation(location);
                    if (currentIndex == index) {
                        resetTimer.location = location;
                        resetTimer.start();
                    }
                    else {
                        currentIndex = index;
                    }
                }

                onCommitLocation: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    currentIndex = index;
                    zoomToLocation(location);
                    selectLocation(location);
                    resetGeocoder(location);
                }

                onLocationDoubleClicked: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                    resetGeocoder(location);
                }

                onLocationPressAndHold: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                    resetGeocoder(location);
                }

                onLocationIndicatorClicked: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                    resetGeocoder(location);
                }

                onReverseGeocodeSuccess: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    if (typeof editLocation === "boolean") {
                        setEditLocation(location);
                    }
                }

                onResultsReturned: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    if (resultCount > 0) {
                        inputError = false;
                        forwardGeocodeErrorText = "";
                        return;
                    }
                    if (editLocation !== undefined && editLocation !== null) {
                        inputError = false;
                        forwardGeocodeErrorText = "";
                        return;
                    }
                    inputError = true;
                }

                onGeocoderError: {
                    forwardGeocodeErrorText = error;
                }

                onReverseGeocodeError: {
                    reverseGeocodeErrorText = error;
                }

                onTextChanged: {
                    inputError = false;
                    forwardGeocodeErrorText = "";
                    if (text < "" && editingCoords) {
                        editingCoords = false;
                    }
                }

                onCleared: {
                    if (editingCoords){
                        editingCoords = false;
                    }
                }
            }
        }

        Text {
            id: errorText

            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            visible: text > "" && !geocoderSearch.busy
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter
            text: forwardGeocodeErrorText

            color: barTextColor
            font {
                bold: xform.style.boldText
                family: app.fontFamily
            }
        }
    }

    //--------------------------------------------------------------------------

    Map {
        id: mapCalc

        anchors.fill: map
        plugin: Plugin { name: "itemsoverlay" }
        gesture.enabled: false
        color: 'transparent'
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        property real positionZoomLevel: xform.mapSettings.positionZoomLevel
        property real centerHorizontalAccuracy: Number.NaN
        property real centerVerticalAccuracy: Number.NaN

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
        }

        positionSourceConnection: positionSourceConnection
        gesture.enabled: true /* !editingCoords */  // removed gesture locking jnw
        mapSettings: parent.mapSettings

        mapControls.onPositionRequested: {

            if (editingCoords) {
                editingCoords = false;
            }

            if (geocoderSearch.locationCommitted){
                geocoderSearch.locationCommitted = false;
            }
        }

        mapControls.onHomeRequested: {
            if (editingCoords) {
                editingCoords = false;
            }

            if (geocoderSearch.locationCommitted){
                geocoderSearch.locationCommitted = false;
            }

            geopointCapture.changeReason = 1;
        }

        onCenterChanged: {
            if (!initializing && !geocoderSearch.locationCommitted) {

                if (!editingCoords || editingCoords && !latLonDidntChangeViaCoordEdit) {
                    editAltitude = Number.NaN;
                    editHorizontalAccuracy = Number.NaN;
                    editVerticalAccuracy = Number.NaN;
                }

                if (editingCoords && latLonDidntChangeViaCoordEdit) {
                    latLonDidntChangeViaCoordEdit = false;
                }

                editLatitude = map.center.latitude;
                editLongitude = map.center.longitude;
                editVerticalAccuracy = map.centerVerticalAccuracy;
                editHorizontalAccuracy = map.centerHorizontalAccuracy;

                if (editingCoords) {
                    geocoderSearch.text = "%1 %2".arg(formattedCoordinate.coordinateString).arg(showAltitude && isFinite(editAltitude) && formattedCoordinate.coordIsLatLongFormat ? editAltitude.toFixed(7) : "");
                    geocoderSearch.geocodeTimer.stop();
                }
            }
        }

        gesture.onPanStarted: {
            geopointCapture.changeReason = 1; // User manipulated the map.
            if (!geocoderSearch.locationCommitted) {
                // don't destroy the location if it has been 'committed'
                editLocation = undefined;
            }
        }

        function clearAccuracy() {
            centerHorizontalAccuracy = Number.NaN;
            centerVerticalAccuracy = Number.NaN;
        }

        MouseArea {
            anchors {
                fill: parent
            }

            onPressed: {
                geopointCapture.changeReason = 1;
                map.clearAccuracy();
            }

            onClicked: {
                // NOTE: may want to de-commit location at this point.
                geopointCapture.changeReason = 1;
                panTo(map.toCoordinate(Qt.point(mouseX, mouseY)));
                geocoderSearch.locationCommitted = false
                geocoderSearch.currentIndex = -1
            }

            onWheel: {
                wheel.accepted = false;
                map.clearAccuracy();
            }

            onPressAndHold: {
                reverseGeocodeErrorText = "";
                forwardGeocodeErrorText = "";
                reverseGeocode(map.toCoordinate(Qt.point(mouseX, mouseY)));
            }
        }

        GeocoderItemView {
            search: geocoderSearch

            onClicked: {
                geopointCapture.changeReason = 1;
                geocoderSearch.showLocation(index, true);
                var location = geocoderSearch.getLocation(index);
                zoomToLocation(location);
                selectLocation(location);
            }
        }

        MapCircle {
            visible: isFinite(map.centerHorizontalAccuracy) && map.centerHorizontalAccuracy > 0

            radius: map.centerHorizontalAccuracy
            center: geopointMarker.coordinate
            color: "#4000B2FF"
            border {
                width: 1
                color: "#8000B2FF"
            }

            z: 1000
        }

        XFormMapMarker {
            id: geopointMarker

            zoomLevel: 0 //16

            coordinate {
                latitude: geopointCapture.editLatitude
                longitude: geopointCapture.editLongitude
            }

            z: 1001

            visible: !map.gesture.panActive
        }

        MapCrosshairs {
            visible: map.gesture.panActive
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: footer

        anchors {
            fill: footerRow
            margins: -footerRow.anchors.margins
        }

        color: barBackgroundColor
    }

    RowLayout {
        id: footerRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        layoutDirection: xform.layoutDirection
        width: parent.width - anchors.margins

        /*
        XFormText {
            text: map.zoomLevel
        }
        */

        RowLayout {
            id: coordinateAddressDisplay

            Layout.fillWidth: true
//            Layout.preferredWidth:  parent.width - footerSeparator.width - submitButton.width - (parent.spacing * 2) - spacing

            ColumnLayout {
                spacing: 2 * AppFramework.displayScaleFactor
                Layout.fillWidth: true
                Layout.leftMargin: spacing
                Layout.rightMargin: spacing

                XFormText {
                    id: reverseGeocodeError

                    Layout.fillWidth: true

                    visible: reverseGeocodeErrorText > ""
                    text: reverseGeocodeErrorText
                    color: "white"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: xform.localeInfo.textAlignment
                    font {
                        pointSize: coordinatePointSize
                    }

                    Rectangle {
                        anchors.fill: parent
                        z: parent.z - 1
                        color: "#77000000"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            reverseGeocodeErrorText = "";
                        }
                    }
                }

                XFormText {
                    id: addressText

                    Layout.fillWidth: true

                    visible: text > ""
                    text: editLocation ? editLocation.displayAddress : ""
                    font {
                        pointSize: coordinatePointSize
                    }
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: xform.localeInfo.textAlignment
                    elide: xform.localeInfo.textElide

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            geopointCapture.changeReason = 1;
                            map.positionMode = map.positionModeOn;
                            geocoderSearch.text = "%1".arg(addressText.text);
                            geocoderSearch.textField.cursorPosition = 0;
                            if (geocoderSearch.coordinateModeTriggeredbyEditCoordinates) {
                                geocoderSearch.coordinateModeTriggeredbyEditCoordinates = false;
                            }
                            geocoderSearch.geocodeTimer.stop();
                        }
                    }
                }

                HorizontalSeparator {
                    Layout.fillWidth: true

                    visible: addressText.visible || reverseGeocodeError.visible
                }

                XFormText {
                    id: formattedCoordinate

                    visible: coordinateString > "" && isEditValid

                    property bool coordIsLatLongFormat: JS.isLatLonFormat(mapSettings.coordinateFormat)
                    property string coordinateString: coordIsLatLongFormat
                                                      ? "%1 %2"
                                                        .arg(JS.formatLatitude(geopointMarker.coordinate.latitude, mapSettings.coordinateFormat))
                                                        .arg(JS.formatLongitude(geopointMarker.coordinate.longitude, mapSettings.coordinateFormat))
                                                      : "%1".arg(JS.formatCoordinate(geopointMarker.coordinate, mapSettings.coordinateFormat))

                    Layout.fillWidth: true

                    text: coordinateString > ""
                          ? "%1 %2"
                            .arg(coordinateString)
                            .arg(!isNaN(editHorizontalAccuracy) ? qsTr("± %1 m").arg(JS.round(editHorizontalAccuracy, editHorizontalAccuracy < 1 ? mapSettings.horizontalAccuracyPrecisionHigh : mapSettings.horizontalAccuracyPrecisionLow)) : "")
                          : ""
                    font {
                        pointSize: coordinatePointSize
                    }
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: xform.localeInfo.textAlignment
                    elide: xform.localeInfo.textElide

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            geocoderSearch.editingCoordsInitiated = true;
                            map.positionMode = map.positionModeOn;
                            geocoderSearch.coordinateModeTriggeredbyEditCoordinates = true;
                            geocoderSearch.text = "%1 %2".arg(formattedCoordinate.coordinateString).arg(showAltitude && isFinite(editAltitude) && formattedCoordinate.coordIsLatLongFormat ? editAltitude.toFixed(7) : "");
                            editingCoords = true;
                            geopointCapture.changeReason = 1;
                        }
                        onPressAndHold: {
                            reverseGeocodeErrorText = "";
                            forwardGeocodeErrorText = "";
                            reverseGeocode(map.center);
                        }
                    }
                }

                Row {
                    Layout.maximumWidth: coordinateAddressDisplay.width - parent.spacing
                    Layout.alignment: xform.localeProperties.isRightToLeft ? Qt.AlignRight : Qt.AlignLeft

                    visible: showAltitude && isFinite(editAltitude)

                    spacing: 2 * AppFramework.displayScaleFactor

                    XFormText {
                        text: qsTr("Alt")
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }

                    XFormText {
                        text: JS.round(editAltitude, editVerticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow) + "m"
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }

                    XFormText {
                        visible: isFinite(editVerticalAccuracy)
                        text: qsTr("± %1 m").arg(JS.round(editVerticalAccuracy, editVerticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow))
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }
                }

                XFormText {
                    id: positionError
                    Layout.maximumWidth: coordinateAddressDisplay.width
                    visible: positionSourceConnection.errorString > "" && map.positionMode > 0
                    text: positionSourceConnection.errorString
                    color: "white"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: xform.localeInfo.textAlignment
                    font {
                        pointSize: coordinatePointSize
                    }
                }
            }

            /*
            Column {
                id: speedColumn

                visible: positionSourceConnection.active
                spacing: 2

                property Position position: lastPositionSourceReading

                XFormText {
                    visible: speedColumn.position.speedValid
                    text: qsTr("%1 km/h").arg(Math.round(speedColumn.position.speed))
                    color: barTextColor
                    font {
                        pointSize: coordinatePointSize
                    }
                }

                XFormText {
                    visible: speedColumn.position.verticalSpeedValid
                    text: qsTr("↕ %1 m/s").arg(Math.round(speedColumn.position.verticalSpeed))
                    color: barTextColor
                    font {
                        pointSize: coordinatePointSize
                    }
                }
            }
            */
        }

//        Rectangle {
//            id: footerSeparator
//            Layout.fillHeight: true
//            Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
//            Layout.topMargin: 9 * AppFramework.displayScaleFactor
//            Layout.bottomMargin: 9 * AppFramework.displayScaleFactor
//            color: barTextColor
//            opacity: 0.3
//        }

        XFormImageButton {
            id: submitButton

            Layout.fillHeight: true
            Layout.preferredHeight: buttonHeight
            Layout.preferredWidth: buttonHeight
            Layout.alignment: Qt.AlignRight

            source: Icons.icon("check")
            color: xform.style.titleTextColor
            enabled: isEditValid
            visible: isEditValid

            onClicked: {
                forceActiveFocus();

                if (geopointCapture.changeReason === 1){

                    if (editingCoords) {

                        initializing = true;
                        editHorizontalAccuracy = Number.NaN;
                        editVerticalAccuracy = Number.NaN;

                        map.center.latitude = editLatitude;
                        map.center.longitude = editLongitude;
                        map.centerHorizontalAccuracy = editHorizontalAccuracy;
                        map.centerVerticalAccuracy = editVerticalAccuracy;

                        editingCoords = false;
                        initializing = false;
                        Qt.inputMethod.hide();
                    }
                }
                accepted();
                positionSourceConnection.stop();
                geopointCapture.parent.pop();
            }
        }
    }

    //--------------------------------------------------------------------------
/*
    XFormMenuPanel {
        id: mapMenuPanel

        textColor: xform.style.titleTextColor
        backgroundColor: xform.style.titleBackgroundColor
        fontFamily: xform.style.menuFontFamily

        title: qsTr("Map Types")
        menu: Menu {
            id: mapMenu
        }
    }
*/
    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        listener: "XFormGeopointCapture"

        onNewPosition: {
            lastPositionSourceReading = position;

            if (position.latitudeValid & position.longitudeValid) {

                var wasValid = isEditValid

                if (map.positionMode > 0) {
                    if (position.horizontalAccuracyValid) {
                        map.centerHorizontalAccuracy = position.horizontalAccuracy;
                    }
                    else {
                        map.centerHorizontalAccuracy = Number.NaN;
                    }

                    if (position.altitudeValid) {
                        editAltitude = position.coordinate.altitude;
                    }
                    else {
                        editAltitude = Number.NaN;
                    }

                    if (position.verticalAccuracyValid) {
                        map.centerVerticalAccuracy = position.verticalAccuracy;
                    }
                    else {
                        map.centerVerticalAccuracy = Number.NaN;
                    }
                }

                if (isEditValid && wasValid != isEditValid) {
                    map.zoomLevel = mapSettings.previewZoomLevel;
                    map.center = position.coordinate;
                }

                if (map.zoomLevel < map.positionZoomLevel && map.positionMode == map.positionModeAutopan) {
                    map.zoomLevel = map.positionZoomLevel;
                }

                if (map.positionMode > 0){
                    // Put this last to compensate for changeReason possibly being overwritten
                    // when the map changes center, etc. And only record when in autopan mode.
                    geopointCapture.changeReason = 4;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function selectLocation(location) {

        if (!location.coordinate.isValid) {
            return;
        }

        setEditLocation(location);
        geocoderSearch.locationCommitted = true;
    }

    function resetGeocoder(location) {
        if (location) {
            geocoderSearch.text = location.displayAddress;
        }
        geocoderSearch.reset();
    }

    Timer {
        id: resetTimer

        property var location

        interval: 250
        repeat: false
        running: false

        onTriggered: resetGeocoder(location);
    }

    //--------------------------------------------------------------------------

    function panTo(coord) {

        if (positionSourceConnection.active && map.positionMode === map.positionModeAutopan) {
            map.positionMode = map.positionModeOn;
        }

        editHorizontalAccuracy = Number.NaN;
        editVerticalAccuracy = Number.NaN;
        map.clearAccuracy();

        map.center = coord;

        editLatitude = coord.latitude;
        editLongitude = coord.longitude;
        if (!editingCoords) {
            editAltitude = Number.NaN;
        }
    }

    //--------------------------------------------------------------------------

    function zoomToLocation(location) {

        editHorizontalAccuracy = Number.NaN;
        editVerticalAccuracy = Number.NaN;
        map.clearAccuracy();

        var coord = location.coordinate;
        map.center = coord;

        editLatitude = coord.latitude;
        editLongitude = coord.longitude;
        if (!editingCoords) {
            editAltitude = Number.NaN;
        }

        setEditLocation(location);
    }

    //--------------------------------------------------------------------------

    function setEditLocation(location) {
        //        console.log("setEditLocation:", JSON.stringify(location, undefined, 2));

        editLocation = JSON.parse(JSON.stringify(location));
        //        console.log("editLocation: ", JSON.stringify(editLocation, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function reverseGeocode(coord) {
        if (!canReverseGeocode) {
            console.warn("Reverse geocoding not available");
            return;
        }

        panTo(coord);
        editLocation = false;
        geocoderSearch.reverseGeocode([coord.latitude,coord.longitude]);
    }

    //--------------------------------------------------------------------------
}
