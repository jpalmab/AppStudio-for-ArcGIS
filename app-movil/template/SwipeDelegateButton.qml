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
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

import "../Controls"

Rectangle {
    id: control

    //--------------------------------------------------------------------------

    property real buttonSize: 30 * AppFramework.displayScaleFactor
    property color backgroundColor: "transparent"
    property alias image: image

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    implicitHeight: buttonSize
    implicitWidth: buttonSize * 2

    color: control.SwipeDelegate.pressed
           ? Qt.darker(backgroundColor, 1.1)
           : backgroundColor
    
    //--------------------------------------------------------------------------

    onClicked: {
        forceActiveFocus();
    }

    //--------------------------------------------------------------------------

//    SwipeDelegate.onClicked: {
//        control.clicked()
//    }

    //--------------------------------------------------------------------------

    StyledImage {
        id: image

        anchors.centerIn: parent
        width: buttonSize
        height: width
        
        color: "#505050"
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        onClicked: {
            control.clicked();
        }

        onPressAndHold: {
            control.clicked();
        }
    }

    //--------------------------------------------------------------------------
}
