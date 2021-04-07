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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "Singletons"

Button {
    id: control
    
    //--------------------------------------------------------------------------
    
    padding: 8 * AppFramework.displayScaleFactor
    hoverEnabled: true
    
    //--------------------------------------------------------------------------
    /*
        InvalidRole = -1,
        AcceptRole,             0
        RejectRole,             1
        DestructiveRole,        2
        ActionRole,             3
        HelpRole,               4
        YesRole,                5
        NoRole,                 6
        ResetRole,              7
        ApplyRole,              8
        
        NRoles,
        */
    
    readonly property var kButtonRoleText: {
        0 : qsTr("Ok"),
        1 : qsTr("Cancel"),
        5 : qsTr("Yes"),
        6 : qsTr("No"),
        8 : qsTr("Apply"),
    }
    
    readonly property var kButtonRoleIcon: {
        0 : "check",
        1 : "x",
    }
    
    //--------------------------------------------------------------------------
    
    property int buttonRole: -1
    property var roleText: kButtonRoleText[buttonRole]
    property var roleIcon: kButtonRoleIcon[buttonRole]
    
    //--------------------------------------------------------------------------
    
    icon.source: roleIcon ? Icons.icon(roleIcon) : ""
    
    contentItem: Text {
        text: control.text > "" ? control.text : (roleText || control.text)
        
        font {
            family: control.font.family
            bold: pressed
            pointSize: 15
        }
        
        opacity: enabled ? 1.0 : 0.3
        color: control.down
               ? "black"
               : "#404040"
        
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        elide: Text.ElideRight
    }
    
    //--------------------------------------------------------------------------
    
    background: Rectangle {
        implicitWidth: 80 * AppFramework.displayScaleFactor
        
        opacity: enabled ? 1 : 0.3
        border {
            color: control.down
                   ? "darkgrey"
                   : "#e5e6e7"
            width: (down ? 2 : 1) * AppFramework.displayScaleFactor
        }
        
        color: pressed
               ? "#e1f0fb"
               : hovered
                 ? "#ecfbff"
                 : "white"
        
        radius: height / 2

        MouseArea {
            anchors.fill: parent

            enabled: control.enabled
            hoverEnabled: enabled

            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }
    
    //--------------------------------------------------------------------------
}
