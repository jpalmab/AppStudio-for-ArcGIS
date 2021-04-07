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

QtObject {
    id: expressionsList

    //--------------------------------------------------------------------------

    property var expressions: []
    property var getValue
    property var getValues
    property var getContext
    property bool debug
    property bool enabled: false
    property var jsCache: ({})
    property alias imagesFolder: exif.imagesFolder

    readonly property XFormExif exif: XFormExif {
        id: exif
    }
    
    //--------------------------------------------------------------------------

    signal valueChanged(var nodeset, var value)

    //--------------------------------------------------------------------------

    property Component expressionComponent: XFormExpression {
        enabled: expressionsList.enabled

        getValue: expressionsList.getValue
        getValues: expressionsList.getValues
        getContext: expressionsList.getContext
        exif: expressionsList.exif
        debug: expressionsList.debug
    }

    //--------------------------------------------------------------------------

    onEnabledChanged: {
        if (debug) {
            console.log("expressionList enabled:", enabled);
        }
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        if (debug) {
            console.log("expressionList valueChanged:", nodeset, "value:", value, "enabled:", enabled);
        }

        if (enabled) {
            updateExpressions(nodeset, value);
        }
    }

    //--------------------------------------------------------------------------

    function updateExpressions(nodeset, value) {
        for (var i = 0; i < expressions.length; i++) {
            var instance = expressions[i];
            instance.valueChanged(nodeset, value);
        }
    }

    //--------------------------------------------------------------------------

    function triggerExpression(binding, purpose) {
        var nodeset = binding["@nodeset"];

        for (var i = 0; i < expressions.length; i++) {
            var instance = expressions[i];
            if (instance.thisNodeset === nodeset && instance.purpose === purpose) {
                if (debug) {
                    console.log("Triggering expresssion instance:", nodeset, "purpose:", purpose, "expression:", instance.expression);
                }
                instance.trigger();
            }
        }
    }

    //--------------------------------------------------------------------------

    function addExpression(expression, thisNodeset, purpose, forceAdd) {
        if (debug) {
            console.log("Add expression for:", purpose, "expression:", JSON.stringify(expression), "nodeset:", thisNodeset);
        }

        if (!thisNodeset) {
            thisNodeset = "";
        }

        var expressionInstance = expressionComponent.createObject(this, {
                                                                      expression: expression,
                                                                      thisNodeset: thisNodeset,
                                                                      purpose: purpose
                                                                  });

        if (!forceAdd) {
            for (var i = 0; i < expressions.length; i++) {
                var instance = expressions[i];
                if (instance.jsExpression === expressionInstance.jsExpression && !expressionInstance.isOnce && expressionInstance.isDeterministic) {

                    if (debug) {
                        console.log("Duplicate expression:", expression);
                    }

                    expressionInstance = undefined;
                    return instance;
                }
            }
        }

        expressions.push(expressionInstance);

        if (debug) {
            console.log("Added expression:", expression, "js:", expressionInstance.jsExpression);
        }

        return expressionInstance;
    }

    //--------------------------------------------------------------------------
}
