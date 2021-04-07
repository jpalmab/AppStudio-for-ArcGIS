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

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

SpinBox {
    id: control

    //--------------------------------------------------------------------------

    property XFormStyle style
    property real implictIndicatorSize: style.buttonSize
    property color textColor: style.inputTextColor
    property color hoverColor: "#eee"
    property bool inputError: !textInput.acceptableInput
    property real radius: style.inputBackgroundRadius
    property color activeBorderColor: style.inputActiveBorderColor
    property color borderColor: style.inputBorderColor
    property color buttonBorderColor: borderColor
    property real buttonBorderWidth: style.inputBorderWidth

    //--------------------------------------------------------------------------

    padding: 6 * AppFramework.displayScaleFactor

    font {
        family: style.inputFontFamily
        pointSize: style.inputPointSize
        bold: style.inputBold
    }
    
    //--------------------------------------------------------------------------

    contentItem: TextInput {
        id: textInput

        z: 2

        text: control.displayText

        font: control.font
        color: readOnly
               ? style.inputReadOnlyTextColor
               : inputError ? style.inputErrorTextColor : textColor
        selectionColor: control.palette.highlight
        selectedTextColor: control.palette.highlightedText
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints

        Rectangle {
            x: -control.padding + 1
            y: -control.padding
            width: control.width - up.indicator.width - down.indicator.width - 2
            height: control.height
            visible: control.activeFocus
            color: "transparent"
            border {
                color: inputError ? style.inputErrorTextColor : activeBorderColor
                width: style.inputActiveBorderWidth
            }
        }
    }

    //--------------------------------------------------------------------------

    up.indicator: Rectangle {
        implicitWidth: implictIndicatorSize
        implicitHeight: implictIndicatorSize

        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        radius: control.radius
        color: up.hovered ? control.hoverColor : control.enabled ? style.inputBackgroundColor : style.inputReadOnlyTextColor

        border {
            color: up.pressed ? activeBorderColor : buttonBorderColor
            width: buttonBorderWidth
        }

        StyledImage {
            anchors {
                fill : parent
                margins: control.padding
            }

            color: up.pressed ? control.activeBorderColor : control.style.inputTextColor
            opacity: control.enabled ? 1 : 0.3
            source: Icons.icon("plus", style.inputBold)
        }
    }

    //--------------------------------------------------------------------------

    down.indicator: Rectangle {
        implicitWidth: implictIndicatorSize
        implicitHeight: implictIndicatorSize

        x: control.mirrored ? parent.width - width : 0
        height: parent.height
        radius: control.radius
        color: down.hovered ? control.hoverColor : control.enabled ? style.inputBackgroundColor : style.inputReadOnlyTextColor

        border {
            color: down.pressed ? activeBorderColor : buttonBorderColor
            width: buttonBorderWidth
        }

        StyledImage {
            anchors {
                fill : parent
                margins: control.padding
            }

            color: down.pressed ? control.activeBorderColor : control.style.inputTextColor
            opacity: control.enabled ? 1 : 0.3
            source: Icons.icon("minus", style.inputBold)
        }
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        implicitWidth: 140 * AppFramework.displayScaleFactor

        color: control.enabled
               ? (inputError ? style.inputErrorBackgroundColor : style.inputBackgroundColor)
               : style.inputReadOnlyBackgroundColor

        radius: control.radius
        border {
            color: borderColor
            width: style.inputBorderWidth
        }
    }

    //--------------------------------------------------------------------------

    onValueModified: {
        style.buttonFeedback();
    }

    //--------------------------------------------------------------------------
}
