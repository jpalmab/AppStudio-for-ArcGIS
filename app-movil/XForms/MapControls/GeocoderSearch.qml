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
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtPositioning 5.8
import QtLocation 5.9

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Sql 1.0

import "../../Controls" as CustomControls

//------------------------------------------------------------------------------

Item {
    id: control

    property bool debug: false

    readonly property bool clearVisible: text > ""
    readonly property string kSearchAllFlag: "search_all"
    property alias textField: textField
    property alias text: textField.text
    property alias geocodeTimer: geocodeTimer
    property alias geocodeModel: geocoderResults
    property bool busy: false
    property alias textChangedTimeout: geocodeTimer.interval

    property real requiredFontSize: baseFontSize * xform.style.textScaleFactor

    property Component locationDelegate: locationDelegate
    property int minimumLocationDelegateHeight: 40 * AppFramework.displayScaleFactor
    property int viewLimit: 4
    property var referenceCoordinate: QtPositioning.coordinate()
    property var locale: Qt.locale()

    property var worldBounds: QtPositioning.rectangle(QtPositioning.coordinate(0,0), 360, 180)
    property Map map

    property string fontFamily: xform.style.fontFamily
    property real baseFontSize: 15
    property color inputTextColor: "#000000"
    property color inputErrorTextColor: xform.style.inputErrorTextColor
    property bool inputError: false

    property int currentIndex: -1
    property string locationPinImage: "images/location-pin.png"
    property string selectedPinImage: "images/selected-location-pin.png"
    property string collectionImage: "images/collection.png"
    property color locationPinTextColor: "black"
    property color selectedPinTextColor: "black"
    property url arrowImage: "images/direction_arrow.png"
    property url centerImage: "images/position-cursor.png"

    property bool searchEnabled: true
    property bool isOnline: Networking.isOnline
    readonly property bool canSearch: isOnline && searchEnabled
    property bool hasCoordinate
    property var coordInfo: null
    property var parseOptions

    property var geocoderSpecification: null
    property var operation: null
    property bool searchAllGeocoders: false
    property int mapSpatialReference: 4326
    property int outSpatialReference: 4326
    property bool useQtGeocoder: geocoders.count <= 0 // not implemented
    property bool hasLocations: geocoderResults.count > 0
    property bool locationCommitted: false

    property string searchModeHeader: qsTr("Search Mode")
    property string geocoderHeader: qsTr("Geocoder")
    property string locatorHeader: qsTr("Locator")

    property color locationHeaderTextColor: xform.style.titleBackgroundColor
    property color locationHeaderBackgroundColor: xform.style.titleTextColor

    property var geocoderResultsIndex: []
    property int geocoderResultsCounter: 0

    //--------------------------------------------------------------------------

    property int searchMode: kSearchModeGlobalExtents
    readonly property int activeSearchMode: canSearch ? searchMode : kSearchModeCoordinates
    property var objectCache: app.objectCache

    property string langCode: AppFramework.localeInfo(xform.locale.uiLanguages[0]).esriName

    readonly property var kSearchModeImages: [
        "coordinates.png",
        "globe.png",
        "map.png",
    ]

    readonly property var kSearchModePlaceholderText: [
        qsTr("Map coordinate"),
        qsTr("Search location or map coordinate"),
        qsTr("Search location on map or coordinate"),
    ]

    readonly property int kSearchModeCoordinates: 0
    readonly property int kSearchModeGlobalExtents: 1
    readonly property int kSearchModeMapExtents: 2

    property bool coordinateModeTriggeredbyEditCoordinates: false
    property bool editingCoordsInitiated: false
    property int lastSearchMode: -1

    onCoordinateModeTriggeredbyEditCoordinatesChanged: {
        if (coordinateModeTriggeredbyEditCoordinates) {
            lastSearchMode = searchMode;
            searchModeComboBox.currentIndex = searchModeComboBox.getIndex(kSearchModeCoordinates);
            searchMode = kSearchModeCoordinates;
        }
        else {
            searchModeComboBox.currentIndex = searchModeComboBox.getIndex(lastSearchMode);
            searchMode = lastSearchMode;
            lastSearchMode = -1;
        }
    }

    //--------------------------------------------------------------------------

    signal locationClicked(int index, GeocoderLocation location, real distance)
    signal locationDoubleClicked(int index, GeocoderLocation location, real distance)
    signal locationPressAndHold(int index, GeocoderLocation location, real distance)
    signal locationIndicatorClicked(int index, GeocoderLocation location, real distance)
    signal commitLocation(int index, GeocoderLocation location);

    signal reverseGeocodeSuccess(GeocoderLocation location)
    signal resultsReturned(int resultCount)
    signal mapCoordinate(var coordinateInfo)

    signal geocoderError(string error)
    signal reverseGeocodeError(string error)
    signal cleared()

    //--------------------------------------------------------------------------

    implicitHeight: layout.height
    height: layout.height

    //--------------------------------------------------------------------------

    Connections {
        target: map

        onZoomLevelChanged: {
            //geocodeTimer.restart();
        }

        onCenterChanged: {
            //geocodeTimer.restart();
        }
    }

    onHasLocationsChanged: {
        currentIndex = -1;
    }

    onLocationCommittedChanged: {
        if (locationCommitted) {
            textField.cursorPosition = 0;
            Qt.inputMethod.hide();
        }
    }

    //--------------------------------------------------------------------------

    TextMetrics {
        id: textMetricHelper
        font.family: fontFamily
        font.pointSize: baseFontSize * xform.style.textScaleFactor
        text: "W"
    }

    ColumnLayout {
        id: layout

        width: parent.width

        spacing: 4 * AppFramework.displayScaleFactor

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1 * AppFramework.displayScaleFactor
            color: barTextColor
            opacity: 0.3
        }

        RowLayout {
            id: searchTextFieldContainer
            Layout.minimumHeight: textMetricHelper.height < 40 * AppFramework.displayScaleFactor ? 40 * AppFramework.displayScaleFactor : textMetricHelper.height
            Layout.fillWidth: true

            layoutDirection: xform.layoutDirection
            spacing: 2 * AppFramework.displayScaleFactor

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                color: "transparent"
                radius: 5 * AppFramework.displayScaleFactor

                StyledImageButton {
                    id: searchButton

                    anchors {
                        fill: parent
                        margins: 1 * AppFramework.displayScaleFactor
                    }

                    visible: true
                    width: height
                    checkable: true
                    checkedColor: xform.style.titleTextColor
                    uncheckedColor: xform.style.titleTextColor
                    checked: true
                    hasDropdown: true
                    source: "images/%1".arg(kSearchModeImages[activeSearchMode])

                    onClicked: {
                        searchTypePopup.open();
                    }

                    onPressAndHold: {
                        if (debug) {
                            isOnline = !isOnline;
                        }
                    }

                    ActionPopup {
                        id: searchTypePopup

                        x: searchButton.x
                        y: searchButton.height + searchTextFieldContainer.spacing + searchButton.anchors.margins
                        width: searchTextFieldContainer.width > 500 * AppFramework.displayScaleFactor
                               ? 500 * AppFramework.displayScaleFactor
                               : searchTextFieldContainer.width

                        onAboutToShow: {
                            searchButton.parent.color = "#80000000";
                        }

                        onAboutToHide: {
                            searchButton.parent.color = "transparent";
                        }

                        ColumnLayout {
                            anchors.fill: parent

                            spacing: searchTypePopup.padding

                            Text {
                                Layout.fillWidth: true
                                text: searchModeHeader
                                font.family: control.fontFamily
                                font.pointSize: 15 * xform.style.textScaleFactor
                                horizontalAlignment: xform.localeInfo.textAlignment
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !canSearch
                                text: qsTr("Only map coordinate input available when offline")
                                font.family: control.fontFamily
                                horizontalAlignment: xform.localeInfo.textAlignment
                            }

                            Item {
                                visible: canSearch
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

                                CustomControls.StyledComboBox {
                                    id: searchModeComboBox

                                    anchors.fill: parent
                                    fontFamily: control.fontFamily
                                    indicatorColor: xform.style.titleBackgroundColor
                                    textRole: "name"
                                    model: [
                                        {
                                            "name": qsTr("Search everywhere"),
                                            "mode": kSearchModeGlobalExtents
                                        },
                                        {
                                            "name": qsTr("Search within the visible map extent"),
                                            "mode": kSearchModeMapExtents
                                        },
                                        {
                                            "name": qsTr("Map coordinate input only"),
                                            "mode": kSearchModeCoordinates
                                        }
                                    ]

                                    onActivated: {
                                        var mode = model[index];
                                        searchTypePopup.setSearchMode(mode.mode);
                                    }

                                    function getIndex(mode){
                                        var index = model.findIndex(function(val){
                                            return val.mode === mode;
                                        });
                                        return index;
                                    }
                                }
                            }

                            Text {
                                visible: geocodersComboBoxContainer.visible
                                Layout.fillWidth: true
                                text: geocoderHeader
                                font.family: control.fontFamily
                                font.pointSize: 15 * xform.style.textScaleFactor
                                horizontalAlignment: xform.localeInfo.textAlignment
                            }

                            Item {
                                id: geocodersComboBoxContainer
                                visible: canSearch && searchMode > kSearchModeCoordinates
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

                                CustomControls.StyledComboBox {
                                    id: geocodersComboBox

                                    anchors.fill: parent
                                    model: geocoders
                                    enabled: geocoders.count > 0
                                    textRole: "name"
                                    currentIndex: 0
                                    fontFamily: control.fontFamily
                                    indicatorColor: xform.style.titleBackgroundColor
                                    onActivated: {
                                        setIndex(index);
                                    }

                                    function setIndex(geocoderIndex) {

                                        currentIndex = geocoderIndex;

                                        geocoderSpecification = geocoders.get(geocoderIndex);

                                        searchAllGeocoders = geocoderSpecification.url === kSearchAllFlag;

                                        objectCache["lastGeocoderSearchUrl"] = geocoderSpecification.url;

                                        if (searchAllGeocoders) {
                                            return;
                                        }

                                        if (geocoderSpecification.requiresToken > -1) {
                                            return;
                                        }

                                        if (debug) {
                                            console.log(JSON.stringify(geocoderSpecification, undefined, 2));
                                        }

                                        var spec = geocoderSpecification;

                                        var cachedLocatorInfo = objectCache[spec.url] || {};

                                        if (debug) {
                                            console.log(JSON.stringify(cachedLocatorInfo, undefined, 2));
                                        }

                                        var cachedLocatorHasTokenInfo = cachedLocatorInfo.hasOwnProperty("requiresToken");

                                        console.log("----------setIndex > geocoderSpecification.requiresToken < 0 > cachedLocatorHasTokenInfo: ", cachedLocatorHasTokenInfo);



                                        // Try geocoders object cache

                                        if (objectCache.hasOwnProperty("geocoders")) {
                                            if (objectCache.geocoders[spec.url] !== undefined && objectCache.geocoders[spec.url].requiresToken > -1) {
                                                spec.requiresToken = objectCache.geocoders[spec.url].requiresToken;
                                                geocoders.set(geocoderIndex, spec);
                                                return;
                                            }
                                        }

                                        // Try shared object cache object first

                                        if (cachedLocatorHasTokenInfo){
                                            spec.requiresToken = cachedLocatorInfo.requiresToken ? 1 : 0;
                                            geocoders.set(geocoderIndex, spec);
                                            return;
                                        }

                                        // No cache info, so test the service.

                                        if (isOnline) {
                                            var infoRequest = geocoderTokenCheck.createObject(control, {
                                                                                                  "geocoderData": spec,
                                                                                                  "geocoderIndex": geocoderIndex,
                                                                                                  "url": "%1/info?f=json&token=%2".arg(spec.url).arg(portal.token)
                                                                                              });
                                            infoRequest.tokenCheckComplete.connect(function(spec, index, requiresToken){
                                                updateGecodersModelAndObjectCache(spec, index)
                                            })
                                            infoRequest.send();
                                        }
                                    }
                                }
                            }
                        }

                        function setSearchMode(mode) {
                            searchMode = mode;
                            if (activeSearchMode > kSearchModeCoordinates && text > "") {
                                forwardGeocode({
                                                   "text": text,
                                                   "withSuggest": false,
                                                   "magicKey": "",
                                                   "isCollection": false,
                                                   "searchAllGeocoders": searchAllGeocoders
                                               });
                            }
                        }
                    }
                }
            }

            //------------------------------------------------------------------

            CustomControls.SearchTextBox {
                id: textField

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.minimumHeight: textMetricHelper.height < 40 * AppFramework.displayScaleFactor
                                      ? 40 * AppFramework.displayScaleFactor
                                      : textMetricHelper.height

                placeholderText: kSearchModePlaceholderText[activeSearchMode]
                font {
                    family: fontFamily
                    pointSize: requiredFontSize
                }

                locale: xform.locale
                layoutDirection: xform.layoutDirection
                horizontalAlignment: xform.localeInfo.inputAlignment

                activeBorderColor: xform.style.titleBackgroundColor
                borderColor: xform.style.titleBackgroundColor
                editTimeout: 0
                busy: control.busy

                textColor: inputError ? inputErrorTextColor : inputTextColor

                TextMetrics {
                    id: locationTextMetrics

                    font {
                        family: fontFamily
                        pointSize: baseFontSize * xform.style.textScaleFactor
                    }

                    text: textField.text
                }


                Connections {
                    target: control
                    onLocationCommittedChanged:{
                        if (locationCommitted) {
                            if (locationTextMetrics.width > textField.width) {
                                var requiredTextSize = (textField.width / locationTextMetrics.width) * baseFontSize;
                                requiredFontSize = requiredTextSize < 10 ? 10 * xform.style.textScaleFactor : requiredTextSize * xform.style.textScaleFactor;
                            }
                            else {
                                requiredFontSize = baseFontSize * xform.style.textScaleFactor;
                            }
                            return;
                        }
                        else {
                            requiredFontSize = baseFontSize * xform.style.textScaleFactor;
                        }
                    }
                }

                //--------------------------------------------------------------

                onTextChanged: {
                    if (canSearch && text > "") {
                        geocodeTimer.restart();
                    }
                }

                onCleared: {
                    control.clear();
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: locationPasteButton.visible ? height : 0
                LocationPasteButton {
                    id: locationPasteButton
                    anchors {
                        fill: parent
                        margins: 3 * AppFramework.displayScaleFactor
                    }
                    onPaste: {
                        reset();
                        text = pasteText;
                        textField.editingFinished();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: geocoderResults.count === 1
                                    ? resultsView.contentHeight + resultsScrollView.padding + resultsScrollView.anchors.margins
                                    : Math.min(geocoderResults.count, viewLimit) * (minimumLocationDelegateHeight + resultsView.spacing)

            Layout.topMargin: -parent.spacing

            visible: geocoderResults.count > 0

            radius: resultsScrollView.anchors.margins / 2

            border {
                width: 1
                color: "#20000000"
            }

            ScrollView {
                id: resultsScrollView
                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor
                }

                ListView {
                    id: resultsView

                    model: geocoderResults //geocodeModel
                    spacing: 2 * AppFramework.displayScaleFactor
                    delegate: locationDelegate
                    clip: true
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: locationDelegate

        Rectangle {
            id: locationItem

            readonly property bool selected: currentIndex === index
            property alias delegateMouseArea: mouseArea
            property bool isGeocodeCollection: isCollection !== undefined ? isCollection : false
            property bool geocodeMagicKey: magicKey !== undefined ? magicKey : ""
            property bool showItemNumber: !isCollection && magicKey === ""
            property bool isGeocodeHeader: isHeader !== undefined ? isHeader : false
            property string geocoderHeaderText: headerText !== undefined ? headerText > "" ? headerText : qsTr("Geocoder Name Missing") : ""

            width: ListView.view.width
            height: locationLayout.height + locationLayout.anchors.margins * 2
            color: mouseArea.containsMouse ? "#F0F0F0" : "white"
            radius: 2 * AppFramework.displayScaleFactor

            GeocoderLocation {
                id: thisLocation

                property var locationData: index >= 0 ? geocoderResults.get(index) : null
                property double distance: referenceCoordinate.distanceTo(coordinate)
                property double azimuth: referenceCoordinate.azimuthTo(coordinate)

                coordinate: QtPositioning.coordinate(coord.y,coord.x)
                attributes: locationData !== null ? locationData.attributes : {}
                displayAddress: address
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                enabled: !locationItem.isGeocodeHeader

                onClicked: {
                    if (magicKey > "") {
                        forwardGeocode({
                                           "text": address,
                                           "withSuggest": false,
                                           "magicKey": magicKey,
                                           "isCollection": isCollection,
                                           "searchAllGeocoders": searchAllGeocoders
                                       });
                        return;
                    }
                    locationClicked(index, thisLocation, thisLocation.distance);
                }

                onPressAndHold: {
                    if (magicKey > "") {
                        forwardGeocode({
                                           "text": address,
                                           "withSuggest": false,
                                           "magicKey": magicKey,
                                           "isCollection": isCollection,
                                           "searchAllGeocoders": searchAllGeocoders
                                       });
                        return;
                    }
                    locationPressAndHold(index, thisLocation, thisLocation.distance);
                }

                onDoubleClicked: {
                    if (magicKey > "") {
                        forwardGeocode({
                                           "text": address,
                                           "withSuggest": false,
                                           "magicKey": magicKey,
                                           "isCollection": isCollection,
                                           "searchAllGeocoders": searchAllGeocoders
                                       });
                        return;
                    }
                    locationDoubleClicked(index, thisLocation, thisLocation.distance);
                }
            }

            Rectangle {
                visible: locationItem.isGeocodeHeader
                anchors {
                    fill: parent
                }
                color: locationHeaderBackgroundColor

                RowLayout {
                    anchors {
                        fill : parent
                        margins: 2 * AppFramework.displayScaleFactor
                    }

                    layoutDirection: xform.layoutDirection

                    Item {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: Layout.preferredHeight

//                        CustomControls.StyledImage {
//                            anchors {
//                                fill: parent
//                                margins: 4 * AppFramework.displayScaleFactor
//                            }

//                            source: "images/home-24.svg"
//                            color: locationHeaderTextColor
//                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        font {
                            pointSize: 13 * xform.style.textScaleFactor
                            family: fontFamily
                            bold: true
                        }
                        color: locationHeaderTextColor

                        text: locationItem.geocoderHeaderText || qsTr("Geocoder Name Missing")
                        elide: xform.localeInfo.textElide
                        horizontalAlignment: xform.localeInfo.textAlignment
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            RowLayout {
                id: locationLayout

                visible: !locationItem.isGeocodeHeader
                layoutDirection: xform.layoutDirection

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2 * AppFramework.displayScaleFactor
                }

                Item {
                    Layout.preferredHeight: minimumLocationDelegateHeight
                    Layout.preferredWidth: Layout.preferredHeight

                    Image {
                        id: pinImage

                        anchors {
                            fill: parent
                        }

                        source: isCollection
                                ? collectionImage
                                : locationItem.showItemNumber
                                  ? selected
                                    ? selectedPinImage
                                    : locationPinImage
                        : "images/suggest_map_pin.png"
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                commitLocation(index, thisLocation);
                            }
                        }
                    }

                    Item {
                        anchors {
                            centerIn: parent
                        }

                        width: pinImage.width / 2
                        height: width
                        visible: locationItem.showItemNumber

                        Text {
                            id: indexText

                            anchors {
                                fill: parent
                                margins: 2 * AppFramework.displayScaleFactor
                            }

                            text: "%1".arg(geocoderResultsIndex[index] + 1)

                            color: locationItem.selected ? selectedPinTextColor : locationPinTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            fontSizeMode: Text.HorizontalFit
                            minimumPointSize: 10
                            font {
                                pointSize: 13 * xform.style.textScaleFactor
                                bold: selected
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumHeight: contentHeight + 5 * AppFramework.displayScaleFactor

                    text: thisLocation.displayAddress
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: xform.localeInfo.textAlignment
                    verticalAlignment: Text.AlignVCenter
                    elide: xform.localeInfo.textElide
                    //fontSizeMode: Text.HorizontalFit
                    maximumLineCount: 2
                    minimumPointSize: 11

                    font {
                        pointSize: 13 * xform.style.textScaleFactor
                        family: fontFamily
                        bold: selected
                    }
                }

                Text {
                    visible: index != currentIndex && Math.round(thisLocation.distance) > 0 && (!isCollection && magicKey === "")
                    text: displayDistance(thisLocation.distance)

                    horizontalAlignment: xform.localeInfo.textAlignment
                    font {
                        pointSize: 12 * xform.style.textScaleFactor
                        family: fontFamily
                    }
                }

                Image {
                    Layout.preferredHeight: minimumLocationDelegateHeight * 0.75
                    Layout.preferredWidth: Layout.preferredHeight

                    //opacity: Math.round(distance) > 1 ? 1 : 0
                    fillMode: Image.PreserveAspectFit
                    rotation: index != currentIndex ? thisLocation.azimuth : 0
                    source: index != currentIndex ? arrowImage : centerImage
                    visible: !isCollection && magicKey === ""
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 1
                color: "#10000000"
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: geocodeTimer

        interval: 1000
        repeat: false

        onTriggered: {
            geocodeTriggered();
        }
    }

    function geocodeTriggered(){

        if (editingCoordsInitiated) {
            editingCoordsInitiated = false;
            return;
        }

        hasCoordinate = parseCoordinate(textField.text);

        if (hasCoordinate) {
            if (coordInfo !== null) {
                mapCoordinate(coordInfo)
            }
            geocoderResults.clear();
            geocoderResultsIndex = [];
            geocoderResultsCounter = 0;
        }
        else if (canSearch && activeSearchMode > kSearchModeCoordinates){
            forwardGeocode({
                               "text": textField.text,
                               "withSuggest": false,
                               "magicKey": "",
                               "isCollection": false,
                               "searchAllGeocoders": searchAllGeocoders
                           });
        }
        geocodeTimer.stop();

    }

    //--------------------------------------------------------------------------

    GeocodersModel {
        id: geocoders

        property int setGeocoderIndex: 0
        property var geocoderList: null

        Component.onCompleted: {

            if (!portal.signedIn) {
                addEsriWorldGeocoder();
                finalize();
                return;
            }

            if (portal.info === null || portal.info.helperServices === undefined || portal.info.helperServices.geocode === undefined) {
                addEsriWorldGeocoder();
                finalize();
                return;
            }

            geocoderList = portal.info.helperServices.geocode;

            if (!Array.isArray(geocoderList)){
                addEsriWorldGeocoder();
                finalize();
                return;
            }

            if (geocoderList.length < 1) {
                addEsriWorldGeocoder();
                finalize();
                return;
            }

            geocoderList.forEach(function(geocoder, index){
                geocoders.addItem(geocoder);
            });

            finalize();
        }

        onFinished: {

            if (count > 0) {

                var lastGeocoderSearchUrl = objectCache["lastGeocoderSearchUrl"] || "";
                console.log("-----> lastGeocoderSearchUrl: ", lastGeocoderSearchUrl)

                var geocodersCache = objectCache["geocoders"] || null;

                console.log(">>> geocoderscache: ", JSON.stringify(geocodersCache));

                for (var x = 0; x < count; x++) {

                    var geocoderInModel = get(x);

                    if (geocodersCache !== null) {
                        if (geocodersCache[geocoderInModel.url] !== undefined) {
                            geocoderInModel.requiresToken = geocodersCache[geocoderInModel.url].requiresToken;
                            console.log("------geocoder updated from cache", JSON.stringify(geocoderInModel));
                        }
                    }

                    if (geocoderInModel.url === lastGeocoderSearchUrl) {
                        console.log("found at : ", x)
                        setGeocoderIndex = x;
                    }
                }
            }

            geocodersComboBox.setIndex(setGeocoderIndex);
        }

        onCountChanged: {
            if (count < 1) {
                geocoderSpecification = null;
                geocodersComboBox.currentIndex = -1;
            }
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: geocoderResults
    }

    //--------------------------------------------------------------------------

    Component {
        id: geocoderTokenCheck
        GeocoderTokenCheck {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geocodeLocationComponent
        GeocoderLocation {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geocodeRequest
        GeocodeRequest {
        }
    }

    //--------------------------------------------------------------------------

    function reverseGeocode(coordinate /* array [lat | y , lon | x] */){

        if (!canSearch) {
            geocoderError(qsTr("Offline. Can't Search"));
            return;
        }

        if (geocoders.count < 1) {
            geocoderError(qsTr("No geocoders are enabled."));
            return;
        }

        if (searchAllGeocoders) {
            geocoderError(qsTr("Reverse geocoding is not available on All geocoders. Please select a single geocoder."));
            return;
        }

        if (geocoderSpecification === null || geocoderSpecification.reverse === undefined) {
            geocoderError(qsTr("Reverse geocode specification undefined for this service."));
            return;
        }

        var reverseGeocodeRequest = geocodeRequest.createObject(control, {
                                                                    "geocoderSpecification": geocoderSpecification,
                                                                    "operation": geocoderSpecification.reverse,
                                                                    "reverseGeocode": true
                                                                });

        var searchURL = geocoderSpecification.reverse.url;
        if (geocoderSpecification.urlCoordinateFormat === "y,x"){
            searchURL += encodeURIComponent("%1,%2".arg(coordinate[0].toString()).arg(coordinate[1].toString()));
        }
        else {
            // if its 'x,y' its most likely an esri locator, so use point json syntax
            searchURL += encodeURIComponent("{x:%1,y:%2,spatialReference:{wkid:%3}}".arg(coordinate[1].toString()).arg(coordinate[0].toString()).arg(mapSpatialReference));
        }

        searchURL += "&outSR=%1".arg(outSpatialReference);

        if (langCode > "") {
            searchURL += "&langCode=%1".arg(langCode);
        }

        if (geocoderSpecification.requiresToken > 0){
            searchURL += "&token=%1".arg(portal.token);
        }

        if (debug) {
            console.log("reverseGeocode searchURL: ", searchURL);
        }

        reverseGeocodeRequest.url = searchURL;

        reverseGeocodeRequest.reverseGeocodeResultsReturned.connect(function(candidate){
            var reverseGeocodeLocation = geocodeLocationComponent.createObject(control);
            reverseGeocodeLocation.coordinate = QtPositioning.coordinate(candidate.coord.y,candidate.coord.x);
            reverseGeocodeLocation.displayAddress = candidate.address;
            reverseGeocodeLocation.attributes = candidate.attributes;
            reverseGeocodeSuccess(reverseGeocodeLocation);
        });

        reverseGeocodeRequest.geocodeRequestComplete.connect(function(){
            busy = false;
        });

        reverseGeocodeRequest.reverseGeocodeError.connect(function(error){
            reverseGeocodeError(error);
        })

        reverseGeocodeRequest.send();

        busy = true;
    }

    //--------------------------------------------------------------------------

    function forwardGeocode(geocodeParams /* object{ } */) {
        /*
            // geocodeParams <object>
            {
                "text": "text to search" <string>,
                "withSuggest": false <bool> [false default],
                "magicKey": magicKey <string> ["" default],
                "isCollection": isCollection <bool> [false default],
                "searchAllGeocoders": false <bool>
            }
        */

        if (!canSearch) {
            geocoderError(qsTr("Offline. Can't Search"));
            return;
        }

        if (geocoders.count < 1) {
            geocoderError(qsTr("No geocoders are enabled."));
            return;
        }

        if (geocodeParams.searchAllGeocoders !== undefined && !geocodeParams.searchAllGeocoders) {
            if (geocoderSpecification === null || geocoderSpecification.forward === undefined) {
                geocoderError(qsTr("Forward geocode specification not defined for this service."))
                return;
            }
        }

        geocoderResults.clear();
        geocoderResultsIndex = [];
        geocoderResultsCounter = 0;

        var geocoderArray = [];

        if (!geocodeParams.searchAllGeocoders) {
            geocoderArray.push(geocoderSpecification);
        }
        else {
            for (var x = 1; x < geocoders.count; x++) {
                geocoderArray.push(geocoders.get(x));
            }
        }

        geocoderArray.forEach(function(geocoder, i){
            if (searchAllGeocoders) {
                i++;
            }

            if (geocoder === null || geocoder.forward === undefined) {
                if (!searchAllGeocoders){
                    geocoderError(qsTr("Forward geocode specification not defined for this service."))
                }
                return;
            }

            if (geocoder.requiresToken === 1 && portal.token === ""){
                if (!searchAllGeocoders){
                    geocoderError(qsTr("Geocoder requires a token."));
                }
                return;
            }

            if (!searchAllGeocoders) {
                busy = true;
            }

            if (geocoder.requiresToken === 1 || geocoder.requiresToken < 0) {

                if (debug) {
                    console.log("thisGeocoder.requiresToken === 1 || thisGeocoder.requiresToken < 0 ", geocoder.url);
                }

                var forwardRequestWithToken = geocodeRequest.createObject(control, {
                                                                              "geocoderSpecification": geocoder,
                                                                              "geocoderIndex": i,
                                                                              "operation": geocoder.forward,
                                                                              "geocoderName": geocoder.name,
                                                                          });

                forwardRequestWithToken.url = setupGeocodeRequestURL(geocoder, geocodeParams.text, geocodeParams.withSuggest, geocodeParams.magicKey, geocodeParams.isCollection, true);

                forwardRequestWithToken.geocoderDoesNotRequireTokenOrTokenIsInvalid.connect(function(spec, index){
                    updateGecodersModelAndObjectCache(spec, index);
                });

                forwardRequestWithToken.geocoderRequiresToken.connect(function(spec, index){
                    updateGecodersModelAndObjectCache(spec, index);
                });

                forwardRequestWithToken.geocoderError.connect(function(error){
                    if (!searchAllGeocoders) {
                        geocoderError(error);
                    }
                });

                forwardRequestWithToken.geocodeRequestComplete.connect(function(){
                    if (!searchAllGeocoders) {
                        busy = false;
                    }
                });

                forwardRequestWithToken.resultsReturned.connect(function(name, results, index, spec){

                    var updatedSpec = spec;

                    if (spec.requiresToken < 0) {
                        updatedSpec.requiresToken = 1;
                        updateGecodersModelAndObjectCache(updatedSpec, index);
                    }

                    if (results.length < 1) {
                        // if want to display no results message, add this header back.
                        //addGeocoderResultsHeader(qsTr("%1: No Results").arg(name));
                        return;
                    }

                    if (searchAllGeocoders) {
                        addGeocoderResultsHeader(name);
                    }

                    results.forEach(function(result){
                        geocoderResults.append(result);
                        geocoderResultsIndex.push(geocoderResultsCounter++)
                    });

                });

                forwardRequestWithToken.send();
            }

            if (geocoder.requiresToken === 0 || geocoder.requiresToken < 0) {

                if (debug) {
                    console.log("thisGeocoder.requiresToken === 0 || thisGeocoder.requiresToken < 0 ", geocoder.url);
                }

                var forwardRequestWithoutToken = geocodeRequest.createObject(control, {
                                                                                 "geocoderSpecification": geocoder,
                                                                                 "geocoderIndex": i,
                                                                                 "operation": geocoder.forward,
                                                                                 "geocoderName": geocoder.name
                                                                             });

                forwardRequestWithoutToken.url = setupGeocodeRequestURL(geocoder, geocodeParams.text, geocodeParams.withSuggest, geocodeParams.magicKey, geocodeParams.isCollection, false);


                forwardRequestWithoutToken.geocoderDoesNotRequireTokenOrTokenIsInvalid.connect(function(spec, index){
                    updateGecodersModelAndObjectCache(spec, index);
                });

                forwardRequestWithoutToken.geocoderRequiresToken.connect(function(spec, index){
                    updateGecodersModelAndObjectCache(spec, index);
                });

                forwardRequestWithoutToken.geocoderError.connect(function(error){
                    if (!searchAllGeocoders) {
                        geocoderError(error);
                    }
                });

                forwardRequestWithoutToken.geocodeRequestComplete.connect(function(){
                    if (!searchAllGeocoders) {
                        busy = false;
                    }
                });

                forwardRequestWithoutToken.resultsReturned.connect(function(name, results, index, spec){

                    var updatedSpec = spec;

                    if (spec.requiresToken < 0) {
                        updatedSpec.requiresToken = 0;
                        updateGecodersModelAndObjectCache(updatedSpec, index);
                    }

                    if (results.length < 1) {
                        // if want to display no results message, add this header back.
                        //addGeocoderResultsHeader(qsTr("%1: No Results").arg(name));
                        return;
                    }

                    if (searchAllGeocoders) {
                        addGeocoderResultsHeader(name);
                    }

                    results.forEach(function(result){
                        geocoderResults.append(result);
                        geocoderResultsIndex.push(geocoderResultsCounter++)
                    })
                });

                forwardRequestWithoutToken.send();
            }
        });
    }

    //--------------------------------------------------------------------------

    function addGeocoderResultsHeader(name) {
        var header = {
            "address": "",
            "coord": {"y": 0, "x": 0},
            "spatialReference": null,
            "score": -100,
            "attributes": null,
            "magicKey": "",
            "isCollection": false,
            "type": null,
            "isHeader": true,
            "headerText": name
        }
        geocoderResultsIndex.push(-1);
        geocoderResults.append(header);
    }

    //--------------------------------------------------------------------------

    function setupGeocodeRequestURL(geocoderSpecification, text, withSuggest, magicKey, isCollection, addToken) {

        if (withSuggest === undefined) {
            withSuggest = geocoderSpecification.suggest.available ? true : false;
        }

        withSuggest = false; // Turn off suggest always for now. Remove this line to re-implement suggest.

        geocodeTimer.interval = withSuggest ? 1 : 1000;

        var searchURL = withSuggest ? geocoderSpecification.suggest.url : geocoderSpecification.forward.url;

        searchURL += encodeURIComponent(text.trim());

        searchURL += "&Single+Line+Input=%1".arg(encodeURIComponent(text.trim())); // support older geocoders

        if (activeSearchMode == kSearchModeMapExtents) {
            var rect = map.visibleRegion.boundingGeoRectangle();
            searchURL += "&searchExtent=%1,%2,%3,%4".arg(rect.topLeft.longitude).arg(rect.topLeft.latitude).arg(rect.bottomRight.longitude).arg(rect.bottomRight.latitude)
        }

        searchURL += "&outSR=%1".arg(outSpatialReference);

        if (magicKey !== undefined && magicKey > "") {
            searchURL += "&magicKey=%1".arg(magicKey);
        }

        if (geocoderSpecification.requiresToken > 0){
            if (portal.token === "" && !searchAllGeocoders) {
                geocoderError(qsTr("Service requires token, but token is empty."));
                return;
            }
            searchURL += "&token=%1".arg(portal.token);
        }

        if (geocoderSpecification.requiresToken < 0) {
            if (addToken !== undefined && addToken && portal.token > "") {
                searchURL += "&token=%1".arg(portal.token);
            }
        }

        if (langCode > "") {
            searchURL += "&langCode=%1".arg(langCode);
        }

        if (referenceCoordinate.isValid) {
            searchURL += "&location=";
            searchURL += encodeURIComponent('{"x":%1,"y":%2,"spatialReference":{"wkid":%3}}'
                                            .arg(referenceCoordinate.longitude)
                                            .arg(referenceCoordinate.latitude)
                                            .arg(mapSpatialReference));
        }

        return searchURL;

    }

    //--------------------------------------------------------------------------

    function updateGecodersModelAndObjectCache(spec, index) {

        if (debug) {
            console.log("-------------updateGecodersModelAndObjectCache", index)
            console.log(JSON.stringify(spec));
        }

        if (!objectCache.hasOwnProperty("geocoders")) {
            objectCache.geocoders = {};
        }

        geocoders.set(index, spec);

        var requiresAsBoolean = spec.requiresToken > 0 ? true : false

        objectCache[spec.url] = { "requiresToken": requiresAsBoolean } // for XFormExpressionGeopointHelper.js

        objectCache.geocoders[spec.url] = { "requiresToken": spec.requiresToken } // for GeocoderSearch

        if (debug) {
            console.log("---- objectCache: ",JSON.stringify(objectCache.geocoders));
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        geocodeTimer.stop();
        geocoderResults.clear();
        geocoderResultsIndex = [];
        geocoderResultsCounter = 0;
        text = "";
        currentIndex = -1;
        locationCommitted = false;
        cleared();
        if (coordinateModeTriggeredbyEditCoordinates) {
            coordinateModeTriggeredbyEditCoordinates = false;
        }
    }

    //--------------------------------------------------------------------------

    function reset() {
        geocodeTimer.stop();
        geocoderResults.clear();
        geocoderResultsIndex = [];
        geocoderResultsCounter = 0;
        currentIndex = -1;
    }

    //--------------------------------------------------------------------------

    function getLocation(index) {
        // "location" elements of the geocodeModel are different from the "location"
        // emitted by the locationClicked(), etc. signals. Add the missing relevant entries.
        var location = JSON.parse(JSON.stringify(geocoderSearch.geocodeModel.get(index)));
        location.coordinate = QtPositioning.coordinate(location.coord.y, location.coord.x);
        location.displayAddress = location.address;

        if (debug) {
            console.log("getLocation:", JSON.stringify(location, undefined, 2));
        }

        return location;
    }

    //--------------------------------------------------------------------------

    function showLocation(index, select) {
        if (select) {
            currentIndex = index;
        }

        if (index >= 0) {
            resultsView.positionViewAtIndex(index, ListView.Center);
        }
    }

    //--------------------------------------------------------------------------

    function displayDistance(distance) {
        switch (locale.measurementSystem) {
        case Locale.ImperialUSSystem:
        case Locale.ImperialUKSystem:
            var distanceFt = distance * 3.28084;
            if (distanceFt < 1000) {
                return "%1 ft".arg(Math.round(distanceFt).toLocaleString(locale, "f", 0))
            } else {
                var distanceMiles = distance * 0.000621371;
                return "%1 mi".arg(Math.round(distanceMiles).toLocaleString(locale, "f", distanceMiles < 10 ? 1 : 0))
            }

        default:
            if (distance < 1000) {
                return "%1 m".arg(Math.round(distance).toLocaleString(locale, "f", 0))
            } else {
                var distanceKm = distance / 1000;
                return "%1 km".arg(Math.round(distanceKm).toLocaleString(locale, "f", distanceKm < 10 ? 1 : 0))
            }
        }
    }

    //--------------------------------------------------------------------------

    function parseCoordinate(text) {

        if (debug) {
            console.log("parseCoordinate from > ", text);
        }

        if (!(text > "")) {
            coordInfo = null;
            return false;
        }

        var parsedCoord = Coordinate.parse(text, parseOptions);
        if (!parsedCoord.coordinate) {
            coordInfo = null;
            return false;
        }

        control.coordInfo = parsedCoord;

        if (debug) {
            console.log("parseCoordinate parsedCoord > ", JSON.stringify(control.coordInfo, undefined, 2));
        }

        return true;
    }

    //--------------------------------------------------------------------------
}
