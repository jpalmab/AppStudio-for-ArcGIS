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

QtObject {
    id: controlParameters

    //--------------------------------------------------------------------------

    property var target: controlParameters
    property var nodeset
    property var element
    property string attribute: kAttributeParameters
    property var parameters

    property bool debug

    //--------------------------------------------------------------------------

    readonly property string kAttributeParameters: "esri:parameters"
    readonly property string kAttributeStyle: "esri:style"

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        name: AppFramework.typeOf(controlParameters, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        parseParameters();
    }

    //--------------------------------------------------------------------------

    function parseParameters() {
        if (!element) {
            return;
        }

        parameters = XFormJS.parseParameters(element["@" + attribute]);

        if (debug) {
            console.log(logCategory, attribute, JSON.stringify(parameters, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function bind(target, targetProperty, sourceProperty, defaultValue) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "targetProperty:", targetProperty, "sourceProperty:", sourceProperty);
        }

        if (!parameters) {
            console.warn(logCategory, arguments.callee.name, "Empty parameters");
            return false;
        }

        if (!target) {
            target = controlParameters;
        }

        if (targetProperty && !sourceProperty) {
            sourceProperty = targetProperty;
        } else if (!targetProperty && sourceProperty) {
            targetProperty = sourceProperty;
        } else if (!targetProperty && !sourceProperty) {
            console.error(logCategory, arguments.callee.name, "Empty target and source properties");
            return false;
        }

        var definition = parameters[sourceProperty];

        if (typeof definition !== "string") {
            return false;
        }

        definition = definition.trim();

        if (debug) {
            console.log(logCategory, arguments.callee.name, "definition:", JSON.stringify(definition));
        }

        var targetType = typeof target[targetProperty];
        if (targetType === "object") {
            targetType = AppFramework.typeOf(target[targetProperty]);
        }

        var purpose = attribute + "." + sourceProperty;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "targetProperty:", targetProperty, "targetType:", targetType);
        }

        if (definition.charAt(0) === "/") {
            var expressionInstance = formData.expressionsList.addExpression(
                        definition,
                        nodeset,
                        purpose,
                        true);

            switch (targetType) {
            case "color":
                target[targetProperty] = expressionInstance.colorBinding(defaultValue);
                break;

            case "number":
                target[targetProperty] = expressionInstance.numberBinding(defaultValue);
                break;

            case "string":
            default:
                target[targetProperty] = expressionInstance.stringBinding(defaultValue ? defaultValue : "");
                break;
            }

        } else {
            target[targetProperty] = definition;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function toColor(value, defaultValue) {
        if (value > "") {
            var color = Qt.tint(value, "transparent");
            return color === null ? defaultValue : color;
        } else {
            return defaultValue;
        }
    }

    //--------------------------------------------------------------------------

    function toHeight(value, defaultValue) {
        var height = defaultValue;

        if (value > "") {
            var match = value.match(/([\d\.]+)\s*(px|pixels|\%|lines)?/);

            if (debug) {
                console.log(logCategory, arguments.callee.name, "match:", JSON.stringify(match));
            }

            if (Array.isArray(match)) {
                height = Number(match[1]);
                if (!isFinite(height)) {
                    return defaultValue;
                }

                switch (match[2]) {
                case "%":
                    return Qt.binding(function() { return Math.round(height * app.height / 100.0); });

                case "px":
                case "pixels":
                    height *= AppFramework.displayScaleFactor;
                    break;

                case "lines":
                default:
                    height = Math.round(height * xform.style.lineHeight);
                    break;

                }
            }
        }

        if (!isFinite(height)) {
            height = defaultValue;
        }

        return height;
    }

    //--------------------------------------------------------------------------
}
