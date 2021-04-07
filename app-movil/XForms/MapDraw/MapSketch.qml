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
import QtQuick.Layouts 1.12
import QtPositioning 5.12
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import "../SketchControl"
import "../SketchControl/SketchLib.js" as SketchLib
import "../SketchControl/dollar.js" as Dollar

Canvas {
    id: canvas

    //--------------------------------------------------------------------------

    property bool active: false

    property string penColor: "red"
    property real penWidth: 3

    property var sketchPoints
    property bool debug: false

    property alias unistroke: unistroke

    property Map map: parent

    //--------------------------------------------------------------------------

    signal sketched(var path)

    //--------------------------------------------------------------------------

    visible: active

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(canvas, true)
    }

    //--------------------------------------------------------------------------

    Unistroke {
        id: unistroke

        Component.onCompleted: {
            clearGestures();

            addGesture2("rectangle", new Array(new Dollar.Point(78,149),new Dollar.Point(78,153),new Dollar.Point(78,157),new Dollar.Point(78,160),new Dollar.Point(79,162),new Dollar.Point(79,164),new Dollar.Point(79,167),new Dollar.Point(79,169),new Dollar.Point(79,173),new Dollar.Point(79,178),new Dollar.Point(79,183),new Dollar.Point(80,189),new Dollar.Point(80,193),new Dollar.Point(80,198),new Dollar.Point(80,202),new Dollar.Point(81,208),new Dollar.Point(81,210),new Dollar.Point(81,216),new Dollar.Point(82,222),new Dollar.Point(82,224),new Dollar.Point(82,227),new Dollar.Point(83,229),new Dollar.Point(83,231),new Dollar.Point(85,230),new Dollar.Point(88,232),new Dollar.Point(90,233),new Dollar.Point(92,232),new Dollar.Point(94,233),new Dollar.Point(99,232),new Dollar.Point(102,233),new Dollar.Point(106,233),new Dollar.Point(109,234),new Dollar.Point(117,235),new Dollar.Point(123,236),new Dollar.Point(126,236),new Dollar.Point(135,237),new Dollar.Point(142,238),new Dollar.Point(145,238),new Dollar.Point(152,238),new Dollar.Point(154,239),new Dollar.Point(165,238),new Dollar.Point(174,237),new Dollar.Point(179,236),new Dollar.Point(186,235),new Dollar.Point(191,235),new Dollar.Point(195,233),new Dollar.Point(197,233),new Dollar.Point(200,233),new Dollar.Point(201,235),new Dollar.Point(201,233),new Dollar.Point(199,231),new Dollar.Point(198,226),new Dollar.Point(198,220),new Dollar.Point(196,207),new Dollar.Point(195,195),new Dollar.Point(195,181),new Dollar.Point(195,173),new Dollar.Point(195,163),new Dollar.Point(194,155),new Dollar.Point(192,145),new Dollar.Point(192,143),new Dollar.Point(192,138),new Dollar.Point(191,135),new Dollar.Point(191,133),new Dollar.Point(191,130),new Dollar.Point(190,128),new Dollar.Point(188,129),new Dollar.Point(186,129),new Dollar.Point(181,132),new Dollar.Point(173,131),new Dollar.Point(162,131),new Dollar.Point(151,132),new Dollar.Point(149,132),new Dollar.Point(138,132),new Dollar.Point(136,132),new Dollar.Point(122,131),new Dollar.Point(120,131),new Dollar.Point(109,130),new Dollar.Point(107,130),new Dollar.Point(90,132),new Dollar.Point(81,133),new Dollar.Point(76,133)));
            addGesture2("circle", new Array(new Dollar.Point(127,141),new Dollar.Point(124,140),new Dollar.Point(120,139),new Dollar.Point(118,139),new Dollar.Point(116,139),new Dollar.Point(111,140),new Dollar.Point(109,141),new Dollar.Point(104,144),new Dollar.Point(100,147),new Dollar.Point(96,152),new Dollar.Point(93,157),new Dollar.Point(90,163),new Dollar.Point(87,169),new Dollar.Point(85,175),new Dollar.Point(83,181),new Dollar.Point(82,190),new Dollar.Point(82,195),new Dollar.Point(83,200),new Dollar.Point(84,205),new Dollar.Point(88,213),new Dollar.Point(91,216),new Dollar.Point(96,219),new Dollar.Point(103,222),new Dollar.Point(108,224),new Dollar.Point(111,224),new Dollar.Point(120,224),new Dollar.Point(133,223),new Dollar.Point(142,222),new Dollar.Point(152,218),new Dollar.Point(160,214),new Dollar.Point(167,210),new Dollar.Point(173,204),new Dollar.Point(178,198),new Dollar.Point(179,196),new Dollar.Point(182,188),new Dollar.Point(182,177),new Dollar.Point(178,167),new Dollar.Point(170,150),new Dollar.Point(163,138),new Dollar.Point(152,130),new Dollar.Point(143,129),new Dollar.Point(140,131),new Dollar.Point(129,136),new Dollar.Point(126,139)));
            addGesture2("triangle", new Array(new Dollar.Point(137,139),new Dollar.Point(135,141),new Dollar.Point(133,144),new Dollar.Point(132,146),new Dollar.Point(130,149),new Dollar.Point(128,151),new Dollar.Point(126,155),new Dollar.Point(123,160),new Dollar.Point(120,166),new Dollar.Point(116,171),new Dollar.Point(112,177),new Dollar.Point(107,183),new Dollar.Point(102,188),new Dollar.Point(100,191),new Dollar.Point(95,195),new Dollar.Point(90,199),new Dollar.Point(86,203),new Dollar.Point(82,206),new Dollar.Point(80,209),new Dollar.Point(75,213),new Dollar.Point(73,213),new Dollar.Point(70,216),new Dollar.Point(67,219),new Dollar.Point(64,221),new Dollar.Point(61,223),new Dollar.Point(60,225),new Dollar.Point(62,226),new Dollar.Point(65,225),new Dollar.Point(67,226),new Dollar.Point(74,226),new Dollar.Point(77,227),new Dollar.Point(85,229),new Dollar.Point(91,230),new Dollar.Point(99,231),new Dollar.Point(108,232),new Dollar.Point(116,233),new Dollar.Point(125,233),new Dollar.Point(134,234),new Dollar.Point(145,233),new Dollar.Point(153,232),new Dollar.Point(160,233),new Dollar.Point(170,234),new Dollar.Point(177,235),new Dollar.Point(179,236),new Dollar.Point(186,237),new Dollar.Point(193,238),new Dollar.Point(198,239),new Dollar.Point(200,237),new Dollar.Point(202,239),new Dollar.Point(204,238),new Dollar.Point(206,234),new Dollar.Point(205,230),new Dollar.Point(202,222),new Dollar.Point(197,216),new Dollar.Point(192,207),new Dollar.Point(186,198),new Dollar.Point(179,189),new Dollar.Point(174,183),new Dollar.Point(170,178),new Dollar.Point(164,171),new Dollar.Point(161,168),new Dollar.Point(154,160),new Dollar.Point(148,155),new Dollar.Point(143,150),new Dollar.Point(138,148),new Dollar.Point(136,148)));
        }
    }

    //--------------------------------------------------------------------------

    onVisibleChanged: {
        if (visible) {
            requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    onSketched: {
        active = false;
    }

    //--------------------------------------------------------------------------

    function start() {
        sketchPoints = undefined;
        active = true;
    }

    //--------------------------------------------------------------------------

    function cancel() {
        active = false;
    }

    //--------------------------------------------------------------------------

    function addSketch(sketch) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "sketch:", JSON.stringify(sketch, undefined, 2));
        }

        switch (sketch.type) {
        case "rectangle":
            addRectangle(sketch);
            break;

        case "ellipse":
            addEllipse(sketch);
            break;

        case "triangle":
            addTriangle(sketch);
            break;
        }
    }

    //--------------------------------------------------------------------------

    function toRadians(degrees) {
        return degrees / 180.0 * Math.PI;
    }

    //--------------------------------------------------------------------------

    function addRectangle(sketch) {
        var points = [];

        var cx = sketch.center.x;
        var cy = sketch.center.y;
        var w2 = sketch.width / 2;
        var h2 = sketch.height / 2;

        points.push(Qt.point(cx - w2, cy - h2));
        points.push(Qt.point(cx - w2, cy + h2));
        points.push(Qt.point(cx + w2, cy + h2));
        points.push(Qt.point(cx + w2, cy - h2));
        points.push(points[0]);

        //points = rotate(sketch.center, points, 360 - sketch.indicativeAngle);

        addGeometry(points);
    }

    //--------------------------------------------------------------------------

    function addEllipse(sketch) {
        var points = [];

        var step = 2 * Math.PI / 100;
        var h = sketch.center.x;
        var k = sketch.center.y;
        var r1 = sketch.height / 2;
        var r2 = sketch.height / sketch.width * r1

        for(var theta = 0; theta < 2 * Math.PI; theta += step) {
            var x = h + r1 * Math.cos(theta);
            var y = k - r2 * Math.sin(theta);

            points.push(Qt.point(x, y));
        }

        addGeometry(points);
    }

    //--------------------------------------------------------------------------

    function addTriangle(sketch) {
        var points = [];

        var cx = sketch.center.x;
        var cy = sketch.center.y;
        var w2 = sketch.width / 2;
        var h2 = sketch.height / 2;

        points.push(Qt.point(cx - w2, cy + h2));
        points.push(Qt.point(cx, cy - h2));
        points.push(Qt.point(cx + w2, cy + h2));
        points.push(points[0]);

        addGeometry(points);
    }

    //--------------------------------------------------------------------------

    function rotate(origin, points, angle) {
        if (!angle) {
            return points;
        }

        var a = toRadians(angle);
        var sina = Math.sin(a);
        var cosa = Math.cos(a);

        var rpoints = [];

        points.forEach(function (point) {
            var x = (cosa * (point.x - origin.x)) + (sina * (point.y - origin.y)) + origin.x;
            var y = (cosa * (point.y - origin.y)) - (sina * (point.x - origin.x)) + origin.y;

            rpoints.push(Qt.point(x, y));
        });

        return rpoints;
    }

    //--------------------------------------------------------------------------

    function addGeometry(points) {
        var path = [];

        points.forEach(function (point) {
            path.push(map.toCoordinate(point));
        });

        sketched(path);
    }

    //--------------------------------------------------------------------------

    onPaint: {
        var ctx = getContext('2d');

        if (mouseArea.pressed) {
            if (sketchPoints) {
                ctx.save();

                ctx.fillStyle = penColor;
                ctx.strokeStyle = penColor;
                ctx.lineWidth = penWidth * AppFramework.displayScaleFactor;
                ctx.lineCap = "round";

                ctx.beginPath();
                var s = penWidth * AppFramework.displayScaleFactor * 2;
                var x = sketchPoints[0].x;
                var y = sketchPoints[0].y;
                ctx.ellipse(x - s / 2, y - s / 2, s, s);
                ctx.fill();

                ctx.moveTo(x, y);
                SketchLib.drawLine(ctx, sketchPoints);

                ctx.restore();
            }
        } else {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
    }

    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea
        
        enabled: canvas.active
        preventStealing: true
        propagateComposedEvents: false
        scrollGestureEnabled: false

        anchors.fill: parent
        
        onPressed: {
            sketchPoints = undefined;

            addSketchPoint(mouseX, mouseY);
        }
        
        onReleased: {
            var sketch = unistroke.recognize(sketchPoints);

            if (debug) {
                console.log(logCategory, "name:", unistroke.result.Name, "score:", Math.round(unistroke.result.Score * 100));
            }

            if (sketch) {
                addSketch(sketch);
            } else {
                sketch = SketchLib.detectSketch(sketchPoints);
                if (sketch) {
                    addSketch(sketch);
                }
            }

            sketchPoints = undefined;
            requestPaint();
        }
        
        onPressAndHold: {
        }
        
        onPositionChanged: {
            addSketchPoint(mouseX, mouseY);
        }
    }
    
    //--------------------------------------------------------------------------

    function addSketchPoint(x, y) {

        if (debug) {
            console.log(logCategory, arguments.callee.name, x, y);
        }

        var point = {
            "x": x,
            "y": y
        };

        if (!Array.isArray(sketchPoints)) {
            sketchPoints = [point];
            return;
        }

        if (SketchLib.eq(point, sketchPoints[sketchPoints.length - 1])) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "Dup point:", JSON.stringify(point), JSON.stringify(sketchPoints[sketchPoints.length - 1]));
            }
            return;
        }

        sketchPoints.push(point);

        if (sketchPoints.length > 0) {
            canvas.requestPaint();
        }
    }

    //--------------------------------------------------------------------------
}
