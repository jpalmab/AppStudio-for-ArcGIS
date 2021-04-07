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

import ArcGIS.AppFramework 1.0

import "../Controls"

TextBox {
    id: control

    //--------------------------------------------------------------------------

    property bool actionEnabled: false
    property bool actionIfReadOnly: false
    property string actionImage: "images/clear.png"
    property bool actionVisible: text > "" && (!readOnly || actionIfReadOnly)
    property bool actionSeparator: false
    property bool altTextColor: false
    property bool valid: true
    property color actionColor: xform.style.inputTextColor

    //--------------------------------------------------------------------------

    signal action()

    //--------------------------------------------------------------------------

    locale: xform.locale
    layoutDirection: xform.layoutDirection
    horizontalAlignment: xform.localeInfo.inputAlignment

    placeholderTextColor: xform.style.inputPlaceholderTextColor

    font {
        bold: xform.style.inputBold
        pointSize: xform.style.inputPointSize
        family: xform.style.inputFontFamily
    }

    textColor: (valid && acceptableInput)
               ? altTextColor
                 ? xform.style.inputAltTextColor
                 : (readOnly ? xform.style.inputReadOnlyTextColor : xform.style.inputTextColor)
    : xform.style.inputErrorTextColor

    activeBorderColor: xform.style.inputActiveBorderColor
    borderColor: xform.style.inputBorderColor
    backgroundColor: readOnly
                     ? xform.style.inputReadOnlyBackgroundColor
                     : xform.style.inputBackgroundColor

    radius: xform.style.inputBackgroundRadius

    //--------------------------------------------------------------------------

    rightIndicator: RowLayout {
        id: rightLayout

        implicitHeight: textInput.height

        visible: actionEnabled && actionVisible
        spacing: control.spacing
        layoutDirection: xform.layoutDirection

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth:  2 * AppFramework.displayScaleFactor
            Layout.topMargin: -control.padding + control.border.width
            Layout.bottomMargin: -control.padding + control.border.width

            color: control.borderColor

            visible: actionSeparator
        }

        XFormImageButton {
            Layout.preferredHeight: textInput.height
            Layout.preferredWidth: Layout.preferredHeight

            mouseArea.anchors.margins: -control.padding

            implicitWidth: height
            width: height

            source: actionImage
            color: actionColor

            onClicked: {
                action();
            }
        }
    }

    //--------------------------------------------------------------------------
}
