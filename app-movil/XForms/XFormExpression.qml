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
import QtQml 2.12
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as XFormJS
import "XFormExpressionGeopointHelper.js" as GeopointHelper;
import "XFormGeometry.js" as Geometry;


QtObject {
    id: expressionObject

    //--------------------------------------------------------------------------

    property bool enabled: true
    property var getValue
    property var getValues
    property var getContext
    property var thisNodeset
    property string expression
    property var purpose
    property string jsExpression
    property var nodesets: []
    property bool debug
    property var errorResult
    property bool isOnce: false
    property bool isDeterministic: true
    property XFormExif exif

    property bool _bindingTrigger

    readonly property real kMillisecondsPerDay: 86400000

    //--------------------------------------------------------------------------

    readonly property var nonDeterministicFunctions: [
        "now()",
        "today()",
        "random()"
    ]

    //--------------------------------------------------------------------------

    readonly property string kFunctionPulldata: "pulldata"

    readonly property var kAggregateFunctions: [
        "count",
        "count-non-empty",
        "sum",
        "min",
        "max",
        "join",
        kFunctionPulldata,
    ]

    // Don't use aggregate value if in same row as expression

    readonly property var kAggregateSpecialFunctions: [
        "min",
        "max",
        kFunctionPulldata,
    ]

    //--------------------------------------------------------------------------

    readonly property var kFunctionMappings: [
        { from: /string-length\(/g,         to: "string_length(" },
        { from: /selected-at\(/g,           to: "selected_at(" },
        { from: /count-selected\(/g,        to: "count_selected(" },
        { from: /decimal-date-time\(/g,     to: "decimal_date_time(" },
        { from: /decimal-date\(/g,          to: "decimal_date(" },
        { from: /decimal-time\(/g,          to: "decimal_time(" },
        { from: /format-date\(/g,           to: "format_date(" },
        { from: /format-date-time\(/g,      to: "format_date_time(" },
        { from: /date-time\(/g,             to: "date_time(" },
        { from: /boolean\(/g,               to: "_boolean(" },
        { from: /int\(/g,                   to: "_int(" },
        { from: /if\(/g,                    to: "_if(" },
        { from: /string\(/g,                to: "_string(" },
        { from: /true\(\)/g,                to: "true" },
        { from: /false\(\)/g,               to: "false" },
        { from: /jr:choice-name\(/g,        to: "jr_choice_name(" },
        { from: /boolean-from-_string\(/g,  to: "boolean_from_string(" }, // NOTE Workaround from: value for previous string( replacement
        { from: /count-non-empty\(/g,       to: "count_non_empty(" },
        { from: /starts-with\(/g,           to: "starts_with(" },
        { from: /ends-with\(/g,           to: "ends_with(" },
    ];

    //--------------------------------------------------------------------------

    signal valueChanged(var nodeset, var value);

    //--------------------------------------------------------------------------

    readonly property LoggingCategory _logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(expressionObject, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        update();

        if (debug) {
            console.log("Expression instance:", expression);
            console.log("  jsExpression:", jsExpression);
            console.log("  thisNodeset:", thisNodeset);
            console.log("  nodesets:", JSON.stringify(nodesets));
            console.log("  purpose:", purpose);
        }
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        //        if (debug) {
        //            console.log("expression valueChanged:", nodeset, "value:", value);
        //        }

        if (!nodeset || nodesets.indexOf(nodeset) >= 0) {
            trigger();
        }
    }

    //--------------------------------------------------------------------------

    function trigger() {
        if (!enabled) {
            console.warn(logCategory, arguments.callee.name, "not enabled for:", expression);
        }

        _bindingTrigger = !_bindingTrigger;
    }

    //    onEnabledChanged: {
    //        if (enabled) {
    //            console.log(logCategory, "Triggering expression after enable:", expression);
    //            trigger();
    //        }
    //    }

    //--------------------------------------------------------------------------

    function update() {
        isOnce = expression.trim().substring(0, 5) === "once(" && thisNodeset > "";
        nodesets = [];
        jsExpression = translate(expression, thisNodeset, nodesets, _valueRef);

        if (isOnce && debug) {
            console.log("once expression for:", purpose, "nodeset:", thisNodeset, "expression:", expression);
        }

        isDeterministic = isDeterministicExpression(expression);

        if (debug) {
            console.log("isDeterministic:", isDeterministic, "expression:", expression);
        }
    }

    //--------------------------------------------------------------------------

    function isDeterministicExpression(text) {
        for (var i = 0; i < nonDeterministicFunctions.length; i++) {
            if (text.indexOf(nonDeterministicFunctions[i]) >= 0) {
                return false;
            }
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function _valueRef(nodeset, aggregate) {
        if (debug) {
            console.log("valueRef:", nodeset, "aggregate:", aggregate);
        }

        if (aggregate) {
            return '_values("%1")'.arg(nodeset);
        } else {
            return '_value("%1")'.arg(nodeset);
        }
    }

    //--------------------------------------------------------------------------

    function _value(nodeset) {
        if (!getValue) {
            console.error("getValue not defined");
            return undefined;
        }

        var value = getValue(nodeset);

        if (XFormJS.isNullOrUndefined(value)) {
            value = '';
        }

        if (debug) {
            console.log(arguments.callee.name, typeof value, "nodeset:", nodeset, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function _values(nodeset) {
        if (!getValues) {
            console.error("getValues not defined");
            return [];
        }

        var values = getValues(nodeset);

        if (!Array.isArray(values)) {
            values = [];
        }

        if (debug) {
            console.log(arguments.callee.name, "nodeset:", nodeset, "=", JSON.stringify(values));
        }

        return values;
    }

    //--------------------------------------------------------------------------

    function binding() {
        return Qt.binding(function () {
            return evaluate(errorResult, _bindingTrigger);
        });
    }

    //--------------------------------------------------------------------------

    function boolBinding(errorResult) {
        return Qt.binding(function () {
            return Boolean(evaluate(errorResult, _bindingTrigger));
        });
    }

    //--------------------------------------------------------------------------

    function numberBinding(defaultValue) {
        return Qt.binding(function () {
            var value = Number(evaluate(defaultValue, _bindingTrigger));

            return isFinite(value) ? value : defaultValue;
        });
    }

    //--------------------------------------------------------------------------

    function stringBinding(errorResult) {
        return Qt.binding(function () {
            return String(evaluate(errorResult, _bindingTrigger));
        });
    }

    //--------------------------------------------------------------------------

    function nodesetValuesBinding() {
        return Qt.binding(function () {
            return nodesetValues(_bindingTrigger);
        });
    }

    //--------------------------------------------------------------------------

    function colorBinding(defaultValue) {
        return Qt.binding(function () {
            var value = Qt.tint(evaluate(defaultValue, _bindingTrigger), "transparent");

            return value === null ? defaultValue : value;
        });
    }

    //--------------------------------------------------------------------------

    function nodesetValues() {
        var values = {};

        nodesets.forEach(function (nodeset) {
            values[nodeset] = getValue(nodeset);
        });

        return values;
    }

    //--------------------------------------------------------------------------

    function evaluate(errorResult) {
        if (isOnce) {
            var value = getValue(thisNodeset);

            if (debug) {
                console.log("once:", purpose, "value:", value, "nodeset:", thisNodeset);
            }

            if (!XFormJS.isEmpty(value)) {
                return value;
            }
        }

        var result;

        try {
            result = eval(jsExpression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression, "xml expression:", expression);
            if (typeof errorResult !== "undefined") {
                result = errorResult;
            } else {
                result = "%1 in expression: %2".arg(error).arg(expression);
            }
        }

        if (debug) {
            console.log("evaluated:", result, "type:", typeof result, "from:", expression);
        }

        return result;
    }

    //--------------------------------------------------------------------------

    function tryEval(jsExpression, errorResult) {
        var result;

        try {
            result = eval(jsExpression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression);
            if (typeof errorResult !== "undefined") {
                result = errorResult;
            } else {
                result = "%1 in expression: %2".arg(error).arg(jsExpression);
            }
        }

        if (debug) {
            console.log("tryEval:", result, "type:", typeof result, "from:", jsExpression);
        }

        return result;
    }

    //--------------------------------------------------------------------------

    function translate(expression, thisNodeset, nodesets, valueCallback) {
        if (typeof valueCallback !== "function") {
            console.error(logCategory, arguments.callee.name, "valueCallback not a function:", typeof valueCallback)
        }

        var expressionTokens = expression.match(/(['][^']*['])|([0-9A-Za-z_\-\/.']+)|./g);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "expression:", expression, "thisNodeset:", thisNodeset);
            console.log(logCategory, arguments.callee.name, "expression tokens:", JSON.stringify(expressionTokens));
        }

        function addNodeset(nodeset) {
            if (!(nodeset > "")) {
                return;
            }

            if (Array.isArray(nodesets)) {
                if (nodesets.indexOf(nodeset) < 0) {
                    nodesets.push(nodeset);
                }
            }
        }

        function parentNode(nodeset) {
            if (!nodeset) {
                return "";
            }

            return nodeset.substr(0, nodeset.lastIndexOf('/'));
        }

        function inThisContext(nodeset) {
            var thisContext = getContext(thisNodeset);
            var nodesetContext = getContext(nodeset);

            if (debug) {
                console.log(arguments.callee.name, "nodeset:", nodeset, "thisNodeset:", thisNodeset, "thisContext:", thisContext, "nodesetContext:", nodesetContext);
            }

            return thisContext && nodesetContext && thisContext === nodesetContext;
        }

        var groupStack = [];
        var tokens = [];
        var inString;
        var stringToken;

        if (expressionTokens) {
            expressionTokens.forEach(function (element, index) {

                if (debug) {
                    console.log("expressionToken:", element, "index:", index);
                }

                // Parenthesis group handling

                var currentGroup = groupStack[groupStack.length - 1];
                var token;

                if (inString) {
                    if (element === inString) {
                        if (debug) {
                            console.log("Exiting string:", inString, "value:", inString + stringToken + inString);
                        }

                        token = inString + stringToken + inString;
                        tokens.push(token);
                        if (currentGroup) {
                            currentGroup.tokens.push(token);
                        }

                        inString = undefined;
                    } else {
                        if (debug) {
                            console.log("inString:", inString, "element:", element);
                        }

                        stringToken += element;
                    }
                    return;
                } else if (element === "'" || element === '"') {
                    if (debug) {
                        console.log("Entering string:", inString);
                    }

                    inString = element;
                    stringToken = "";
                    return;
                }

                // Aggregate functions handling

                var inAggregateGroup = currentGroup
                        ? kAggregateFunctions.indexOf(currentGroup.name) >= 0
                        : false;

                if (debug) {
                    console.log("currentGroup:", JSON.stringify(currentGroup), "inAggregateGroup:", inAggregateGroup);
                }

                switch (element) {
                case "(":
                    var group = {
                        name: index > 0 ? expressionTokens[index - 1] : element,
                        tokens: []
                    };

                    groupStack.push(group);
                    if (debug) {
                        console.log("groupStack push:", JSON.stringify(group), groupStack.length, JSON.stringify(groupStack), "expression:", expression);
                    }
                    break;

                case  ")":
                    group = groupStack.pop();
                    if (debug) {
                        console.log("groupStack pop:", JSON.stringify(group), groupStack.length, JSON.stringify(groupStack), "expression:", expression);
                    }
                    break;
                }

                // Aggregate special functions only if not in same context

                var aggregate;
                if (inAggregateGroup) {
                    var match = element.match(/\/(\w+)/);
                    var rootContext = match ? match[1] : null;

                    if (debug) {
                        console.log("element:", element, "rootContext:", rootContext, "match:", JSON.stringify(match), "getContext(element):", getContext(element));
                    }

                    aggregate = kAggregateSpecialFunctions.indexOf(currentGroup.name) >= 0
                            ? !inThisContext(element) && getContext(element) !== rootContext
                            : true;


                    // Special case to only aggregate values for pulldata("@javascript", ...

                    if (aggregate && currentGroup.name === kFunctionPulldata) {
                        var isJavaScript = false;

                        for (var i = 0; !isJavaScript && i < currentGroup.tokens.length; i++) {
                            var groupToken = currentGroup.tokens[i];

                            if (!groupToken) {
                                continue;
                            }

                            if (groupToken === ",") {
                                break;
                            }

                            isJavaScript = groupToken.indexOf("@javascript") >= 0;
                        }

                        if (!isJavaScript) {
                            aggregate = false;

                            if (debug) {
                                console.log(logCategory, arguments.callee.name, 'Not pulldata("@javascript",...');
                            }
                        }
                    }

                    if (debug) {
                        console.log("currentGroup:", JSON.stringify(currentGroup), "aggregate:", aggregate);
                    }
                }


                token = element;

                switch (element.toLowerCase()) {
                case "=":
                    token = "==";
                    break;

                case "or":
                    token = "||";
                    break;

                case "and":
                    token = "&&";
                    break;

                case "mod":
                    token = "%";
                    break;

                case "div":
                    token = "/";
                    break;

                case ".":
                    token = valueCallback(thisNodeset);
                    addNodeset(thisNodeset);
                    break;

                case "..":
                    var parentNodeset = parentNode(thisNodeset);
                    token = "'" + parentNodeset + "'";
                    addNodeset(parentNodeset);
                    break;

                default:
                    if (element.charAt(0) === '/') {
                        token = valueCallback(element, aggregate);
                        addNodeset(element);
                    } else if (element.charAt(0) === '.') {
                        var nodeset = thisNodeset;
                        var nodeParent = parentNode(nodeset);
                        var relativeNode = nodeParent + element.substr(2);
                        //console.log("relative ref", element, "nodeset:", nodeset, "nodeParent:", nodeParent, "relativeNode:", relativeNode);
                        token = valueCallback(relativeNode);
                        addNodeset(relativeNode);
                    } else if (element.charAt(0) === '\'') {
                        token = token.replace(/\\/g, "\\\\");
                    }
                    break;
                }

                tokens.push(token);
                if (currentGroup) {
                    currentGroup.tokens.push(token);
                }
            });
        } else {
            console.log("No expressionTokens for:", expression, "nodeset:", thisNodeset);
        }

        var translatedExpression = tokens.join("");

        // Quick hack until better regex is figured out

        translatedExpression = XFormJS.replaceAll(translatedExpression, "<==", "<=");
        translatedExpression = XFormJS.replaceAll(translatedExpression, ">==", ">=");
        translatedExpression = XFormJS.replaceAll(translatedExpression, "!==", "!=");

        kFunctionMappings.forEach(function (mapping) {
            translatedExpression = translatedExpression.replace(mapping.from, mapping.to);
        });

        if (debug) {
            console.log("expression tokens:", JSON.stringify(tokens));
            console.log("expression:", expression, "==>>", translatedExpression);
        }

        return translatedExpression;
    }

    //--------------------------------------------------------------------------
    // Expression functions
    // Ref: https://docs.opendatakit.org/form-operators-functions/
    // Ref: http://opendatakit.org/help/form-design/binding/
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Control flow
    // https://docs.opendatakit.org/form-operators-functions/#control-flow

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#if

    function _if(condition, a, b) {
        return condition ? a : b;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#position

    function position(xpath) {
        return "**" + xpath + "**";
    }

    //--------------------------------------------------------------------------
    // Accessing response values
    // https://docs.opendatakit.org/form-operators-functions/#accessing-response-values

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#selected

    function selected(array, value) {
        if (Array.isArray(array)) {
            return array.indexOf(value) >= 0;
        } else {
            return array == value;
        }
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#selected-at

    function selected_at(array, index) {
        if (Array.isArray(array)) {
            var value = array[index];
            return XFormJS.isNullOrUndefined(value) ? "" : value;
        } else {
            return array;
        }
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#count-selected

    function count_selected(array) {
        if (Array.isArray(array)) {
            return array.length;
        } else {
            return array.toString() > "" ? 1 : 0;
        }
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#jr:choice-name

    function jr_choice_name(value, nodeset) {
        if (XFormJS.isNullOrUndefined(nodeset)) {
            console.error(arguments.callee.name, "Empty nodeset for:", value);
            return value;
        }

        if (XFormJS.isEmpty(value)) {
            return "";
        }

        nodeset = String(nodeset).trim();

        if (debug) {
            console.log("jr:choice-value(", JSON.stringify(value), ",", JSON.stringify(nodeset), ")");
        }

        var controlNode = xform.controlNodes[nodeset];

        if (!controlNode) {
            console.error(arguments.callee.name, "No control node for:", nodeset);
            return value;
        }

        var control = controlNode.control;

        if (!control) {
            console.error(arguments.callee.name, "No control for:", nodeset);
            return value;
        }

        var lookupLabel = control.lookupLabel;
        if (typeof lookupLabel !== "function") {
            console.error(arguments.callee.name, "No lookupLabel function for:", nodeset);
            return value;
        }

        return lookupLabel(value);
    }

    //--------------------------------------------------------------------------

    function _int(value) {
        return Math.floor(Number(value));
    }

    //--------------------------------------------------------------------------

    function _boolean(value) {
        return Boolean(value);
    }

    //--------------------------------------------------------------------------

    function not(value) {
        return !Boolean(value);
    }

    //--------------------------------------------------------------------------

    function number(value) {
        return Number(value);
    }

    //--------------------------------------------------------------------------

    function coalesce() {
        for (var i = 0; i < arguments.length; i++) {
            if (!XFormJS.isEmpty(arguments[i])) {
                return arguments[i];
            }
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function round(value, power) {
        var p = Math.pow(10, power);
        return Math.round(value * p) / p;
    }

    //--------------------------------------------------------------------------

    function pow(value, power) {
        return Math.pow(value, power);
    }

    //--------------------------------------------------------------------------
    // Strings
    // https://docs.opendatakit.org/form-operators-functions/#strings

    //--------------------------------------------------------------------------
    // Searching and matching strings
    // https://docs.opendatakit.org/form-operators-functions/#searching-and-matching-strings

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#regex

    function regex(value, pattern) {
        return (new RegExp(pattern)).test(value);
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#contains

    function contains(value, substring) {
        var _value = _string(value);
        var _substring = _string(substring);

        return _value === _substring ||
                _string(value).indexOf(_string(substring)) >= 0;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#starts-with

    function starts_with(value, substring) {
        var _value = _string(value);
        var _substring = _string(substring);

        return _value === _substring ||
                _string(value).indexOf(_string(substring)) === 0;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#ends-with

    function ends_with(value, substring) {
        var _value = _string(value);
        var _substring = _string(substring);

        return _value === _substring ||
                _value.indexOf(_substring, _value.length - _substring.length) !== -1;
    }

    //--------------------------------------------------------------------------
    //https://docs.opendatakit.org/form-operators-functions/#substr

    function substr(value, start, end) {
        if (end) {
            return _string(value).substr(start, end - start);
        } else {
            return _string(value).substr(start);
        }
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#string-length

    function string_length(value) {
        //console.log("string-length:", value);

        return _string(value).length;
    }

    //--------------------------------------------------------------------------
    // Combining strings
    // https://docs.opendatakit.org/form-operators-functions/#combining-strings

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#concat

    function concat() {
        //console.log("concat:", JSON.stringify(arguments));

        var text = "";

        for (var i = 0; i < arguments.length; i++) {
            text += _string(arguments[i]);
        }

        return text;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#join

    function join(separator) {
        if (!separator) {
            separator = "";
        }

        var text = "";

        function joinValue(value) {
            if (text > "") {
                text += separator;
            }

            text += _string(value);
        }

        for (var i = 1; i < arguments.length; i++) {
            if (Array.isArray(arguments[i])) {
                arguments[i].forEach(function (value) {
                    joinValue(value);
                });
            } else {
                joinValue(arguments[i]);
            }
        }

        return text;
    }

    //--------------------------------------------------------------------------
    // Converting to and from strings
    // https://docs.opendatakit.org/form-operators-functions/#converting-to-and-from-strings

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#string

    function _string(value) {
        if (XFormJS.isEmpty(value)) {
            return "";
        }

        // console.log(arguments.callee.name, "value:", JSON.stringify(value));

        function objectToString() {
            if (value instanceof Date) {
                return Qt.formatDateTime(value, Qt.ISODate);
            }

            if (Array.isArray(value)) {

                if (Geometry.isPointsArray(value, true)) {
                    return value.filter(function (o) { return typeof o === "object" && o !== null; }).map(XFormJS.toCoordinateString).join(";")
                }

                return value.map(function (element) { return element ? element.toString() : ""}).join(",");
            }

            if (value.type) {
                switch (value.type) {
                case "point":
                case "geopoint":
                    return XFormJS.toCoordinateString(value);
                }
            }

            return JSON.stringify(value);
        }

        switch (typeof value) {
        case "object":
            return objectToString()
        default:
            return value.toString();
        }
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#boolean-from-string

    function boolean_from_string(value) {
        if (typeof value === "boolean") {
            return value;
        }

        if (XFormJS.isNullOrUndefined(value)) {
            return false;
        }

        if (typeof value !== "string") {
            value = value.toString();
        }

        return value === "true" || value === "1";
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#uuid

    function uuid() {
        return AppFramework.createUuidString(1);
    }

    //--------------------------------------------------------------------------
    // Date and time
    // https://docs.opendatakit.org/form-operators-functions/#date-and-time

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#now

    function now() {
        return XFormJS.toDateValue(new Date());
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#today

    function today() {
        return clearTimeValue(new Date());
    }

    //--------------------------------------------------------------------------
    // Converting dates and time
    // https://docs.opendatakit.org/form-operators-functions/#converting-dates-and-time

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#decimal-date-time

    function decimal_date_time(value) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return date.valueOf() / kMillisecondsPerDay;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#decimal-time

    function decimal_time(value) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return (date.getHours()
                + date.getMinutes()  / 60
                + (date.getSeconds() + date.getMilliseconds() / 1000)  / 3600) / 24;
    }

    //--------------------------------------------------------------------------
    // Deprecated ?

    function decimal_date(value) {
        var date = clearTime(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return date.valueOf() / kMillisecondsPerDay;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#date

    function date(value) {
        return clearTimeValue(date_time(value));
    }

    //--------------------------------------------------------------------------

    function date_time(value) {
        if (typeof value === "number") {
            return XFormJS.toDateValue(value * kMillisecondsPerDay);
        } else {
            return XFormJS.toDateValue(value);
        }
    }

    //--------------------------------------------------------------------------

    function clearTime(dateValue) {
        if (XFormJS.isEmpty(dateValue)) {
            return;
        }

        return XFormJS.clearTime(XFormJS.toDate(dateValue));
    }

    function clearTimeValue(date) {
        return XFormJS.toDateValue(clearTime(date));
    }

    //--------------------------------------------------------------------------
    // Formatting dates and times for display
    // https://docs.opendatakit.org/form-operators-functions/#formatting-dates-and-times-for-display

    //--------------------------------------------------------------------------
    // %y           2-digit year
    // %Y           4-digit year
    // %n           numeric month
    // %m           0-padded month
    // %b           3 letter short text month (3 char)
    // %e           day of month
    // %d           0-padded day of month
    // %a           Three letter short text day
    // %H           0-padded hour (24-hr time)
    // %h           hour (24-hr time)
    // %M           0-padded minute
    // %S           0-padded second
    // %3           0-padded millisecond ticks (000-999)
    // %Z %A %B     Unsupported
    // %W           Week number (Survey123 specific)

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#format-date

    function format_date(value, format) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return "";
        }

        if (XFormJS.isEmpty(format)) {
            return date.toLocaleDateString(xform.locale);
        }

        var text = "";

        for (var i = 0; i < format.length; i++) {
            var c = format.charAt(i);

            if (c !== '%') {
                text += c;
                continue;
            }

            c = format.charAt(++i);
            if (c === '%') {
                text += c;
                continue;
            }

            switch (c) {
            case 'y':
                text += Qt.formatDate(date, "yy");
                break;

            case 'Y':
                text += Qt.formatDate(date, "yyyy");
                break;

            case 'n':
                text += Qt.formatDate(date, "M");
                break;

            case 'm':
                text += Qt.formatDate(date, "MM");
                break;

            case 'b':
                text += Qt.formatDate(date, "MMM").substr(0, 3);
                break;

            case 'e':
                text += Qt.formatDate(date, "d");
                break;

            case 'd':
                text += Qt.formatDate(date, "dd");
                break;

            case 'a':
                text += Qt.formatDate(date, "ddd").substr(0, 3);
                break;

            case 'h':
                text += Qt.formatTime(date, "h");
                break;

            case 'H':
                text += Qt.formatTime(date, "hh");
                break;

            case 'M':
                text += Qt.formatTime(date, "mm");
                break;

            case 'S':
                text += Qt.formatTime(date, "ss");
                break;

            case '3':
                text += Qt.formatTime(date, "zzz");
                break;

            case 'W':
                text += XFormJS.weekNumber(date).toString();
                break;

            default:
                console.warn("format-date:", format, "Unhandled escape:", "'" + c + "'");
                break;
            }
        }

        //console.log("format-date:", value, "date:", date, "format:", format, "text:", text);

        return text;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#format-date-time

    function format_date_time(value, format) {
        return format_date(value, format);
    }

    //--------------------------------------------------------------------------
    // Trignometry

    function pi() {
        return Math.PI;
    }

    function cos(value) {
        return Math.cos(value);
    }

    function sin(value) {
        return Math.sin(value);
    }

    function tan(value) {
        return Math.tan(value);
    }

    function acos(value) {
        return Math.acos(value);
    }

    function asin(value) {
        return Math.asin(value);
    }

    function atan(value) {
        return Math.atan(value);
    }

    function atan2(y, x) {
        return Math.atan2(y, x);
    }

    //--------------------------------------------------------------------------
    // Other math

    function sqrt(value) {
        return Math.sqrt(value);
    }

    function exp(value) {
        return Math.exp(value);
    }

    function exp10(value) {
        return Math.exp(value * Math.LN10);
    }

    function log(value) {
        return Math.log(value);
    }

    function log10(value) {
        return Math.log(value) / Math.LN10;
    }

    function min(values) {
        var minValue;

        for (var i = 0; i < arguments.length; i++) {
            var value = arguments[i];
            if (Array.isArray(value)) {
                value = _arrayMin(value);
            }

            if (!XFormJS.isEmpty(value)) {
                if (minValue === undefined || value < minValue) {
                    minValue = value;
                }
            }
        }

        return minValue;
    }

    function max(values) {
        var maxValue;

        for (var i = 0; i < arguments.length; i++) {
            var value = arguments[i];
            if (Array.isArray(value)) {
                value = _arrayMax(value);
            }
            if (!XFormJS.isEmpty(value)) {
                if (maxValue === undefined || value > maxValue) {
                    maxValue = value;
                }
            }
        }

        return maxValue;
    }


    function random() {
        return Math.random();
    }

    //--------------------------------------------------------------------------
    // Nodeset aggregate functions

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#count

    function count(values) {
        return values.length;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#count-non-empty

    function count_non_empty(values) {
        if (debug) {
            console.log("count_non_empty", JSON.stringify(values));
        }

        var count = 0;

        values.forEach(function (value) {
            if (!XFormJS.isNullOrUndefined(value)) {
                count++;
            }
        });

        return count;
    }

    //--------------------------------------------------------------------------
    // https://docs.opendatakit.org/form-operators-functions/#sum

    function sum(values) {
        if (!values.length) {
            return;
        }

        var value0 = values[0];
        if (value0 !== null && typeof value0 === "object") {
            return values;
        }

        var s;

        values.forEach(function(value) {
            if (typeof s === "undefined") {
                if (typeof value === "number") {
                    s = 0;
                } else {
                    s = "";
                }
            }

            s += value;
        });

        return s;
    }

    function _arrayMin(values) {
        if (!values.length) {
            return;
        }

        var m = values[0];
        values.forEach(function(value) {
            if (value < m) {
                m = value;
            }
        });

        return m;
    }

    function _arrayMax(values) {
        if (!values.length) {
            return;
        }

        var m = values[0];
        values.forEach(function(value) {
            if (value > m) {
                m = value;
            }
        });

        return m;
    }

    //--------------------------------------------------------------------------

    function version() {
        return xform.version;
    }

    //--------------------------------------------------------------------------

    function pulldata(sourceName) {
        if (sourceName.charAt(0) === "@") {
            var typeName = sourceName.substring(1);
            var context = {
                objectCache: app.objectCache,
                portal: app.portal,
                xform: xform
            };

            switch (typeName) {
            case "geopoint":
                return GeopointHelper.pulldata_geopoint(context, arguments[1], arguments[2], arguments[3], arguments[4], arguments[5]);

            case "exif":
                return pulldata_exif(arguments[1], arguments[2]);

            case "json":
                return pulldata_json(arguments[1], arguments[2]);

            case "javascript":
                return pulldata_javascript(arguments);

            case "property":
                return pulldata_property(arguments[1]);

            default:
                console.error("Unknown pulldata type name:", typeName);
                return;
            }
        }

        if (arguments.length < 4) {
            console.error("pulldata requires 4 parameters", arguments.length);
            return;
        }

        return pulldata_list(sourceName, arguments[1], arguments[2], arguments[3]);
    }

    //--------------------------------------------------------------------------

    function pulldata_list(listName, nameField, keyField, keyValue) {
        var dataList = dataLists.getList(listName);
        if (!dataList) {
            return "";
        }

        var data = dataList.data;
        for (var i = 0; i < data.length; i++) {
            if (data[i][keyField] === keyValue) {
                return data[i][nameField];
            }
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function pulldata_exif(imageName, propertyName) {
        //console.log("pulldata_exif:", imageName, propertyName);

        return exif.propertyValue(imageName, propertyName);
    }

    //--------------------------------------------------------------------------

    function pulldata_json(jsonValue, propertyPath) {
        // console.log("pulldata_json:", typeof jsonValue, jsonValue, propertyPath);

        if (XFormJS.isNullOrUndefined(jsonValue) || XFormJS.isNullOrUndefined(propertyPath)) {
            return;
        }

        var json;

        if (typeof jsonValue === "object") {
            json = jsonValue;
        } else {
            if (typeof jsonValue !== "string") {
                console.error("pulldata_json: Not a string:", typeof jsonValue, jsonValue);
                return;
            }

            try {
                json = JSON.parse(jsonValue);
            } catch (error) {
                console.error("pulldata_json:", error, 'parsing:', jsonValue);
            }

            if (!json) {
                return;
            }
        }

        var value = XFormJS.getPropertyPathValue(json, propertyPath);

        // console.log("pulldata_json:", path[path.length - 1], "=", value);

        return value;
    }

    //--------------------------------------------------------------------------

    function pulldata_javascript(args) {
        if (!xform.extensionsEnabled) {
            console.warn("pulldata_javascript extensions disabled");
            return "Extensions disabled";
        }

        //console.log("pulldata_javascript:", JSON.stringify(args));

        var jsFileName = args[1];
        var jsFunction = args[2];

        var jsUrl = extensionsFolder.fileUrl(jsFileName);
        var jsObject = expressionsList.jsCache[jsFileName];

        if (!jsObject) {
            console.log("@javascript url:", jsUrl);

            var jsSource = "import QtQml 2.2;\r\nimport \"%1\" as JS;\r\nQtObject {\r\n\tfunction evaluate(e) {\r\n\t\treturn eval(e);\r\n\t}\r\n}".arg(jsUrl);

            if (debug) {
                console.log("Creating @javascript component:", jsSource);
            }

            jsObject = Qt.createQmlObject(jsSource, expressionsList, extensionsFolder.path);

            expressionsList.jsCache[jsFileName] = jsObject;
        }

        var expression = "JS." + jsFunction + "(";

        for (var i = 3; i < args.length; i++) {
            if (i > 3) {
                expression += ", ";
            }

            var value = JSON.stringify(args[i]);

            expression += value;
        }

        expression += ");";

        if (debug) {
            console.log("pulldata_javascript:", jsFileName, "expression:", expression);
        }

        try {
            value = jsObject.evaluate(expression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression);
            value = "@javascript error:%1 in %2:%3".arg(error).arg(jsFileName).arg(jsFunction);
        }

        if (debug) {
            console.log("pulldata_javascript:", jsFunction, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function pulldata_property(name) {
        if (typeof name !== "string") {
            console.warn("Invalid @property:", JSON.stringify(name));
            return;
        }

        if (!name.length) {
            return;
        }

        name = name.toLowerCase();

        var value;

        switch (name) {
        case "online":
            value = Networking.isOnline;
            break;

        case "portalurl":
            value = app.portal.portalUrl.toString();
            break;

        case "portalinfo":
            value = app.portal.info;
            break;

        case "token":
            value = app.portal.token > "" ? app.portal.token : undefined;
            break;

        case "owningsystemurl":
            value = app.portal.owningSystemUrl.toString();
            break;

        case "utcoffset":
            value = - new Date().getTimezoneOffset() / 60;
            break;

        case "timezone":
            value = Qt.formatDateTime(new Date(), "t");
            break;

        case "language":
            value = xform.language;
            break;

        case "locale":
            value = xform.locale;
            break;

        case "localeinfo":
            value = AppFramework.localeInfo(xform.locale.name);
            break;

        case "mode":
        case "status":
            value = xform.expressionProperties[name];
            break;

        default:
            console.warn("Unknown @property:", name);
            value = "Unknown @property: %1".arg(name);
            break;
        }

        if (debug) {
            console.log("@property:", name, "value:", JSON.stringify(value, undefined, 2));
        }

        return value;
    }

    //--------------------------------------------------------------------------
    // Special handling required

    function once(value) {
        return value;
    }

    //--------------------------------------------------------------------------

    function property(name) {
        return XFormJS.systemProperty(app, name);
    }

    //--------------------------------------------------------------------------
    // Geometry functions

    //--------------------------------------------------------------------------

    function distance(geometry) {
        if (typeof geometry === "string") {
            geometry = XFormJS.toGeometry("geotrace", geometry);
        }

        if (typeof geometry !== "object") {
            console.error("geometry is not an object:", typeof geometry, geometry);
            return;
        }

        var path = [];

        var isPolygon = false;
        if (Array.isArray(geometry.rings)) {
            path = Geometry.pointsToPath(geometry.rings[0]);
            isPolygon = true;
        } else if (Array.isArray(geometry.paths)) {
            path = Geometry.pointsToPath(geometry.paths[0]);
        }

        var geopath = QtPositioning.path(path);

        return Geometry.geopathLength(geopath, isPolygon);
    }

    //--------------------------------------------------------------------------

    function area(geoshape) {
        if (typeof geoshape === "string") {
            geoshape = XFormJS.toGeometry("geoshape", geoshape);
        }

        if (typeof geoshape !== "object") {
            console.error("geoshape is not an object:", typeof geoshape, geoshape);
            return;
        }

        var path = [];

        if (Array.isArray(geoshape.rings)) {
            path = Geometry.pointsToPath(geoshape.rings[0]);
        }

        return Geometry.pathArea(path);
    }

    //--------------------------------------------------------------------------
}
