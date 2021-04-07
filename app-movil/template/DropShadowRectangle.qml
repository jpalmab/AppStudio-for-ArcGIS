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
    implicitWidth: rectangle.implicitWidth
    implicitHeight: rectangle.implicitHeight

    //--------------------------------------------------------------------------

    property alias anitaliasing: rectangle.antialiasing
    property alias color: rectangle.color
    property alias border: rectangle.border
    property alias radius: rectangle.radius
    property alias gradient: rectangle.gradient

    property alias rectangle: rectangle
    property alias dropShadow: dropShadow

    //--------------------------------------------------------------------------

    DropShadow {
        id: dropShadow

        anchors.fill: source
        horizontalOffset: 3 * AppFramework.displayScaleFactor
        verticalOffset: horizontalOffset

        radius: 5 * AppFramework.displayScaleFactor
        samples: 9
        color: "#12000000"
        source: rectangle
    }
    
    //--------------------------------------------------------------------------

    Rectangle {
        id: rectangle

        anchors.fill: parent
    }

    //--------------------------------------------------------------------------
}
