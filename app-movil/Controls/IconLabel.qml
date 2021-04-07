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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property var icon
    property alias label: label
    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property alias elide: label.elide

    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    StyledImage {
        Layout.preferredHeight: label.height
        Layout.preferredWidth: label.height

        source: icon.source
        color: icon.color
    }
    
    //--------------------------------------------------------------------------

    Text {
        id: label

        Layout.fillWidth: true

        opacity: enabled ? 1.0 : 0.3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    //--------------------------------------------------------------------------
}
