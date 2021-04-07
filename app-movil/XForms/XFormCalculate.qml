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

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

// TODO: Merge functionality into XFormBinding

QtObject {
    id: calculate

    //--------------------------------------------------------------------------

    property XFormBinding binding
    property XFormData formData
    property Item group
    property var field

    property var calculatedValue
    property var constraint

    readonly property bool groupRelevant: group ? group.binding.isRelevant: true
    readonly property bool relevant: groupRelevant && (binding ? binding.isRelevant : true)

    property bool debug: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        calculatedValue = formData.calculateBinding(field.binding);
        constraint = formData.createConstraint(this, field.binding);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (debug) {
            console.log("Calculate onRelevantChanged:", relevant, "nodeset:", binding.nodeset);
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(binding.element);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant) {
            var value = XFormJS.toBindingType(calculatedValue, field.binding);

            if (formData.valueByField(field) !== value) {
                setValue(value);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        formData.setValue(field.binding, value);
    }

    //--------------------------------------------------------------------------
}
