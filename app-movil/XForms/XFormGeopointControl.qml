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
import QtQml 2.12
import QtQuick.Layouts 1.12
import QtLocation 5.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

import "XForm.js" as XFormJS

ColumnLayout {
    id: control

    //--------------------------------------------------------------------------

    property XFormData formData

    property var formElement

    property XFormBinding binding

    property alias isValid: geoposition.isValid

    property alias mapSettings: previewMap.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding.isReadOnly

    property color accurateFillColor: "#4000B2FF"
    property color accurateBorderColor: "#8000B2FF"
    property color inaccurateFillColor: "#40FF0000"
    property color inaccurateBorderColor: "#A0FF0000"

    property var calculatedValue

    readonly property string coordsFormat: mapSettings.previewCoordinateFormat
    readonly property bool isLatLonFormat: XFormJS.isLatLonFormat(coordsFormat)
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property alias isOnline: previewMap.isOnline

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated, 4=Position source

    readonly property bool supportsZ: XFormJS.geometryTypeHasZ(binding.esriFieldType)

    property int averageSeconds: 0
    property int averageTotalCount: 0

    property real padding: 8 * AppFramework.displayScaleFactor
    readonly property int buttonSize: xform.style.buttonBarSize
    readonly property url positionIcon: Icons.icon(positionSourceConnection.active ? "gps-on" : "gps-off")

    //--------------------------------------------------------------------------

    property real previewMapHeight: kDefaultPreviewMapHeight
    readonly property real kDefaultPreviewMapHeight: (ControlsSingleton.inputHeight + control.spacing) * 3

    //--------------------------------------------------------------------------

    readonly property int kQualityGood: 0
    readonly property int kQualityWarning: 1
    readonly property int kQualityError: 2

    readonly property var kQualityBackgroundColors: [
        "#008000",
        "#FFBF00",
        "#A80000"
    ]

    readonly property var kQualityIcons: [
        "",
        Icons.icon("exclamation-mark-triangle", true),
        Icons.icon("exclamation-mark-circle", true)
    ]

    //--------------------------------------------------------------------------

    property int qualityStatus: kQualityGood
    property alias qualityMessage: qualityText.text

    readonly property color qualityTextColor: !isValid
                                              ? xform.style.inputTextColor
                                              : qualityStatus === kQualityError
                                                ? xform.style.inputErrorTextColor
                                                : changeReason === 3
                                                  ? xform.style.inputAltTextColor
                                                  : xform.style.inputTextColor


    readonly property color qualityBackgroundColor: kQualityBackgroundColors[qualityStatus]

    readonly property alias horizontalAccuracy: geoposition.horizontalAccuracy
    readonly property string accuracyMessgae: qsTr("Coordinates are not within the accuracy threshold of %1 m").arg(accuracyThreshold)
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])
    readonly property bool isAccurate: accuracyThreshold <= 0
                                       || !isFinite(accuracyThreshold)
                                       || (geoposition.horizontalAccuracyValid ? geoposition.horizontalAccuracy <= accuracyThreshold : true)
    property bool showAccuracy: true

    property var constraint
    property bool constraintOk: true

    readonly property string kAttributeQualityWarning: "esri:warning"
    property var warningExpressionInstance
    property bool warningOk: true
    property string warningMessage: qsTr("Location quality warning")

    //--------------------------------------------------------------------------

    readonly property var kIndicatorFillColors: [
        "#4000B2FF",
        "#40FFBF00",
        "#40FF0000"
    ]

    readonly property var kIndicatorBorderColors: [
        "#8000B2FF",
        "#80FFBF00",
        "#A0FF0000"
    ]

    readonly property color indicatorFillColor: kIndicatorFillColors[qualityStatus]
    readonly property color indicatorBorderColor: kIndicatorBorderColors[qualityStatus]

    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (isValid) {
            previewMap.zoomLevel = previewZoomLevel;
        } else {
            previewMap.zoomLevel = 0;
        }

        initializeQuality();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: "XFormGeopointControl" //AppFramework.typeOf(control, true)
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
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (!relevant || formData.changeBinding === binding.element) {
            return;
        }

        if (debug) {
            console.log(logCategory, "onCalculatedValueChanged changeReason:", changeReason, "geopoint:", JSON.stringify(calculatedValue, undefined, 2), "isValid:", isValid, geoposition.toString(), "default:", JSON.stringify(binding.defaultValue));
        }

        if (changeReason !== 1 || (!isValid && !binding.defaultValue)) {
            setValue(calculatedValue, 3);
            recalculateButton.enabled = true;
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        visible: !isValid && !readOnly

        Item {
            Layout.fillWidth: true
        }

        XFormButtonBar {
            spacing: xform.style.buttonBarSize * 0.6
            leftPadding: visibleItemsCount > 1 ? spacing : padding
            rightPadding: leftPadding

            XFormImageButton {
                id: positionButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: positionIcon

                PulseAnimation {
                    target: positionButton
                    running: positionSourceConnection.active
                }

                onClicked: {
                    forceActiveFocus();
                    positionSourceToggle();
                }

                onPressAndHold: {
                    forceActiveFocus();
                    averagingToggle();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: previewMap.hasMaps

                source: Icons.icon("map")

                onClicked: {
                    showCapturePage();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: recalculateButton.enabled && !readOnly && (changeReason === 1 || changeReason === 4)

                source: recalculateButton.imageSource

                onClicked: {
                    recalculateButton.clicked();
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

            implicitHeight: locationLayout.height + padding * 2

            color: xform.style.inputBackgroundColor
            radius: xform.style.inputBackgroundRadius

            border {
                width: ((isValid && qualityStatus > kQualityGood)
                        ? xform.style.errorBorderWidth
                        : xform.style.inputBorderWidth) * AppFramework.displayScaleFactor

                color: (isValid && qualityStatus > kQualityGood)
                       ? qualityBackgroundColor
                       : xform.style.inputBorderColor
            }

            ColumnLayout {
                id: locationLayout

                anchors.centerIn: parent

                width: parent.width - padding * 2
                spacing: padding

                ColumnLayout {
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true

                        layoutDirection: xform.layoutDirection
                        spacing: padding

                        StyledImageButton {
                            id: locationButton

                            Layout.preferredWidth: ControlsSingleton.inputTextHeight
                            Layout.preferredHeight: ControlsSingleton.inputTextHeight

                            enabled: positionSourceConnection.valid && !readOnly

                            source: positionIcon
                            color: xform.style.inputTextColor
                            image.opacity: 1

                            mouseArea.anchors.margins: -control.padding

                            PulseAnimation {
                                target: locationButton
                                running: positionSourceConnection.active
                            }

                            onClicked: {
                                forceActiveFocus();
                                positionSourceToggle();
                            }

                            onPressAndHold: {
                                forceActiveFocus();
                                averagingToggle();
                            }
                        }

                        Text {
                            id: locationText

                            Layout.fillWidth: true

                            visible: isValid

                            color: qualityTextColor

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

                            color: qualityTextColor

                            onClicked: {
                                control.clear();
                            }
                        }
                    }
                }

                XFormIconLabel {
                    id: qualityText

                    Layout.fillWidth: true

                    visible: qualityStatus > kQualityGood && text > ""

                    icon {
                        source: kQualityIcons[qualityStatus]
                        color: qualityBackgroundColor
                    }

                    label {
                        color: qualityTextColor
                    }
                }

                Item {
                    Layout.fillWidth: true

                    Layout.preferredHeight: previewMapHeight// (ControlsSingleton.inputHeight + control.spacing) * 3
                    Layout.fillHeight: xform.isGridTheme

                    visible: isValid && previewMap.hasMaps

                    XFormPreviewMap {
                        id: previewMap

                        anchors.fill: parent

                        nodeset: binding.nodeset
                        formSettings: xform.settings
                        mapSettings: xform.mapSettings

                        zoomLevel: previewZoomLevel
                        center {
                            latitude: geoposition.latitude
                            longitude: geoposition.longitude
                        }

                        MapCircle {
                            visible: showAccuracy && geoposition.horizontalAccuracyValid && geoposition.horizontalAccuracy > 0

                            radius: horizontalAccuracy
                            center: mapMarker.coordinate
                            color: indicatorFillColor
                            border {
                                width: 1
                                color: indicatorBorderColor
                            }
                        }

                        XFormMapMarker {
                            id: mapMarker

                            visible: isValid
                            coordinate {
                                latitude: geoposition.latitude
                                longitude: geoposition.longitude
                            }
                        }
                    }

                    XFormText {
                        anchors {
                            fill: parent
                            margins: 10 * AppFramework.displayScaleFactor
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

                        enabled: !readOnly
                        hoverEnabled: true

                        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            showCapturePage();
                        }
                    }
                }

                XFormText {
                    Layout.fillWidth: true

                    visible: (positionSourceConnection.active && geoposition.averaging) || geoposition.averageCount > 0
                    text: qsTr("Averaged %1 of %2 positions (%3 seconds)").arg(geoposition.averageCount).arg(averageTotalCount).arg(averageSeconds)
                    color: xform.style.textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Qt.AlignHCenter
                }
            }
        }

        XFormRecalculateButton {
            id: recalculateButton

            enabled: false
            visible: enabled && !readOnly && (changeReason === 1 || changeReason === 4)

            onClicked: {
                if (positionSourceConnection.active) {
                    positionSourceConnection.stop();
                }

                changeReason = 0;
                formData.triggerCalculate(binding.element);
                valueModified(control);
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormErrorMessage {
        Layout.fillWidth: true

        style: xform.style
        locale: xform.locale

        visible: !isValid && !readOnly && text > ""

        text: positionSourceConnection.errorString
    }

    //--------------------------------------------------------------------------

    XFormGeoposition {
        id: geoposition

        debug: control.debug

        onChanged: {
            if (debug) {
                console.log(logCategory, "Updating value from geoposition for:", binding.nodeset);
            }

            updateValue();
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        property var lastPosition: ({})

        positionSourceManager: xform.positionSourceManager
        listener: binding.nodeset

        onNewPosition: {
            if (control.debug) {
                console.log(logCategory, "Updating geopoint nodeset:", binding.nodeset, "position:", JSON.stringify(position, undefined, 2));
            }
            lastPosition = position;
            updatePosition(position);
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: 1000
        running: positionSourceConnection.active && geoposition.averaging
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            averageSeconds++;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointCapture

        XFormGeopointCapture {
            id: _geopointCapture

            debug: control.debug

            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: previewMap.plugin
            mapName: previewMap.mapName

            title: textValue(formElement.label, "", "long")
            subTitle: textValue(formElement.hint, "", "long")
            marker: mapMarker

            onAccepted: {
                previewMap.setMapType(map.activeMapType);

                if (control.debug) {
                    console.log(logCategory, "accepted:", changeReason, "control.changeReason:", control.changeReason);
                }

                switch (_geopointCapture.changeReason) {

                case 1:
                    var coordinate = {
                        latitude: editLatitude,
                        longitude: editLongitude,
                        altitude: editAltitude,
                        horizontalAccuracy: editHorizontalAccuracy,
                        verticalAccuracy: editVerticalAccuracy,
                        positionSourceType: XFormPositionSourceManager.PositionSourceType.User
                    };

                    if (editLocation && editLocation.displayAddress) {
                        var address = editLocation.displayAddress;
                        address.objectName = undefined;
                        coordinate.displayAddress = address;
                    }

                    if (editLocation && editLocation.attributes) {
                        var attributes = editLocation.attributes;
                        attributes.objectName = undefined;
                        coordinate.attributes = attributes;
                    }

                    if (control.debug) {
                        console.log(logCategory, "edited coordinate:", JSON.stringify(coordinate, undefined, 2));
                    }

                    geoposition.fromObject(coordinate);

                    previewMap.zoomLevel = previewZoomLevel;

                    control.changeReason = 1;
                    valueModified(control);
                    break;

                case 0:
                    // User didn't interact with the map control at all.
                    updatePosition(_geopointCapture.lastPositionSourceReading);
                    break;

                case 4:
                    updatePosition(_geopointCapture.lastPositionSourceReading);
                    break;

                case 2:
                case 3:
                    break;
                }
            }

            onRejected: {
                previewMap.setMapType(map.activeMapType);
            }
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        positionSourceConnection.stop();
        setValue(null, 1);
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function positionSourceToggle() {
        valueModified(control);

        if (positionSourceConnection.active) {
            geoposition.averageEnd();
            positionSourceConnection.stop();
        } else {
            geoposition.averageClear();
            positionSourceConnection.start();
        }
    }

    //--------------------------------------------------------------------------

    function averagingToggle() {
        valueModified(control);

        if (!geoposition.averaging || !positionSourceConnection.active) {
            startAverage();
        }
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    function updatePosition(position) {
        if (!position.coordinate) {
            return;
        }

        var isAcceptable = qualityStatus <= kQualityWarning;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "isAcceptable:", isAcceptable, "changeReason:", changeReason, "coordinate:", position.coordinate);
        }

        if (geoposition.averaging) {
            if (isAcceptable) {
                geoposition.averagePosition(position);
            }

            averageTotalCount++;
        } else {
            geoposition.fromPosition(position);

            if (isAcceptable) {
                positionSourceConnection.stop();
            }
        }

        previewMap.zoomLevel = previewZoomLevel;
        changeReason = 4;
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "geoposition:", JSON.stringify(geoposition.toObject()));
        }

        formData.setValue(binding.element, geoposition.toObject());
        previewMap.zoomLevel = previewZoomLevel;

        locationText.text = formatLocation();
    }

    //--------------------------------------------------------------------------

    function formatLocation() {
        if (!isValid) {
            return "";
        }

        var text = formatCoordinate(geoposition, coordsFormat);

        if (geoposition.horizontalAccuracyValid) {
            text += " ± %1 m".arg(XFormJS.round(geoposition.horizontalAccuracy, geoposition.horizontalAccuracy < 1 ? mapSettings.horizontalAccuracyPrecisionHigh : mapSettings.horizontalAccuracyPrecisionLow))
        }

        if (supportsZ && geoposition.altitudeValid) {
            text += ", %1".arg(XFormJS.round(geoposition.altitude, geoposition.verticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow));

            if (geoposition.verticalAccuracyValid) {
                text += " ± %1".arg(XFormJS.round(geoposition.verticalAccuracy, geoposition.verticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow))
            }

            text += " m";
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "value:", JSON.stringify(value), "reason:", reason, "changeReason:", changeReason, "nodeset:", binding.nodeset);
            console.trace();
        }

        if (value === "position" || value === "average") {
            var doAverage = value === "average";

            if (debug) {
                console.log(logCategory, "Activating position source for:", binding.nodeset, "currentValue:", JSON.stringify(geoposition.toObject()));
            }

            geoposition.clear();

            if (doAverage) {
                startAverage();
            }
            positionSourceConnection.start();

            return;
        }

        if (XFormJS.isNullOrUndefined(value)) {
            geoposition.clear();
            return;
        }

        if ((changeReason === 1 || changeReason === 3) && positionSourceConnection.active) {
            console.log(logCategory, arguments.callee.name, "Stopping position source for:", binding.nodeset, "reason:", reason, "changeReason:", changeReason);
            positionSourceConnection.stop();
        }

        var doZoom = false;

        if (typeof value === "object") {
            geoposition.fromObject(value);

            doZoom = true;
        } else if (typeof value === "string") {
            var coordinate = XFormJS.parseGeopoint(value);

            if (coordinate && coordinate.isValid) {
                geoposition.fromObject(coordinate);

                doZoom = true;
            } else {
                geoposition.clear();
            }
        } else {
            geoposition.clear();
        }

        if (doZoom) {
            previewMap.zoomLevel = previewZoomLevel;
        }
    }

    //--------------------------------------------------------------------------

    function showCapturePage() {
        // prevent double clicking
        enabled = false;

        forceActiveFocus();
        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: geopointCapture,
                                        properties: {
                                            formElement: formElement,
                                            editLatitude: geoposition.latitude,
                                            editLongitude: geoposition.longitude,
                                            editAltitude: geoposition.altitude,
                                            editHorizontalAccuracy: geoposition.horizontalAccuracy,
                                            editVerticalAccuracy: geoposition.verticalAccuracy,
                                            showAltitude: supportsZ,
                                            mapSettings: mapSettings,
                                            lastPositionSourceReading: positionSourceConnection.lastPosition
                                        }
                                    });

        positionSourceConnection.stop();
    }

    Timer {
        running: !enabled
        interval: 250
        repeat: false

        onTriggered: enabled = true
    }

    //--------------------------------------------------------------------------

    function startAverage() {
        console.log(logCategory, "startAverage");
        averageTotalCount = 0;
        averageSeconds = 0;
        geoposition.averageBegin();
    }

    //--------------------------------------------------------------------------

    function formatCoordinate(geoposition, coordinateFormat) {
        var coordinate = QtPositioning.coordinate(geoposition.latitude, geoposition.longitude);

        return XFormJS.formatCoordinate(coordinate, coordinateFormat);
    }

    //--------------------------------------------------------------------------

    function initializeQuality() {

        var bindElement = binding.element;

        constraint = formData.createConstraint(this, bindElement);
        if (constraint) {
            if (!(constraint.message > "")) {
                constraint.message = qsTr("Location quality constraint not satisfied");
            }

            constraintOk = constraint.expressionInstance.boolBinding(false);

            console.log(logCategory, "geopoint constraint expression:", constraint.expressionInstance.expression, "message:", constraint.message);
        }

        var expression = formData.getExpression(bindElement, kAttributeQualityWarning);
        if (expression) {
            warningExpressionInstance = formData.expressionsList.addExpression(
                        expression,
                        binding.nodeset,
                        "warning",
                        true);

            var message = bindElement["@" + kAttributeQualityWarning + "_message"];
            if (message > "") {
                warningMessage = message;
            }

            warningOk = warningExpressionInstance.boolBinding(false);

            console.log(logCategory, "geopoint warning expression:", warningExpressionInstance.expression, "message:", warningMessage);
        }
    }

    //--------------------------------------------------------------------------

    onIsValidChanged: {
        updateQuality();
    }

    onIsAccurateChanged: {
        updateQuality();
    }

    onConstraintOkChanged: {
        updateQuality();
    }

    onWarningOkChanged: {
        updateQuality();
    }

    //--------------------------------------------------------------------------

    function updateQuality() {
        if (debug) {
            console.log(logCategory, "updateQuality");

            console.log(logCategory, "isValid:", isValid);
            console.log(logCategory, "isAccurate:", isAccurate, "threshold:", accuracyThreshold, "horizontalAccuracy:", geoposition.horizontalAccuracy, "valid:", geoposition.horizontalAccuracyValid);
            console.log(logCategory, "constraintOk:", constraintOk);
            console.log(logCategory, "warningOk:", warningOk);
        }

        if (!isValid) {
            qualityMessage = "";
            qualityStatus = kQualityError;

            return;
        }

        if (!isAccurate) {
            qualityMessage = accuracyMessgae;
            qualityStatus = kQualityError;

            return;
        }

        if (!constraintOk) {
            qualityMessage = constraint.message;
            qualityStatus = kQualityError;

            return;
        }


        if (!warningOk) {
            qualityMessage = warningMessage;
            qualityStatus = kQualityWarning;

            return;
        }

        qualityMessage = "";
        qualityStatus = kQualityGood;
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        property string symbolDefinition
        property string heightDefinition

        element: control.formElement
        attribute: kAttributeStyle

        debug: control.debug

        Component.onCompleted: {
            bind(controlStyle, "symbolDefinition", "symbol");
            bind(previewMap, previewMap.kPropertyMapName, "map");
            bind(controlStyle, "heightDefinition", "height");
        }

        onSymbolDefinitionChanged: {
            if (debug) {
                console.log(logCategory, "symbolDefinition:", JSON.stringify(symbolDefinition));
            }

            var urlInfo = AppFramework.urlInfo("");
            urlInfo.fromUserInput(symbolDefinition);

            if (debug) {
                console.log(logCategory, "symbol host:", JSON.stringify(urlInfo.host), "queryParameters:", JSON.stringify(urlInfo.queryParameters));
            }

            if (!urlInfo.isValid) {
                console.warn(logCategory, "Invalid url:", urlInfo.url);
                mapMarker.reset();
                return;
            }

            var image = urlInfo.host;
            if (xform.mediaFolder.fileExists(image)) {
                mapMarker.image.source = xform.mediaFolder.fileUrl(image);

                var x = 0.5;
                var y = 1;
                var scale = 1;

                var parameters = urlInfo.queryParameters;

                var keys = Object.keys(parameters);

                keys.forEach(function (key) {
                    var value = parameters[key];

                    if (debug) {
                        console.log(logCategory, "key:", JSON.stringify(key), "=", JSON.stringify(value));
                    }

                    switch (key) {
                    case "x" :
                        x = Number(value);
                        break;

                    case "y" :
                        y = Number(value);
                        break;

                    case "scale" :
                        scale = Number(value);
                        break;
                    }

                });

                if (isFinite(x)) {
                    mapMarker.anchorX = x;
                }

                if (isFinite(y)) {
                    mapMarker.anchorY = y;
                }

                if (isFinite(scale)) {
                    mapMarker.imageScale = scale;
                }
            } else {
                mapMarker.reset();
            }
        }

        onHeightDefinitionChanged: {
            previewMapHeight = toHeight(heightDefinition, kDefaultPreviewMapHeight);
        }
    }

    //--------------------------------------------------------------------------
}
