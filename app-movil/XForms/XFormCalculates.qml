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

// TODO: Merge functionality into XFormBindings

Item {
    id: calculates
    
    //--------------------------------------------------------------------------

    property XFormData formData
    property var nodes: []

    property bool debug: false

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(calculates, true)
    }

    //--------------------------------------------------------------------------

    function createCalculate(field, binding, group) {
        var calculate = calculateComponent.createObject(calculates,
                                                        {
                                                            binding: binding,
                                                            formData: formData,
                                                            field: field,
                                                            group: group
                                                        });

        nodes.push(calculate);

        return calculate;
    }
    
    //--------------------------------------------------------------------------
    
    function findByNodeset(nodeset) {
        if (!nodeset) {
            return;
        }

        var calculate = nodes.find(function(calculate) {
            return calculate.binding && calculate.binding.nodeset === nodeset;
        });

        if (!calculate) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "No calculate for nodeset:", nodeset);
            }
        }

        return calculate;
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: calculateComponent

        XFormCalculate {
        }
    }

    //--------------------------------------------------------------------------
}
