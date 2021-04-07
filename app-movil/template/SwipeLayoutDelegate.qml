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

SwipeDelegate {
    id: delegate

    //--------------------------------------------------------------------------

    default property alias contentItems: layout.data
    property alias layout: layout
    property Component behindLayout

    property alias layoutDirection: layout.layoutDirection

    property real buttonSize: 30 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    padding: 5 * AppFramework.displayScaleFactor
    rightInset: 3 * AppFramework.displayScaleFactor
    leftInset: rightInset
    
    hoverEnabled: true
    
    //--------------------------------------------------------------------------

    swipe {
        left: layoutDirection === Qt.RightToLeft ? behindLayout : null
        right: layoutDirection === Qt.LeftToRight ? behindLayout : null
    }

    //--------------------------------------------------------------------------

    onClicked: {
        if (behindLayout) {
            forceActiveFocus();
            if (swipe.position) {
                swipe.close();
            } else {
                swipe.open(layoutDirection === Qt.LeftToRight ? SwipeDelegate.Right : SwipeDelegate.Left);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    background: DropShadowRectangle {
        id: backgroundRectangle
        
        // dropShadow.visible: !delegate.swipe.position
        
        color: !behindLayout
               ? "white"
               : delegate.pressed
                 ? "#e1f0fb"
                 : delegate.hovered & !delegate.swipe.position
                   ? "#ecfbff"
                   : "white"
        
        border {
            width: 1 * AppFramework.displayScaleFactor
            color: "#e5e6e7"
        }

        radius: 2 * AppFramework.displayScaleFactor
    }
    
    //--------------------------------------------------------------------------

    contentItem: Item {
        
        implicitWidth: delegate.availableWidth
        implicitHeight: layout.height + layout.anchors.margins * 2
        
        RowLayout {
            id: layout
            
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 5 * AppFramework.displayScaleFactor
            }
            
            spacing: 8 * AppFramework.displayScaleFactor
        }
    }
    
    //--------------------------------------------------------------------------

    Timer {
        running: delegate.swipe.complete && delegate.swipe.position != 0
        interval: 5000
        
        onTriggered: {
            delegate.swipe.close();
        }
    }

    //--------------------------------------------------------------------------
}
