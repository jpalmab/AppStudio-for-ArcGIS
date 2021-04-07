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

import ArcGIS.AppFramework 1.0

Item {
    id: control

    //--------------------------------------------------------------------------

    property alias source: image.source
    property color color: checkable ? checked ? checkedColor : uncheckedColor : "transparent"
    property color checkedColor: "black"
    property color uncheckedColor: "#c0c0c0"
    property color hoverColor: color
    property alias hoverEnabled: mouseArea.hoverEnabled
    property color pressedColor: color
    property alias radius: image.radius
    property alias asynchronous: image.asynchronous
    property alias mirror: image.mirror

    property bool checkable
    property bool checked

    property alias mouseArea: mouseArea
    property alias background: background
    property alias image: image

    property real padding: 0

    property bool activeFocusOnPress: true

    //--------------------------------------------------------------------------

    signal clicked(var mouse)
    signal pressAndHold(var mouse)
    signal released(var mouse)

    //--------------------------------------------------------------------------

    implicitWidth: 35 * AppFramework.displayScaleFactor
    implicitHeight: 35 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    onClicked: {
        if (activeFocusOnPress) {
            forceActiveFocus();
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: background

        anchors.fill: parent

        visible: control.enabled && mouseArea.containsMouse

        color: mouseArea.containsPress
               ? pressedColor
               : hoverColor

        radius: height / 2 //control.radius
        opacity: mouseArea.containsPress ? 0.4 : 0.1
    }

    //--------------------------------------------------------------------------

    StyledImage {
        id: image

        color: mouseArea.containsPress
               ? pressedColor
               : mouseArea.containsMouse
                 ? pressedColor
                 : control.color

        anchors {
            fill: parent
            margins: control.padding
        }

        opacity: control.enabled ? 1 : 0.5
    }
    
    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        enabled: control.enabled
        hoverEnabled: true

        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            control.clicked(mouse);
        }

        onPressAndHold: {
            control.pressAndHold(mouse);
        }

        onReleased: {
            control.released(mouse);
        }
    }

    //--------------------------------------------------------------------------
}
