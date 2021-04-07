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
import ArcGIS.AppFramework.Sql 1.0


SqlDatabase {
    id: sqlDatabase

    //--------------------------------------------------------------------------

    readonly property string kTableProperties: "_properties_"

    readonly property string kColumnName: "name"
    readonly property string kColumnValue: "value"
    readonly property string kColumnDescription: "description"

    property bool debug: false

    //--------------------------------------------------------------------------

    driverName: "SQLITE"

    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        id: loggingCategory

        name: AppFramework.typeOf(sqlDatabase, true)
    }

    //--------------------------------------------------------------------------

    function executeSql(sql, ...values) {
        if (debug) {
            console.log(logCategory, "executeSql:", sql, "values:", JSON.stringify(values));
        }

        var query = sqlDatabase.query(sql, ...values);

        if (query.error) {
            console.error(logCategory, "executeSql error:", query.error.toString(), "sql:", sql, "values:", JSON.stringify(values));
            return;
        }

        if (debug) {
            console.log(logCategory, "executeSql rowsAffected:", query.rowsAffected, "count:", query.count, "insertId:", query.insertId);
        }

        return query;
    }

    //--------------------------------------------------------------------------

    function batchExecute(sqlCommands, transaction) {
        if (!Array.isArray(sqlCommands)) {
            return;
        }

        if (sqlCommands.length < 1) {
            return;
        }

        if (transaction) {
            sqlCommands.unshift("BEGIN TRANSACTION;");
            sqlCommands.push("COMMIT;");
        }

        var errorCount = 0;
        var successCount = 0;

        sqlCommands.forEach(function (sql) {
            sql = sql.trim();
            if (!sql.length) {
                return;
            }

            if (sql.substring(0, 2) === "--") {
                return;
            }

            console.log(logCategory, "sql:", sql);

            var query = sqlDatabase.query(sql);

            if (query.error) {
                // console.log(logCategory, "Command sql:", sql);
                console.log(logCategory, "Command error:", query.error.toString());
                errorCount++;
            } else {
                //console.log(logCategory, "Command succeeded");
                successCount++;
            }
        });

        console.log(logCategory, successCount, "commmands succeeded");
        console.log(logCategory, errorCount, "commands failed");
    }

    //--------------------------------------------------------------------------

    function loadFile(url) {
        var fileInfo = AppFramework.fileInfo(url);
        if (!fileInfo.exists) {
            console.error(logCategory, "File not found:", url);
            return;
        }

        return fileInfo.folder.readTextFile(fileInfo.fileName);
    }

    //--------------------------------------------------------------------------

    function loadSqlCommands(url) {
        var text = loadFile(url);

        return splitSqlCommands(text);
    }

    //--------------------------------------------------------------------------

    function splitSqlCommands(text, eol) {
        if (!eol) {
            eol = ";";
        }

        var sqlCommands = text.split(eol);

        if (debug) {
            console.log(logCategory, "SQL commands:", sqlCommands.length);
        }

        return sqlCommands;
    }

    //--------------------------------------------------------------------------

    function initializeProperties() {
        var commands = [];

        commands.push("PRAGMA foreign_keys = ON;");

        commands.push("CREATE TABLE IF NOT EXISTS \"%1\" (\"%2\" TEXT, \"%3\" TEXT, \"%4\" TEXT, PRIMARY KEY(\"%2\"));"
                      .arg(kTableProperties)
                      .arg(kColumnName)
                      .arg(kColumnValue)
                      .arg(kColumnDescription));

        sqlDatabase.batchExecute(commands, true);
    }

    //--------------------------------------------------------------------------

    function queryProperty(name, defaultValue) {
        var query = sqlDatabase.query("SELECT \"%1\" FROM \"%2\" WHERE \"%3\" = ?"
                                      .arg(kColumnValue)
                                      .arg(kTableProperties)
                                      .arg(kColumnName),
                                      name);
        if (!query) {
            console.log("Null property query");
            return defaultValue;
        }

        if (query.error) {
            console.log("Invalid property query:", query.error.toString());
            return defaultValue;
        }

        var value = defaultValue;
        if (query.first()) {
            value = query.value(0);
        }
        query.finish();

        if (debug) {
            console.log("query property name:", name, "value:", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function updateProperty(name, value, description) {
        var query = sqlDatabase.query("INSERT OR REPLACE INTO \"%1\" (\"%2\", \"%3\", \"%4\") VALUES (?, ?, ?)"
                                      .arg(kTableProperties)
                                      .arg(kColumnName)
                                      .arg(kColumnValue)
                                      .arg(kColumnDescription),
                                      name,
                                      value,
                                      description);

        if (!query) {
            console.log(logCategory, "Null property update");
            return;
        }

        if (query.error) {
            console.log(logCategory, "Invalid property update:", query.error.toString());
            return;
        }
        query.finish();


        if (debug) {
            console.log(logCategory, "update property name:", name, "value:", value, "descriptin:", description);
        }
    }

    //--------------------------------------------------------------------------
}
