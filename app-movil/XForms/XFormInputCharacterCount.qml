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

Text {
    //--------------------------------------------------------------------------

    property Item inputControl: parent
    property real warningThreshold: 0.75
    property bool remaining: true
    property bool overThreshold: inputControl.length / inputControl.maximumLength > warningThreshold
    property var locale: inputControl.locale

    //--------------------------------------------------------------------------

    visible: inputControl.activeFocus && !inputControl.readOnly && inputControl.enabled && enabled
    text: remaining
          ? inputControl.maximumLength - inputControl.length
          : "%1/%2".arg(inputControl.length).arg(inputControl.maximumLength)

    color: overThreshold
           ? xform.style.inputCountWarningColor
           : xform.style.inputCountColor

    font {
        family: xform.style.fontFamily
        pixelSize: 11 * AppFramework.displayScaleFactor
        bold: overThreshold
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        onClicked: {
            remaining = !remaining;
        }
    }

    //--------------------------------------------------------------------------
}
