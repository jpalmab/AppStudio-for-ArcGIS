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

import "XFormSingletons"
import "../Controls"

RowLayout {
    id: radioControl

    //--------------------------------------------------------------------------

    property var bindElement
    property var label
    property var value
    property string appearance
    property XFormRadioGroup radioGroup
    property alias radioButton: radioButton
    property alias textColor: radioButton.textColor
    readonly property alias checked: radioButton.checked

    //--------------------------------------------------------------------------

    signal clicked()

    //--------------------------------------------------------------------------

    Layout.preferredWidth: xform.style.gridColumnWidth
    Layout.fillWidth: true
    Layout.alignment: likert ? Qt.AlignTop : Qt.AlignVCenter | Qt.AlignLeft

    //--------------------------------------------------------------------------

    readonly property bool compact: Appearance.contains(appearance, Appearance.kCompact) ||
                                    Appearance.contains(appearance, Appearance.kQuickCompact)

    readonly property bool likert: Appearance.contains(appearance, Appearance.kLikert)

    readonly property string imageSource: mediaValue(label, "image")
    readonly property string audioSource: mediaValue(label, "audio")
    
    //--------------------------------------------------------------------------

    clip: true
    layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    Component {
        id: imageButtonComponent

        StyledImageButton {
            source: imageSource

            onClicked: {
                xform.popoverStackView.push({
                                                item: valuesPreview,
                                                properties: {
                                                    values: radioControl.label
                                                }
                                            });
            }
        }
    }

    Loader {
        Layout.preferredWidth: xform.style.imageButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: imageButtonComponent
        active: imageSource > ""
        visible: active
    }
    
    //--------------------------------------------------------------------------

    XFormRadioButton {
        id: radioButton

        Layout.fillWidth: true

        text: (!compact || compact && !(imageSource > "")) ? textValue(label) + (language ? "" : "") : ""
        checked: radioGroup.value == value
        orientation: likert ? Qt.Vertical : Qt.Horizontal

        onClicked: {
            //console.log("radio click:", text, "checked:", checked, "value:", value, "groupValue:", radioGroup.value);

            if (checked) {
                radioGroup.label = label;
                radioGroup.valid = true;
                radioGroup.value = value;
            } else if (radioGroup.value == value) {
                radioGroup.label = undefined;
                radioGroup.value = undefined;
            }

            radioControl.clicked();
        }

        onActiveFocusChanged: {
            xform.controlFocusChanged(this, activeFocus, bindElement);
        }
    }

    //    Connections {
    //        target: radioGroup

    //        onValueChanged: {
    //            radioButton.checked = radioGroup.value == value;
    //        }
    //    }

    //--------------------------------------------------------------------------

    Component {
        id: audioButtonComponent

        XFormAudioButton {
            audio {
                source: audioSource
            }

            ttsText: radioButton.text
        }
    }

    Loader {
        Layout.preferredWidth: xform.style.playButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: audioButtonComponent
        active: audioSource > ""
        visible: active
    }

    //--------------------------------------------------------------------------
}
