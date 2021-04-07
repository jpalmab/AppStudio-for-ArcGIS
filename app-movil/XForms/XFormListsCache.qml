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

    //--------------------------------------------------------------------------

    property alias dataFolder: dataFolder
    readonly property int kSchemaVersion: 1

    property alias database: database

    //--------------------------------------------------------------------------

    FileFolder {
        id: dataFolder
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (database.isOpen) {
            return;
        }

        var filePath = dataFolder.filePath("lists.sqlite");

        console.log("Initializing lists cache:", filePath);

        database.databaseName = filePath;
        database.open();

        database.initializeProperties();
    }

    //--------------------------------------------------------------------------

    function loadTable(sourceFileInfo, targetTableName, where) {

        console.log("Loading list table:", targetTableName, "source:", sourceFileInfo.filePath);

        var lastModifiedProperty = "%1_lastModified".arg(targetTableName);
        var versionProperty = "%1_version".arg(targetTableName);

        var lastModified = Number(database.queryProperty(lastModifiedProperty));
        var version = Number(database.queryProperty(versionProperty, 0));

        console.log("source lastModified:", fileInfo.lastModified.valueOf(), "kSchemaVersion:", kSchemaVersion);
        console.log("target lastModified:", lastModified, "version:", version);

        if (sourceFileInfo.lastModified.valueOf() === lastModified.valueOf() && kSchemaVersion === version) {
            console.log("List table is current:", targetTableName);
            return true;
        }

        var sourceTableName = targetTableName + "_CSV";

        var commands = [];

        commands.push("DROP TABLE IF EXISTS \"%1\";".arg(sourceTableName));
        commands.push("CREATE VIRTUAL TABLE IF NOT EXISTS \"%1\" USING CSV('%2');"
                      .arg(sourceTableName)
                      .arg(sourceFileInfo.filePath));
        commands.push("DROP TABLE IF EXISTS \"%1\";".arg(targetTableName));
        commands.push("CREATE TABLE IF NOT EXISTS \"%1\" AS SELECT * FROM \"%2\" %3;"
                      .arg(targetTableName)
                      .arg(sourceTableName)
                      .arg(where || ""));
        commands.push("DROP TABLE \"%1\";".arg(sourceTableName));

        database.batchExecute(commands, true);

        database.updateProperty(lastModifiedProperty, sourceFileInfo.lastModified.valueOf(), Qt.formatDateTime(sourceFileInfo.lastModified, Qt.ISODate));
        database.updateProperty(versionProperty, kSchemaVersion, "Schema version %1".arg(kSchemaVersion));
    }

    //--------------------------------------------------------------------------
    
    XFormSqlDatabase {
        id: database
    }

    //--------------------------------------------------------------------------
}
