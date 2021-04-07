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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Popup {
    id: popup

    //--------------------------------------------------------------------------

    property alias backgroundRectangle: backgroundRectangle
    property XFormStyle style: xform.style

    //--------------------------------------------------------------------------

    font {
        family: style.popupFontFamily
        pointSize: style.popupPointSize
        bold: popup.style.boldText
    }

    //--------------------------------------------------------------------------

    anchors.centerIn: parent

    modal: true
    dim: true

    padding: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Item {
        DropShadow {
            anchors.fill: source
            horizontalOffset: radius / 2
            verticalOffset: horizontalOffset

            radius: 10 * AppFramework.displayScaleFactor
            samples: 9
            color: "#80000000"
            source: backgroundRectangle
        }

        Rectangle {
            id: backgroundRectangle

            anchors.fill: parent

            color: style.popupBackgroundColor
            radius: 3 * AppFramework.displayScaleFactor

            border {
                color: style.popupBorderColor
                width: style.popupBorderWidth
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
