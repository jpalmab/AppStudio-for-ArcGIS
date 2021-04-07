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
    //--------------------------------------------------------------------------

    property alias color: rect.color
    property alias border: rect.border
    property alias gradient: rect.gradient
    property alias radius: rect.radius
    property alias glow: glow

    //--------------------------------------------------------------------------

    implicitWidth: 100
    implicitHeight: 100

    //--------------------------------------------------------------------------

    RectangularGlow {
        id: glow

        anchors.fill: rect
        cornerRadius: 0
        glowRadius: 10 * AppFramework.displayScaleFactor
        spread: 0
        color: "lightgrey"
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: rect

        anchors.fill: parent
    }

    //--------------------------------------------------------------------------
}
