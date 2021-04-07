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

import "../../Controls/Singletons"

MapOverlay {
    id: mapDraw
    
    //--------------------------------------------------------------------------

    enum CaptureType {
        None = 0,
        Line,
        SketchLine,
        Polygon,
        SketchPolygon
    }

    property int captureType: MapDraw.CaptureType.None

    //--------------------------------------------------------------------------

    enum Mode {
        View    = 0,
        Capture = 1,
        Edit    = 2
    }

    property int mode: MapDraw.Mode.View

    //--------------------------------------------------------------------------

    property var vertices: QtPositioning.path()

    readonly property bool isCapturing: captureType > MapDraw.CaptureType.None && mapMouseArea.pressed
    readonly property bool isSegmentedCaptureType: captureType === MapDraw.CaptureType.Line || captureType === MapDraw.CaptureType.Polygon
    readonly property bool isSketchingCaptureType: captureType === MapDraw.CaptureType.SketchLine || captureType === MapDraw.CaptureType.SketchPolygon
    readonly property bool isSketching: isSketchingCaptureType && mapMouseArea.pressed
    property bool isCapturingVertex: false
    property bool isEditingVertex: false
    readonly property bool isMovingVertex: verticesView.selectedIndex >= 0
    readonly property bool isDrawing: isCapturingVertex || isEditingVertex //|| isSketchingCaptureType

    property bool isPolygon: captureType === MapDraw.CaptureType.Polygon || captureType === MapDraw.CaptureType.SketchPolygon
    readonly property var mapPoly: isPolygon ? mapPolygon : mapPolyline
    property int verticesCount
    readonly property bool isEmpty: verticesCount <= 0
    readonly property bool isValid: isPolygon ? verticesCount > 2 : verticesCount > 1
    readonly property bool canEdit: verticesCount > 0 && mode !== MapDraw.Mode.Capture
    property bool panZoom: false
    property var panZoomState


    property color lineColor: "#00b2ff"
    property real lineWidth: 3 * AppFramework.displayScaleFactor
    property color fillColor: "#4000b2ff"

    property color editLineColor: "#00b2ff"
    property real editLineWidth: 3 * AppFramework.displayScaleFactor
    property color editFillColor: "#4000b2ff"
    property color editSegmentLineColor: "grey"

    property real tolerance: 30 * AppFramework.displayScaleFactor
    property bool vertexMoved: false

    property bool debug: false

    //--------------------------------------------------------------------------

    enum UndoType {
        ReplacePath,
        ReplaceVertex,
        InsertVertex,
        DeleteVertex
    }

    property var undoStack: []
    property bool canUndo: false

    //--------------------------------------------------------------------------

    signal editVertex(int index, var coordinate)
    signal shapeUpdated()

    //--------------------------------------------------------------------------

    enabled: mode > MapDraw.Mode.View && !panZoom

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(mapDraw, true)
    }

    //--------------------------------------------------------------------------

    onCenterChanged: {
        if (isMovingVertex) {
            replaceVertex(verticesView.selectedIndex, center, vertexMoved);
            vertexMoved = true;
        }
    }

    //--------------------------------------------------------------------------

    onPanZoomChanged: {
        if (panZoom) {
            panZoomState = baseMap.gesture.enabled;
            baseMap.gesture.enabled = true;
        } else {
            if (typeof panZoomState === "boolean") {
                baseMap.gesture.enabled = panZoomState;
            }
        }
    }

    //--------------------------------------------------------------------------

    MapSketch {
        id: sketch

        anchors.fill: parent

        enabled: true
    }

    //--------------------------------------------------------------------------

    MapMouseArea {
        id: mapMouseArea

        property int insertIndex: -1

        //preventStealing: captureType != MapDraw.CaptureType.Point
        //hoverEnabled: preventStealing

        onClicked: {
            if (isEditingVertex) {
                //                var geopath = insertPathCoordinate(coordinate);
                //                if (geopath) {
                //                    mapPolyline.insertCoordinate(geopath.width, coordinate);
                //                    updateShape();
                //                } else {
                //                    panTo(coordinate);
                //                }

                //                if (insertIndex < 0) {
                //                    panTo(coordinate);
                //                }

                return;
            }

            if (!isCapturingVertex) {
                panTo(toCoordinate(mouse));
            }
        }

        onDoubleClicked: {
            if (isMovingVertex) {
                panTo(toCoordinate(mouse));
            }

            //            if (isEditingVertex) {
            //                return;
            //            }

            //            if (isCapturingVertex) {
            //                endCapture(coordinate);
            //            } else {
            //                map.zoomTo(coordinate);
            //            }
        }

        onPressAndHold: {
            if (isEditingVertex) {
                return;
            }

            if (!isCapturingVertex && !isSketching) {
                startCapture(toCoordinate(mouse));
            }
        }

        onPressed: {
            if (isMovingVertex) {
                return;
            }

            if (isEditingVertex) {
                var geopath = insertPathCoordinate(toCoordinate(mouse));
                if (geopath) {
                    mouse.accepted = true;
                    insertIndex = geopath.width;
                    segmentPolyline.setVertex(this, geopath.path, insertIndex);
                    preventStealing = true;
                } else {
                    insertIndex = -1;
                    mouse.accepted = false;
                }

                return;
            }

            if (isCapturingVertex) {
                addVertex(toCoordinate(mouse), isSketchingCaptureType);
                vertexBin.activeMouseArea = this;
            } else if (captureType > MapDraw.CaptureType.None) {
                startCapture(toCoordinate(mouse));
            }
        }

        onPositionChanged: {
            if (isEditingVertex) {
                if (insertIndex >= 0) {
                    mouse.accepted = true;
                    segmentPolyline.setCoordinate(toCoordinate(mouse));
                }

                return;
            }

            if (isSketching) {
                addVertex(toCoordinate(mouse), true);
            } else if (isCapturing) {
                setVertex(toCoordinate(mouse));
            }
        }

        onReleased: {
            if (isEditingVertex) {
                if (insertIndex >= 0) {
                    mouse.accepted = true;
                    segmentPolyline.hide();

                    if (!vertexBin.containsMouse(this, mouse)) {
                        insertVertex(insertIndex, toCoordinate(mouse));
                    }

                    insertIndex = -1;
                }

                return;
            }

            if (isSketching) {
                endCapture(toCoordinate(mouse));
            } else if (isCapturingVertex) {
                vertexBin.activeMouseArea = null;

                if (vertexBin.containsMouse(this, mouse)) {
                    deleteVertex(-1);
                }
                //setVertex(coordinate);
            }
        }

        onCanceled: {
            console.log(logCategory, "cancelled");

            if (isEditingVertex) {
                if (insertIndex >= 0) {
                    segmentPolyline.hide();

                    mapPolyline.insertCoordinate(insertIndex, toCoordinate(mouse));
                    updateShape();

                    insertIndex = -1;
                }

                return;
            }
        }
    }

    //--------------------------------------------------------------------------

    VertexItem {
        id: segmentVertex

        visible: segmentPolyline.visible
        coordinate: segmentPolyline.coordinate
    }
    
    //--------------------------------------------------------------------------

    MapPolyline {
        id: mapPolyline

        visible: !isPolygon

        line {
            width: isDrawing ? editLineWidth : lineWidth
            color: isDrawing ? editLineColor : lineColor
        }
    }

    MapPolygon {
        id: mapPolygon

        visible: isPolygon

        color: isDrawing ? editFillColor : fillColor
        border {
            width: isDrawing ? editLineWidth : lineWidth
            color: isDrawing ? editLineColor : lineColor
        }
    }

    //--------------------------------------------------------------------------

    MapPolyline {
        id: _segmentPolyline

        visible: segmentPolyline.visible

        line {
            width: lineWidth
            color: editSegmentLineColor
        }
    }

    MapPolyline {
        id: segmentPolyline
        
        property int index: 0
        property var coordinate: baseMap.center
        
        visible: false
        
        line {
            width: editLineWidth
            color: editLineColor
        }

        function hide() {
            visible = false;
            vertexBin.activeMouseArea = null;
        }

        function setCoordinate(_coordinate) {
            coordinate = _coordinate;
            replaceCoordinate(index, coordinate);
        }

        function setVertex(mouseArea, vertices, i, ii) {
            vertexBin.activeMouseArea = mouseArea;

            var nVertices = vertices.length;

            var segmentPath = [];

            if (isPolygon && (i === 0 || i === (nVertices - 1))) {
                if (i === 0) {
                    segmentPath.push(vertices[nVertices - 1]);
                } else {
                    segmentPath.push(vertices[i - 1]);
                }

                coordinate = vertices[i];
                segmentPath.push(coordinate);
                index = segmentPath.length - 1;

                if (i === 0) {
                    segmentPath.push(vertices[i + 1]);
                } else {
                    segmentPath.push(vertices[0]);
                }
            } else {
                if (i > 0) {
                    segmentPath.push(vertices[i - 1]);
                }

                coordinate = vertices[i];
                segmentPath.push(coordinate);
                index = segmentPath.length - 1;

                if (i < (nVertices - 1)) {
                    segmentPath.push(vertices[i + 1]);
                }
            }

            segmentPolyline.path = segmentPath;
            _segmentPolyline.path = segmentPath;
            visible = true;
        }
    }

    //--------------------------------------------------------------------------

    MapItemView {
        id: verticesView
        
        property int editIndex: -1
        property int selectedIndex: -1

        model: ((isCapturingVertex || isEditingVertex) && !isSketching) ? mapPolyline.path : null

        delegate: VertexItem {
            id: vertexItem

            property int vertexIndex: index
            property var vertexCoordinate: verticesView.model[index]
            readonly property int isSelected: index === verticesView.selectedIndex && index >= 0

            coordinate: vertexCoordinate ? vertexCoordinate : QtPositioning.coordinate()
            editing: segmentPolyline.visible && vertexIndex === verticesView.editIndex
            visible: !segmentPolyline.visible || editing

            //contentItem.border.width: (isSelected ? 5 : 2) * AppFramework.displayScaleFactor

            /*
            SequentialAnimation {
                running: vertexItem.isSelected
                loops: Animator.Infinite

                OpacityAnimator {
                    id: ani1

                    target: vertexItem
                    duration: 750
                    from: 0.3
                    to: 1
                    easing.type: Easing.InQuad
                }

                OpacityAnimator {
                    target: vertexItem
                    duration: ani1.duration
                    from: ani1.to
                    to: ani1.from
                    easing.type: Easing.OutQuad
                }

                onStopped: {
                    vertexItem.opacity = 1;
                }
            }
            */

            Rectangle {
                anchors.centerIn: parent

                visible: isCapturingVertex && index === (verticesView.model.length - 1)

                width: parent.width / 2
                height: width
                radius: width / 2

                color: "#a0ff0000"
            }

            MouseArea {
                property bool insertCoordinate: false

                anchors.fill: parent

                preventStealing: true
                acceptedButtons: Qt.AllButtons
                cursorShape: isMovingVertex ? Qt.ArrowCursor : Qt.DragMoveCursor

                onPressAndHold: {
                    //editVertex(vertexItem.vertexIndex, vertexItem.vertexCoordinate);

                    if (isEditingVertex) {
                        mapMouseArea.preventStealing = false;
                        startVertexMove(vertexItem.vertexIndex, vertexItem.vertexCoordinate);
                    }
                }

                onPressed: {
                    if (isMovingVertex) {
                        return;
                    }

                    verticesView.editIndex = vertexItem.vertexIndex;

                    if (mouse.buttons & Qt.RightButton) {
                        var coordinate = mapDraw.toCoordinate(mapToItem(mapDraw, mouse.x, mouse.y));
                        var shape = QtPositioning.path(mapPoly.path);
                        shape.insertCoordinate(vertexItem.vertexIndex + 1, coordinate);
                        segmentPolyline.setVertex(this, shape.path, vertexItem.vertexIndex + 1);
                        insertCoordinate = true;
                    } else {
                        insertCoordinate = false;
                        segmentPolyline.setVertex(this, verticesView.model, vertexItem.vertexIndex);
                    }
                }

                onPositionChanged: {
                    if (isMovingVertex) {
                        return;
                    }

                    var pt = mapToItem(mapDraw, mouseX, mouseY);
                    var coordinate = mapDraw.toCoordinate(Qt.point(pt.x, pt.y));

                    segmentPolyline.setCoordinate(coordinate);
                }

                onReleased: {
                    console.log(logCategory, "vertex released:", vertexItem.vertexIndex, "isMovingVertex:", isMovingVertex);

                    segmentPolyline.hide();

                    if (isMovingVertex) {
                        return;
                    }

                    if (vertexBin.containsMouse(this, mouse)) {
                        if (!insertCoordinate) {
                            deleteVertex(vertexItem.vertexIndex);
                        }
                    } else {
                        var coordinate = mapDraw.toCoordinate(mapToItem(mapDraw, mouse.x, mouse.y));

                        if (insertCoordinate) {
                            insertVertex(vertexItem.vertexIndex + 1, coordinate);
                        } else {
                            replaceVertex(vertexItem.vertexIndex, coordinate);
                        }
                    }
                }

                onCanceled: {
                    segmentPolyline.hide();
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Item {
        id: vertexBin

        property MouseArea activeMouseArea
        property bool active: visible
                              && (isCapturingVertex || isEditingVertex)
                              && activeMouseArea.pressed
                              && contains(mapFromItem(activeMouseArea, activeMouseArea.mouseX, activeMouseArea.mouseY))

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            margins: 10 * AppFramework.displayScaleFactor
        }

        visible: enabled && activeMouseArea && activeMouseArea.pressed && !isSketchingCaptureType

        width: 40 * AppFramework.displayScaleFactor
        height: width

        Image {
            id: trashImage

            anchors.fill: parent
            source: Icons.icon("trash", vertexBin.active)
            visible: false
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
        }

        Glow {
            anchors.fill: trashImage
            source: trashImage
            color: "white"
            radius: 10 * AppFramework.displayScaleFactor
        }

        ColorOverlay {
            anchors.fill: trashImage
            source: trashImage
            color: vertexBin.active ? "red" : "#00b2ff"
        }

        function containsXY(item, x, y) {
            return contains(mapFromItem(item, x, y));
        }

        function containsMouse(mouseArea, mouseEvent) {
            if (mouseEvent) {
                return contains(mapFromItem(mouseArea, mouseEvent.x, mouseEvent.y));
            } else {
                return contains(mapFromItem(mouseArea, mouseArea.mouseX, mouseArea.mouseY));
            }
        }
    }

    //--------------------------------------------------------------------------

    function startCapture(coordinate) {
        console.log(logCategory, arguments.callee.name, coordinate);

        baseMap.gesture.enabled = false;

        switch (captureType) {
        case MapDraw.CaptureType.Line :
        case MapDraw.CaptureType.Polygon :
            startSegmented(coordinate);
            break;

        case MapDraw.CaptureType.SketchLine :
        case MapDraw.CaptureType.SketchPolygon :
            startSketch(coordinate);
            break;

        default:
            break;
        }
    }

    //--------------------------------------------------------------------------

    function endCapture(coordinate) {
        console.log(logCategory, arguments.callee.name, coordinate);

        switch (captureType) {
        case MapDraw.CaptureType.Line :
        case MapDraw.CaptureType.Polygon :
            endSegmented(coordinate);
            break;

        case MapDraw.CaptureType.SketchLine :
        case MapDraw.CaptureType.SketchPolygon :
            endSketch(coordinate);
            break;

        default:
            break;
        }

        baseMap.gesture.enabled = true;
    }

    //--------------------------------------------------------------------------

    function startSketch(coordinate) {
        console.log(logCategory, arguments.callee.name, coordinate);
        baseMap.gesture.enabled = false;

        mapPolyline.path = [coordinate];

        updateShape();
    }

    //--------------------------------------------------------------------------

    function endSketch(coordinate) {
        baseMap.gesture.enabled = true;

        addVertex(coordinate, true);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", mapPolyline.path);
        }

        updateShape();

        mode = MapDraw.Mode.View;
        captureType = MapDraw.CaptureType.None;
        baseMap.gesture.enabled = true;
        isCapturingVertex = false;
        isEditingVertex = false;
    }

    //--------------------------------------------------------------------------

    function startSegmented(coordinate) {
        console.log(logCategory, arguments.callee.name, "coordinate:", coordinate);

        baseMap.gesture.enabled = false;


        vertices.path = [coordinate];
        mapPolyline.path = [coordinate];
        isCapturingVertex = true;
        verticesCount = mapPolyline.pathLength();

        undoPush({
                     type: MapDraw.UndoType.DeleteVertex,
                     index: 0
                 });
    }

    //--------------------------------------------------------------------------

    function endSegmented(coordinate) {
        baseMap.gesture.enabled = true;
        isCapturingVertex = false;

        if (coordinate) {
            setVertex(coordinate);
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", mapPolyline.path);
        }

        updateShape();
        undoClear();
    }

    //--------------------------------------------------------------------------

    function isEqualCoordinate(c1, c2) {
        if (!c1 || !c2) {
            return false;
        }

        return c1.latitude === c2.latitude &&
                c1.longitude === c2.longitude &&
                c1.altitude === c2.altitude;
    }

    //--------------------------------------------------------------------------

    function addVertex(coordinate, noUndo) {
        if (debug) {
            console.log(logCategory, "addVertex:", coordinate);
        }

        var index = -1;

        function isSameAsLastCoordinate() {
            var lastIndex = mapPolyline.pathLength() - 1;
            if (lastIndex < 0) {
                return false;
            }

            return isEqualCoordinate(coordinate, mapPolyline.coordinateAt(lastIndex));
        }

        if (!isSameAsLastCoordinate()) {
            index = mapPolyline.pathLength();
            mapPolyline.addCoordinate(coordinate);
        }

        if (!noUndo && index >= 0) {
            undoPush({
                         type: MapDraw.UndoType.DeleteVertex,
                         index: index
                     });
        }

        updateShape();
    }


    //--------------------------------------------------------------------------

    function insertVertex(index, coordinate) {
        undoPush({
                     type: MapDraw.UndoType.DeleteVertex,
                     index: index
                 });

        mapPolyline.insertCoordinate(index, coordinate);
        updateShape();
    }

    //--------------------------------------------------------------------------

    function deleteVertex(index) {
        if (index < 0) {
            index = mapPolyline.pathLength() - 1;

            if (index < 0) {
                return;
            }
        }

        var coordinate = mapPolyline.coordinateAt(index);

        undoPush({
                     type: MapDraw.UndoType.InsertVertex,
                     index: index,
                     coordinate: coordinate
                 });

        mapPolyline.removeCoordinate(index);

        updateShape();
    }

    //--------------------------------------------------------------------------

    function setVertex(coordinate) {
        //console.log("setLastVertex:", coordinate);

        var n = mapPolyline.pathLength();
        if (n === 0) {
            mapPolyline.path = [coordinate];
        } else if (n === 1) {
            mapPolyline.addCoordinate(coordinate);
        } else {
            mapPolyline.replaceCoordinate(n - 1, coordinate);
        }

        updateShape();
    }

    //--------------------------------------------------------------------------

    function updateShape() {
        if (isPolygon) {
            mapPolygon.path = mapPolyline.path;
        }

        verticesCount = mapPolyline.pathLength();

        shapeUpdated();
    }

    //--------------------------------------------------------------------------

    function replacePath(path) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, path);
        }

        if (mapPolyline.pathLength() > 0) {
            undoPush({
                         type: MapDraw.UndoType.ReplacePath,
                         path: mapPolyline.path
                     });
        }

        mapPolyline.path = path;
        updateShape();
        isCapturingVertex = false;
        isEditingVertex = false;
    }

    //--------------------------------------------------------------------------

    function setPath(path) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, path);
        }

        if (!path.length) {
            isCapturingVertex = true;
            updateShape();
            return;
        }

        mapPolyline.path = path;
        updateShape();
        zoomToShape(mapPoly.geoShape, 1.1);
    }

    //--------------------------------------------------------------------------

    function panTo(coordinate) {
        if (coordinate && coordinate.isValid) {
            baseMap.center = coordinate;
        }
    }

    //--------------------------------------------------------------------------

    function zoomToShape(geoShape, scale) {
        var zoomRegion = geoShape.boundingGeoRectangle();

        if (zoomRegion && zoomRegion.isValid && !zoomRegion.isEmpty) {
            if (scale) {
                zoomRegion.width *= scale;
                zoomRegion.height *= scale;
            }

            baseMap.visibleRegion = zoomRegion;
        }
    }

    //--------------------------------------------------------------------------

    function zoomAll() {
        zoomToShape(mapPoly.geoShape, 1.1);
    }

    //--------------------------------------------------------------------------

    function replaceVertex(index, coordinate, noUndo) {
        if (!noUndo) {
            undoPush({
                         type: MapDraw.UndoType.ReplaceVertex,
                         index: index,
                         coordinate: mapPolyline.coordinateAt(index)
                     });
        }

        mapPolyline.replaceCoordinate(index, coordinate);
        updateShape();
    }

    //--------------------------------------------------------------------------

    function insertPathCoordinate(coordinate) {
        if (!coordinate || !coordinate.isValid) {
            return;
        }

        var tolerance = toleranceWidth();

        var geopath = QtPositioning.path(mapPoly.path, tolerance);

        var removeLastCoordinate = false;
        if (isPolygon) {
            var first = geopath.path[0];
            var last = geopath.path[geopath.path.length - 1];

            if (first.latitude !== last.latitude || first.longitude !== last.longitude) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "Closing polygon");
                }
                removeLastCoordinate = true;
                geopath.addCoordinate(first);
            }
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "tolerance:", geopath.width, "coordinate:", coordinate);
        }

        if (!geopath.contains(coordinate)) {
            return;
        }

        var path = geopath.path;
        var n = path.length;

        for (var index = 0; index < n - 1; index++) {

            var segment = QtPositioning.path([
                                                 path[index],
                                                 path[index + 1]
                                             ],
                                             tolerance);

            if (segment.contains(coordinate)) {
                index++;

                if (debug) {
                    console.log(logCategory, arguments.callee.name, "insert index:", index," coordinate:", coordinate);
                }

                geopath.insertCoordinate(index, coordinate);
                geopath.width = index;

                if (removeLastCoordinate) {
                    geopath.removeCoordinate(geopath.path.length - 1);
                }

                return geopath;
            }
        }
    }

    //--------------------------------------------------------------------------

    function toleranceWidth() {
        var coord1 = toCoordinate(Qt.point(0, 0));
        var coord2 = toCoordinate(Qt.point(tolerance, tolerance));

        return coord1.distanceTo(coord2);
    }

    //--------------------------------------------------------------------------

    function setMode(mode, captureType) {
        console.log(logCategory, arguments.callee.name, "mode:", mode, "captureType:", captureType, "isMovingVertex:", isMovingVertex);

        if (mapDraw.mode === mode) {
            if (captureType) {
                if (captureType === mapDraw.captureType) {
                    return;
                }
            } else {
                return;
            }
        }

        if (isMovingVertex) {
            endVertexMove();
        }

        switch (mapDraw.mode) {
        case MapDraw.Mode.Capture:
            endCapture();
            panZoom = false;
            baseMap.gesture.enabled = true;
            break;

        case MapDraw.Mode.Edit:
            isEditingVertex = false;
            break;
        }

        mapDraw.mode = mode;

        switch (mode) {
        case MapDraw.Mode.View:
            mapDraw.captureType = MapDraw.CaptureType.None;
            break;

        case MapDraw.Mode.Capture:
            if (captureType) {
                mapDraw.captureType = captureType;
            }
            panZoom = false;
//            baseMap.gesture.enabled = false;
            break;

        case MapDraw.Mode.Edit:
            isEditingVertex = true;
            mapDraw.captureType = MapDraw.CaptureType.None;
            snapshot();
            break;
        }
    }

    //--------------------------------------------------------------------------

    function clear(noUndo) {

        if (!noUndo && mapPolyline.pathLength() > 0) {
            undoPush({
                         type: MapDraw.UndoType.ReplacePath,
                         path: mapPolyline.path
                     });
        }

        mapPolyline.path = [];
        updateShape();
        isCapturingVertex = false;
    }

    //--------------------------------------------------------------------------

    function undoClear() {
        undoStack = [];
        canUndo = false;
    }

    //--------------------------------------------------------------------------

    function undoPush(action) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, JSON.stringify(action));
        }

        undoStack.push(action);
        canUndo = true;
    }

    //--------------------------------------------------------------------------

    function undo() {
        if (!undoStack.length) {
            return;
        }

        var action = undoStack.pop();
        canUndo = undoStack.length > 0;

        if (!action) { // Null action
            return;
        }

        switch (action.type) {
        case MapDraw.UndoType.ReplacePath:
            mapPolyline.path = action.path;
            break;

        case MapDraw.UndoType.ReplaceVertex:
            mapPolyline.replaceCoordinate(action.index, action.coordinate);
            break;

        case MapDraw.UndoType.InsertVertex:
            mapPolyline.insertCoordinate(action.index, action.coordinate);
            break;

        case MapDraw.UndoType.DeleteVertex:
            mapPolyline.removeCoordinate(action.index);
            break;
        }

        updateShape();

        return action;
    }

    //--------------------------------------------------------------------------

    function startVertexMove(index, coordinate) {
        panTo(coordinate);

        if (verticesView.selectedIndex === index) {
            verticesView.selectedIndex = -1;
        } else {
            verticesView.selectedIndex = index;
            vertexMoved = false;
        }
    }

    //--------------------------------------------------------------------------

    function endVertexMove(undoMove) {
        verticesView.selectedIndex = -1;

        if (undoMove) {
            var action = undo();
            panTo(action.coordinate);
        }
    }

    //--------------------------------------------------------------------------

    MapPolyline {
        id: snapshotPolyline

        visible: false
    }

    function snapshot() {
        console.log(logCategory, arguments.callee.name, "#", mapPoly.path.length);

        snapshotPolyline.path = mapPoly.path;
    }

    //--------------------------------------------------------------------------

    function restoreSnapshot() {
        console.log(logCategory, arguments.callee.name, "#", snapshotPolyline.path.length);

        mapPolyline.path = snapshotPolyline.path;
        updateShape();
        snapshotPolyline.path = [];
    }

    //--------------------------------------------------------------------------
}
