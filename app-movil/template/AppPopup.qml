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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"

Popup {
    id: popup
    
    //--------------------------------------------------------------------------

    property LocaleProperties localeProperties: app.localeProperties

    //--------------------------------------------------------------------------

    modal: true
    dim: true
    
    anchors.centerIn: parent

    width: parent.width * 0.75
    
    padding: 10 * AppFramework.displayScaleFactor

    font {
        family: app.fontFamily
        pointSize: 14
    }

    palette {
        window: "white"
        windowText: "black"
        dark: "darkgrey"
    }
    
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
            radius: 3 * AppFramework.displayScaleFactor

            border {
                color: palette.dark
                width: 1 * AppFramework.displayScaleFactor
            }
        }
    }

    //--------------------------------------------------------------------------

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
        }
    }

    //--------------------------------------------------------------------------
}
