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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"
import "XForm.js" as XFormJS
import "XFormSingletons"

ColumnLayout {
    id: control

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property bool initialized: false
    property var appearance: (formElement ? formElement["@appearance"] : "") || ""
    property var constraint
    property var calculatedValue

    property var dateTimeValue: null
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property date currentDate: new Date(dateTimeValue)
    readonly property date calculatedDate: showTime
                                           ? XFormJS.clearSeconds(XFormJS.toDate(calculatedValue))
                                           : XFormJS.clearTime(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && (!initialized || +calculatedDate !== +currentDate)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool debug: false

    property bool showDate: true
    property bool showTime: true

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    spacing: 8 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);
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
            setValue(undefined, 3);
            timePicker.clear();
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            //console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: layout

        Layout.fillWidth: true

        layoutDirection: xform.layoutDirection

        XFormDateTimeField {
            id: dateTimeField

            Layout.fillWidth: true

            locale: xform.locale
            style: xform.style
            dateTime: dateTimeValue
            readOnly: control.readOnly
            useAltTextColor: changeReason === 3
            appearance: control.appearance

            showDate: control.showDate
            showTime: control.showTime

            datePickerItem: datePicker
            timePickerItem: timePicker

            onActiveFocusChanged: {
                if (!activeFocus && dateTimeValue && !control.readOnly) {
                    formData.setValue(bindElement, dateTimeValue.valueOf());
                    changeReason = 1;
                }
                xform.controlFocusChanged(control, activeFocus, bindElement);
            }

            onDateClicked: {
                xform.controlFocusChanged(control, true, bindElement);
                datePicker.visible = !datePicker.visible;
            }

            onTimeClicked: {
                xform.controlFocusChanged(control, true, bindElement);
                timePicker.visible = !timePicker.visible;
            }

            onCleared: {
                if (datePickerVisible) {
                    datePickerItem.visible = false;
                }

                if (timePickerVisible) {
                    timePickerItem.visible = false;
                }

                forceActiveFocus();
                setValue(undefined, 1);
                changeReason = 1;
                valueModified(control);
                timePicker.clear();
            }


            Canvas {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                width: 20 * AppFramework.displayScaleFactor
                height: 10 * AppFramework.displayScaleFactor

                visible: parent.pickerVisible

                onPaint: {
                    if (available) {
                        var ctx = getContext("2d");
                        ctx.fillStyle = xform.style.inputActiveBorderColor
                        ctx.beginPath();
                        ctx.moveTo(width/2, 0);

                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height);
                        ctx.lineTo(width/2,0);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
        }

        XFormRecalculateButton {
            visible: showCalculate

            onClicked: {
                changeReason = 0;
                formData.triggerCalculate(bindElement);
                valueModified(control);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    XFormDatePicker {
        id: datePicker

        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: control.width

        weekNumbersVisible: Appearance.contains(appearance, Appearance.kWeekNumber)
        enabled: !readOnly

        onVisibleChanged: {
            if (visible) {
                valueModified(control);

                if (timePicker.visible) {
                    timePicker.visible = false
                }

                xform.ensureItemVisible(control);

                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
        }

        onClicked: {
            if (debug) {
                console.log(logCategory, "onClicked:", selectedDate);
            }

            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setFullYear(selectedDate.getFullYear());
                date.setMonth(selectedDate.getMonth());
                date.setDate(selectedDate.getDate());

                if (!showTime) {
                    XFormJS.clearTime(date);
                } else {
                    XFormJS.clearSeconds(date);
                }

                dateTimeValue = date;
                formData.setValue(bindElement, date.valueOf());
                changeReason = 1;
                xform.controlFocusChanged(control, activeFocus, bindElement);
                visible = false;
            }
        }
    }

    XFormTimePicker {
        id: timePicker

        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: control.width

        enabled: !readOnly
        appearance: control.appearance
        style: xform.style

        onVisibleChanged: {
            if (visible) {
                valueModified(control);

                if (datePicker.visible) {
                    datePicker.visible = false
                }

                xform.ensureItemVisible(control);

                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
            if (!visible) {
                if (dateTimeValue) {
                    formData.setValue(bindElement, dateTimeValue.valueOf());
                    changeReason = 1;
                }

                xform.controlFocusChanged(control, activeFocus, bindElement);
            }
        }

        onSelectedDateChanged: {

            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setHours(selectedDate.getHours());
                date.setMinutes(selectedDate.getMinutes());
                XFormJS.clearSeconds(date);

                dateTimeValue = date;
                formData.setValue(bindElement, date.valueOf());
                xform.controlFocusChanged(control, activeFocus, bindElement);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = XFormJS.toDate(value);

        if (!showTime) {
            date = XFormJS.clearTime(date);
        } else {
            date = XFormJS.clearSeconds(date);
        }

        if (debug) {
            console.log("dateTime setValue:", reason, value, date);
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && XFormJS.equalDates(date, dateTimeValue)) {
                if (debug) {
                    console.log("date setValue == calculated:", JSON.stringify(date));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        if (XFormJS.isEmpty(date)) {
            resetControl();
            formData.setValue(bindElement, undefined);
        } else {
            initialized = true;
            dateTimeValue = date;
            formData.setValue(bindElement, dateTimeValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------

    function resetControl() {
        datePicker.selectedDate = new Date();
        //timePicker.selectedDate = new Date();
        dateTimeValue = null;
        initialized = false;
    }

    //--------------------------------------------------------------------------
}
