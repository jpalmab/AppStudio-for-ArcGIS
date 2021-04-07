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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

import "XForm.js" as XFormJS
import "XFormSingletons"

Item {
    id: control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property var appearance: formElement ? formElement["@appearance"] : null;
    property bool monthYear: !Appearance.contains(appearance, Appearance.kYear)
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property date todayDate: clearDate(new Date())
    readonly property date currentDate: clearDate(XFormJS.toDate(dateValue));
    readonly property date calculatedDate: clearDate(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && +calculatedDate !== +currentDate

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property date dateValue: new Date()
    property alias dateMonth: monthSpinBox.value
    property alias dateYear: yearSpinBox.value


    property var locale: xform.locale
    property real padding: 0
    property real spacing: 8 * AppFramework.displayScaleFactor

    property bool debug: false

    property var monthNames: []
    property alias monthNameRegExp: monthValidator.regExp

    property XFormStyle style: xform.style
    property int layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    implicitHeight: controlLayout.height + padding * 2

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);

        localeChanged();
    }

    //--------------------------------------------------------------------------

    onLocaleChanged: {
        var regExp;

        function add(monthName) {
            monthNames.push(monthName);

            if (regExp) {
                regExp += "|" + monthName;
            } else {
                regExp = "(" + monthName;
            }
        }

        for (var i = 0; i < 12; i++) {
            add(locale.standaloneMonthName(i).toLowerCase());
        }

        for (i = 0; i < 12; i++) {
            add(locale.monthName(i, Locale.LongFormat).toLowerCase());
        }

        for (i = 0; i < 12; i++) {
            add(locale.monthName(i, Locale.ShortFormat).toLowerCase());
        }

        if (locale.name !== "C") {
            var cLocale = Qt.locale("C");

            for (i = 0; i < 12; i++) {
                add(cLocale.monthName(i, Locale.ShortFormat).toLowerCase());
            }
        }

        for (i = 0; i < 12; i++) {
            add((i + 1).toString());
        }

        regExp += ")";

        monthNameRegExp = new RegExp(regExp, "i");
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
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            if (debug) {
                console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            }
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    onDateValueChanged: {
        dateMonth = dateValue.getMonth();
        dateYear = dateValue.getFullYear();
        formData.setValue(bindElement, dateValue.valueOf());
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            left: layoutDirection === Qt.LeftToRight ? parent.left : undefined
            right: layoutDirection === Qt.RightToLeft ? parent.right : undefined
            top: parent.top
            bottom: parent.bottom
        }

        width: valueLayout.width

        border {
            color: xform.style.inputBorderColor
            width: xform.style.inputBorderWidth
        }

        radius: xform.style.inputBackgroundRadius
        color: xform.style.inputBackgroundColor
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: controlLayout

        anchors {
            left: parent.left
            right: parent.right
            margins: padding
            verticalCenter: parent.verticalCenter
        }

        layoutDirection: control.layoutDirection

        RowLayout {
            id: valueLayout

            Layout.fillWidth: true

            enabled: !readOnly
            spacing: 0

            layoutDirection: control.layoutDirection

            GridLayout {
                id: monthYearLayout

                Layout.fillWidth: true

                layoutDirection: control.layoutDirection

                columnSpacing: 0
                rowSpacing: 0

                columns: valueLayout.width < (xform.style.buttonSize * 4 + xform.style.textScaleFactor * 250 * AppFramework.displayScaleFactor) ? 1 : 2

                XFormDateSpinBox {
                    id: monthSpinBox

                    Layout.fillWidth: true

                    visible: monthYear

                    locale: control.locale
                    style: xform.style
                    textColor: changeReason === 3 ? xform.style.inputAltTextColor : xform.style.inputTextColor

                    from: 0
                    to: 11
                    editable: true
                    wrap: true

                    textFromValue: function (value, locale) {
                        return locale.monthName(value);
                    }

                    valueFromText: function (text, locale) {
                        var index = monthNames.indexOf(text.toLowerCase());
                        return index >= 0 ? index % 12 : value;
                    }

                    validator: RegExpValidator {
                        id: monthValidator
                    }

                    onValueModified: {
                        updateMonth(value);
                    }
                }

                XFormDateSpinBox {
                    id: yearSpinBox

                    Layout.fillWidth: !monthSpinBox.visible || (monthYearLayout.columns === 1)

                    locale: control.locale
                    style: xform.style
                    textColor: changeReason === 3 ? xform.style.inputAltTextColor : xform.style.inputTextColor

                    from: 1
                    to: 2099
                    editable: true
                    value: (new Date()).getFullYear()

                    textFromValue: function (value, locale) {
                        return value.toString();
                    }

                    valueFromText: function (text, locale) {
                        return Number.parseInt(text);
                    }

                    onValueModified: {
                        updateYear(value);
                    }
                }
            }

            StyledImageButton {
                Layout.margins: 8 * AppFramework.displayScaleFactor
                Layout.preferredHeight: ControlsSingleton.inputTextHeight
                Layout.preferredWidth: ControlsSingleton.inputTextHeight

                visible: !readOnly && +currentDate !== +todayDate

                source: Icons.icon("reset", style.inputBold)
                mirror: xform.isRightToLeft

                color: style.inputTextColor

                onClicked: {
                    forceActiveFocus();
                    setValue(new Date().valueOf(), 1);
                    valueModified(control);
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

    function updateMonth(month) {
        var date = new Date(dateValue.valueOf());
        date.setMonth(month);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function updateYear(year) {
        var date = new Date(dateValue.valueOf());
        date.setFullYear(year);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function clearDate(date) {
        if (!XFormJS.isValidDate(date)) {
            return date;
        }

        if (!monthYear) {
            date.setMonth(0);
        }

        date.setDate(1);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);

        return date;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = clearDate(XFormJS.toDate(value));

        if (reason) {
            if (reason === 1 && changeReason === 3 && XFormJS.equalDates(date, dateValue)) {
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
            dateValue = clearDate(new Date());
            formData.setValue(bindElement, undefined);
        } else {
            dateValue = date;
            formData.setValue(bindElement, dateValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
