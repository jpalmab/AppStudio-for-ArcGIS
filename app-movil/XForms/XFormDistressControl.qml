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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"
import "XForm.js" as XFormJS

RowLayout {
    id: control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property var appearance: formElement ? formElement["@appearance"] : null
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property bool rightToLeft: xform.isRightToLeft

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property var calculatedValue
    readonly property var calculatedNumber: isFinite(calculatedValue) ? calculatedValue : Number.NaN
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    readonly property var value: !slider.isEmpty ? slider.normalisedValue : Number.NaN
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedNumber, value)

    property bool debug: false

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

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
            if (debug) {
                console.log("distress: onCalculatedValueChanged:", JSON.stringify(binding.nodeset), "value:", JSON.stringify(calculatedValue));
            }

            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    onRightToLeftChanged: {
        slider.value = maximumValue - slider.value;
    }

    Slider {
        id: slider

        Layout.fillWidth: true

        property bool isEmpty: true
        property bool inSetValue: false
        property var normalisedValue

        minimumValue: 0
        maximumValue: 10
        stepSize: 1
        tickmarksEnabled: true
        value: rightToLeft ? maximumValue : minimumValue
        wheelEnabled: false

        style: SliderStyle {
            handle: Item {
                implicitWidth: ControlsSingleton.inputHeight
                implicitHeight: ControlsSingleton.inputHeight

                visible: !slider.isEmpty

                Rectangle {
                    id: handle
                    anchors.fill: parent

                    radius: width / 2

                    color: xform.style.inputBackgroundColor

                    border {
                        color: control.pressed //control.activeFocus
                               ? xform.style.inputActiveBorderColor
                               : xform.style.inputBorderColor

                        width: control.pressed //control.activeFocus
                               ? xform.style.inputActiveBorderWidth
                               : xform.style.inputBorderWidth
                    }

                    Text {
                        anchors.centerIn: parent

                        text: rightToLeft ? control.maximumValue - control.value : control.value
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: changeReason === 3
                               ? xform.style.inputAltTextColor
                               : xform.style.inputTextColor

                        font {
                            family: xform.style.inputFontFamily
                            pointSize: xform.style.inputPointSize
                            bold: xform.style.inputBold
                        }
                    }
                }
            }

            groove: Rectangle {
                id: grooveRect

                implicitWidth: 200
                implicitHeight: ControlsSingleton.inputHeight / 2
                radius: ControlsSingleton.inputHeight / 2

                anchors.verticalCenter: parent.verticalCenter

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: grooveRect.width
                        height: grooveRect.height

                        Rectangle {
                            anchors.fill: parent
                            radius: grooveRect.radius
                        }
                    }
                }

                Rectangle {
                    width: parent.height
                    height: parent.width
                    anchors.centerIn: parent
                    rotation: 90

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: rightToLeft ? "green": "red" }
                        GradientStop { position: 0.5; color: "yellow" }
                        GradientStop { position: 1.0; color: rightToLeft ? "red" : "green" }
                    }
                }

                Rectangle {
                    anchors.fill: parent

                    color: "transparent"
                    radius: parent.radius
                    border {
                        color: xform.style.inputBorderColor
                        width: xform.style.inputActiveBorderWidth
                    }
                }
            }
        }

        onValueChanged: {
            if (!inSetValue) {
                normalisedValue = rightToLeft ? maximumValue - value : value;
                formData.setValue(bindElement, normalisedValue);
                isEmpty = false;
                changeReason = 1;
                xform.style.slideFeedback();
                valueModified(control);
            }
        }

        onPressedChanged: {
            if (slider.isEmpty && pressed) {
                slider.valueChanged();
            }
        }

        function setValue(_value, reason) {
            inSetValue = true;
            normalisedValue = _value;
            value = rightToLeft ? maximumValue - _value : _value;
            inSetValue = false;
            changeReason = reason ? reason : 0;
        }
    }
    
    //--------------------------------------------------------------------------

    XFormClearButton {
        visible: !slider.isEmpty && !readOnly

        onClicked: {
            setValue(null, 1);
            valueModified(control);
        }
    }

    //--------------------------------------------------------------------------

    XFormRecalculateButton {
        visible: showCalculate

        onClicked: {
            changeReason = 0;
            formData.triggerCalculate(bindElement);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log("distress setValue:", value, JSON.stringify(value), "_value:", control.value, JSON.stringify(control.value), "reason:", reason, "bindElement:", JSON.stringify(bindElement));
        }

        if (!XFormJS.isEmpty(value)) {
            if (value < 0) {
                value = 0;
            } else if (value > 10) {
                value = 10;
            }
        }

        var _changeReason = changeReason;
        var _value = control.value;

        slider.isEmpty = XFormJS.isEmpty(value);
        slider.setValue(slider.isEmpty ? 0 : value, reason);

        formData.setValue(bindElement, value);

        if (reason) {
            if (reason === 1 && _changeReason === 3 && value == _value) {
                if (debug) {
                    console.log("distress setValue == calculated:", JSON.stringify(value));
                }
                changeReason = 3;
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }
    }

    //--------------------------------------------------------------------------

    function isEqual(v1, v2) {
        return XFormJS.isEmpty(v1) && XFormJS.isEmpty(v2) || v1 == v2;
    }

    //--------------------------------------------------------------------------
}
