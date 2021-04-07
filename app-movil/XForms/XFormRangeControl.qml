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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XFormSingletons"
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
    property alias minimumValue: slider.from
    property alias maximumValue: slider.to
    property alias step: slider.stepSize
    property bool rightToLeft: xform.isRightToLeft

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property var calculatedValue
    readonly property var calculatedNumber: isFinite(calculatedValue) ? calculatedValue : Number.NaN
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    readonly property var currentValue: !slider.isEmpty ? slider.value : Number.NaN
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedNumber, currentValue)

    property bool debug: false

    property string appearance: (formElement ? formElement["@appearance"] : "") || ""

    property color startColor: kDefaultStartColor
    property color endColor: kDefaultEndColor
    property color color: kDefaultColor

    property real precision: 0

    readonly property bool showTicks: !Appearance.contains(appearance, Appearance.kNoTicks)

    //--------------------------------------------------------------------------

    readonly property string kParameterStart: "start"
    readonly property string kParameterEnd: "end"
    readonly property string kParameterStep: "step"

    readonly property real kDefaultStart: 0
    readonly property real kDefaultEnd: 10
    readonly property real kDefaultStep: 1

    readonly property string kPropertyStartColor: "startColor"
    readonly property string kPropertyEndColor: "endColor"
    readonly property string kPropertyColor: "color"

    readonly property color kDefaultStartColor: kTransparent
    readonly property color kDefaultEndColor: kTransparent
    readonly property color kDefaultColor: kTransparent

    readonly property color kTransparent: "transparent"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        minimumValue = getAttributeValue(formElement, kParameterStart, kDefaultStart);
        maximumValue = getAttributeValue(formElement, kParameterEnd, kDefaultEnd);
        step = getAttributeValue(formElement, kParameterStep, kDefaultStep);

        var stepString = step.toString();
        var dot = step.toString().indexOf(".");
        if (dot >= 0) {
            precision = Math.max(0, stepString.length - dot - 1);
        }

        if (debug || true) {
            console.log(logCategory, "step:", step, "precision:", precision, "appearance:", appearance);
        }
    }

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
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            if (debug) {
                console.log(logCategory, "onCalculatedValueChanged:", JSON.stringify(binding.nodeset), "value:", JSON.stringify(calculatedValue));
            }

            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        Layout.fillWidth: true

        spacing: 0

        Slider {
            id: slider

            Layout.fillWidth: true
            LayoutMirroring.enabled: rightToLeft

            property bool isEmpty: true

            value: minimumValue //rightToLeft ? maximumValue : minimumValue
            leftPadding: ControlsSingleton.inputHeight / 2
            rightPadding: ControlsSingleton.inputHeight / 2

            onMoved: {
                isEmpty = false;
                changeReason = 1;
                formData.setValue(bindElement, niceValue(value));
            }

            background: Rectangle {
                implicitWidth: 200 * AppFramework.displayScaleFactor
                implicitHeight: ControlsSingleton.inputHeight / 3

                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2

                width: slider.availableWidth
                height: implicitHeight
                radius: height / 2

                color: xform.style.inputBackgroundColor
                border {
                    color: xform.style.inputBorderColor
                    width: xform.style.inputBorderWidth
                }

                Rectangle {
                    width: parent.height
                    height: parent.width
                    anchors.centerIn: parent
                    rotation: 90
                    radius: parent.radius
                    visible: startColor != kTransparent || endColor != kTransparent

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: rightToLeft ? startColor: endColor }
                        GradientStop { position: 1.0; color: rightToLeft ? endColor : startColor }
                    }

                    border {
                        color: xform.style.inputBorderColor
                        width: xform.style.inputBorderWidth
                    }
                }

                Repeater {
                    id: ticks

                    property int steps: Math.abs(Math.round((slider.to - slider.from) / slider.stepSize))
                    property real stepWidth: slider.availableWidth / steps
                    property var intervals

                    model: intervals
                    visible: stepWidth > 10 * AppFramework.displayScaleFactor

                    Rectangle {
                        anchors {
                            top: parent.bottom
                            topMargin: ControlsSingleton.inputHeight / 5
                        }

                        height: ControlsSingleton.inputHeight / 5
                        width: xform.style.inputBorderWidth
                        x: ticks.intervals[index] * slider.availableWidth - width / 2

                        color: xform.style.labelColor
                    }

                    Component.onCompleted: {
                        if (!showTicks) {
                            return;
                        }

                        var range = Math.abs(slider.to - slider.from);
                        var step = Math.abs(slider.stepSize) / range;
                        var a = [];
                        for (var i = 0; i < steps; i++) {
                            a.push(i * step);
                        }
                        if (a.indexOf(1) < 0) {
                            a.push(1);
                        }

                        intervals = a;
                    }
                }

                Rectangle {
                    anchors {
                        left: rightToLeft ? undefined: parent.left
                        right: rightToLeft ? parent.right: undefined
                    }

                    width: (rightToLeft ? 1 - slider.visualPosition : slider.visualPosition) * parent.width
                    height: parent.height
                    color: control.color
                    radius: parent.radius
                    visible: !slider.isEmpty && control.color != kTransparent

                    border {
                        color: xform.style.inputBorderColor
                        width: xform.style.inputBorderWidth
                    }
                }
            }

            handle: Rectangle {
                implicitWidth: ControlsSingleton.inputHeight
                implicitHeight: ControlsSingleton.inputHeight

                x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width / 2
                y: slider.topPadding + (slider.availableHeight - height) / 2

                visible: !slider.isEmpty

                radius: height / 2
                color: slider.pressed
                       ? "#f0f0f0"
                       : xform.style.inputBackgroundColor

                border {
                    color: slider.pressed //control.activeFocus
                           ? xform.style.inputActiveBorderColor
                           : xform.style.inputBorderColor

                    width: slider.pressed //control.activeFocus
                           ? xform.style.inputActiveBorderWidth
                           : xform.style.inputBorderWidth
                }

                Text {
                    anchors {
                        fill: parent
                    }

                    text: niceValue(slider.value)

                    color: changeReason === 3
                           ? xform.style.inputAltTextColor
                           : xform.style.inputTextColor

                    font {
                        family: xform.style.inputFontFamily
                        pointSize: xform.style.inputPointSize
                        bold: xform.style.inputBold
                    }

                    fontSizeMode: Text.Fit
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: ControlsSingleton.inputHeight / 4
            Layout.rightMargin: ControlsSingleton.inputHeight / 4

            layoutDirection: xform.layoutDirection
            visible: showTicks

            Text {
                Layout.fillWidth: true

                text: slider.from
                horizontalAlignment: rightToLeft ? Text.AlignRight : Text.AlignLeft
                color: xform.style.labelColor

                font {
                    family: xform.style.inputFontFamily
                    pointSize: xform.style.inputPointSize
                    bold: xform.style.inputBold
                }
            }

            Text {
                Layout.fillWidth: true

                text: slider.to
                horizontalAlignment: rightToLeft ? Text.AlignLeft : Text.AlignRight
                color: xform.style.labelColor

                font {
                    family: xform.style.inputFontFamily
                    pointSize: xform.style.inputPointSize
                    bold: xform.style.inputBold
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormClearButton {
        visible: !slider.isEmpty && !readOnly

        onClicked: {
            setValue(undefined, 1);
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
            console.log("range setValue:", value, "bindElement:", JSON.stringify(bindElement));
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && isEqual(value, control.currentValue)) {
                if (debug) {
                    console.log("range setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        slider.isEmpty = XFormJS.isEmpty(value);
        slider.value = slider.isEmpty ? slider.from : value;

        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------

    function getAttributeValue(element, name, defaultValue) {
        var value = Number(element["@" + name]);

        if (!isFinite(value)) {
            return defaultValue;
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function isEqual(v1, v2) {
        return XFormJS.isEmpty(v1) && XFormJS.isEmpty(v2) || v1 == v2;
    }

    //--------------------------------------------------------------------------

    readonly property var cLocale: Qt.locale("C")

    function niceValue(value) {
        if (binding.type === Bind.kTypeDecimal && precision > 0) {
            value = value.toLocaleString(cLocale, "f", precision) / 1;
        }

        return value;
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

            bind(control, undefined, kPropertyStartColor, kDefaultStartColor);
            bind(control, undefined, kPropertyEndColor, kDefaultEndColor);
            bind(control, undefined, kPropertyColor, kDefaultColor);
        }
    }

    //--------------------------------------------------------------------------
}
