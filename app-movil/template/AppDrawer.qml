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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"

Drawer {
    id: popup
    
    //--------------------------------------------------------------------------

    property LocaleProperties localeProperties: app.localeProperties
    property alias layout: layout
    default property alias contentItems: layout.data

    //--------------------------------------------------------------------------

    modal: true
    dim: true

    implicitHeight: 100
    
    width: 300 * AppFramework.displayScaleFactor
    height: parent.height
    
    font {
        family: app.fontFamily
        pointSize: 14
    }

    palette {
        window: "white"
        windowText: "black"
        dark: "darkgrey"
    }

    edge: app.localeProperties.isRightToLeft ? Qt.LeftEdge : Qt.RightEdge
    
    //--------------------------------------------------------------------------
    /*
    Overlay.modal: Rectangle {
        color: palette.shadow

        Behavior on opacity {
            OpacityAnimator {
                to: 0.3
            }
        }
    }
*/
    //--------------------------------------------------------------------------

    background: Item {
        DropShadow {
            anchors.fill: source
            horizontalOffset: radius / 2
            verticalOffset: horizontalOffset

            radius: 20 * AppFramework.displayScaleFactor
            samples: 20
            color: palette.shadow
            source: backgroundRectangle
        }

        Rectangle {
            id: backgroundRectangle

            anchors.fill: parent

            color: palette.window
        }
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        id: layout

        spacing: 0
    }

    //--------------------------------------------------------------------------
}
