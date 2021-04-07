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
import QtGraphicalEffects 1.0
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls/Singletons"

Item {
    id: control

    //--------------------------------------------------------------------------

    property Map map: parent

    property real bearing: map.bearing
    property real size: 38 * AppFramework.displayScaleFactor

    property bool bold: false
    property alias color: overlay.color
    property alias background: background
    property alias font: bearingText.font

    enum Mode {
        Arrow = 0,
        Cardinal = 1,
        Degrees = 2,

        Count = 3
    }

    property int mode: NorthArrow.Mode.Arrow

    //--------------------------------------------------------------------------

    readonly property var kCardinals: [
        qsTr("N"),
        qsTr("NNE"),
        qsTr("NE"),
        qsTr("ENE"),
        qsTr("E"),
        qsTr("ESE"),
        qsTr("SE"),
        qsTr("SSE"),
        qsTr("S"),
        qsTr("SSW"),
        qsTr("SW"),
        qsTr("WSW"),
        qsTr("W"),
        qsTr("WNW"),
        qsTr("NW"),
        qsTr("NNW")
    ];

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    implicitWidth: size
    implicitHeight: size

    rotation: mode === NorthArrow.Mode.Arrow ? -bearing : 0
    visible: bearing != 0
    z: parent.z + 1

    //--------------------------------------------------------------------------

    onClicked: {
        map.bearing = 0;
    }

    onPressAndHold: {
        mode = (mode + 1) % NorthArrow.Mode.Count;
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            control.clicked();
        }

        onPressAndHold: {
            control.pressAndHold();
        }
    }

    //--------------------------------------------------------------------------

    DropShadow {
        id: dropShadow

        anchors.fill: source

        horizontalOffset: 3 * AppFramework.displayScaleFactor
        verticalOffset: horizontalOffset

        radius: 5 * AppFramework.displayScaleFactor
        samples: 9
        color: "#40000000"
        source: background
        opacity: background.opacity

    }

    Rectangle {
        id: background

        anchors {
            fill: parent
        }

        radius: height / 2

        color: "#eeeeee"
        opacity: 0.5

        border {
            width : (bold ? 2 : 1) * AppFramework.displayScaleFactor
            color: "#ddd"
        }
    }

    //--------------------------------------------------------------------------

    Image {
        id: image
        
        anchors {
            fill: parent
            margins: 6 * AppFramework.displayScaleFactor
        }
        
        fillMode: Image.PreserveAspectFit
        source: Icons.bigIcon("compass-needle", true)

        visible: false
    }
    
    ColorOverlay {
        id: overlay

        anchors.fill: image
        
        visible: mode === NorthArrow.Mode.Arrow
        source: image
        color: "black"
    }

    //--------------------------------------------------------------------------

    Image {
        anchors {
            top: parent.top
            topMargin: background.border.width
            horizontalCenter: parent.horizontalCenter
        }

        width: parent.width * 0.25

        visible: mode >= NorthArrow.Mode.Cardinal
        source: Icons.icon("caret-up", true)
        fillMode: Image.PreserveAspectFit
    }

    Text {
        id: bearingText

        anchors {
            fill: parent
            margins: 4 * AppFramework.displayScaleFactor
        }

        visible: mode >= NorthArrow.Mode.Cardinal

        text: mode === NorthArrow.Mode.Cardinal
            ? toCardinal(bearing)
            : "%1°".arg(Math.round(bearing))

        fontSizeMode: Text.HorizontalFit
        font {
            pointSize: 11
            bold: control.bold
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    //--------------------------------------------------------------------------

    function toCardinal(degrees) {
        if (!isFinite(degrees)) {
            return "";
        }

        var index = Math.floor((degrees / 22.5) + 0.5);
        return kCardinals[index % 16];
    }

    //--------------------------------------------------------------------------
}
