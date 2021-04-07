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

Item {
    id: bindingsItem

    //--------------------------------------------------------------------------

    property XFormData formData
    property var bindings: []

    readonly property var nullBinding: null

    property bool debug: false

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(bindingsItem, true)
    }

    //--------------------------------------------------------------------------

    function initialize(bindArray, defaultInstance) {
        if (!Array.isArray(bindArray)) {
            console.warn(logCategory, arguments.callee.name, "No bind array")
            return;
        }

        console.log(logCategory, arguments.callee.name, "Creating bindings:", bindArray.length);

        bindArray.forEach(function (bind) {
            var nodesetPath = XFormJS.replaceAll(bind["@nodeset"], "/", ".").substring(1);
            var defaultValue = XFormJS.getPropertyPathValue(defaultInstance, nodesetPath);

            if (debug) {
                console.log(logCategory, arguments.callee.name, "nodesetPath:", nodesetPath, "defaultValue:", defaultValue);
            }

            var binding = bindingComponent.createObject(bindingsItem,
                                                        {
                                                            formData: formData,
                                                            element: bind,
                                                            defaultValue: defaultValue,
                                                            debug: debug
                                                        });

            bindings.push(binding);
        });

        console.log(logCategory, arguments.callee.name, "Bindings created:", bindings.length);
    }

    //--------------------------------------------------------------------------

    function findByNodeset(nodeset) {
        if (!nodeset) {
            return nullBinding;
        }

        var binding = bindings.find(function(binding) {
            return binding.nodeset === nodeset;
        });

        if (!binding) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "No binding for nodeset:", nodeset);
            }

            return nullBinding;
        }

        return binding;
    }

    //--------------------------------------------------------------------------

    Component {
        id: bindingComponent

        XFormBinding {
            debug: bindingsItem.debug
        }
    }

    //--------------------------------------------------------------------------

    XFormBinding {
        // id: nullBinding
        debug: bindingsItem.debug
    }

    //--------------------------------------------------------------------------
}

