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

import "XForm.js" as XFormJS


ColumnLayout {
    //--------------------------------------------------------------------------

    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var constraint
    property var calculatedValue
    property var value: calculatedValue

    readonly property bool relevant: parent.relevant

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!bindElement) {
            return;
        }

        var calculate = bindElement["@calculate"];
        if (calculate > "") {
            calculatedValue = formData.calculateBinding(bindElement);
        }

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
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    Text {
        id: textControl

        Layout.fillWidth: true

        visible: text > ""
        text: XFormJS.isEmpty(value) ? "" : value
        color: xform.style.textColor
        font {
            pointSize: xform.style.valuePointSize
            bold: xform.style.valueBold
            family: xform.style.valueFontFamily
        }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: xform.localeInfo.textAlignment

        //--------------------------------------------------------------------------

        onLinkActivated: {
            xform.openLink(link);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (!bindElement) {
            return;
        }

        var nodeset = binding.nodeset;
        var field = schema.fieldNodes[nodeset];
        if (field) {
            setValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        textControl.text = XFormJS.isEmpty(value) ? "" : value.toString();
        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------
}
