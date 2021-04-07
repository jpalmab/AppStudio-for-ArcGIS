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

RowLayout {
    id: checkControl

    //--------------------------------------------------------------------------

    Layout.preferredWidth: xform.style.gridColumnWidth

    //--------------------------------------------------------------------------

    property var bindElement
    property var label
    property var value
    property string appearance
    property bool compact: appearance === "compact" || appearance === "quickcompact"
    property alias checkBox: checkBox

    readonly property string imageSource: mediaValue(label, "image")
    readonly property string audioSource: mediaValue(label, "audio")

    //--------------------------------------------------------------------------

    signal clicked()

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
                                   values: checkControl.label
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

    XFormCheckBox {
        id: checkBox
        
        Layout.fillWidth: true

        text: (!compact || compact && !(imageSource > "")) ? textValue(label) + (language ? "" : "") : ""

        onActiveFocusChanged: {
            xform.controlFocusChanged(this, activeFocus, bindElement);
        }

        onClicked: {
            checkControl.clicked();
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: audioButtonComponent

        XFormAudioButton {
            audio {
                source: audioSource
            }

            ttsText: checkBox.text
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

    function setValue(values) {
        checkBox.checked = values.indexOf(checkControl.value) >= 0;
    }

    //--------------------------------------------------------------------------
}
