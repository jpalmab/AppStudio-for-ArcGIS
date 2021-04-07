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

Item {
    id: itemsetItem

    //--------------------------------------------------------------------------

    property var itemset
    property XFormData formData
    property string nodeset: itemset["@nodeset"]
    property string valueRef: itemset.value["@ref"]
    property string labelRef: itemset.label["@ref"]
    property string labelProperty
    property string listName
    property var itemsPath
    property string expression
    property XFormExpression expressionInstance
    property var expressionNodesets
    property var items
    property string filterExpression
    property var filteredItems: []
    property var nodesetValues
    property var previousNodesetValues

    property bool debug

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "itemset:", JSON.stringify(itemset, undefined, 2));
            console.log(logCategory, "nodeset:", nodeset);
            console.log(logCategory, "valueRef:", valueRef);
            console.log(logCategory, "labelRef:", labelRef);
        }

        labelProperty = labelRef.match(/jr:itext\((.*)\)/)[1];

        if (debug) {
            console.log(logCategory, "labelProperty:", labelProperty);
        }

        var nodesetTokens = nodeset.match(/instance\(\s*\'([A-Za-z0-9_]+)\'\s*\)([0-9A-Za-z_\/.']+)\[([0-9A-Za-z=_\ \/]+)\]/);

        if (debug) {
            console.log(logCategory, "nodesetTokens:", nodeset, "=", JSON.stringify(nodesetTokens, undefined, 2));
        }

        listName = nodesetTokens[1];
        itemsPath = nodesetTokens[2].split("/");
        expression = nodesetTokens[3];

        if (debug) {
            console.log(logCategory, "listName:", listName);
            console.log(logCategory, "itemsPath:", JSON.stringify(itemsPath, undefined, 2));
            console.log(logCategory, "expression:", expression);
        }

        items = xform.itemsets.findItems(listName);

        if (debug) {
            console.log(logCategory, "items count:", items.length);
            //console.log(logCategory, "items:", JSON.stringify(items, undefined, 2));
        }

        expressionInstance = formData.expressionsList.addExpression(expression, undefined, "select");
        expressionNodesets = expressionInstance.nodesets;
        nodesetValues = expressionInstance.nodesetValuesBinding();
    }

    //--------------------------------------------------------------------------

    onNodesetValuesChanged: {
        if (debug) {
            console.log(logCategory, "onNodesetValuesChanged:", JSON.stringify(nodesetValues, undefined, 2));
        }

        var changed = false;

        if (!previousNodesetValues) {
            previousNodesetValues = {};
        }

        expressionNodesets.forEach(function (nodeset) {
            if (nodesetValues[nodeset] != previousNodesetValues[nodeset]) {
                previousNodesetValues[nodeset] = nodesetValues[nodeset];
                changed = true;
            }
        });

        if (debug) {
            console.log(logCategory, "Itemset changed:", changed);
        }

        if (changed) {

            function valueToken(nodeset) {
                return formData.valueToken(formData.valueById(nodeset));
            }

            filterExpression = expressionInstance.translate(expression, "", undefined, valueToken);

            filteredItems = filterItems(filterExpression);

            //            console.log(logCategory, "filteredItems", JSON.stringify(filteredItems, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(itemsetItem, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onLanguageChanged: {
            console.log(logCategory, 'Language:', language);

            if (itemset.external) {
                filteredItems = filterItems(filterExpression);
            }
        }
    }

    //--------------------------------------------------------------------------

    function filterItems(expressionArg) {
        var filteredItems = [];

        if (!Array.isArray(items)) {
            return filteredItems;
        }

        if (debug) {
            console.log(logCategory, "Filtering", items.length, "items with expression:", expressionArg, "language:", xform.language);
        }

        var translatedLabelProperty = labelProperty + "::" + xform.language;

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            if (evaluateExpressionItem(expressionArg, item)) {
                filteredItems.push({
                                       value: item[valueRef],
                                       label: itemset.external
                                              ? translatedLabel(item, translatedLabelProperty)
                                              : { "@ref": "jr:itext('" + item[labelProperty] + "')" }
                                   });
            }

        }

        if (debug) {
            console.log(logCategory, "# Filtered:", filteredItems.length);
        }

        return filteredItems;
    }

    //--------------------------------------------------------------------------

    function evaluateExpressionItem(expressionArg, itemArg) {
        with (itemArg) {
            return Boolean(eval(expressionArg));
        }
    }

    //--------------------------------------------------------------------------

    function translatedLabel(item, translatedLabelProperty) {
        if (item[translatedLabelProperty]) {
            return item [translatedLabelProperty];
        }

        return item[labelProperty];
    }

    //--------------------------------------------------------------------------
}
