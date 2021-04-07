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

import "../Models"
import "../template/SurveyHelper.js" as Helper
import "XForm.js" as XFormJS

SortedListModel {
    id: model

    //--------------------------------------------------------------------------

    property string dbIdentifer: "SurveysData"
    property string dbVersion: "1.0"
    property string dbDescription: "Surveys Database"

    readonly property string databasePath: AppFramework.fileFolder(AppFramework.offlineStoragePath).folder("Databases").filePath(Qt.md5(dbIdentifer) + ".sqlite")

    readonly property int statusDraft: 0
    readonly property int statusComplete: 1
    readonly property int statusSubmitted: 2
    readonly property int statusSubmitError: 3
    readonly property int statusInbox: 4

    property int statusFilter: -1
    property int statusFilter2: statusFilter
    property int changed: 0

    property bool validSchema
    property bool hasDateValues

    property alias isOpen: database.isOpen

    //--------------------------------------------------------------------------

    sortProperty: "updated"
    sortOrder: kSortOrderDesc

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: loggingCategory

        name: AppFramework.typeOf(model, true)
    }

    //--------------------------------------------------------------------------

    property XFormSqlDatabase database: XFormSqlDatabase {
        id: database
    }

    //--------------------------------------------------------------------------
    /*
    onStatusFilterChanged: {
        refresh();
    }
    */

    onChangedChanged: {
        console.log("changedChanged")
    }

    //--------------------------------------------------------------------------

    function open() {
        console.log(logCategory, arguments.callee.name, "databasePath:", databasePath);

        if (!isOpen) {
            database.databaseName = databasePath;
            if (!database.open()) {
                console.error(logCategory, arguments.callee.name, "Error opening:", databasePath);
            }
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, arguments.callee.name, "path:", databasePath);

        var fileInfo = AppFramework.fileInfo(databasePath);
        if (!fileInfo.folder.exists) {
            if (!fileInfo.folder.makeFolder()) {
                console.log(logCategory, "Error creating folder:", fileInfo.folder.path);
            }
        }

        open();

        clear();

        database.executeSql("CREATE TABLE IF NOT EXISTS Surveys(name TEXT, path TEXT, created DATE, updated DATE, status INTEGER, statusText TEXT, data TEXT, feature TEXT, snippet TEXT, favorite INTEGER DEFAULT 0)");

        if (Qt.platform.os === "ios") {
            console.log("Checking survey paths");
            fixSurveysPath();
        }

    }

    //--------------------------------------------------------------------------

    function reinitialize() {
        console.log(logCategory, arguments.callee.name);

        database.close();
        open();

        database.executeSql("DROP TABLE IF EXISTS Surveys");

        initialize();
        changed++;
    }

    //--------------------------------------------------------------------------

    function validateSchema() {
        if (!isOpen) {
            console.error(logCategory, "Database not open");
            return;
        }

        var columns = [];

        var query = database.executeSql("PRAGMA table_info(Surveys)");

        if (query) {
            while (query.next()) {
                var row = query.values;
                //console.log("row", JSON.stringify(row, undefined, 2));
                columns.push(row.name);
            }
        }

        validSchema = true;

        var requiredColumns = [
                    "name",
                    "path",
                    "created",
                    "updated",
                    "status",
                    "statusText",
                    "data",
                    "feature",
                    "snippet"
                ];

        requiredColumns.forEach(function (name) {
            if (columns.indexOf(name) < 0) {
                console.error(logCategory, "Column not found:", name);
                validSchema = false;
            }
        });

        //console.log("validSchema", validSchema, JSON.stringify(columns), JSON.stringify(requiredColumns));

        return validSchema;
    }

    //--------------------------------------------------------------------------

    function refresh(path) {
        clear();
        hasDateValues = false;

        var select = "SELECT rowid, * FROM Surveys ";
        var orderClause = "";//" ORDER BY updated desc";
        var query;

        if (statusFilter >= 0) {
            if (path > "") {
                query = database.executeSql(select + 'WHERE path = ? AND (status = ? OR status = ?)' + orderClause, path, statusFilter, statusFilter2);
            } else {
                query = database.executeSql(select + 'WHERE status = ?' + orderClause, statusFilter);
            }
        } else {
            if (path > "") {
                query = database.executeSql(select + 'WHERE path = ?' + orderClause, path);
            } else {
                query = database.executeSql(select + orderClause);
            }
        }

        if (!query) {
            console.error(arguments.callee.name);
            return;
        }

        while (query.next()) {
            var row = query.values;

            if (row.data > "") {
                row.data = JSON.parse(row.data);
            } else {
                row.data = null;
            }

            if (row.feature > "") {
                row.feature = JSON.parse(row.feature);
            } else {
                row.feature = null;
            }

            //console.log(i, JSON.stringify(row, undefined, 2));

            if (row.created > "") {
                if (row.created.charAt(row.created.length - 1) !== "Z") {
                    row.created += "Z";
                }
            }

            if (row.updated > "") {
                hasDateValues = true;

                if (row.updated.charAt(row.updated.length - 1) !== "Z") {
                    row.updated += "Z";
                }
            } else {
                row.updated = "";
            }

            append(row);
        }
    }

    //--------------------------------------------------------------------------

    function addRow(jobs) {
        for (var i = 0; i < jobs.length; i++) {
            var rowData = jobs[i];

            if (!rowData.statusText) {
                rowData.statusText = "";
            }

            if (!rowData.created) {
                rowData.created = new Date();
            }

            if (!rowData.updated) {
                rowData.updated = rowData.created;
            }

            //console.log("addRow:", JSON.stringify(rowData, undefined, 2));

            var result = database.executeSql(
                        "INSERT INTO Surveys (name, path, created, updated, status, statusText, data, feature, snippet) VALUES (?,?,?,?,?,?,?,?,?)",
                        rowData.name,
                        rowData.path,
                        XFormJS.isValidDate(rowData.created) ? rowData.created.toISOString() : null,
                        XFormJS.isValidDate(rowData.updated) ? rowData.updated.toISOString() : null,
                        rowData.status,
                        rowData.statusText,
                        JSON.stringify(rowData.data, undefined, 2),
                        _stringify(rowData.feature),
                        rowData.snippet);

            //console.log("addRow result:", JSON.stringify(result, undefined, 2));

            rowData.rowid = result.insertId;

            if (rowData.favorite) {
                updateFavorite(rowData);
            }
        }
    }

    //--------------------------------------------------------------------------

    function finalizeAddRows() {
        changed++;
    }

    //--------------------------------------------------------------------------

    function queryRow(rowid) {
        var rowData;

        var result = database.executeSql("SELECT rowid, * FROM Surveys WHERE rowid = ?", rowid);

        if (result && result.first()) {
            var row = result.values;

            rowData = {
                rowid: row.rowid,
                data: JSON.parse(row.data),
                feature: JSON.parse(row.feature),
                snippet: row.snippet,
                updated: new Date(row.updated),
                status: row.status,
                statusText: row.statusText,
            };
        }

        //console.log("queryRow result:", JSON.stringify(rowData, undefined, 2));

        return rowData;
    }

    //--------------------------------------------------------------------------

    function updateRow(rowData, setUpdatedTimeStamp) {

        if (setUpdatedTimeStamp === undefined) {
            setUpdatedTimeStamp = true;
        }

        if (!rowData.statusText) {
            rowData.statusText = "";
        }

        if (setUpdatedTimeStamp) {
            rowData.updated = new Date();
        }

        var results = database.executeSql(
                    "UPDATE Surveys SET status = ?, statusText = ?, data = ?, feature = ?, snippet = ? WHERE rowid = ?",
                    rowData.status,
                    rowData.statusText,
                    JSON.stringify(rowData.data, undefined, 2),
                    _stringify(rowData.feature),
                    rowData.snippet,
                    rowData.rowid);

        if (setUpdatedTimeStamp) {
            var timeStampUpdateResults = database.executeSql(
                        "UPDATE Surveys SET updated = ? WHERE rowid = ?",
                        rowData.updated.toISOString(),
                        rowData.rowid);
        }

        if (rowData.favorite) {
            updateFavorite(rowData);
        }

        updateModelRow(rowData);

        changed++;
    }

    //--------------------------------------------------------------------------

    function updateStatus(rowid, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        if (database.executeSql(
                    "UPDATE Surveys SET status = ?, statusText = ? WHERE rowid = ?",
                    status,
                    statusText,
                    rowid)) {

            updateModelRow({
                               "rowid": rowid,
                               "status": status,
                               "statusText": statusText
                           });

            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function updateDataStatus(rowid, data, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        if (database.executeSql(
                    "UPDATE Surveys SET data = ?, status = ?, statusText = ? WHERE rowid = ?",
                    JSON.stringify(data, undefined, 2),
                    status,
                    statusText,
                    rowid)) {
            updateModelRow({
                               "rowid": rowid,
                               "data": data,
                               "status": status,
                               "statusText": statusText
                           });

            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function updateModelRow(rowData) {
        var modelRow;
        var i;

        if (rowData.favorite) {
            for (i = 0; i < count; i++) {
                modelRow = get(i);
                if (modelRow.path === rowData.path) {

                    modelRow.favorite = modelRow.rowid === rowData.rowid ? 1 : 0;

                    set(i, modelRow);
                }
            }
        }

        for (i = 0; i < count; i++) {
            modelRow = get(i);
            if (modelRow.rowid === rowData.rowid) {
                modelRow.status = rowData.status;

                if (rowData.statusText) {
                    modelRow.statusText = rowData.statusText;
                }

                if (rowData.data) {
                    modelRow.data = rowData.data;
                }

                if (rowData.feature) {
                    modelRow.feature = rowData.feature;
                }

                set(i, modelRow);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateFavorite(rowData) {
        database.executeSql("UPDATE Surveys SET favorite = 0 WHERE path = ?", rowData.path);
        database.executeSql("UPDATE Surveys SET favorite = 1 WHERE rowid = ?", rowData.rowid);

        //console.log("updateFavorite", JSON.stringify(results, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function getFavorite(path) {

        var row = {};

        var query = database.executeSql(
                    'SELECT rowid, * FROM Surveys WHERE path = ? AND favorite > 0',
                    path);

        if (query && query.first()) {
            row = query.values;

            if (row.data > "") {
                row.data = JSON.parse(row.data);
            } else {
                row.data = null;
            }

            if (row.feature > "") {
                row.feature = JSON.parse(row.feature);
            } else {
                row.feature = null;
            }
        }

        //console.log("getFavorite", path, "row:", JSON.stringify(row, undefined, 2));

        return row;
    }

    //--------------------------------------------------------------------------

    function deleteSurvey(rowid) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE rowid = ?",
                    rowid)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveys(status) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE status = ? AND favorite = 0",
                    status)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveyBox(formname, status) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE name = ? AND status = ? AND favorite = 0",
                    formname,
                    status)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function deleteSurveyData(path) {
        if (database.executeSql(
                    "DELETE FROM Surveys WHERE path = ?",
                    path)) {
            changed++;
        }
    }

    //--------------------------------------------------------------------------

    function surveyCount(path) {
        var count = 0;

        var query = database.executeSql(
                    "SELECT COUNT(*) AS count FROM Surveys WHERE path = ?",
                    path);

        if (query && query.first()) {
            count = query.values.count;
        }

        return count;
    }

    //--------------------------------------------------------------------------

    function statusCount(path, status) {
        var count = 0;
        var query;

        if (path > "") {
            query = database.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE path = ? AND status = ?",
                                        path,
                                        status);
        } else {
            query = database.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE status = ?", status);
        }

        if (query && query.first()) {
            count = query.values.count;
        }

        return count;
    }

    //--------------------------------------------------------------------------

    function fixSurveysPath() {
        var jobs = [];

        var query = database.executeSql("SELECT rowid, * FROM Surveys");

        while (query.next()) {
            var row = query.values;

            var resolvedPath = Helper.resolveSurveyPath(row.path, surveysFolder);

            if ((resolvedPath !== null) && (row.path !== resolvedPath)) {
                var rowData = {
                    "path": resolvedPath,
                    "rowid": row.rowid
                };

                jobs.push(rowData);
            }
        }

        for (var i = 0; i < jobs.length; i++) {
            database.executeSql(
                        "UPDATE Surveys SET path = ? WHERE rowid = ?",
                        jobs[i].path,
                        jobs[i].rowid);
        }
    }

    //--------------------------------------------------------------------------

    function getSurvey(index) {
        return get(index);
    }

    //--------------------------------------------------------------------------

    function _stringify(value) {
        if (value === null) {
            return null;
        }

        return JSON.stringify(value, undefined, 2);
    }

    //--------------------------------------------------------------------------
}
