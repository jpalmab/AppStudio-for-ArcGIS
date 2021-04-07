/* Copyright 2015 Esri
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

import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtLocation 5.3
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../XForms"
import "../XForms/XFormGeometry.js" as Geometry
import "SurveyHelper.js" as Helper
import "../Models"

Item {
    id: mapView

    //--------------------------------------------------------------------------

    property XFormsDatabase xformsDatabase: app.surveysModel
    property bool debug: false
    property bool showDelete: true
    property var surveysModel: filteredSurveysModel.visualModel //xformsDatabase
    property XFormSchema schema
    property XFormSettings formSettings
    property XFormMapSettings mapSettings

    property alias map: map
    property string mapKey
    property var extent

    property color labelTextColor: "black"
    property color labelStyleColor: "white"

    readonly property real kDefaultLineWidth: 4
    property real lineWidth: kDefaultLineWidth

    // Clustering strategy: Point markers, polygons, and polylines are displayed
    // once the zoom level is greater than a given default zoom level. For zoom
    // levels below this threshold, clustering is used. Labels are displayed once
    // the default labelling zoom level is reached.
    //
    // Polygons and polylines follow additional rules:
    //
    // 1) We calculate the zoom level for which a given polygon/polyline is larger
    //    than a certain fraction of the screen dimensions. If the map zoom level is
    //    larger than this value, the polygon/polyline is drawn regardless of the
    //    default threshold. This ensures that the extent of large polygons/polylines
    //    are fully visible, while smaller polygons/polylines are still clustered.
    //
    // 2) The default zoom level to draw all features is modified (within a certain range)
    //    according to the size distribution of the polygons/polylines. We use the
    //    zoom level at which a polygon/polyline fills a certain fraction of the screen
    //    as an indicator of its size. We calculate the histogram of these zoom levels and
    //    use the zoom level where the peak of the histogram lies to determin the new default
    //    zoom level. This ensures that clustering can be used for larger zoom levels if
    //    the polygons/polylines are small, and vice versa. It also ensures that no (or
    //    fewer) "holes" appear, where a polygon/polyline is of similar size than its
    //    neighbours, which are displayed on the map, but just misses out on being drawn
    //    itself. Alternatively, instead of using a histogram, the median or a percentile
    //    could be used to determine the new default zoom level.
    //
    // 3) The label of a polygon/polyline is only drawn once the map zoom level is greater
    //    than the zoom level at which the polygon/polyline fills a certain fraction of
    //    the screen. This reduces the number of labels that are overlapping each other.

    property real defaultDetailedZoomLevel: 13.5
    property real defaultLabelsZoomLevel: 15.5

    property real detailedZoomLevelPoints: defaultDetailedZoomLevel
    property real labelsZoomLevelPoints: defaultLabelsZoomLevel

    property real detailedZoomLevelGeoshapes: defaultDetailedZoomLevel
    property real labelsZoomLevelGeoshapes: defaultLabelsZoomLevel

    property var tolerance: 30 * AppFramework.displayScaleFactor
    property var fractionToFit: 0.33
    property var distanceThreshold: 10

    readonly property string geometryType: schema.schema.fieldsRef[schema.schema.geometryFieldName].esriGeometryType
    readonly property bool isPoints: geometryType === "esriGeometryPoint"
    readonly property bool isPolygon: geometryType === "esriGeometryPolygon"
    readonly property bool isPolyline: geometryType === "esriGeometryPolyline"

    readonly property bool showClusters: !isPoints || map.zoomLevel < detailedZoomLevelPoints
    readonly property bool showLabels: !isPoints || map.zoomLevel >= labelsZoomLevelPoints
    readonly property bool showPointMarkers: isPoints && map.zoomLevel >= detailedZoomLevelPoints

    property var featureCoordinates: []
    property var featureZoomLevels: []
    property var featureClustered: []
    property var featurePaths: []

    //--------------------------------------------------------------------------

    signal clicked(var survey)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("SurveysMapView.onCompleted");
        map.mapSettings.selectMapType(map, formSettings.mapName(mapKey));

        getMapFeatures();
        if (updateExtent()) {
            map.zoomToRectangle(extent, map.mapSettings.previewZoomLevel);
        }
        else {
            map.zoomToDefault();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: filteredSurveysModel

        onUpdating: {
            console.log("Surveys updating");
        }

        onUpdated: {
            refresh();
            console.log("Surveys updated");
        }
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        anchors {
            fill: parent
        }

        mapSettings: mapView.mapSettings

        positionSourceConnection: XFormPositionSourceConnection {
            positionSourceManager: app.positionSourceManager
            listener: "SurveysMapView"
        }

        localeProperties: app.localeProperties

        MouseArea {
            anchors.fill: parent

            enabled: isPolyline

            onClicked: {
                var coordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y));
                var tolerance = toleranceWidth();

                featurePaths.some(function (path, index) {
                    var geopath = QtPositioning.path(path, tolerance);

                    if (!featureClustered[index] && geopath.contains(coordinate)) {
                        mapView.clicked(surveysModel.getSurvey(index));
                        return true;
                    }

                    return false;
                })
            }
        }

        plugin: XFormMapPlugin {
            settings: map.mapSettings
            offline: !Networking.isOnline
        }

        MapItemView {
            model: isPolygon ? surveysModel : null
            delegate: geoPolygonComponent
        }

        MapItemView {
            model: isPolyline ? surveysModel : null
            delegate: geoPolylineComponent
        }

        MapItemView {
            model: showPointMarkers ? surveysModel : null
            delegate: geopointMarkerComponent
        }

        MapItemView {
            model: showLabels ? surveysModel : null
            delegate: geopointLabelComponent
        }

        MapItemView {
            model: showClusters ? clustersModel : null
            delegate: geopointClusterComponent
        }

        onPositionModeChanged: {
            if (positionMode > positionModeOff) {
                zoomLevel = mapSettings.defaultPreviewZoomLevel;
            }
        }

        onZoomLevelChanged: {
            clustersModel.update();
        }

        onMapTypeChanged: {
            formSettings.setMapName(mapKey, mapType.name);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geoPolygonComponent

        MapPolygon {
            id: mapPolygon

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);

            visible: index >= 0 && featureCoordinates[index].isValid
                     && (Math.round(map.zoomLevel) >= featureZoomLevels[index]
                         || map.zoomLevel >= detailedZoomLevelGeoshapes);

            color: AppFramework.alphaColor(actionColor, 0.33)
            border {
                color: actionColor
                width: lineWidth * AppFramework.displayScaleFactor
            }

            MouseArea {
                anchors {
                    fill: parent
                }

                onClicked: {
                    mapView.clicked(rowData);
                }
            }

            Component.onCompleted: {
                if (visible) {
                    mapPolygon.path = featurePaths[index];
                } else if (mapPolygon.path && mapPolygon.path.length > 0) {
                    mapPolygon.path = [];
                }
            }

            onVisibleChanged: {
                if (visible) {
                    mapPolygon.path = featurePaths[index];
                } else if (mapPolygon.path && mapPolygon.path.length > 0) {
                    mapPolygon.path = [];
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geoPolylineComponent

        MapPolyline {
            id: mapPolyline

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);

            visible: index >= 0 && featureCoordinates[index].isValid
                     && (Math.round(map.zoomLevel) >= featureZoomLevels[index]
                         || map.zoomLevel >= detailedZoomLevelGeoshapes);

            line {
                color: actionColor
                width: lineWidth * AppFramework.displayScaleFactor
            }

            Component.onCompleted: {
                if (visible) {
                    mapPolyline.path = featurePaths[index];
                } else if (mapPolyline.path && mapPolyline.path.length > 0) {
                    mapPolyline.path = [];
                }
            }

            onVisibleChanged: {
                if (visible) {
                    mapPolyline.path = featurePaths[index];
                } else if (mapPolyline.path && mapPolyline.path.length > 0) {
                    mapPolyline.path = [];
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointMarkerComponent

        MapQuickItem {
            id: mapItem

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);
            property int rowStatus: rowData ? rowData.status : -1

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height
            }

            visible: mapItem.coordinate.isValid && rowStatus >= 0;

            sourceItem: Image {
                id: mapMarker

                width: 40 * AppFramework.displayScaleFactor
                height: width
                source: rowStatus >= 0 ? "../XForms/images/pin-%1.png".arg(rowStatus) : ""
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        mapView.clicked(rowData);
                    }
                }
            }

            Component.onCompleted: {
                var coordinate = featureCoordinates[index];
                if (coordinate) {
                    mapItem.coordinate = coordinate;
                    if (!mapItem.coordinate.isValid) {
                        console.error("Map geometry error - Markers");
                    }

                    // console.log("mapItem:", snippet, mapItem.coordinate);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointLabelComponent

        MapQuickItem {
            id: mapItem

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);

            anchorPoint {
                x: mapText.width/2
                y: 0
            }

            visible: index >= 0 && featureCoordinates[index].isValid
                     && (isPoints || Math.round(map.zoomLevel) >= featureZoomLevels[index])

            sourceItem: Text {
                id: mapText

                width: 100 * AppFramework.displayScaleFactor
                text: rowData ? rowData.snippet || "" : ""
                color: labelTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: app.fontFamily
                    pointSize: 11
                    bold: true
                }
                //styleColor: labelStyleColor
                //style: Text.Outline

                Rectangle {
                    anchors {
                        centerIn: parent
                    }

                    width: parent.paintedWidth + parent.paintedHeight / 2
                    height: parent.paintedHeight + 6
                    radius: parent.paintedHeight / 2
                    border {
                        color: "lightgrey"
                        width: 1
                    }

                    opacity: 0.5
                    z: parent.z - 1
                }

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        mapView.clicked(rowData);
                    }
                }
            }

            Component.onCompleted: {
                var coordinate = featureCoordinates[index];
                if (coordinate) {
                    mapItem.coordinate = coordinate;
                    if (!mapItem.coordinate.isValid) {
                        console.error("Map geometry error - Labels");
                    }

                    // console.log("mapItem:", snippet, mapItem.coordinate);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointClusterComponent

        MapQuickItem {
            id: mapItem

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height/2
            }

            coordinate: QtPositioning.coordinate(cy, cx)
            sourceItem: Rectangle {
                id: mapMarker

                property int size: Math.max(countText.paintedHeight + 8 * AppFramework.displayScaleFactor, countText.paintedWidth + 16 * AppFramework.displayScaleFactor)
                height: size
                width: size
                color: actionColor
                border {
                    color: "white"
                    width: 1
                }
                radius: height / 2

                Text {
                    id: countText
                    anchors.centerIn: parent

                    text: count
                    color: "white"
                }

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        var clusterExtent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));
                        map.zoomToRectangle(clusterExtent, isPoints ? labelsZoomLevelPoints : labelsZoomLevelGeoshapes);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ClustersModel {
        id: clustersModel

        function update() {
            var mapZoomLevel = Math.round(map.zoomLevel);

            if (mapZoomLevel === level) {
                return;
            }

            initialize(mapZoomLevel);

            var clusterZoomLevel = isPoints ? detailedZoomLevelPoints : detailedZoomLevelGeoshapes;
            for (var i = 0; i < surveysModel.count; i++) {
                if ((isPoints || mapZoomLevel < featureZoomLevels[i]) && map.zoomLevel < clusterZoomLevel) {
                    addPoint(featureCoordinates[i]);
                    featureClustered[i] = true;
                } else {
                    featureClustered[i] = false;
                }
            }

            finalize();
        }
    }

    //--------------------------------------------------------------------------

    // Set up the pertinent points of features, i.e. the point itself or the feature centroid,
    // the zoom levels for which individual features should be displayed, and derive the
    // default zoom level to display all features
    function getMapFeatures() {
        detailedZoomLevelGeoshapes = defaultDetailedZoomLevel;
        labelsZoomLevelGeoshapes = defaultLabelsZoomLevel;

        featureCoordinates.length = 0;
        featureZoomLevels.length = 0;
        featurePaths.length = 0;

        var coordinate;
        var zoomLevel;
        var result;

        for (var i = 0; i < surveysModel.count; i++) {
            var rowData = surveysModel.getSurvey(i);

            if (rowData && rowData.data && schema.schema.geometryFieldName) {
                var geometry = rowData.data[schema.instanceName][schema.schema.geometryFieldName];

                if (geometry) {
                    if (geometry.x && geometry.y) {
                        zoomLevel = labelsZoomLevelPoints;
                        coordinate = QtPositioning.coordinate(geometry.y, geometry.x);
                    } else if (isPolygon) {
                        result = geometryToPathBoundingRect(geometry);
                        zoomLevel = calcZoomLevel(result.boundingRect, fractionToFit);
                        coordinate = getAreaCentroid(result.path, distanceThreshold);
                    } else if (isPolyline) {
                        result = geometryToPathBoundingRect(geometry);
                        zoomLevel = calcZoomLevel(result.boundingRect, fractionToFit);
                        coordinate = getLineCentroid(result.path, distanceThreshold);
                    }

                    featureCoordinates.push(coordinate);
                    featureZoomLevels.push(zoomLevel);

                    if (isPolygon || isPolyline) {
                        featurePaths.push(result.path)
                    }
                }
            }
        }

        if (isPolygon || isPolyline) {
            var binSize = 1;
            var lowerBoundExtension = 2
            var upperBoundExtension = 2
            var peakAtShift = 1.5

            var offset = labelsZoomLevelGeoshapes - detailedZoomLevelGeoshapes;
            var peakAt = zoomLevelClusteredAt(featureZoomLevels, binSize);

            if (peakAt < detailedZoomLevelGeoshapes - lowerBoundExtension) {
                detailedZoomLevelGeoshapes = detailedZoomLevelGeoshapes - lowerBoundExtension - peakAtShift + 0.5;
            } else if (peakAt > detailedZoomLevelGeoshapes + upperBoundExtension) {
                detailedZoomLevelGeoshapes = detailedZoomLevelGeoshapes + upperBoundExtension - peakAtShift + 0.5;
            } else {
                detailedZoomLevelGeoshapes = peakAt - peakAtShift;
            }

            labelsZoomLevelGeoshapes = detailedZoomLevelGeoshapes + offset;
        }
    }

    //--------------------------------------------------------------------------

    // Return path & bounding rectangle
    function geometryToPathBoundingRect(geometry) {
        var result;

        if (isPolygon && Array.isArray(geometry.rings)) {
           result = Geometry.pointsToPathBoundingRect(geometry.rings[0]);
        }
        else if (isPolyline && Array.isArray(geometry.paths)) {
            result = Geometry.pointsToPathBoundingRect(geometry.paths[0]);
        }
        else if (Array.isArray(geometry.coordinates)) {
            result = Geometry.pointsToPathBoundingRect(geometry.coordinates[0]);
        }

        return result;
    }

    //--------------------------------------------------------------------------

    // Derive the zoom level from the web mercator projection formula so that the bounding
    // box of the map polygon or polyline fits within the given fraction of the map.
    // See https://en.wikipedia.org/wiki/Web_Mercator_projection for the projection formula.
    // Take the difference of the (x,y) coordinates of two points after projection and solve
    // for zoom level.
    function calcZoomLevel(boundingRect, fractionToFit) {
        if (!boundingRect || boundingRect.xMax === boundingRect.xMin && boundingRect.yMax === boundingRect.yMin) {
            return detailedZoomLevelGeoshapes;
        }

        var zoomX = 360.0 / (boundingRect.xMax - boundingRect.xMin) * mapView.width / 256 * fractionToFit;

        var tanYMin = Math.tan( (boundingRect.yMin/2) * Math.PI / 180 + Math.PI/4 );
        var tanYMax = Math.tan( (boundingRect.yMax/2) * Math.PI / 180 + Math.PI/4 );
        var zoomY = 2 * Math.PI / Math.log(tanYMax / tanYMin) * mapView.height / 256 * fractionToFit;

        return Math.round(Math.log( Math.min(zoomX, zoomY) ) / Math.LN2);
    }

    //--------------------------------------------------------------------------

    // Naive MapPolygon centroid in flat earth approximation. This works
    // best for small, simple shapes. A distance threshold can been set
    // to reduce the number of close vertices (the centroid is biased
    // towards regions with the most vertices, e.g. bends in the line)
    function getAreaCentroid(path, threshold) {

        if (path.length <= 0) {
            return QtPositioning.coordinate();
        }

        var coordinate = path[0];
        var lastGood = path[0];
        var count = 1;

        var latitude = coordinate.latitude;
        var longitude = coordinate.longitude;

        for (var i = 1; i < path.length; i++) {
            coordinate = path[i];

            if (coordinate.isValid) {
                var distance = lastGood.distanceTo(coordinate);

                if (distance >= threshold) {
                    lastGood = coordinate
                    latitude += coordinate.latitude;
                    longitude += coordinate.longitude;
                    count++;
                }
            }
        }

        return QtPositioning.coordinate(latitude/count, longitude/count);
    }

    //--------------------------------------------------------------------------

    // Use the point in the middle of the array as the line centroid
    function getLineCentroid(path) {
        if (path.length <= 0) {
            return QtPositioning.coordinate();
        }

        return path[~~(path.length/2)];
    }

    //--------------------------------------------------------------------------

    // Calculate the zoom level for which most polygons should be displayed
    function zoomLevelClusteredAt(array, binSize) {
        const minZoomLevel = Math.min(...array);
        const maxZoomLevel = Math.max(...array);

        const nbins = (maxZoomLevel - minZoomLevel + 1) / binSize;
        const histo = new Array(nbins).fill(0);

        array.forEach(function createHisto(val) {
            histo[Math.round((val - minZoomLevel) / binSize)]++;
        })

        const indexOfMaxValue = histo.indexOf(Math.max(...histo));
        const maxValue = minZoomLevel + indexOfMaxValue * binSize;

        return maxValue;
    }

    //--------------------------------------------------------------------------

    function updateExtent() {

        var xMin;
        var yMin;
        var xMax;
        var yMax;

        if (surveysModel.count <= 0) {
            return false;
        }

        for (var i = 0; i < surveysModel.count; i++) {
            var coordinate = featureCoordinates[i];

            if (coordinate && coordinate.isValid) {
                if (i) {
                    xMin = Math.min(xMin, coordinate.longitude);
                    xMax = Math.max(xMax, coordinate.longitude);
                    yMin = Math.min(yMin, coordinate.latitude);
                    yMax = Math.max(yMax, coordinate.latitude);
                } else {
                    xMin = coordinate.longitude;
                    yMin = coordinate.latitude;
                    xMax = xMin;
                    yMax = yMin;
                }
            }
        }

        extent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));

        console.log("Surveys extent:", extent);

        return true;
    }

    //--------------------------------------------------------------------------

    function refresh() {
        console.log("Refreshing map view");

        getMapFeatures();
        updateExtent();
        clustersModel.reset();

        if (showClusters) {
            clustersModel.update();
        }
    }

    //--------------------------------------------------------------------------

    function toleranceWidth() {
        var coord1 = map.toCoordinate(Qt.point(0, 0));
        var coord2 = map.toCoordinate(Qt.point(tolerance, tolerance));

        return coord1.distanceTo(coord2);
    }

    //--------------------------------------------------------------------------
}
