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

import "XForm.js" as XFormJS
import "XFormGeometry.js" as Geometry

import "../Controls"
import "../Controls/Singletons"

ColumnLayout {
    id: control

    //--------------------------------------------------------------------------

    property XFormData formData

    property var formElement

    property XFormBinding binding
    property bool isPolygon: binding.type === "geoshape"
    readonly property var mapPoly: isPolygon ? mapPolygon : mapPolyline

    property alias mapSettings: previewMap.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding.isReadOnly
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])

    property var calculatedValue
    property var currentValue
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedValue, currentValue)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property alias isOnline: previewMap.isOnline

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property bool isValid: false

    property real padding: 8 * AppFramework.displayScaleFactor
    readonly property int buttonSize: xform.style.buttonBarSize

    property bool debug: false

    //--------------------------------------------------------------------------
    // TODO: Move to style

    property color lineColor: kDefaultLineColor
    property real lineWidth: kDefaultLineWidth
    property color fillColor: kDefaultFillColor
    property color vertexFillColor: "red"
    property color vertexOutlineColor: "white"
    property real vertexOutlineWidth: 1 * AppFramework.displayScaleFactor
    property real vertexRadius: 10

    property string method
    property bool showVertices: false

    //--------------------------------------------------------------------------

    property real previewMapHeight: kDefaultPreviewMapHeight
    readonly property real kDefaultPreviewMapHeight: (ControlsSingleton.inputHeight + control.spacing) * 3

    //--------------------------------------------------------------------------

    readonly property string kPropertyLineColor: "lineColor"
    readonly property string kPropertyLineWidth: "lineWidth"
    readonly property string kPropertyFillColor:"fillColor"
    readonly property string kPropertyMethod: "method"

    //--------------------------------------------------------------------------

    readonly property color kDefaultLineColor: "#00b2ff"
    readonly property real kDefaultLineWidth: 4
    readonly property color kDefaultFillColor: "#3000b2ff"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var parameters = XFormJS.parseParameters(appearance);
        if (debug) {
            console.log(logCategory, "parameters:", JSON.stringify(parameters, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(binding.element);
        } else {
            isValid = true;
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding.element && changeReason !== 1) {
            if (debug) {
                console.log("onCalculatedValueChanged:", JSON.stringify(calculatedValue, undefined, 2));
            }

            setValue(calculatedValue, 3);
            recalculateButton.enabled = true;
        }
    }

    //--------------------------------------------------------------------------

    onValueModified: {
        updateText();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        visible: !isValid && !readOnly

        Item {
            Layout.fillWidth: true
        }

        StyledImage {
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            color: xform.style.valueColor
            visible: !buttonBar.visible
            source: Icons.icon("no-map", xform.style.valueBold)
        }

        XFormButtonBar {
            id: buttonBar

            readonly property bool canRecalculate: recalculateButton.enabled && !readOnly && changeReason === 1

            spacing: xform.style.buttonBarSize * 0.6
            leftPadding: visibleItemsCount > 1 ? spacing : padding
            rightPadding: leftPadding
            visible: previewMap.hasMaps || canRecalculate

            XFormImageButton {
                id: mapButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: previewMap.hasMaps

                source: Icons.icon("map")

                onClicked: {
                    showCapturePage();
                }
            }

            XFormImageButton {
                id: recalcButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                enabled: recalculateButton.enabled
                visible: buttonBar.canRecalculate

                source: Icons.icon("refresh")

                onClicked: {
                    recalculate();
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        visible: isValid || readOnly

        layoutDirection: xform.layoutDirection
        spacing: padding

        Rectangle {
            Layout.fillWidth: true
            //            Layout.fillHeight: xform.isGridTheme

            implicitHeight: locationLayout.height + padding * 2

            color: xform.style.inputBackgroundColor
            radius: xform.style.inputBackgroundRadius

            border {
                width: xform.style.inputBorderWidth
                color: xform.style.inputBorderColor
            }

            ColumnLayout {
                id: locationLayout

                anchors.centerIn: parent

                width: parent.width - padding * 2
                spacing: padding


                RowLayout {
                    Layout.fillWidth: true

                    layoutDirection: xform.layoutDirection
                    spacing: padding

                    Text {
                        id: locationText

                        Layout.fillWidth: true

                        visible: isValid

                        color: changeReason === 3
                               ? xform.style.inputAltTextColor
                               : xform.style.inputTextColor

                        font {
                            family: xform.style.inputFontFamily
                            pointSize: xform.style.inputPointSize
                            bold: xform.style.inputBold
                        }

                        horizontalAlignment: xform.localeInfo.textAlignment
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    InputClearButton {
                        visible: !readOnly && isValid

                        color: locationText.color

                        onClicked: {
                            control.clear();
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true

                    Layout.preferredHeight: previewMapHeight
                    Layout.fillHeight: xform.isGridTheme

                    visible: isValid && previewMap.hasMaps

                    XFormPreviewMap {
                        id: previewMap

                        anchors.fill: parent

                        visible: hasMaps

                        debug: control.debug

                        nodeset: binding.nodeset
                        formSettings: xform.settings
                        mapSettings: xform.mapSettings

                        center {
                            latitude: mapSettings.latitude
                            longitude : mapSettings.longitude
                        }

                        MapItemView {
                            id: verticesView

                            model: showVertices ? mapPoly.path : null

                            delegate: MapCircle {
                                center {
                                    latitude: verticesView.model[index].latitude
                                    longitude: verticesView.model[index].longitude
                                }

                                radius: vertexRadius
                                color: vertexFillColor
                                border {
                                    color: vertexOutlineColor
                                    width: vertexOutlineWidth
                                }
                            }
                        }

                        MapPolyline {
                            id: mapPolyline

                            visible: false

                            line {
                                color: lineColor
                                width: lineWidth * AppFramework.displayScaleFactor
                            }
                        }

                        MapPolygon {
                            id: mapPolygon

                            visible: false
                            color: fillColor

                            border {
                                color: lineColor
                                width: lineWidth * AppFramework.displayScaleFactor
                            }
                        }
                    }

                    Text {
                        anchors {
                            fill: parent
                            margins: 10
                        }

                        visible: isValid && !previewMap.hasMaps

                        text: isOnline
                              ? qsTr("Map preview not available")
                              : qsTr("Offline map preview not available")

                        color: "red"
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: previewMap.hasMaps && ((isValid && readOnly) || !readOnly)

                        onClicked: {
                            showCapturePage();
                        }

                        onPressAndHold: {
                            showVertices = !showVertices;
                        }
                    }
                }
            }
        }

        XFormRecalculateButton {
            id: recalculateButton

            enabled: false
            visible: enabled && !readOnly && changeReason === 1

            onClicked: {
                recalculate();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopolyCapture

        XFormGeopolyCapture {
            formElement: control.formElement
            readOnly: control.readOnly
            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: previewMap.plugin
            mapName: previewMap.mapName
            isPolygon: control.isPolygon
            mapObject: mapPoly
            lineColor: control.lineColor
            lineWidth: control.lineWidth * AppFramework.displayScaleFactor
            fillColor: control.fillColor
            method: control.method.trim()

            onAccepted: {
                previewMap.setMapType(map.activeMapType);
                setValue(mapObject.path, 1);
                valueModified(control);
            }

            onRejected: {
                previewMap.setMapType(map.activeMapType);
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        property string heightDefinition

        element: control.formElement
        attribute: kAttributeStyle

        debug: control.debug

        Component.onCompleted: {
            bind(control, undefined, kPropertyLineColor, kDefaultLineColor);
            bind(control, undefined, kPropertyLineWidth, kDefaultLineWidth);
            bind(control, undefined, kPropertyFillColor, kDefaultFillColor);
            bind(control, undefined, kPropertyMethod);

            bind(previewMap, previewMap.kPropertyMapName, "map");
            bind(controlStyle, "heightDefinition", "height");
        }

        onHeightDefinitionChanged: {
            previewMapHeight = toHeight(heightDefinition, kDefaultPreviewMapHeight);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {

        if (debug) {
            console.log(logCategory, arguments.callee.name,"typeof:", typeof value, "isArray:", Array.isArray(value), "value:", JSON.stringify(value), "reason:", reason, "nodeset:", binding.nodeset);
        }

        if (typeof value === "string") {
            var o;

            try {
                o = JSON.parse(value);
            } catch (e) {
            }

            if (o && typeof o === "object") {
                value = o;
            }
        }

        var geometryValue;

        if (XFormJS.isEmpty(value)) {
            mapPoly.path = [];
            isValid = false;
        } else if (Array.isArray(value)) {
            if (Geometry.isPointsArray(value, true)) {
                mapPoly.path = Geometry.pointsToPath(value);
            } else {
                mapPoly.path = value;
            }

            zoomAll();
            isValid = mapPoly.path.length > 0
            geometryValue = XFormJS.toEsriGeometry(binding.type, mapPoly.path);
        } else if (typeof value === "object") {
            geometryValue = value;

            mapPoly.path = geometryToPath(geometryValue);
            zoomAll();
            isValid = mapPoly.path.length > 0
        }
        else if (typeof value === "string") {
            var geoshape = XFormJS.parsePoly(value);

            if (!geoshape.isEmpty) {

                mapPoly.path = geoshape.path;

                if (debug) {
                    console.log(logCategory, "mapPoly:", mapPoly, mapPoly.path, "geoshape:", typeof geoshape, AppFramework.typeOf(geoshape, true), JSON.stringify(geoshape));
                }

                isValid = true;
                geometryValue = XFormJS.toEsriGeometry(binding.type, mapPoly.path);
            }
        }
        else {
            console.error(logCategory, arguments.callee.name, "Unexpected value:", JSON.stringify(value));
        }

        if (debug) {
            console.log(logCategory, "geometryValue:", JSON.stringify(geometryValue, undefined, 2));
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && isEqual(geometryValue, currentValue)) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        //        formData.setValue(bindElement, XFormXFormJS.toBindingType(value, bindElement));
        formData.setValue(binding.element, geometryValue);

        zoomAll();
        updateText();
    }

    //--------------------------------------------------------------------------

    function zoomAll() {
        var zoomScale = 1.1;
        var zoomRegion = mapPoly.geoShape.boundingGeoRectangle();

        if (zoomRegion && zoomRegion.isValid && !zoomRegion.isEmpty) {
            if (zoomScale) {
                zoomRegion.width *= zoomScale;
                zoomRegion.height *= zoomScale;
            }

            previewMap.visibleRegion = zoomRegion;
            mapPoly.visible = true;
        }
    }

    //--------------------------------------------------------------------------

    function isEqual(value1, value2) {
        return false;
    }

    //------------------------------------------------------------------------------

    function geometryToPath(geometry) {
        var path = [];

        if (isPolygon && Array.isArray(geometry.rings)) {
            path = Geometry.pointsToPath(geometry.rings[0]);
        }
        else if (!isPolygon && Array.isArray(geometry.paths)) {
            path = Geometry.pointsToPath(geometry.paths[0]);
        }
        else if (Array.isArray(geometry.coordinates)) {
            path = Geometry.pointsToPath(geometry.coordinates[0]);
        }

        return path;
    }

    //--------------------------------------------------------------------------

    function showCapturePage() {
        // prevent double clicking
        enabled = false;

        Qt.inputMethod.hide();

        xform.popoverStackView.push({
                                        item: geopolyCapture,
                                        properties: {
                                        }
                                    });
    }

    Timer {
        running: !enabled
        interval: 250
        repeat: false

        onTriggered: enabled = true
    }

    //--------------------------------------------------------------------------

    function clear() {
        setValue(null, 1);
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function recalculate() {
        changeReason = 0;
        formData.triggerCalculate(binding.element);
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function updateText() {
        if (!isValid) {
            locationText.text = "";
            return;
        }

        var geopath = QtPositioning.path(mapPoly.path);
        var length = Geometry.displayLength(Geometry.geopathLength(geopath, isPolygon), xform.locale);

        if (isPolygon) {
            var area = Geometry.displayArea(Geometry.pathArea(geopath.path), xform.locale);
            locationText.text = qsTr("Area: %1, Perimeter: %2").arg(area).arg(length);
        } else {
            locationText.text = qsTr("Length: %1").arg(length);
        }
    }

    //--------------------------------------------------------------------------
}
