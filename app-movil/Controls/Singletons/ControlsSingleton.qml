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

pragma Singleton

import QtQuick 2.12
import ArcGIS.AppFramework 1.0

import "."

Item {
    visible: false

    //--------------------------------------------------------------------------

    property url backIcon: Icons.icon("chevron-left")
    property real backIconPadding: 6 * AppFramework.displayScaleFactor

    property url closeIcon: Icons.icon("x")
    property real closeIconPadding: 6 * AppFramework.displayScaleFactor

    property url menuIcon: Icons.icon("hamburger")
    property real menuIconPadding: 6 * AppFramework.displayScaleFactor

    property real inputClearButtonOpacity: 0.3
    property url inputClearButtonIcon: Icons.icon("x-circle", true)
    property alias inputFont: inputText.font
    property alias inputTextHeight: inputText.height
    property real inputTextPadding: 8 * AppFramework.displayScaleFactor
    property real inputHeight: inputText.height + 2 * inputTextPadding
    property alias inputTextColor: inputText.color

    //--------------------------------------------------------------------------

    Text {
        id: inputText

        color: "#303030"
        text: "AXjgy"
        font {
            pointSize: 15
        }
    }

    //--------------------------------------------------------------------------
}

