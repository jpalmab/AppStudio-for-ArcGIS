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

import "../Controls/Singletons"

Loader {
    id: control
    
    width: ControlsSingleton.inputHeight
    height: ControlsSingleton.inputHeight

    //--------------------------------------------------------------------------

    property XFormStyle style: xform.style

    property real padding: 0
    property real imagePadding: ControlsSingleton.inputTextPadding

    property url imageSource
    property color imageColor: style.inputTextColor
    property color pressedImageColor: style.keyTextColor

    property color backgroundColor: style.inputBackgroundColor
    property color pressedBackgroundColor: style.keyPressedColor
    property color hoverBackgroundColor: "#ccc"

    property color borderColor: style.inputBorderColor
    property color pressedBorderColor: style.keyPressedColor
    property real borderWidth: style.inputBorderWidth

    property real radius: height / 2
    property bool mirror: false

    property bool activeFocusOnPress: false

    //--------------------------------------------------------------------------
    
    signal clicked()
    signal pressAndHold()
    
    //--------------------------------------------------------------------------
    
    visible: false
    
    //--------------------------------------------------------------------------
    
    onVisibleChanged: {
        if (visible) {
            active = true;
        }
    }
    
    //--------------------------------------------------------------------------
    
    sourceComponent: Item {
        implicitWidth: style.buttonSize
        implicitHeight: style.buttonSize
        
        Rectangle {
            radius: control.radius
            
            anchors {
                fill: parent
                margins: control.padding
            }
            
            color: button.mouseArea.containsMouse ? hoverBackgroundColor : button.mouseArea.pressed ? pressedBackgroundColor : backgroundColor

            border {
                width: borderWidth
                color: button.mouseArea.pressed ? pressedBorderColor : borderColor
            }
            
            XFormImageButton {
                id: button
                
                anchors {
                    fill: parent
                }
                
                padding: control.imagePadding
                color: button.mouseArea.pressed ? pressedImageColor : imageColor
                source: imageSource
                mirror: control.mirror

                mouseArea.hoverEnabled: true
                
                onClicked: {
                    control.clicked();
                }

                onPressAndHold: {
                    control.pressAndHold();
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    onClicked: {
        if (activeFocusOnPress) {
            forceActiveFocus();
        }

        style.buttonFeedback()
    }

    //--------------------------------------------------------------------------

    onPressAndHold: {
        if (activeFocusOnPress) {
            forceActiveFocus();
        }
    }

    //--------------------------------------------------------------------------
}
