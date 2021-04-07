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
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Menu {
    //--------------------------------------------------------------------------

    property color itemColor: "#202020"
    property color highlightColor: "#dadada"
    property alias radius: backgroundRectangle.radius

    //--------------------------------------------------------------------------

    implicitWidth: 200 * AppFramework.displayScaleFactor
    padding: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    font {
        pointSize: 14
    }

    //--------------------------------------------------------------------------

    background: Item {
        DropShadow {
            anchors.fill: source
            horizontalOffset: radius / 2
            verticalOffset: horizontalOffset

            radius: 5 * AppFramework.displayScaleFactor
            samples: 9
            color: "#80000000"
            source: backgroundRectangle
        }

        Rectangle {
            id: backgroundRectangle

            anchors.fill: parent

            color: "#fafafa"
            radius: 4 * AppFramework.displayScaleFactor
            border {
                color: "#c0c0c0"
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
