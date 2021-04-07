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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../XForms/XForm.js" as XFormJS

RowLayout {
    property alias prefixText: prefixText.text
    property alias suffixText: suffixText.text
    property alias placeholderText: textField.placeholderText

    property real value: Number.NaN
    property alias validator: textField.validator
    property alias maximumValue: doubleValidator.top
    property alias minimumValue: doubleValidator.bottom
    property alias locale: textField.locale

    property alias inputRequired: textField.inputRequired
    property alias readOnly: textField.readOnly

    property var numberLocale: app.localeProperties.numberLocale

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        textField.text = XFormJS.numberToLocaleString(numberLocale, value);
    }

    //--------------------------------------------------------------------------

    AppText {
        id: prefixText

        visible: text > ""
    }

    AppTextField {
        id: textField

        Layout.fillWidth: true

        validator: DoubleValidator {
            id: doubleValidator

            locale: numberLocale.name
            notation: DoubleValidator.StandardNotation
        }

        Component.onCompleted: {
            if (Qt.platform.os === "ios") {
                inputMethodHints = Qt.ImhPreferNumbers;
            } else {
                inputMethodHints = Qt.ImhFormattedNumbersOnly;
            }
        }

        onTextChanged: {
            updateValue();
        }

        onEditingFinished: {
            updateValue();
        }

        function updateValue() {
            if (length && acceptableInput) {
                value = XFormJS.numberFromLocaleString(numberLocale, text);
            } else {
                value = Number.NaN;
            }
            //console.log("updateValue:", value, length, acceptableInput, locale.name)
        }
    }
    
    AppText {
        id: suffixText

        visible: text > ""
    }

    //--------------------------------------------------------------------------
}
