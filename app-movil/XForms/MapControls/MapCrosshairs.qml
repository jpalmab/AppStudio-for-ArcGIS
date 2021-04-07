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
    //--------------------------------------------------------------------------

    property real crosshairLength: 50 * AppFramework.displayScaleFactor
    property int crosshairWidth: 2 * AppFramework.displayScaleFactor
    property int crosshairBorderWidth: 1
    
    //--------------------------------------------------------------------------
    
    anchors.fill: parent

    //--------------------------------------------------------------------------
    
    Rectangle {
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        
        width: crosshairLength
        height: crosshairWidth + 2 * border.width
        color: "black"
        border {
            width: parent.crosshairBorderWidth
            color: "#80FFFFFF"
        }
    }
    
    Rectangle {
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        
        width: crosshairLength
        height: crosshairWidth + 2 * border.width
        color: "black"
        border {
            width: crosshairBorderWidth
            color: "#80FFFFFF"
        }
        rotation: 90
    }
    
    //--------------------------------------------------------------------------
}
