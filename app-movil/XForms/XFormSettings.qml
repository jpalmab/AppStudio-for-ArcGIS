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
    id: object

    //--------------------------------------------------------------------------

    property Settings settings
    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kKeyMap: "map"

    //--------------------------------------------------------------------------

    function initialize(folder, baseName) {
        console.log(arguments.callee.name, "folder:", folder.path, "baseName:", baseName);

        object.settings = folder.settingsFile(baseName + ".settings");

        read();
    }

    //--------------------------------------------------------------------------

    function read() {
    }

    //--------------------------------------------------------------------------

    function mapKey(key) {
        return key > ""
                ? kKeyMap + "/" + key
                : kKeyMap;
    }

    //--------------------------------------------------------------------------

    function mapName(key, defaultValue) {
        if (!defaultValue) {
            defaultValue = "";
        }

        var name = settings.value(mapKey(key), defaultValue);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "name:", name);
        }

        return name;
    }

    //--------------------------------------------------------------------------

    function setMapName(key, name, defaultValue) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "name:", name, "defaultValue:", defaultValue);
        }

        settings.setValue(mapKey(key), name, defaultValue);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(object, true)
    }

    //--------------------------------------------------------------------------

}
