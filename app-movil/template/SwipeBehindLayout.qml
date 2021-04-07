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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

DropShadowRectangle {
    //--------------------------------------------------------------------------

    default property alias contentItems: layout.data
    property alias layout: layout

    //--------------------------------------------------------------------------

    height: parent.height
    width: layout.width
    
    anchors {
        right: parent.right
        rightMargin: parent.rightInset
    }
    
    color: parent.background.color

    border {
        width: parent.background.border.width
        color: parent.background.border.color
    }
    
    visible: parent.swipe.position < 0
    
    //--------------------------------------------------------------------------

    RowLayout {
        id: layout
        
        anchors {
            top: parent.top
            right: parent.right
            margins: parent.border.width
        }
        
        height: parent.height - anchors.margins * 2
        spacing: 0
        layoutDirection: parent.layout.layoutDirection
    }

    //--------------------------------------------------------------------------
}
