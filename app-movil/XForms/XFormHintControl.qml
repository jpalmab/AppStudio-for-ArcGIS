/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Layouts 1.3
// TODO import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

RowLayout {
    property XFormData formData

    property var hint
    property string hintText
    // TODO     property string guidanceText


    readonly property var textValue: translationTextValue(hint, language)
    readonly property string audioSource: mediaValue(hint, "audio", language)
    // TODO     readonly property var guidanceValue: translationTextValue(hint, language, "guidance")

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    onTextValueChanged: {
        hintText = formData.createTextExpression(textValue);
    }

    // TODO
    /*
    onGuidanceValueChanged: {
         guidanceText = formData.createTextExpression(guidanceValue);
    }
    */

    //--------------------------------------------------------------------------

    Loader {
        id: hintControl

        Layout.fillWidth: true
        Layout.fillHeight: true

        sourceComponent: hintTextComponent
    }

    Loader {
        sourceComponent: component_ColumnLayout
        active: audioSource > ""
    }

    //--------------------------------------------------------------------------

    Component {
        id: hintTextComponent

        Text {
            id: textItem

            text: XFormJS.encodeHTMLEntities(hintText.trim()) // TODO + (guidanceText > "" ?  " ☝︎" : "")
            color: xform.style.hintColor
            font {
                pointSize: xform.style.hintPointSize
                bold: xform.style.hintBold
                family: xform.style.hintFontFamily
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: text > ""
            textFormat: Text.RichText
            horizontalAlignment: xform.localeInfo.textAlignment

            onLinkActivated: {
                xform.openLink(link);
            }

            // TODO
            /*
            MouseArea {
                anchors.fill: parent

                enabled: guidanceText > ""

                onClicked: {
                    mouse.accepted = false;
                    showGuidance();
                }
            }

            function showGuidance() {
                ToolTip.toolTip.font.family = xform.style.guidanceHintFontFamily;
                ToolTip.toolTip.font.pointSize = xform.style.guidanceHintPointSize;

                ToolTip.show(guidanceText, 3000);
            }
            */
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: component_ColumnLayout

        ColumnLayout {
            XFormAudioButton {
                Layout.preferredWidth: xform.style.playButtonSize
                Layout.preferredHeight: Layout.preferredWidth

                audio {
                    source: audioSource
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
