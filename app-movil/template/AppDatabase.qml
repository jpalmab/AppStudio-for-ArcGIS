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

Item {
    id: appDatabase

    //--------------------------------------------------------------------------

    property bool debug: true
    readonly property string databasePath: "~/ArcGIS/My Survey123/Survey123.sqlite"
    property string key: ""

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(appDatabase, true)
    }

    //--------------------------------------------------------------------------

    SqlDatabase {
        id: database

        driverName: "SQLITE"
    }

    //--------------------------------------------------------------------------

    function open() {
        console.log(logCategory, arguments.callee.name, "databasePath:", databasePath);

        if (database.isOpen) {
            return;
        }

        var fileInfo = AppFramework.fileInfo(databasePath);
        if (!fileInfo.folder.exists) {
            if (!fileInfo.folder.makeFolder()) {
                console.log(logCategory, "Error creating folder:", fileInfo.folder.path);
            }
        }

        database.databaseName = fileInfo.filePath;
        if (!database.open()) {
            console.error(logCategory, arguments.callee.name, "Error opening:", database.databaseName);
        }

        executeSql("PRAGMA textkey='%1'".arg(key));

        executeSql("CREATE TABLE IF NOT EXISTS Users(uid TEXT PRIMARY KEY, info TEXT, thumbnail BLOB)");
    }

    //--------------------------------------------------------------------------

    function executeSql(sql, ...values) {
        if (debug) {
            console.log(logCategory, "executeSql:", sql, "values:", JSON.stringify(values));
        }

        var query = database.query(sql, ...values);

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

    function writeUser(portal) {
        console.log(logCategory, arguments.callee.name, "username:", portal.username, "url:", portal.portalUrl);

        var uid = Qt.md5(portal.portalUrl + portal.username);

        console.log(logCategory, arguments.callee.name, "uid:", uid);

//        var imageObject = imageObjectComponent.createObject(appDatabase, {});
//        imageObject.load(portal.thumbnailUrl);

        executeSql("DELETE FROM Users WHERE uid=?", uid);
        executeSql("INSERT INTO Users(uid, info, thumbnail) VALUES (?,?,?)", uid, JSON.stringify(portal.info, undefined, 2), null);
    }

    Component {
        id: imageObjectComponent

        ImageObject {

        }
    }

    //--------------------------------------------------------------------------
}
