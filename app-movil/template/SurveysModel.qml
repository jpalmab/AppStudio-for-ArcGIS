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

import "../XForms"
import "../template/SurveyHelper.js" as Helper
import "../Models"

SortedListModel {
    id: surveysModel

    //--------------------------------------------------------------------------

    property bool debug: false

    property bool enabled: true

    property bool newSurvey: false
    property string newKey: "*NEW*"
    property string newName: qsTr("New Survey")
    property string newThumbnail: "images/new-thumbnail.png"

    property int skipCount: 0

    property XFormsFolder formsFolder
    property int updatesAvailable

    //--------------------------------------------------------------------------

    property var uniqueTags: []

    readonly property string kTagSeparator: "^"

    //--------------------------------------------------------------------------

    signal updated()
    signal refreshed()

    //--------------------------------------------------------------------------

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    sortProperty: kPropertyTitle
    sortOrder: "asc"
    sortCaseSensitivity: Qt.CaseInsensitive

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        update();
    }

    //--------------------------------------------------------------------------

    readonly property Connections _connections: Connections {
        target: formsFolder

        onFormsChanged: {
            surveysModel.update();
        }
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveysModel, true)
    }

    //--------------------------------------------------------------------------

    function update(forceClear) {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        console.time(arguments.callee.name);

        if (forceClear) {
            clear();
            skipCount = 0;
        } else {
            for (var i = 0; i < count; i++) {
                if (get(i).status === 0) {
                    setProperty(i, "status", 1);
                }
            }
        }

        uniqueTags = [];

        if (!enabled) {
            return;
        }

        if (newSurvey && count == 0) {
            append({
                       survey: newKey,
                       name: newName,
                       title: newName,
                       description: "",
                       path: "",
                       thumbnail: newThumbnail,
                       modified: 0,
                       owner: "",
                       access: "",
                       updateAvailable: false,
                       size: 0,
                       status: -1
                   });

            skipCount++;
        }

        formsFolder.forms.forEach(updateSurvey);

        updatesAvailable = 0;
        for (i = count - 1; i >= 0; i--) {
            var item = get(i);
            if (item.status === 1) {
                remove(i);
            } else if (item.updateAvailable) {
                updatesAvailable++;
            }
        }

        sortItems();

        uniqueTags.sort(function (a, b) {
            return a.toLowerCase().localeCompare(b.toLowerCase());
        });
        surveysModel.uniqueTags = uniqueTags;

        console.timeEnd(arguments.callee.name);
        console.log(logCategory, arguments.callee.name, "count:", count, "uniqueTags:", JSON.stringify(uniqueTags, undefined, 2));

        updated();
    }

    //--------------------------------------------------------------------------

    function updateSurvey (survey) {

        var fileInfo = formsFolder.fileInfo(survey);
        var name = fileInfo.baseName;
        var itemInfo = fileInfo.folder.readJsonFile(name + ".itemInfo");

        var thumbnail = Helper.findThumbnail(fileInfo.folder, name, "images/form-thumbnail.png", itemInfo.thumbnail);
        var upgradeRequired = !fileInfo.folder.fileExists("forminfo.json");

        var title = itemInfo.title > "" ? itemInfo.title : name;
        var published = itemInfo.id > "";
        var description = itemInfo.description > "" ? itemInfo.description : "";
        var itemId = itemInfo.id > "" ? itemInfo.id : "";
        var owner = itemInfo.owner > "" ? itemInfo.owner : "";
        var tags = Array.isArray(itemInfo.tags) ? itemInfo.tags : []
        var modified = itemInfo.modified > 0 ? itemInfo.modified : 0
        var access = itemInfo.access || "";

        var surveyItem = {
            itemId: itemId,
            survey: survey,
            title: title,
            description: description,
            name: name,
            path: fileInfo.filePath,
            folderPath: fileInfo.folder.path,
            folderUrl: fileInfo.folder.url,
            thumbnail: thumbnail,
            upgradeRequired: upgradeRequired,
            published: published,
            modified: fileInfo.lastModified.valueOf(),
            itemModified: modified,
            owner: owner,
            access: access,
            tags: tags.join(kTagSeparator).toUpperCase(),
            updateAvailable: false,
            size: 0,
            status: 0
        }

        updateItem(surveyItem, itemInfo.tags);
    }

    //--------------------------------------------------------------------------

    function updateItem(surveyItem, tags) {
        if (debug) {
        //console.log("surveyItem:", JSON.stringify(surveyItem, undefined, 2));
        //console.log("surveyItem.modified:", surveyItem.modified);
        }

        var index = findByKeyValue("survey", surveyItem.survey);
        if (index >= 0) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "index:", index, "survey:", surveyItem.survey);
            }

            var item = get(index);

            if (surveyItem.itemModified > item.itemModified) {
                item.updateAvailable = false;
            }

            item.itemId = surveyItem.itemId;
            item.thumbnail = surveyItem.thumbnail;
            item.title = surveyItem.title;
            item.description = surveyItem.description;
            item.owner = surveyItem.owner;
            item.access = surveyItem.access;
            item.tags = surveyItem.tags;
            item.modified = surveyItem.modified;
            item.itemModified = surveyItem.itemModified;
            item.published = surveyItem.published;
            item.status = surveyItem.status;

            set(index, item);
        } else {
            append(surveyItem);
        }

        addTags(uniqueTags, tags);
    }

    //--------------------------------------------------------------------------

    function sortItems() {
        //console.log("Sort:", count, "skip:", skipCount, "sortProperty:", sortProperty, "sortOrder:", sortOrder, "sortCaseSensitivity:", sortCaseSensitivity);
        sort(skipCount);
    }

    //--------------------------------------------------------------------------

    function addTags(uniqueTags, tags) {
        if (!Array.isArray(tags)) {
            return;
        }

        for (const tag of tags) {
            if (uniqueTags.findIndex(uniqueTag => tag.toUpperCase() === uniqueTag.toUpperCase()) < 0) {
                uniqueTags.push(tag);
            }
        }
    }

    //--------------------------------------------------------------------------

    function refreshItem(itemId) {
        console.log(logCategory, arguments.callee.name, "itemId:", itemId);

        var index = findByKeyValue("itemId", itemId);
        if (index < 0) {
            console.error(logCategory, "Item not found:", itemId);
            return;
        }

        var item = get(index);

        var fileInfo = formsFolder.fileInfo(item.survey);
        var name = fileInfo.baseName;
        var itemInfo = fileInfo.folder.readJsonFile(name + ".itemInfo");

        item.thumbnail = Helper.findThumbnail(fileInfo.folder, name, "images/form-thumbnail.png", itemInfo.thumbnail);
        item.title = itemInfo.title > "" ? itemInfo.title : name;
        item.description = itemInfo.description > "" ? itemInfo.description : "";
        item.owner = itemInfo.owner > "" ? itemInfo.owner : "";
        item.modified = itemInfo.modified > 0 ? itemInfo.modified : 0
        item.updateAvailable = false;
        item.size = 0;

        set(index, item);
    }

    //--------------------------------------------------------------------------

    function updateUpdatesAvailable() {
        updatesAvailable = 0;
        for (var i = 0; i < count; i++) {
            if (get(i).updateAvailable) {
                updatesAvailable++;
            }
        }
    }

    //--------------------------------------------------------------------------
    // TODO Hack

    readonly property Connections _appConnections: Connections {
        target: app

        onBroadcastSurveyUpdate: {
            refreshItem(id);
            updateUpdatesAvailable();
            refreshed();
        }
    }

    //--------------------------------------------------------------------------
}
