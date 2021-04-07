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

import ArcGIS.AppFramework 1.0

Item {
    id: control

    implicitWidth: 35 * AppFramework.displayScaleFactor
    implicitHeight: 35 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    property alias source: image.source
    property color color: "transparent"
    property alias radius: mask.radius
    property alias asynchronous: image.asynchronous
    property alias mirror: image.mirror
    property alias mipmap: image.mipmap

    //--------------------------------------------------------------------------

    Image {
        id: image
        
        anchors.fill: parent
        
        fillMode: Image.PreserveAspectFit
        visible: !overlay.visible

        sourceSize {
            width: image.width
            height: image.height
        }

        layer {
            enabled: radius > 0 && visible
            effect: OpacityMask {
                maskSource: mask
            }
        }
    }
    
    ColorOverlay {
        id: overlay

        anchors.fill: image
        
        source: image
        color: control.color
        visible: color !== "transparent"

        layer {
            enabled: radius > 0 && visible
            effect: OpacityMask {
                maskSource: mask
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: mask

        anchors.fill: parent
        radius: 0
        visible: false
    }

    //--------------------------------------------------------------------------
}
