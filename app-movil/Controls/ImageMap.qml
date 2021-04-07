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

import QtQml 2.11
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Shapes 1.11

import ArcGIS.AppFramework 1.0

Image {
    id: imageMap

    //--------------------------------------------------------------------------

    property string title
    property alias svgInfo: svgInfo

    property alias model: pathsModel

    property bool selectable: true
    property bool multipleSelection: false
    property var selectableIds
    property var selectedSet: ({})
    property var ids: []
    property string selectedId
    readonly property var selectedIds: Object.keys(selectedSet).filter(function(key) { return selectedSet[key] === true})

    property real strokeWidth: debug ? 2 * AppFramework.displayScaleFactor : 0
    property color strokeColor: debug ? "#20ffffff" : "transparent"
    property color fillColor: "#01000000"

    property real selectedStrokeWidth: 4 * AppFramework.displayScaleFactor
    property color selectedStrokeColor: "#00b2ff"
    property color selectedFillColor: "#4000b2ff"

    property color hoverFillColor: "#40ffffff"

    property bool debug: false

    //--------------------------------------------------------------------------

    signal clicked(string id, var shape)
    signal pressAndHold(string id, var shape)

    //--------------------------------------------------------------------------

    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: false
    mipmap: false
    smooth: true

    //--------------------------------------------------------------------------

    QtObject {
        id: svgInfo

        property rect viewBox
        property double width
        property double height
        readonly property size size: Qt.size(width, height)
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(imageMap, true)
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: pathsModel
    }

    //--------------------------------------------------------------------------

    Item {
        id: pathsView

        anchors.centerIn: parent

        scale: imageMap.paintedWidth / imageMap.sourceSize.width
        width: imageMap.sourceSize.width
        height: imageMap.sourceSize.height

        Repeater {
            model: pathsModel

            delegate: shapeComponent
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            hoverEnabled: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: shapeComponent

        Shape {
            id: shape

            readonly property bool selectable: Array.isArray(selectableIds)
                                               ? selectableIds.indexOf(shapeId) >= 0
                                               : true
            readonly property bool containsMouse: selectable && mouseArea.containsMouse && shape.contains(Qt.point(mouseArea.mouseX, mouseArea.mouseY))
            readonly property bool selected: selectedSet[id] === true

            anchors.fill: parent
            containsMode: Shape.FillContains

            Connections {
                target: mouseArea

                onClicked: {
                    if (!shape.contains(Qt.point(mouse.x, mouse.y))) {
                        return;
                    }

                    if (imageMap.selectable && shape.selectable) {
                        var _selected = !selected;

                        var set = multipleSelection ? selectedSet : {};
                        set[id] = _selected;
                        selectedSet = set;

                        selectedId = selectedIds[0] || "";
                    }

                    imageMap.clicked(id, shape);
                }

                onPressAndHold: {
                    if (!shape.contains(Qt.point(mouse.x, mouse.y))) {
                        return;
                    }

                    imageMap.pressAndHold(id, shape);
                }
            }

            ShapePath {
                strokeWidth: (selected ? selectedStrokeWidth : imageMap.strokeWidth) / pathsView.scale
                strokeColor: selected ? selectedStrokeColor : imageMap.strokeColor
                fillColor: shape.containsMouse ? hoverFillColor : selected ? selectedFillColor : imageMap.fillColor //AppFramework.alphaColor(selected ? selectedFillColor : imageMap.fillColor, shape.containsMouse ? 0 : 0)

                PathSvg {
                    path: d
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        anchors.centerIn: parent

        width: parent.paintedWidth
        height: parent.paintedHeight

        active: debug

        sourceComponent: Rectangle {
            color: "transparent"
            border {
                color: "#10000000"
                width: 1
            }
        }
    }

    //--------------------------------------------------------------------------

    function select(value) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "value:", JSON.stringify(value));
        }

        var set = {};

        if (!value || value === "") {
            // Empty set
        } else if (Array.isArray(value)) {
            var ids = Array.isArray(selectableIds) ? selectableIds : imageMap.ids;
            value.forEach(function (v) {
                if (ids.indexOf(v) >= 0) {
                    set[v] = true;
                }
            });
        } else if (value > "") {
            set[value] = true;
        } else {
            console.error(logCategory, "Unexpected value:", JSON.stringify(value));
            return;
        }

        if (JSON.stringify(selectedSet) === JSON.stringify(set)) {
            return;
        }

        selectedSet = set;
    }

    //--------------------------------------------------------------------------

    onSourceChanged: {
        loadSvg();
    }

    //--------------------------------------------------------------------------

    function loadSvg() {
        var fileInfo = AppFramework.fileInfo(imageMap.source);
        var svg = fileInfo.folder.readTextFile(fileInfo.fileName);
        var svgJson = AppFramework.xmlToJson(svg);

        pathsModel.clear();
        ids = [];

        var viewBox = (svgJson["@viewBox"] || "").split(" ");

        svgInfo.viewBox = Qt.rect(viewBox[0], viewBox[1], viewBox[2], viewBox[3]);

        title = svgJson["@title"] || "";
        svgInfo.width = parseFloat(svgJson["@width"]);
        svgInfo.height = parseFloat(svgJson["@height"]);
        if (!isFinite(svgInfo.width)) {
            svgInfo.width = svgInfo.viewBox.width;
        }
        if (!isFinite(svgInfo.height)) {
            svgInfo.height = svgInfo.viewBox.height;
        }

        if (debug) {
            console.log(logCategory, "viewBox:", svgInfo.viewBox);
            console.log(logCategory, "size:", svgInfo.size);
        }

        loadPaths(svgJson);

        if (debug) {
            console.log(logCategory, "ids:", JSON.stringify(ids));
        }
    }

    function loadPaths(g) {
        var keys = Object.keys(g);

        keys.forEach(function (key) {
            var value = g[key];

            switch (key) {
            case "g" :
                loadPaths(value);
                break;

            case "path" :
                if (Array.isArray(value)) {
                    value.forEach(addPath);
                } else {
                    addPath(value);
                }
                break;
            }
        });
    }

    function addPath(path) {
        var id = path["@id"];
        if (id > "") {

            ids.push(id);

            var attributes = {};

            var keys = Object.keys(path);
            keys.forEach(function (key) {
                if (key[0] === "@") {
                    attributes[key.substr(1)] = path[key];
                }
            });

            pathsModel.append(attributes);
        }
    }

    //--------------------------------------------------------------------------
}
