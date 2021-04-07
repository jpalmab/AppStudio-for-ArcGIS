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
import "../Controls/Singletons"
import "XForm.js" as XFormJS

Column {
    id: control

    //--------------------------------------------------------------------------

    property XFormData formData

    property var label
    property string labelText

    readonly property var textValue: translationTextValue(label, language)
    readonly property string imageSource: mediaValue(label, "image", language)

    property bool collapsed: false
    property bool collapsible: false
    property bool required: false
    
    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    onTextValueChanged: {
        labelText = formData.createTextExpression(textValue);
    }

    //--------------------------------------------------------------------------

    Loader {
        sourceComponent: labelTextComponent
        width: parent.width
    }

    Loader {
        width: parent.width
        sourceComponent: imageComponent
        active: imageSource > ""
    }

    //--------------------------------------------------------------------------

    Component {
        id: labelTextComponent

        RowLayout {
            layoutDirection: xform.layoutDirection

            Loader {
                Layout.preferredWidth: 20 * AppFramework.displayScaleFactor * xform.style.textScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                active: collapsible
                visible: collapsible
                sourceComponent: StyledImageButton {

                    source: Icons.icon("caret-down")
                    color: _labelText.color
                    rotation: collapsed ? (xform.isRightToLeft ? 90 : -90) : 0
                    opacity: 0.5

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    onClicked: {
                        toggleCollapsed();
                    }
                }
            }

            Text {
                id: _labelText

                Layout.fillWidth: true

                text: xform.requiredText(labelText, required)
                color: xform.style.groupLabelColor
                font {
                    pointSize: xform.style.groupLabelPointSize
                    bold: xform.style.groupLabelBold
                    family: xform.style.groupLabelFontFamily
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                visible: text > ""
                textFormat: Text.RichText
                horizontalAlignment: xform.localeInfo.textAlignment

                onLinkActivated: {
                    xform.openLink(link);
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: collapsible
                    hoverEnabled: collapsible

                    cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: {
                        var link = parent.linkAt(mouse.x, mouse.y);
                        if (link > "") {
                            xform.openLink(link);
                        } else {
                            toggleCollapsed();
                        }
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    function toggleCollapsed() {
        collapsed = !collapsed;
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageComponent

        Image {
            source: imageSource
            fillMode: Image.PreserveAspectFit
            visible: !collapsed

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    xform.popoverStackView.push({
                                                    item: valuesPreview,
                                                    properties: {
                                                        values: label
                                                    }
                                                });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

}
