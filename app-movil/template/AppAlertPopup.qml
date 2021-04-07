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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Popup {
    id: popup
    
    //--------------------------------------------------------------------------

    property url icon
    property string text
    property int duration: 3000
    property color textColor: "black"
    property color backgroundColor: "white"
    property bool showClose: false
    property LocaleProperties localeProperties
    
    //--------------------------------------------------------------------------

    x: 0
    y: parent.height
    width: parent.width
    height: 45 * AppFramework.displayScaleFactor
    padding: 8 * AppFramework.displayScaleFactor
    
    palette {
        window: backgroundColor
        windowText: textColor
        dark: "transparent"
    }
    
    font {
        family: app.fontFamily
        pointSize: 14
    }
    
    modal: false
    dim: false

    //--------------------------------------------------------------------------

    background: Item {
        DropShadow {
            anchors.fill: source
            horizontalOffset: radius / 2
            verticalOffset: horizontalOffset

            radius: 20 * AppFramework.displayScaleFactor
            samples: 20
            color: palette.shadow
            source: backgroundRectangle
        }

        Rectangle {
            id: backgroundRectangle

            anchors.fill: parent
            color: popup.palette.window

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    popup.close();
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        id: layout

        layoutDirection: localeProperties.layoutDirection
        
        spacing: 5 * AppFramework.displayScaleFactor
        
        StyledImage {
            Layout.preferredHeight: layout.height * 0.75
            Layout.preferredWidth: Layout.preferredHeight
            
            source: popup.icon
            color: popup.palette.windowText
        }
        
        Text {
            Layout.fillWidth: true
            
            text: popup.text
            font: popup.font
            color: popup.palette.windowText
            elide: localeProperties.textElide
            horizontalAlignment: localeProperties.textAlignment
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: 12
        }

        StyledImage {
            Layout.preferredHeight: layout.height * 0.75
            Layout.preferredWidth: Layout.preferredHeight

            visible: showClose

            source: Icons.icon("x")
            color: popup.palette.windowText
        }
    }
    
    //--------------------------------------------------------------------------

    enter: Transition {
        NumberAnimation {
            property: "y"

            from: parent.height
            to: parent.height - height
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "y"

            from: parent.height - height
            to: parent.height
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: popup.duration
        running: interval > 0

        onTriggered: {
            popup.close();
        }
    }

    //--------------------------------------------------------------------------
}
