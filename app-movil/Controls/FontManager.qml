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
    id: fontManager

    //--------------------------------------------------------------------------

    property alias folder: fontsFolder
    property var families: []

    property bool debug: false

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(fontManager, true)
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: fontsFolder

        url: "fonts"
    }

    //--------------------------------------------------------------------------

    function loadFonts() {
        if (!folder.exists) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "Non-existent path:", fontsFolder.url);
            }
            return;
        }

        console.log(logCategory, arguments.callee.name, "url:", fontsFolder.url);

        var fileNames = folder.fileNames("*.ttf");

        fileNames.forEach(loadFont);
    }

    //--------------------------------------------------------------------------

    function loadFont(fileName) {
        console.log(logCategory, arguments.callee.name, "fileName:", fileName);

        var loader = fontLoader.createObject(fontManager,
                                             {
                                                 fileName: fileName
                                             });
    }

    //--------------------------------------------------------------------------

    function addFamily(family) {
        if (families.indexOf(family) < 0) {
            families.push(family);

            console.log(logCategory, arguments.callee.name, "family:", family);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: fontLoader

        FontLoader {
            property string fileName

            source: fontsFolder.fileUrl(fileName)

            onStatusChanged: {
                if (debug) {
                    console.log(logCategory, "status:", status, "source:", source);
                }

                if (status === FontLoader.Ready) {
                    addFamily(name);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
