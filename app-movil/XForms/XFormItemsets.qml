/* Copyright 2018 Esri
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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Item {
    property alias dataFolder: dataFolder
    property string dataFileName: "itemsets.csv"
    readonly property string dataSeparator: ","
    readonly property string listNameColumn: "list_name"
    property var itemLists: ({})

    property bool useListsCache: app.features.listCache
    property XFormListsCache listsCache

    property bool debug

    //--------------------------------------------------------------------------

    FileFolder {
        id: dataFolder

        onPathChanged: {
            loadExternal();
        }
    }

    //--------------------------------------------------------------------------

    function findItems(listName) {
        if (Array.isArray(itemLists[listName])) {
            return itemLists[listName];
        }

        var instance = findInstance(listName);

        if (!instance) {
            console.log("List instance not found:", listName);
            return [];
        }

        //console.log("instance:", JSON.stringify(instance));

        var items = XFormJS.childElements(instance["root"]);

        //console.log("items:", JSON.stringify(items, undefined, 2));

        itemLists[listName] = items;

        return items;
    }

    //--------------------------------------------------------------------------

    function loadExternal() {
        if (!dataFolder.fileExists(dataFileName)) {
            console.log("Itemsets data file not found:", dataFolder.filePath(dataFileName));

            return;
        }

        if (useListsCache) {
            initializeCache(dataFolder.filePath(dataFileName));
        }

        console.log("Reading itemsets:", dataFolder.filePath(dataFileName));
        console.time("Reading itemsets");

        var data = dataFolder.readTextFile(dataFileName);

        var rows = data.split("\n");

        if (rows < 1) {
            console.log("No data rows");
            return;
        }

        var columns = rows[0].split(dataSeparator);

        for (var i = 0; i < columns.length; i++) {
            columns[i] = columnValue(columns[i]);
        }

        console.log("# rows", rows.length, "columns:", JSON.stringify(columns, undefined, 2));

        for (i = 1; i < rows.length; i++) {
            var values = rows[i].split(dataSeparator);

            if (values.length < 1) {
                continue;
            }

            var valuesObject = {};

            for (var j = 0; j < values.length; j++) {
                valuesObject[columns[j]] = columnValue(values[j]);
            }

            addListRow(valuesObject);
        }

        console.timeEnd("Reading itemsets");

        // console.log("itemLists:", JSON.stringify(itemLists, undefined, 2));
    }
    
    //--------------------------------------------------------------------------

    function addListRow(values) {
        var listName = values[listNameColumn];

        if (!(listName > "")) {
            if (debug) {
                console.log("Skip:", JSON.stringify(values, undefined, 2));
            }
            return;
        }

        values[listNameColumn] = undefined;

        if (!Array.isArray(itemLists[listName])) {
            itemLists[listName] = [];
        }

        itemLists[listName].push(values);
    }

    //--------------------------------------------------------------------------

    function columnValue(value) {
        var tokens = value.match(/\"(.*)\"/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return value;
        }
    }

    //--------------------------------------------------------------------------

    function findInstance(instanceName) {
        for (var i = 0; i < xform.instances.length; i++) {
            var instance = xform.instances[i];

            if (instance["@id"] === instanceName) {
                return instance;
            }
        }

        console.error("instance not found:", instanceName);

        return undefined;
    }

    //--------------------------------------------------------------------------

    function initializeCache(path) {
        listsCache.dataFolder.path = dataFolder.path;
        listsCache.initialize();

        cacheItemsets(path);
    }

    //--------------------------------------------------------------------------

    function cacheItemsets(path) {
        var fileInfo = AppFramework.fileInfo(path);
        console.log("caching itemsets:", path);

        var targetTableName = "itemsets";

        listsCache.loadTable(fileInfo, targetTableName, "WHERE \"%1\" > '' AND name > ''".arg(listNameColumn));

        var commands = [];

        var targetTable = listsCache.database.table(targetTableName);

        commands.push("CREATE INDEX \"%1_index_%2\" ON \"%1\" (\"%2\");"
                      .arg(targetTableName)
                      .arg(listNameColumn));

        var skipFields = [listNameColumn];
        var descFields = ["label", "image", "audio", "video"];

        for (var i = 0; i < targetTable.fields.count; i++) {
            var fieldName = targetTable.fields.fieldName(i);

            //console.log("field:", fieldName);

            if (skipFields.indexOf(fieldName) >= 0) {
                console.log("skiping field:", fieldName);
                continue;
            }

            for (var j = 0; j < descFields.length; j++) {
                var descField = descFields[j];

                if (fieldName === descField || fieldName.substring(0, descField.length + 2) === (descField + "::")) {
                    console.log("skipping desc field:", fieldName);
                    fieldName = undefined;
                    break;
                }
            }

            if (!fieldName) {
                continue;
            }

            commands.push("CREATE INDEX \"%1_index_%3\" ON \"%1\" (\"%2\", \"%3\");"
                          .arg(targetTableName)
                          .arg(listNameColumn)
                          .arg(fieldName));
        }

        listsCache.database.batchExecute(commands);

        console.log("itemsets cache initialized");

        return true;
    }

    //--------------------------------------------------------------------------
}
