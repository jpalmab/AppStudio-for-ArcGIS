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
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

import "../Controls"

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var constraint
    property var calculatedValue

    property var appearance: (formElement ? formElement["@appearance"] : "") || ""

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias currentValue: textArea.text
    readonly property bool showCalculate: !binding.isReadOnly && changeReason === 1 && calculatedValue !== undefined && calculatedValue != currentValue

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kPropertyDefaultHeight: "defaultHeight"

    //--------------------------------------------------------------------------

    readonly property int kDefaultHeight: 3

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    spacing: 5 * AppFramework.displayScaleFactor

    layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        MultiLineTextBox {
            id: textArea

            Layout.fillWidth: true

            property int maximumLength: 255
            property string previousText: text
            property int defaultHeight: kDefaultHeight

            locale: xform.locale
            layoutDirection: xform.layoutDirection
            horizontalAlignment: xform.localeInfo.inputAlignment

            readOnly: !editable || binding.isReadOnly
            textColor: changeReason === 3
                       ? xform.style.inputAltTextColor
                       : xform.style.inputTextColor


            backgroundColor: xform.style.inputBackgroundColor
            activeBorderColor: xform.style.inputActiveBorderColor
            activeBorderWidth: xform.style.inputActiveBorderWidth
            borderColor: xform.style.inputBorderColor
            borderWidth: xform.style.inputBorderWidth

            font {
                pointSize: xform.style.inputPointSize
                bold: xform.style.inputBold
                family: xform.style.inputFontFamily
            }

            Component.onCompleted: {
                constraint = formData.createConstraint(this, bindElement);

                var fieldLength = 255;
                var imh = inputMethodHints;

                if (appearance.indexOf("nopredictivetext") >= 0) {
                    imh |= Qt.ImhNoPredictiveText;
                } else if (appearance.indexOf("predictivetext") >= 0) {
                    imh &= ~Qt.ImhNoPredictiveText;
                }

                inputMethodHints = imh;

                var esriProperty = bindElement["@esri:fieldLength"];
                if (esriProperty > "") {
                    var n = Number(esriProperty);
                    if (isFinite(n)) {
                        fieldLength = n;
                    }
                }

                if (fieldLength > 0) {
                    maximumLength = fieldLength;
                }
            }

            onDefaultHeightChanged: {
                var text = "";
                if (defaultHeight > 1) {
                    for (var i = 1; i < defaultHeight; i++) {
                        text += "\n";
                    }
                }
                placeholderText = text;
            }

            onHeightChanged: {
                if (activeFocus) {
                    xform.ensureItemVisible(textArea);
                }
            }

            onActiveFocusChanged: {
                if (activeFocus) {
                    xform.ensureItemVisible(textArea);
                } else {
                    var value = currentValue;
                    var validate = false;

                    formData.setValue(bindElement, value);

                    if (validate && constraint && relevant) {
                        var error = constraint.validate();
                        if (error) {
                            xform.validationError(error);
                        }
                    }
                }

                xform.controlFocusChanged(this, activeFocus, bindElement);
            }

            onLengthChanged: {
                if (length === 0) {
                    formData.setValue(bindElement, undefined);
                }
            }

            onTextChanged: {
                if (text.length > maximumLength) {
                    var cursor = cursorPosition;
                    text = previousText;
                    if (cursor > text.length) {
                        cursorPosition = text.length;
                    } else {
                        cursorPosition = cursor - 1;
                    }
                }
                previousText = text
            }

            onCleared: {
                setValue(undefined, 1);
                textArea.forceActiveFocus();
                xform.style.buttonFeedback();
                valueModified(control);
            }

            Keys.onPressed: {
                switch (event.key) {
                case Qt.Key_Tab:
                    event.accepted = true;
                    xform.nextControl(textArea);
                    return;

                case Qt.Key_Backtab:
                    event.accepted = true;
                    xform.nextControl(textArea, false);
                    return;
                }

                if (!readOnly) {
                    changeReason = 1;
                    valueModified(control);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            visible: textArea.activeFocus
            layoutDirection: xform.layoutDirection

            Item {
                Layout.fillWidth: true
            }

            XFormInputCharacterCount {
                locale: xform.locale
                inputControl: textArea
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormRecalculateButton {
        Layout.alignment: Qt.AlignTop

        visible: showCalculate

        onClicked: {
            textArea.forceActiveFocus();
            changeReason = 0;
            formData.triggerCalculate(bindElement);
            valueModified(ctrol);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            if (reason === 1 && changeReason === 3 && value == currentValue) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        var isEmpty = XFormJS.isEmpty(value);
        currentValue = isEmpty ? "" : value.toString();
        formData.setValue(bindElement, XFormJS.toBindingType(value, bindElement));
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        element: formElement
        attribute: kAttributeStyle

        debug: control.debug

        Component.onCompleted: {
            initialize();
        }

        function initialize(reset) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, JSON.stringify(element));
            }

            if (reset) {
                parseParameters();
            }

            bind(textArea, undefined, kPropertyDefaultHeight, kDefaultHeight);
        }
    }

    //--------------------------------------------------------------------------
}
