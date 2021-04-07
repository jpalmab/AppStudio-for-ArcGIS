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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

Item {
    //--------------------------------------------------------------------------

    property bool isOnline: Networking.isOnline
    property alias border: borderRect.border
    property color onlineColor: "#93c259"
    property color offlineColor: "#9a9a9a"

    //--------------------------------------------------------------------------

    implicitWidth: 13 * AppFramework.displayScaleFactor
    implicitHeight: 13 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        
        color: isOnline
               ? onlineColor
               : offlineColor
        
        radius: height / 2
    }
    
    Rectangle {
        id: borderRect

        anchors.fill: parent
        
        color: "transparent"
        
        border {
            width: 2 * AppFramework.displayScaleFactor
            color: "transparent"
        }
        
        radius: height / 2
    }

    //--------------------------------------------------------------------------
}
