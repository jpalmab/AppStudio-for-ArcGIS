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

import "../Controls/Singletons"

Item {
    id: dropdownField

    property bool dropdownVisible: false
    property alias text: valueText.text
    property alias textField: valueText
    property int count: 1
    property int originalCount: 1
    property alias altTextColor: valueText.altTextColor
    property bool valid: true

    property alias textInput: valueText.textInput
    property alias border: valueText.border
    property alias color: valueText.backgroundColor
    property alias radius: valueText.radius

    //--------------------------------------------------------------------------

    signal cleared()
    signal keyPressed()

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }
    
    height: valueLayout.height

    //--------------------------------------------------------------------------

    RowLayout {
        id: valueLayout
        
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        layoutDirection: xform.layoutDirection

        XFormTextField {
            id: valueText
            
            Layout.fillWidth: true
            
            enabled: originalCount > 0
            actionEnabled: true
            actionColor: xform.style.inputTextColor
            actionImage: Icons.icon("chevron-%1".arg(dropdownVisible ? "up" : "down"), true)
            actionVisible: originalCount > 0
            actionSeparator: true

            valid: dropdownField.valid
            altTextColor: dropdownField.altTextColor

            font {
                italic: !dropdownField.valid
            }

            onAction: {
                textInput.forceActiveFocus();
                dropdownVisible = !dropdownVisible;
            }

            onKeysPressed: {
                dropdownField.keyPressed();
            }

            //--------------------------------------------------------------------------

            leftIndicator: Item {
                implicitHeight: textInput.height
                implicitWidth: implicitHeight
                width: height

                visible: dropdownField.enabled && textInput.activeFocus

                Button {
                    anchors.fill: parent

                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0

                    icon {
                        source: Icons.icon("magnifying-glass")
                        color: textInput.color
                        height: textInput.height
                        width: height
                    }

                    display: AbstractButton.IconOnly
                    background: null

                    onClicked: {
                        textInput.textChanged();
                    }

//                    onPressAndHold: {
//                        control.pressAndHold();
//                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
