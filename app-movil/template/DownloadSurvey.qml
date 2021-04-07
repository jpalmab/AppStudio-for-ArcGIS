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

import QtQml 2.12
import QtQuick 2.12

import ArcGIS.AppFramework 1.0

import "../Portal"

Item {
    id: downloadSurvey

    //--------------------------------------------------------------------------

    property alias portal: formItem.portal
    property ProgressPanel progressPanel
    property bool succeededPrompt: true
    readonly property alias itemInfo: formItem.itemInfo

    property bool debug: false

    //--------------------------------------------------------------------------

    signal succeeded()
    signal failed(var error)

    //--------------------------------------------------------------------------

    function download(itemInfo) {
        progressPanel.open();

        console.log(logCategory, arguments.callee.name, "id:", itemInfo.id, "title:", itemInfo.title);

        workFolder.makeFolder();

        progressPanel.title = itemInfo.title;
        progressPanel.message = qsTr("Downloading");

        formItem.itemId = itemInfo.id;
        formItem.isOrgItem = !!itemInfo.isOrgItem;
        formItem.download(workFolder.filePath(itemInfo.id + ".zip"));
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(downloadSurvey, true)
    }

    //--------------------------------------------------------------------------

    PortalItem {
        id: formItem

        property bool isOrgItem

        onDownloaded: {
            progressPanel.message = qsTr("Unpacking");

            console.log("Downloaded form package:", path);

            zipReader.path = path;
            var surveyPath = surveysFolder.filePath(itemId);
            var result = zipReader.extractAll(surveyPath);
            if (!result) {
                console.error("Error unpacking:", result, path);
                progressPanel.closeError("Error unpacking");
            }
        }

        onItemInfoChanged: {
            if (portal.hasOwnProperty("user") && portal.user !== null) {
                if (!itemInfo.orgId && itemInfo.owner === portal.user.username) {
                    console.info("Adding owner orgId to itemInfo");
                    itemInfo.orgId = portal.user.orgId;
                }
            }

            itemInfo.isOrgItem = isOrgItem;
            if ((portal.isPortal || isOrgItem) && !itemInfo.orgId) {
                itemInfo.orgId = portal.user.orgId;
            }

            if (debug) {
                console.log(logCategory, "itemInfo:", JSON.stringify(itemInfo, undefined, 2));
            }

            var error = storeInfo(surveysFolder.folder(itemId));
            if (error > "") {
                progressPanel.closeError(error);
            }
        }

        onThumbnailRequestComplete: {
            if (succeededPrompt) {
                progressPanel.closeSuccess(qsTr("%1 survey download completed").arg(itemInfo.title));
            }
            else {
                progressPanel.close();
            }
            downloadSurvey.succeeded();
        }

        onProgressChanged: {
            progressPanel.progressBar.value = progress;
        }

        function storeInfo(folder) {
            var formInfoFile = "forminfo.json";

            if (!folder.fileExists(formInfoFile)) {
                if (folder.fileExists("esriinfo/" + formInfoFile)) {
                    folder = folder.folder("esriinfo");
                } else {
                    console.log(formInfoFile, "not found in:", folder.path);
                    return qsTr("%1 not found").arg(folder.filePath(formInfoFile));
                }
            }

            var formInfo = folder.readJsonFile(formInfoFile);
            if (!formInfo.name) {
                console.log("Error reading:", formInfoFile, "json:", JSON.stringify(formInfo))
                return qsTr("Error reading %1").arg(formInfoFile);
            }

            folder.writeJsonFile(formInfo.name + ".itemInfo", itemInfo);

            if (!folder.fileExists(".nomedia") && Qt.platform.os === "android"){
                folder.writeFile(".nomedia", "");
            }

            getThumbnailFromServer(folder);

            //folder.writeJsonFile(formInfo.name + ".portalInfo", portal.info);
            //folder.writeJsonFile(formInfo.name + ".userInfo", portal.user);
        }

        function getThumbnailFromServer(folder){
            downloadSurveyThumbnail(folder.path);
            progressPanel.message = qsTr("Downloading thumbnail");
        }
    }

    //--------------------------------------------------------------------------

    ZipReader {
        id: zipReader

        onCompleted: {
            close();

            if (workFolder.removeFile(path)) {
                console.log("Deleted:", path);
            } else {
                //progressPanel.closeError("Delete package error");
                console.error("Error deleting:", path);
            }

            formItem.requestInfo();
        }

        onError: {
            progressPanel.closeError(qsTr("Unpack error"));
        }

        onProgress: {
            progressPanel.progressBar.value = percent / 100;
        }
    }

    //--------------------------------------------------------------------------
}
