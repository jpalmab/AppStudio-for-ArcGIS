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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as JS
import "MapControls"
import "MapDraw"

import "../Controls"
import "../Controls/Singletons"
import "XFormGeometry.js" as Geometry

Rectangle {
    id: geopolyCapture

    //--------------------------------------------------------------------------

    property var formElement
    property bool readOnly: false

    property alias map: map
    property XFormMapSettings mapSettings: xform.mapSettings
    property alias positionSourceManager: positionSourceConnection.positionSourceManager
    property string mapName

    property bool editingCoords: false

    readonly property bool isEditValid: mapDraw.isValid

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: accentColor //AppFramework.alphaColor(accentColor, 0.9)
    property real coordinatePointSize: 12 * xform.style.textScaleFactor
    property real locationZoomLevel: 16
    property bool singleLineLatLon: true

    property int buttonHeight: xform.style.titleButtonSize

    property bool isOnline: Networking.isOnline

    property string forwardGeocodeErrorText: ""

    property bool debug: false

    property var locationCoordinate: QtPositioning.coordinate()

    readonly property alias isEmpty: mapDraw.isEmpty

    property bool enableGeocoder: true

    //--------------------------------------------------------------------------

    property bool isPolygon
    property var mapObject

    //--------------------------------------------------------------------------

    property alias lineColor: mapDraw.lineColor
    property alias lineWidth: mapDraw.lineWidth
    property alias fillColor: mapDraw.fillColor

    //--------------------------------------------------------------------------

    property string method: kDefaultMethod

    readonly property bool isMethodSketch: !method || method === kMethodSketch
    readonly property bool isMethodVertex: method === kMethodVertex

    //--------------------------------------------------------------------------

    readonly property string kMethodSketch: "sketch"
    readonly property string kMethodVertex: "vertex"

    readonly property string kDefaultMethod: kMethodSketch

    //--------------------------------------------------------------------------

    signal accepted
    signal rejected

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        app.settings.setValue("enableGeocoder", true); // temporary

        if (debug) {
            console.log(logCategory, "zoomLevel:", zoomLevel, JSON.stringify(supportedMapTypes, undefined, 2));
        }

        /*
        if (isEditValid) {
            map.zoomLevel = previewMap.zoomLevel;

            if (map.zoomLevel < map.positionZoomLevel) {
                map.zoomLevel = map.positionZoomLevel;
            }
        }
        else {
            if (debug) {
                console.log("Default map location:", mapSettings.latitude, mapSettings.longitude);
            }

            map.zoomLevel = mapSettings.defaultPreviewZoomLevel;
            map.center = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);

            //            map.positionMode = map.positionModeAutopan;
            positionSourceConnection.start();
        }
        */

        mapSettings.selectMapType(map, mapName);

        console.log(logCategory, "isPolygon:", isPolygon);
        mapDraw.setPath(mapObject.path);
        mapDraw.setMode(MapDraw.Mode.View);

        var isEmpty = mapObject.path.length <= 0;

        if (isEmpty) {
            map.zoomLevel = mapSettings.zoomLevel;
            map.center = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);

            map.positionMode = map.positionModeAutopan;
        } else {
            map.positionMode = map.positionModeOn;
        }

        positionSourceConnection.start();
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

    Connections {
        target: mapDraw

        onShapeUpdated: {
            updateText();
        }
    }

    //--------------------------------------------------------------------------

    function updateText() {
        if (mapDraw.isEmpty) {
            infoText.text = "";
            return;
        }

        var geopath = QtPositioning.path(mapDraw.mapPoly.path);
        var length = Geometry.displayLength(Geometry.geopathLength(geopath, isPolygon), xform.locale);

        if (isPolygon) {
            var area = Geometry.displayArea(Geometry.pathArea(geopath.path), xform.locale);
            infoText.text = qsTr("Area:%1, Perimeter:%2").arg(area).arg(length);
        } else {
            infoText.text = qsTr("Length: %1").arg(length);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(geopolyCapture, true)
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
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    source: ControlsSingleton.backIcon
                    padding: ControlsSingleton.backIconPadding
                    color: xform.style.titleTextColor

                    onClicked: {
                        rejected();
                        geopolyCapture.parent.pop();
                    }
                }

                XFormText {
                    id: labelText

                    Layout.fillWidth: true

                    text: textValue(formElement.label, "", "long")
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

                Item {
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    visible: !locationSensorButton.visible
                }

                XFormLocationSensorButton {
                    id: locationSensorButton

                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    positionSourceManager: geopolyCapture.positionSourceManager
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: textValue(formElement.hint, "", "long")
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
                map: geopolyCapture.map
                referenceCoordinate: map.center
                fontFamily: xform.style.fontFamily

                onMapCoordinate: {

                    if (!coordinateInfo.coordinate.isValid) {
                        return;
                    }

                    panTo(coordinateInfo.coordinate);
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
                    inputError = true;
                }

                onGeocoderError: {
                    forwardGeocodeErrorText = error;
                }

                onReverseGeocodeError: {
                    //                    reverseGeocodeErrorText = error;
                }

                onTextChanged: {
                    inputError = false;
                    forwardGeocodeErrorText = "";
                    if (text < "" && editingCoords) {
                        editingCoords = false;
                    }
                }

                onCleared: {
                    if (editingCoords) {
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
                bold: true
                family: app.fontFamily
            }
        }
    }

    //--------------------------------------------------------------------------

    MapSketch {
        id: sketch

        parent: map
        anchors.fill: parent

        penColor: lineColor
        penWidth: lineWidth

        onSketched: {
            mapDraw.replacePath(path);
        }
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        property real positionZoomLevel: xform.mapSettings.positionZoomLevel

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
        }

        positionSourceConnection: positionSourceConnection

        gesture {
            enabled: !sketch.active // true
        }

        mapSettings: parent.mapSettings

        mapControls.onHomeRequested: {
            mapDraw.zoomAll();
        }

        MapDraw {
            id: mapDraw

            isPolygon: geopolyCapture.isPolygon
            visible: !sketch.active

            onEditVertex: {
                editCoordinate(index, coordinate, qsTr("Editing vertex: %1").arg(index + 1));
            }
        }

        GeocoderItemView {
            search: geocoderSearch

            onClicked: {
                geocoderSearch.showLocation(index, true);
                var location = geocoderSearch.getLocation(index);
                zoomToLocation(location);
                selectLocation(location);
            }
        }

        MapCrosshairs {
            visible: (mapDraw.panZoom && mapDraw.mode === MapDraw.Mode.Capture) || geocoderSearch.hasLocations || mapDraw.isMovingVertex
        }

        XFormMapMarker {
            visible: gpsVertexButton.visible

            zoomLevel: 0

            coordinate: locationCoordinate
            image.source: "images/location.png"
            anchorX: 0.5
            anchorY: 0.5
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: footer

        anchors {
            fill: footerLayout
            margins: -footerLayout.anchors.margins
        }

        color: barBackgroundColor
        visible: footerLayout.visible
    }

    ColumnLayout {
        id: footerLayout

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 2 * AppFramework.displayScaleFactor

        XFormText {
            id: infoText

            Layout.fillWidth: true

            font {
                pointSize: 12
            }
            horizontalAlignment: Text.AlignHCenter
            color: barTextColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    showInfoPage();
                }
            }
        }

        HorizontalSeparator {
            Layout.fillWidth: true

            visible: infoText.visible
        }

        RowLayout {
            id: toolsLayout

            Layout.fillWidth: true

            layoutDirection: xform.layoutDirection
            spacing: 10 * AppFramework.displayScaleFactor
            visible: !readOnly

            XFormToolButton {
                id: panZoomButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("move")
                color: xform.style.titleTextColor

                visible: mapDraw.isSegmentedCaptureType
                checkable: true
                checked: mapDraw.panZoom

                onClicked: {
                    if (mapDraw.captureType !== MapDraw.CaptureType.None) {
                        mapDraw.panZoom = !mapDraw.panZoom;
                    }
                }
            }

            XFormToolButton {
                id: smartSketchLineButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("shapes")
                color: xform.style.titleTextColor

                visible: !isPolygon && isMethodSketch && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchLine)
                checked: sketch.active

                onClicked: {
                    if (sketch.active) {
                        sketch.cancel();
                        return;
                    }

                    function startDraw() {
                        mapDraw.setMode(MapDraw.Mode.View);
                        sketch.start();
                    }

                    confirmAreaSketch(Icons.bigIcon("shapes"), startDraw);
                }
            }

            XFormToolButton {
                id: sketchLineButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("freehand")
                color: xform.style.titleTextColor

                visible: !isPolygon && isMethodSketch && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchLine)
                checked: mapDraw.captureType === MapDraw.CaptureType.SketchLine

                onClicked: {
                    if (sketch.active) {
                        sketch.cancel();
                    }

                    if (mapDraw.mode === MapDraw.Mode.Capture) {
                        mapDraw.setMode(MapDraw.Mode.View);
                        mapDraw.undo();
                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.SketchLine);
                    }

                    confirmLineSketch(Icons.bigIcon("freehand"), startDraw);
                }
            }

            XFormToolButton {
                id: vertexLineButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("line")
                color: xform.style.titleTextColor

                visible: !isPolygon && isMethodVertex && (mapDraw.mode === MapDraw.Mode.View || mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line)
                checked: !mapDraw.panZoom && !isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line) {
                        mapDraw.panZoom = !mapDraw.panZoom;

                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.Line);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Line Drawing"),
                                                                  icon: Icons.bigIcon("line"),
                                                                  question: qsTr("Are you sure you want to re-draw the line?"),
                                                                  informativeText: qsTr("This action will replace the existing line.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            XFormToolButton {
                id: smartSketchAreaButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("shapes")
                padding: 3 * AppFramework.displayScaleFactor
                color: xform.style.titleTextColor

                visible: isPolygon && isMethodSketch && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchPolygon)
                checked: sketch.active

                onClicked: {
                    if (sketch.active) {
                        sketch.cancel();
                        return;
                    }

                    function startDraw() {
                        mapDraw.setMode(MapDraw.Mode.View);
                        sketch.start();
                    }

                    confirmAreaSketch(Icons.bigIcon("shapes"), startDraw);
                }
            }

            XFormToolButton {
                id: sketchAreaButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("lasso")
                color: xform.style.titleTextColor

                visible: isPolygon && isMethodSketch && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchPolygon)
                checked: mapDraw.captureType === MapDraw.CaptureType.SketchPolygon

                onClicked: {
                    if (sketch.active) {
                        sketch.cancel();
                    }

                    if (mapDraw.mode === MapDraw.Mode.Capture) {
                        mapDraw.setMode(MapDraw.Mode.View);
                        mapDraw.undo();
                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.SketchPolygon);
                    }

                    confirmAreaSketch(Icons.bigIcon("lasso"), startDraw);
                }
            }

            XFormToolButton {
                id: vertexPolygonButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("polygon-vertices")
                color: xform.style.titleTextColor

                visible: isPolygon && isMethodVertex && (mapDraw.mode === MapDraw.Mode.View || mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon)
                checked: !mapDraw.panZoom && isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon) {
                        mapDraw.panZoom = !mapDraw.panZoom;

                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.Polygon);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Area Drawing"),
                                                                  icon: Icons.bigIcon("polygon-vertices"),
                                                                  question: qsTr("Are you sure you want to re-draw the area?"),
                                                                  informativeText: qsTr("This action will replace the existing area.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            VerticalSeparator {
                Layout.fillHeight: true
                Layout.leftMargin: - toolsLayout.spacing / 2
                Layout.rightMargin: Layout.leftMargin

                visible: panZoomButton.visible
            }

            XFormToolButton {
                id: cancelVertexEditButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("vertex-x")
                mirror: xform.isRightToLeft
                color: xform.style.titleTextColor

                visible: mapDraw.mode === MapDraw.Mode.Edit

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                    mapDraw.restoreSnapshot();
                }
            }

            VerticalSeparator {
                Layout.fillHeight: true
                Layout.leftMargin: - toolsLayout.spacing / 2
                Layout.rightMargin: Layout.leftMargin

                visible: cancelVertexEditButton.visible
            }

            XFormToolButton {
                id: gpsVertexButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("vertex-gps")
                color: xform.style.titleTextColor

                visible: isMethodVertex && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType && positionSourceConnection.active
                enabled: locationCoordinate && locationCoordinate.isValid

                onClicked: {
                    captureVertex(locationCoordinate);
                }
            }

            XFormToolButton {
                Layout.alignment: Qt.AlignRight

                source: Icons.icon("vertex-plus")
                color: xform.style.titleTextColor

                visible: isMethodVertex && mapDraw.panZoom && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType

                onClicked: {
                    captureVertex(map.center);
                }

                onPressAndHold: {
                    editCoordinate(-1, map.center, qsTr("Add vertex"));
                }
            }

            XFormToolButton {
                id: vertexEditButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("vertex-edit")
                color: xform.style.titleTextColor

                visible: isMethodVertex && mapDraw.canEdit && mapDraw.mode === MapDraw.Mode.View || (mapDraw.mode === MapDraw.Mode.Edit && !mapDraw.isMovingVertex)
                checked: mapDraw.mode === MapDraw.Mode.Edit && !mapDraw.isMovingVertex

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.Edit);
                }
            }

            XFormToolButton {
                Layout.alignment: Qt.AlignRight

                source: Icons.icon("vertex-move")
                color: xform.style.titleTextColor

                visible: mapDraw.isMovingVertex
                checked: mapDraw.isMovingVertex

                onClicked: {
                    mapDraw.endVertexMove();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            XFormToolButton {
                id: undoButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("undo")
                mirror: xform.isRightToLeft
                color: xform.style.titleTextColor

                visible: mapDraw.canUndo

                onClicked: {
                    if (sketch.active) {
                        sketch.cancel();
                    }

                    if (mapDraw.isMovingVertex) {
                        mapDraw.endVertexMove(true);
                        return;
                    }

                    mapDraw.undo();
                    if (mapDraw.isSketchingCaptureType) {
                        mapDraw.setMode(MapDraw.Mode.View);
                    }
                }
            }

            VerticalSeparator {
                Layout.fillHeight: true
                Layout.leftMargin: - toolsLayout.spacing / 2
                Layout.rightMargin: Layout.leftMargin

                visible: undoButton.visible && (editVertexOkButton.visible || editOkButton.visible || lineOkButton.visible || polygonOkButton.visible)
            }

            XFormToolButton {
                id: lineOkButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("line-check")
                color: xform.style.titleTextColor

                enabled: isEditValid
                visible: !isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                id: polygonOkButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("polygon-vertices-check")
                color: xform.style.titleTextColor

                enabled: isEditValid
                visible: isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                id: editVertexOkButton

                source: Icons.icon("vertex-check")
                color: xform.style.titleTextColor

                visible: mapDraw.mode === MapDraw.Mode.Edit

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                id: editOkButton

                Layout.alignment: Qt.AlignRight

                source: Icons.icon("check")
                color: xform.style.titleTextColor
                enabled: isEditValid
                visible: isEditValid && mapDraw.mode === MapDraw.Mode.View && !isEmpty

                onClicked: {
                    forceActiveFocus();
                    positionSourceConnection.stop();
                    mapObject = mapDraw.mapPoly;
                    accepted();
                    geopolyCapture.parent.pop();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        listener: "XFormGeopointCapture"

        onNewPosition: {
            if (position.latitudeValid & position.longitudeValid) {
                if (map.zoomLevel < map.positionZoomLevel && map.positionMode == map.positionModeAutopan) {
                    map.zoomLevel = map.positionZoomLevel;
                }

                locationCoordinate = position.coordinate;
            }
        }

        onActiveChanged: {
            locationCoordinate = QtPositioning.coordinate();
        }
    }

    //--------------------------------------------------------------------------

    function selectLocation(location) {
        if (!location.coordinate.isValid) {
            return;
        }

        geocoderSearch.locationCommitted = true;

        if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType) {
            mapDraw.addVertex(location.coordinate);
        }
    }

    function resetGeocoder(location) {
        if (location) {
            geocoderSearch.text = "";//location.displayAddress;
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

    function zoomToLocation(location) {
        map.center = location.coordinate;
    }

    //--------------------------------------------------------------------------

    function panTo(coord) {

        if (positionSourceConnection.active && map.positionMode === map.positionModeAutopan) {
            map.positionMode = map.positionModeOn;
        }

        map.center = coord;
    }

    //--------------------------------------------------------------------------

    function editCoordinate(index, coordinate, title, subTitle) {
        forceActiveFocus();
        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: geopointCapture,
                                        properties: {
                                            title: title,
                                            subTitle: subTitle || "",
                                            editLatitude: coordinate.latitude,
                                            editLongitude: coordinate.longitude,
                                            mapSettings: mapSettings,
                                            editIndex: index
                                        }
                                    });

    }

    //--------------------------------------------------------------------------

    function captureVertex(coordinate) {
        if (mapDraw.isCapturingVertex) {
            mapDraw.addVertex(coordinate);
        } else {
            mapDraw.startCapture(coordinate);
            mapDraw.baseMap.gesture.enabled = mapDraw.panZoom;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointCapture

        XFormGeopointCapture {
            id: _geopointCapture

            property int editIndex

            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: previewMap.plugin
            markerImage: "images/pin-4.png"

            onAccepted: {
                if (_geopointCapture.changeReason === 1) {
                    var coordinate = QtPositioning.coordinate(editLatitude, editLongitude);

                    console.log("edited coordinate:", JSON.stringify(coordinate, undefined, 2));

                    if (editIndex >= 0) {
                        mapDraw.replaceVertex(editIndex, coordinate);
                    } else {
                        mapDraw.addVertex(coordinate);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            iconColor: xform.style.deleteIconColor
        }
    }

    //--------------------------------------------------------------------------

    function confirmLineSketch(icon, callback) {
        if (isEmpty) {
            callback();
        } else {
            var panel = confirmPanel.createObject(app, {
                                                      title: qsTr("Confirm Line Sketch"),
                                                      icon: icon,
                                                      question: qsTr("Are you sure you want to re-sketch the line?"),
                                                      informativeText: qsTr("This action will replace the existing line.")
                                                  });

            panel.show(callback, undefined);
        }
    }

    function confirmAreaSketch(icon, callback) {
        if (isEmpty) {
            callback();
        } else {
            var panel = confirmPanel.createObject(app, {
                                                      title: qsTr("Confirm Area Sketch"),
                                                      icon: icon,
                                                      question: qsTr("Are you sure you want to re-sketch the area?"),
                                                      informativeText: qsTr("This action will replace the existing area.")
                                                  });

            panel.show(callback, undefined);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: infoPage

        XFormGeopolyInfoPage {
        }
    }

    //--------------------------------------------------------------------------

    function showInfoPage() {
        forceActiveFocus();
        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: infoPage,
                                        properties: {
                                            title: labelText.text,
                                            isPolygon: isPolygon,
                                            coordinates: mapDraw.mapPoly.path
                                        }
                                    });

    }

    //--------------------------------------------------------------------------
}
