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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

MenuItem {
    id: menuItem

    //--------------------------------------------------------------------------

    property color highlightColor: menu.highlightColor
    property Shortcut shortcut: Shortcut {}
    property color color: menu.itemColor
    property real iconSize: 40 * AppFramework.displayScaleFactor - padding * 2
    property real iconRadius: 0
    readonly property bool rtl: menuItem.locale.textDirection === Qt.RightToLeft

    //--------------------------------------------------------------------------

    padding: 6 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Rectangle {
        implicitWidth: menu.availableWidth
        implicitHeight: 35 * AppFramework.displayScaleFactor

        opacity: enabled ? 1 : 0.3
        color: menuItem.highlighted ? highlightColor : "transparent"
        radius: menu.radius
    }

    icon {
        color: menu.itemColor
    }

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        implicitWidth: menu.availableWidth

        layoutDirection: menuItem.locale.textDirection

        opacity: menuItem.enabled ? 1 : 0.3
        spacing: 8 * AppFramework.displayScaleFactor

        StyledImage {
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize

            source: menuItem.icon.source
            color: menuItem.icon.color
            radius: iconRadius
            mirror: rtl
        }

        Text {
            Layout.fillWidth: true

            text: menuItem.text
            font: menuItem.font
            color: menuItem.color
            horizontalAlignment: rtl ? Text.AlignRight : Text.AlignLeft
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: rtl ? Text.ElideLeft : Text.ElideRight
        }

        Text {
            Layout.preferredWidth: 50 * AppFramework.displayScaleFactor

            visible: text > ""
            text: shortcut.nativeText
            font: menuItem.font
            color: menuItem.color
            horizontalAlignment: rtl ? Text.AlightLeft : Text.AlignRight
        }
    }

    //--------------------------------------------------------------------------
}
