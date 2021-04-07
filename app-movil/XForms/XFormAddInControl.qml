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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

import "XFormSingletons"
import "XForm.js" as XFormJS

XFormControl {
    id: control

    //--------------------------------------------------------------------------

    property string addInName
    property var addInItem
    readonly property var addInInstance: addInItem ? addInItem.instance : null

    property var value
    property var calculatedValue
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    //--------------------------------------------------------------------------

    debug: true

    implicitHeight: addInItem ? addInItem.implicitHeight : 100

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "addInName:", addInName);

        var addIn = xform.addIns.findInfo(addInName);

        var properties = {
            asynchronous: false,
            font: xform.style.inputFont,
            //palette: xform.style.inputPalette
        }

        if (addIn) {
            addInItem = xform.addIns.createInstance(addInName, control, properties);

            addInItem.palette = Qt.binding(function () { return xform.style.inputPalette; })

        } else {
            properties.addInName = addInName;
            addInItem = xform.addIns.nullAddIn.createObject(control, properties);
        }

        if (addInItem) {
            addInItem.parent = control;
            addInItem.anchors.left = control.left;
            addInItem.anchors.right = control.right;
        }

        return addInItem;
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
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: addInInstance

        onValueChanged: {
            setValue(target.value, 1);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "value:", value, "reason:", reason);
        }

        formData.setValue(binding.element, XFormJS.toBindingType(value, binding.element));

        if (reason !== 1) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "updateValue:", value, "instance:", addInInstance);
            }
            addInInstance.updateValue(value);
        }
    }

    //--------------------------------------------------------------------------
}
