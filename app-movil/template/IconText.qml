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

import ArcGIS.AppFramework 1.0

import "../Controls"

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property url icon
    property string text
    property var palette
    property alias font: textControl.font
    property LocaleProperties localeProperties: app.localeProperties

    property bool expanded: false

    //--------------------------------------------------------------------------

    signal clicked()

    //--------------------------------------------------------------------------

    layoutDirection: localeProperties.layoutDirection
    
    //--------------------------------------------------------------------------

    onClicked: {
        expanded = !expanded;
    }

    //--------------------------------------------------------------------------

    StyledImageButton {
        Layout.preferredWidth: 15 * AppFramework.displayScaleFactor
        Layout.preferredHeight: Layout.preferredWidth
        Layout.alignment: textControl.lineCount > 1 ? Qt.AlignTop : Qt.AlignVCenter

        source: icon
        color: palette.windowText

        onClicked: {
            control.clicked();
        }
    }
    
    //--------------------------------------------------------------------------

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: textControl.height

        MouseArea {
            anchors.fill: parent

            onClicked: {
                control.clicked();
            }
        }

        AppText {
            id: textControl

            width: parent.width
            text: control.text
            color: palette.windowText
            font {
                pointSize: 13
            }
            horizontalAlignment: localeProperties.textAlignment
            elide: expanded ? Text.ElideNone : localeProperties.textElide
            wrapMode: expanded ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }
    }

    //--------------------------------------------------------------------------
}
