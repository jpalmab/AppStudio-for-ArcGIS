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

import "../template/SurveyHelper.js" as Helper
import "../Models"
import "../Portal"
import "../XForms/XForm.js" as XFormJS

SortedListModel {
    id: addInsModel

    //--------------------------------------------------------------------------

    property AddInsFolder addInsFolder
    property bool showSurveysTile: false
    property url surveysTileThumbnail: "images/gallery-thumbnail.png"
    property string type: ""
    property string mode: ""
    property bool includeDisabled: false
    property bool includeInternal: true

    //--------------------------------------------------------------------------

    readonly property string kTypeTool: "tool"
    readonly property string kTypeCamera: "camera"
    readonly property string kTypeControl: "control"

    readonly property string kToolModeTile: "tile"
    readonly property string kToolModeTab: "tab"
    readonly property string kToolModeService: "service"
    readonly property string kToolModeHidden: "hidden"

    //--------------------------------------------------------------------------

    signal updated();

    //--------------------------------------------------------------------------

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    property Component addInComponent: AddIn {}

    //--------------------------------------------------------------------------

    sortProperty: kPropertyTitle
    sortOrder: "asc"
    sortCaseSensitivity: Qt.CaseInsensitive

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    onShowSurveysTileChanged: {
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        name: AppFramework.typeOf(addInsModel, true)
    }

    //--------------------------------------------------------------------------

    readonly property Connections _connections: Connections {
        target: addInsFolder

        onAddInsChanged: {
            Qt.callLater(addInsModel.update);
        }
    }

    //--------------------------------------------------------------------------

    readonly property AddInsFolder internalAddInsFolder: AddInsFolder {
        path: app.folder.filePath("Add-Ins");

        onPathChanged: {
            update();
        }
    }

    //--------------------------------------------------------------------------

    function update(updateFolder) {
        if (updateFolder) {
            addInsFolder.update();
        }

        updateLocal();
        updated();
    }

    //--------------------------------------------------------------------------

    function updateLocal() {
        console.log(logCategory, "Updating add-ins model");

        clear();

        if (showSurveysTile && type === kTypeTool && mode === kToolModeTile) {
            var addInItem = {
                itemId: -1,
                itemUrl: "",
                path: "",
                folderName: "",
                title: qsTr("My Surveys"),
                description: "",
                appearanceAlias: "",
                thumbnail: surveysTileThumbnail,
                icon: "",
                modified: 0,
                owner: "",
                updateAvailable: false,
                internal: true
            }

            append(addInItem);
        }

        if (includeInternal) {
            appendFolder(internalAddInsFolder, true);
        }

        appendFolder(addInsFolder, false);

        sort();

        console.log(logCategory, "Updated add-ins model count:", count, "type:", type, "mode:", mode);
    }

    //--------------------------------------------------------------------------

    function appendFolder(addInsFolder, internal) {
        console.log(logCategory, "Adding from path:", addInsFolder.path, "count:", addInsFolder.addIns.length);

        addInsFolder.addIns.forEach(function (addInInfo) {
            if (type > "" && addInInfo.type !== type) {
                return;
            }

            var addIn = addInComponent.createObject(null,
                                                    {
                                                        path: addInInfo.path
                                                    });

            var config = addIn.config;

            //console.log(logCategory, "enabled:", addIn.config.enabled, "includeDisabled:", includeDisabled);

            if (!config.enabled && !includeDisabled) {
                return;
            }

            if (mode > "" && addIn.config.mode !== mode) {
                return;
            }

            var addInFolder = addIn.folder;
            var itemInfo = addIn.itemInfo;
            var thumbnail = Helper.findThumbnail(addInFolder, "thumbnail", "images/addIn-thumbnail.png");
            var icon = addInFolder.fileUrl("icon.png");

            var addInItem = {
                itemId: itemInfo.id || "",
                itemUrl: addIn.itemUrl,
                path: addInInfo.path,
                folderName: addInInfo.folderName,
                title: addIn.title,
                description:  itemInfo.description || "",
                appearanceAlias: addInInfo.appearanceAlias,
                thumbnail: thumbnail,
                icon: icon,
                modified: itemInfo.modified,
                owner: itemInfo.owner || "",
                updateAvailable: false,
                enabled: config.enabled,
                internal: internal
            }

            append(addInItem);

            //console.log("addInItem:", JSON.stringify(addInItem, undefined, 2));
        });
    }

    //--------------------------------------------------------------------------

    function appendItem(itemInfo) {
        var itemId = itemInfo.id;

        for (var i = 0; i < count; i++) {
            var item = get(i);
            if (item.itemId === itemId) {
                var updated = itemInfo.modified > item.modified;
                setProperty(i, "updateAvailable", updated);
                return;
            }
        }

        var addInItem = {
            itemId: itemId,
            itemUrl: app.portal.portalUrl + "/home/item.html?id=%1".arg(itemId),
            path: "",
            title: itemInfo.title,
            description: itemInfo.description,
            thumbnail: itemInfo.thumbnail,
            modified: itemInfo.modified,
            owner: itemInfo.owner,
            updateAvailable: true,
            enabled: true,
            internal: false
        };

        append(addInItem);
    }

    //--------------------------------------------------------------------------

    function updateItem(index, addIn) {
        console.log(logCategory, arguments.callee.name, "index:", index);

        var config = addIn.config;

        setProperty(index, "enabled", config.enabled);
    }

    //--------------------------------------------------------------------------

    function run(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function edit(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function upload(addInInfo) {

    }

    //--------------------------------------------------------------------------
}
