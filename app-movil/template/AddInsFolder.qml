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

import QtQuick 2.11

import ArcGIS.AppFramework 1.0

FileFolder {
    id: folder

    property var addIns: []

    //--------------------------------------------------------------------------

    Component.onCompleted: {
//        update();
    }

    //--------------------------------------------------------------------------

    onPathChanged: {
//        update();
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log("Refreshing add-ins:", path);

        var addIns = [];

        var files = fileNames("*", true);
        files.forEach(function(fileName) {
            var info = fileInfo(fileName);
            if (info.fileName === "addin.json") {
                var addInInfo = getAddInInfo(fileName);
                if (addInInfo) {
                    addInInfo.folderName = info.folder.folderName;
                    addInInfo.path = info.path;
                    addIns.push(addInInfo);

                    console.log("local addIn path:", addInInfo.path);
                }
            }
        });

        folder.addIns = addIns;

        console.log("Add-Ins found:", addIns.length);

        return addIns.length;
    }

    //--------------------------------------------------------------------------

    function getAddInInfo(fileName) {
        var addInInfo = folder.readJsonFile(fileName);

        console.log("addIn:", JSON.stringify(addInInfo, undefined, 2));

        if (!(addInInfo.type > "")) {
            addInInfo.type = "tool";
        }

        return addInInfo;
    }

    //--------------------------------------------------------------------------
}
