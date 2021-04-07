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
import "XFormSingletons"

Item {
    id: xformSchema

    property var model
    property var schema
    property var tables: []
    property var fieldNodes: ({})
    property var tableNodes: ({})
    property var repeatNodesets: []
    property string instanceName
    property int wkid: 4326

    property bool debug: false

    property bool canPrint: false

    //--------------------------------------------------------------------------

    readonly property string kGeneratedPrefix: "generated_"
    readonly property string kReservedNamePrefix: "reserved_name_for_field_list_labels_"

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(xformSchema, true)
    }

    //--------------------------------------------------------------------------

    function update(formDefinition, searchForRepeats) {

        var model = formDefinition.head.model;

        if (debug) {
            console.log(logCategory, "Update table schema:", JSON.stringify(model, undefined, 2));
        }

        xformSchema.model = model;

        if (searchForRepeats) {
            findRepeatNodesets(formDefinition.body);
        }

        console.log(logCategory, "repeatNodesets:", JSON.stringify(repeatNodesets, undefined, 2));

        tables = [];
        var instance = XFormJS.asArray(model.instance)[0];

        var elements = instance["#nodes"];
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].charAt(0) !== '#') {
                instanceName = elements[i];
                break;
            }
        }

        var schema = buildSchema(null, XFormJS.childElements(instance)[0]);

        if (debug) {
            console.log(logCategory, "schema:", JSON.stringify(schema, undefined, 2));
        }

        xformSchema.schema = schema;
    }

    //--------------------------------------------------------------------------

    function buildSchema(parentNodeset, instance, table, parentNames) {
        if (debug) {
            console.log(logCategory, "buildSchema: instance:", JSON.stringify(instance, undefined, 2));
        }

        var tagName = instance["#tag"];
        var instanceId = instance["@id"];
        var tableName = instanceId > "" ? instanceId : tagName;


        if (!parentNodeset) {
            parentNodeset = "";
        }

        if (!parentNames) {
            parentNames = [];
        }

        var level = parentNames.length;

        var nodeset = parentNodeset +  "/" + tagName;
        var binding = findBinding(nodeset);
        if (!binding) {
            binding = {};
        }

        if (debug) {
            console.log(logCategory, "schema table:", tagName, "nodeset:", nodeset, "level:", level, "parentNames:", JSON.stringify(parentNames), "binding:", JSON.stringify(binding));
        }

        var tableInfo;

        if (!table) {
            table = {
                isRoot: tables.length === 0,
                name: tagName,
                id: instanceId,
                level: level,
                tableName: tableName,
                nodeset: nodeset,
                binding: binding,
                esriParameters: XFormJS.parseParameters(binding["@esri:parameters"]),
                domains: [],
                fields: [],
                fieldsRef: {},
                parentNames: parentNames.slice(0),
                relatedTables: [],
                hasAttachments: false,
                hasZ: false,
                hasM: false,
                required: binding["@required"] === "true()",
                requiredMsg: binding["@jr:requiredMsg"]
            };

            var displayName = "";
            for (var l = 0; l < level; l++) {
                displayName += "  ";
            }
            displayName += level ? "+" : "";
            for (l = 0; l < level; l++) {
                displayName += "-";
            }

            displayName += " " + table.tableName;

            tableInfo = {
                schema: table,
                displayName: displayName
            }

            table.tableId = (tables.length > 0 ? "$" : "%") + table.tableName;
            tables.push(tableInfo);

            tableNodes[table.name] = table;

            parentNames = parentNames.concat(table.name);
        }

        var rowInstance = {};

        var elements = XFormJS.childElements(instance);
        for (var i = 0; i < elements.length; i++) {
            var element = elements[i];
            //            console.log(logCategory, "element:", element, JSON.stringify(element, undefined, 2));

            var fieldName = element["#tag"];
            var ref = nodeset + "/" + fieldName;
            binding = findBinding(ref);

            if (repeatNodesets.indexOf(ref) >= 0) { // Repeat node
                console.log(logCategory, "Found repeat ref:", ref, "in:", JSON.stringify(repeatNodesets));
                var relatedTable = buildSchema(nodeset, element, undefined, parentNames);
                if (relatedTable) {
                    console.log(logCategory, "relatedTable:", relatedTable.name, "parentTable:", table.name, "parentNames:", JSON.stringify(relatedTable.parentNames));
                    table.relatedTables.push(relatedTable);
                }
            } else if (XFormJS.hasChildElements(element)) { // Group
                buildSchema(nodeset, element, table, parentNames);
            } else if (binding) {

                var fieldType = binding["@type"];
                var esriFieldType = XFormJS.esriFieldType(fieldType);
                var esriGeometryType = XFormJS.esriGeometryType(fieldType);
                var requiredExpression = binding["@required"];
                var required = binding["@required"] === "true()";
                var requiredMsg = binding["@jr:requiredMsg"];
                var readonlyExpression = binding["@readonly"];
                var readonly = binding["@readonly"] === "true()";
                var calculate = binding["@calculate"];
                var constraint = binding["@constraint"];
                var constraintMsg = binding["@jr:constraintMsg"];
                var relevant = binding["@relevant"];
                var defaultValue = instance[fieldName];
                var preload = binding["@jr:preload"];
                var preloadParams = binding["@jr:preloadParams"];
                var fieldLength = 255;
                var attachment = false;


                rowInstance[fieldName] = defaultValue;

                // Generated field ?

                if (readonly && fieldName.substring(0, kGeneratedPrefix.length ) === kGeneratedPrefix) {
                    binding["@esri:fieldType"] = "null";

                    if (debug) {
                        console.log(logCategory, "Generated field", ref);
                    }
                }

                // Reserved field created for table-list?

                if (fieldName.substring(0, kReservedNamePrefix.length ) === kReservedNamePrefix) {
                    binding["@esri:fieldType"] = "null";

                    if (debug) {
                        console.log(logCategory, "table-list label", ref);
                    }
                }


                // geopoint default

                if (fieldType === "geopoint" && !(defaultValue > "" || calculate > "")) {
                    defaultValue = "position";
                }

                // Autogenerated "instanceID" meta node ?

                if (XFormJS.endsWith(ref, "meta/instanceID")) {
                    console.log(logCategory, "Skipping meta/instanceID", ref);
                    continue;
                }

                // "instanceName" meta node ?

                if (XFormJS.endsWith(ref, "meta/instanceName")) {
                    console.log(logCategory, "Skipping meta/instanceName", ref);
                    continue;
                }

                // Treat 'binary' fields as attachments

                if (fieldType === "binary") {
                    attachment = true;
                    table.hasAttachments = true;
                    esriFieldType = "<attachment>";
                }

                var controlNode;
                try {
                    controlNode = controlNodes[ref];
                } catch (e) {
                    console.log(logCategory, "XFormSchema basic mode:", fieldName);
                }

                // Build coded value domain for select1 controls

                var domain = undefined;
                var minimumFieldLength = undefined;

                if (fieldType === "select1") {
                    if (controlNode && controlNode.formElement && !controlNode.formElement.itemset) {
                        var domainInfo = {};
                        domain = createDomain(fieldName, controlNode, domainInfo);
                        if (domain) {
                            table.domains.push(domain);
                            minimumFieldLength = domainInfo.maxCodeLength;
                        }
                    }
                }

                // Esri sepcific properties

                var esriProperty = binding["@esri:fieldType"];
                if (esriProperty > "") {
                    if (esriProperty.substr(0, 13) === "esriFieldType") {
                        esriFieldType = esriProperty;
                    } else if (esriProperty.toLowerCase().indexOf("null") >= 0) {
                        esriFieldType = undefined;
                    }
                }

                esriProperty = binding["@esri:fieldLength"];
                if (esriProperty > "") {
                    var n = Number(esriProperty);
                    if (isFinite(n)) {
                        fieldLength = n;
                    }
                }

                //

                var label = undefined;
                var hint = undefined;
                var appearance = undefined;
                var itemset = undefined;
                var print = undefined;
                var printStyle = undefined;

                if (controlNode && controlNode.formElement) {
                    var formElement = controlNode.formElement;

                    label = textValue(formElement.label);
                    if (typeof label === "object") {
                        label = "";
                    } else if (label > "") {
                        label = label.trim();
                    }

                    hint = textValue(formElement.hint);
                    if (typeof hint === "object") {
                        hint = "";
                    }

                    appearance = formElement["@appearance"];
                    itemset = formElement.itemset;

                    var esriPrint = formElement["@esri:print"];
                    print = esriPrint === "yes";
                    if (print) {
                        printStyle = formElement["@esri:printStyle"];
                    }
                }

                var esriFieldAlias = binding["@esri:fieldAlias"];

                if (!(esriFieldAlias > "") && label > "") {
                    esriFieldAlias = label.replace(/(<([^>]+)>)/ig, "");
                }
                if (!(esriFieldAlias > "")) {
                    esriFieldAlias = fieldName;
                }

                var field = {
                    autoField: false,
                    nodeset: ref,
                    name: fieldName,
                    binding: binding,
                    type: fieldType,
                    length: fieldLength,
                    minimumFieldLength: minimumFieldLength,
                    requiredExpression: requiredExpression,
                    required: required,
                    requiredMsg: requiredMsg,
                    readonlyExpression: readonlyExpression,
                    readonly: readonly,
                    calculate: calculate,
                    constraint: constraint,
                    constraintMsg: constraintMsg,
                    relevant: relevant,
                    esriFieldType: esriFieldType,
                    esriFieldAlias: esriFieldAlias,
                    esriGeometryType: esriGeometryType,
                    esriParameters: XFormJS.parseParameters(binding["@esri:parameters"]),
                    attachment: attachment,
                    defaultValue: (defaultValue ? defaultValue : ""),
                    preload: preload,
                    preloadParams: preloadParams,
                    tableName: table.name,
                    domain: domain,
                    label: label,
                    hint: hint,
                    appearance: appearance,
                    itemset: itemset,
                    print: print,
                    printStyle: printStyle
                };

                if (esriGeometryType && !table.geometryFieldName) {
                    table.geometryField = field;
                    table.geometryFieldName = fieldName;
                    table.geometryFieldType = esriGeometryType;
                    table.geometryFieldWkid = 4326;

                    if (field.esriParameters) {
                        let wkid = XFormJS.getPropertyPathValue(field.esriParameters, "wkid");
                        if (wkid > 0) {
                            table.geometryFieldWkid = wkid;
                        }
                    }

                    if (XFormJS.geometryDimension(esriFieldType) === XFormJS.geometryDimension(esriGeometryType)) {
                        table.hasZ = XFormJS.geometryTypeHasZ(esriFieldType);
                        table.hasM = XFormJS.geometryTypeHasM(esriFieldType);
                    }

                    // Set schema wkid to same as first geometry field found

                    xformSchema.wkid = table.geometryFieldWkid;
                }

                if (fieldType === "dateTime") {
                    if (preloadParams === "start" && !table.startTimeField) {
                        table.startTimeField = fieldName;
                    }

                    if (preloadParams === "end" && !table.endTimeField) {
                        table.endTimeField = fieldName;
                    }
                }

                table.fields.push(field);
                table.fieldsRef[field.name] = field;

                var nodeRef = binding["@nodeset"];
                if (nodeRef) {
                    fieldNodes[nodeRef] = field;
                }

                if (print) {
                    canPrint = true;
                }
            } else {
                console.log(logCategory, "Unbound nodeset", ref, "element:", JSON.stringify(element, undefined, 2));
            }
        }


        if (level === 0) {
            geometryCheck(table);
        }

        if (table.geometryFieldName > "" && table.geometryField.esriFieldType > "") {
            table.type = Layer.kTypeFeatureLayer;
        } else {
            table.type = Layer.kTypeTable;
        }

        if (tableInfo) {
            tableInfo.displayName += " (%1)".arg(table.type);
        }

        table.rowInstance = rowInstance;

        //console.log(logCategory, JSON.stringify(table, undefined, 2));

        return table;
    }

    //--------------------------------------------------------------------------

    function geometryCheck(table) {
        if (table.geometryFieldName) {
            return;
        }

        var fieldName = "geometry";
        var fieldType = "geopoint";
        var esriFieldType = "esriFieldTypeGeometry";
        var esriGeometryType = "esriGeometryPoint";

        var field = {
            autoField: true,
            nodeset: "",
            name: fieldName,
            binding: {},
            type: fieldType,
            length: 255,
            required: false,
            readonly: false,
            calculate: "",
            constraint: "",
            relevant: "",
            esriFieldType: esriFieldType,
            esriGeometryType: esriGeometryType,
            defaultValue: "",
            preload: "property",
            preloadParams: "position",
            tableName: table.name
        };

        table.fields.push(field);

        table.geometryField = field;
        table.geometryFieldName = fieldName;
        table.geometryFieldType = esriGeometryType;
        table.geometryFieldWkid = 4326;
        table.hasZ = false;
        table.hasM = false;
    }

    //--------------------------------------------------------------------------

    function createDomain(fieldName, controlNode, domainInfo) {
        var domain = {
            type: "codedValue",
            name: "cvd_" + fieldName,
            codedValues: []
        };

        var maxCodeLength = 0;
        var intValues  = true;
        var floatValues = true;

        var items = XFormJS.asArray(controlNode.formElement.item);

        for (var i = 0; items && i < items.length; i++) {
            var item = items[i];

            var codedValue = {
                "name": textValue(item.label).trim(),
                "code": item.value
            };

            // Check for duplicate codes
            for (var j = 0; j < domain.codedValues.length; j++) {
                if (domain.codedValues[j].code === codedValue.code) {
                    console.warn("skipping duplicate codedValue:", codedValue.code, "=", codedValue.name);
                    codedValue = undefined;
                    break;
                }
            }

            if (!codedValue) {
                continue;
            }

            maxCodeLength = Math.max(maxCodeLength, item.value.toString().length);

            var n = Number(item.value);
            var isNum = !isNaN(n);
            intValues = intValues && isNum && isInteger(n);
            floatValues = floatValues && isNum && (isFloat(n) || isInteger(n));

            domain.codedValues.push(codedValue);
        }

        domainInfo.maxCodeLength = maxCodeLength;

        if (intValues) {
            domainInfo.esriFieldType = "esriFieldTypeInteger";
        } else if (floatValues) {
            domainInfo.esriFieldType = "esriFieldTypeDouble";
        } else {
            domainInfo.esriFieldType = "esriFieldTypeString";
        }

        //        console.log(logCategory, JSON.stringify(domainInfo, undefined, 2));
        //        console.log(logCategory, JSON.stringify(domain, undefined, 2));

        return domain;
    }

    function isInteger(n) {
        return (typeof n === 'number') && (n % 1 === 0);
    }

    function isFloat(n) {
        return (typeof n === 'number') && (n % 1 !== 0);
    }

    function isNumber(n) {
        return typeof n==='number';
    }

    //--------------------------------------------------------------------------

    function findBinding(ref) {
        var bindArray = XFormJS.asArray(model.bind);

        for (var i = 0; i < bindArray.length; i++) {
            var bind = bindArray[i];

            if (bind["@nodeset"] === ref) {
                return bind;
            }
        }

        for (i = 0; i < bindArray.length; i++) {
            bind = bindArray[i];

            var nodeset = bind["@nodeset"];
            var j = nodeset.lastIndexOf("/");
            if (j >= 0) {
                nodeset = nodeset.substr(j + 1);
            }

            if (nodeset === ref) {
                return bind;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    function findTable(name) {
        for (var i = 0; i < tables.length; i++) {
            var table = tables[i].schema;
            if (table.tableName === name) {
                return table;
            }
        }
    }

    //--------------------------------------------------------------------------

    function tableInstance(name) {
        var table = tableNodes[name];

        var values  = table ? table.rowInstance : undefined;

        if (debug) {
            console.log(logCategory, "tableInstance:", name, "values:", JSON.stringify(values));
        }

        return values;
    }

    //--------------------------------------------------------------------------

    function findRepeatNodesets(body) {
        console.log(logCategory, "findRepeatNodesets");

        repeatNodesets = [];

        traverseControls(body, function(nodeName, node, binding) {
            //console.log(logCategory, "traversing:", nodeName, "binding:", JSON.stringify(binding));

            if (nodeName === "repeat") {
                repeatNodesets.push(node["@nodeset"]);
            }
        });

    }

    //--------------------------------------------------------------------------

    function traverseControls(parentNode, callback, skipNodes) {
        if (!parentNode) {
            return;
        }

        if (debug) {
            console.log(logCategory, "traverseControls parentNode:", JSON.stringify(parentNode, undefined, 2))
        }

        var nodeNames = parentNode["#nodes"];

        if (!nodeNames) {
            console.log(logCategory, "No child nodes in parentNode:", JSON.stringify(parentNode));
            return;
        }

        for (var i = 0; i < nodeNames.length; i++) {
            var name = nodeNames[i];
            if (name.charAt(0) === '#') {
                console.log(logCategory, "Skip", name);
                continue;
            }

            var nodeName = XFormJS.nodeName(name);
            var nodeIndex = XFormJS.nodeIndex(name);

            if (skipNodes) {
                if (skipNodes.indexOf(nodeName) >= 0) {
                    continue;
                }
            }

            //console.log(logCategory, nodeNames[i], "nodeName", nodeName, "nodeIndex", nodeIndex);
            var node;

            if (nodeIndex >= 0) {
                node = parentNode[nodeName][nodeIndex];
            } else {
                node = parentNode[nodeName];
            }

            var ref = node["@ref"];

            //console.log(logCategory, i, "ref", ref);

            var binding = findBinding(ref);

            callback(nodeName, node, binding);

            switch (nodeName) {
            case "group":
            case "repeat":
                traverseControls(node, callback, ["label"]);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------
}
