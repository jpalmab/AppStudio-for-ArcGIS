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

import "../Controls/Singletons"

Item {
    id: addIn

    //--------------------------------------------------------------------------

    property bool debug: true

    property alias path: addInFolder.path
    property alias folder: addInFolder
    property alias dataFolder: addInDataFolder

    property var addInInfo
    property var itemInfo
    property url itemUrl

    property string name
    property string title
    property string type: kTypeTool
    property url thumbnail: Icons.bigIcon("add-in")
    property url iconSource: Icons.icon("add-in")
    property bool iconMonochrome: true
    property url mainSource
    property string version

    //--------------------------------------------------------------------------

    readonly property string kTypeTool: "tool"
    readonly property string kTypeCamera: "camera"
    readonly property string kTypeControl: "control"
    readonly property string kTypeScanner: "scanner"

    //--------------------------------------------------------------------------

    property AddInConfig config

    readonly property string kConfigFile: "addin.config"

    //--------------------------------------------------------------------------

    property string settingsFile
    property Settings settings

    property url settingsPageSource
    readonly property bool hasSettingsPage: settingsPageSource > ""

    readonly property string kDefaultSettingsFile: "addin.settings"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        initialize()
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addIn, true)
    }

    //--------------------------------------------------------------------------
    // TODO get user folder from host app

    FileFolder {
        id: userFolder

        path: "~/ArcGIS/My Survey123"
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: addInFolder
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: addInDataFolder
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, arguments.callee.name);

        addInInfo = addInFolder.readJsonFile("addin.json");
        itemInfo = addInFolder.readJsonFile("iteminfo.json");

        console.log(logCategory, "addInInfo:", JSON.stringify(addInInfo, undefined, 2));

        mainSource = addInFolder.fileUrl(addInInfo.mainFile);

        title = itemInfo.title || "Untitled Add-In";
        thumbnail = addInFolder.fileUrl("thumbnail.png")

        if (addInInfo.icon) {
            var icon = addInInfo.icon;

            console.log(logCategory, "icon:", JSON.stringify(icon, undefined, 2))

            if (typeof icon === "string" && addInFolder.fileExists(icon)) {
                iconSource = addInFolder.fileUrl(icon);
            } else if (typeof icon === "object") {

                if (addInFolder.fileExists(icon.source)) {
                    iconSource = addInFolder.fileUrl(icon.source);
                }

                if (typeof icon.monochrome === "boolean") {
                    iconMonochrome = icon.monochrome;
                }
            }
        }

        if (itemInfo.id > "") {
            itemUrl = app.portal.portalUrl + "/home/item.html?id=%1".arg(itemInfo.id);
        }

        if (addInInfo.id > "") {
            name = addInInfo.id;
        } else if (itemInfo.id > "") {
            name = itemInfo.id;
        } else {
            console.error(logCategory, "Add-in id not defined for path:", addInFolder.path);
            name = "unnamed";
        }

        if (addInInfo.type > "") {
            type = addInInfo.type.trim();
        }

        console.error(logCategory, "type:", type, "name:", name, "folder:", addInFolder.path);

        initializeFolders();
        initializeConfig();
        initializeSettings();
    }

    //--------------------------------------------------------------------------

    function initializeFolders() {
        userFolder.makeFolder();

        addInDataFolder.path = userFolder.filePath("data/%1".arg(name));
        addInDataFolder.makeFolder();
    }

    //--------------------------------------------------------------------------

    function initializeConfig() {
        var settings = addInDataFolder.settingsFile(kConfigFile);

        var component = configComponent;

        switch (type) {
        case kTypeTool:
            component = toolConfigComponent
            break;
        }

        config = component.createObject(addIn,
                                        {
                                            addIn: addIn,
                                            settings: settings
                                        });

        console.log(logCategory, arguments.callee.name, "config:", config);
    }

    Component {
        id: configComponent

        AddInConfig {
        }
    }

    Component {
        id: toolConfigComponent

        AddInToolConfig {
        }
    }

    //--------------------------------------------------------------------------

    function initializeSettings() {
        if (addInInfo.settingsFile > "") {
            settingsFile = addInInfo.settingsFile;
        } else {
            settingsFile = kDefaultSettingsFile;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "name:", name, "settingsFile:", addInDataFolder.filePath(settingsFile));
        }

        settings = addInDataFolder.settingsFile(settingsFile);

        if (addInInfo.settingsPageFile > "" && addInFolder.fileExists(addInInfo.settingsPageFile)) {
            settingsPageSource = addInFolder.fileUrl(addInInfo.settingsPageFile);
        }
    }

    //--------------------------------------------------------------------------

    function toVersionString(version) {
        if (!version) {
            version = {};
        }
        if (!version.major) {
            version.major = 0;
        }
        if (!version.minor) {
            version.minor = 0;
        }
        if (!version.micro) {
            version.micro = 0;
        }

        return "%1.%2.%3".arg(version.major).arg(version.minor).arg(version.micro);
    }

    //--------------------------------------------------------------------------
}
