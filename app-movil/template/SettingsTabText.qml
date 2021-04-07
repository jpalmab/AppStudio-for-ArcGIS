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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Controls"
import "../Controls/Singletons"

SettingsTab {
    title: qsTr("Text")
    description: qsTr("Scale the text size used in surveys")
    icon: Icons.icon("change-font-size")

    //--------------------------------------------------------------------------

    Item {
        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 8 * AppFramework.displayScaleFactor

            AppText {
                Layout.fillWidth: true

                text: qsTr("The text scale setting allows you to adjust the ways surveys are displayed to best suit your device's display characteristics.")
                color: app.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Scale %1%").arg(textScaleSlider.value * 100)
                color: app.textColor
            }

            Slider {
                id: textScaleSlider

                Layout.fillWidth: true

                from: 1
                to: 2
                value: appSettings.textScaleFactor
                stepSize: 0.05

                onValueChanged: {
                    appSettings.textScaleFactor = value;
                }
            }

            RowLayout {
                Layout.fillWidth: true

                AppText {
                    id: refText

                    Layout.fillWidth: true

                    text: "A"
                    font {
                        pointSize: 15
                    }

                    color: app.textColor
                    horizontalAlignment: Text.AlignLeft
                }

                AppText {
                    Layout.fillWidth: true

                    text: refText.text
                    font {
                        pointSize: refText.font.pointSize * textScaleSlider.to
                    }

                    color: refText.color
                    horizontalAlignment: Text.AlignRight
                }
            }

            VerticalScrollView {
                id: scrollView

                Layout.fillWidth: true
                Layout.fillHeight: true

                GroupRectangle {
                    width: scrollView.availableWidth
                    height: textPreview.height + textPreview.anchors.margins * 4

                    color: xformStyle.groupBackgroundColor
                    border {
                        color: xformStyle.groupBorderColor
                        width: xformStyle.groupBorderWidth
                    }

                    ColumnLayout {
                        id: textPreview

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 5 * AppFramework.displayScaleFactor
                        }

                        spacing: 8 * AppFramework.displayScaleFactor

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Group Label Text")
                            color: xformStyle.groupLabelColor
                            font {
                                pointSize: xformStyle.groupLabelPointSize
                                bold: xformStyle.groupLabelBold
                                family: xformStyle.groupLabelFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Label Text")
                            color: xformStyle.labelColor
                            font {
                                pointSize: xformStyle.labelPointSize
                                bold: xformStyle.labelBold
                                family: xformStyle.labelFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Hint Text")
                            color: xformStyle.hintColor
                            font {
                                pointSize: xformStyle.hintPointSize
                                bold: xformStyle.hintBold
                                family: xformStyle.hintFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        TextField {
                            Layout.fillWidth: true

                            text: qsTr("Input Text")

                            font: xformStyle.inputFont
                            palette: xform.style.inputPalette
                        }

                        XFormStyle {
                            id: xformStyle
                            visible: false

                            textScaleFactor: textScaleSlider.value
                            fontFamily: appSettings.fontFamily
                        }
                    }
                }
            }

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Font")

                onTitlePressAndHold: {
                    appSettings.fontFamily = appSettings.defaultFontFamily;
                    fontComboBox.updateCurrentIndex();
                }

                ComboBox {
                    id: fontComboBox

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

                    model: Qt.fontFamilies()

                    font {
                        family: appSettings.fontFamily
                        pointSize: 14
                    }

                    Component.onCompleted: {
                        popup.font = font;
                        updateCurrentIndex();
                    }

                    onActivated: {
                        appSettings.fontFamily = model[index];
                    }

                    function updateCurrentIndex() {
                        var i = find(appSettings.fontFamily);
                        if (i < 0) {
                            i = find(Qt.application.font.family);
                        }

                        currentIndex = i;
                    }
                }
            }
        }
    }
}
