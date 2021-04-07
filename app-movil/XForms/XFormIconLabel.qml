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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property alias icon: icon
    property alias label: labelText
    property alias text: labelText.text
    property alias font: labelText.font

    property XFormStyle style: xform.style
    property var locale: xform.locale

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    StyledImage {
        id: icon

        Layout.preferredWidth: 20 * AppFramework.displayScaleFactor * control.style.textScaleFactor
        Layout.preferredHeight: Layout.preferredWidth

        visible: source > ""
        color: control.style.textColor
        height: width
    }

    //--------------------------------------------------------------------------

    Text {
        id: labelText

        Layout.fillWidth: true

        color: control.style.textColor

        font {
            family: control.style.fontFamily
            bold: control.style.boldText
            pointSize: 14 * control.style.textScaleFactor
        }

        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: xform.localeInfo.textAlignment
    }

    //--------------------------------------------------------------------------
}
