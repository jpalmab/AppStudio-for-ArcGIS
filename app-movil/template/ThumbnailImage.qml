/* Copyright 2020 Esri
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
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: control

    //--------------------------------------------------------------------------

    property url url
    property url defaultThumbnail

    property alias glow: glow
    property alias overlay: overlay

    property MouseArea mouseArea
    readonly property bool pressed: mouseArea ? mouseArea.pressed : false
    readonly property bool containsMouse: mouseArea ? mouseArea.containsMouse : false

    //--------------------------------------------------------------------------

    implicitWidth: 200
    implicitHeight: implicitWidth * 133/200

    color: "white"
    border {
        width: 0
    }

    clip: true
    
    //--------------------------------------------------------------------------

    Image {
        id: image
        
        anchors {
            fill: parent
            margins: control.border.width
        }
        
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        
        visible: !desaturate.visible
        source: url > "" ? url : defaultThumbnail
        scale: pressed
               ? 0.95
               : containsMouse
                 ? 1.05
                 : 1
        
        Behavior on scale {
            NumberAnimation {
                duration: 100
            }
        }
    }

    //----------------------------------------------------------------------

    Desaturate {
        id: desaturate

        anchors.fill: image

        visible: overlay.visible

        source: image
        scale: image.scale
        desaturation: 1
        opacity: 0.5
    }

    Glow {
        id: glow

        anchors.fill: overlay

        visible: overlay.visible
        source: overlay
        color: "white"
        radius: overlay.height * 0.15
        spread: 0.6
    }

    StyledImage {
        id: overlay

        anchors {
            centerIn: parent
        }

        height: parent.height * 0.5
        width: height
        visible: false
        source: Icons.bigIcon("refresh")
        color: "#a80000"
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        visible: containsMouse

        color: "#08000000"
    }

    //--------------------------------------------------------------------------
}
