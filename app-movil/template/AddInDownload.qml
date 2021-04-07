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

import "../Portal"

Item {
    id: addInDownload

    property alias portal: addInItem.portal
    property ProgressPanel progressPanel
    property bool succeededPrompt: true
    property bool debug: false
    property FileFolder workFolder
    property AddInsFolder addInsFolder

    signal succeeded()
    signal failed(var error)

    //--------------------------------------------------------------------------

    function download(addInInfo) {
        progressPanel.open();

        var itemId = addInInfo.itemId;

        console.log("Download", itemId, addInInfo.title);

        workFolder.makeFolder();

        progressPanel.title = addInInfo.title;
        progressPanel.message = qsTr("Downloading");

        addInItem.itemId = itemId;
        addInItem.download(workFolder.filePath(itemId + ".zip"));
    }

    //--------------------------------------------------------------------------

    PortalItem {
        id: addInItem

        onDownloaded: {
            progressPanel.message = qsTr("Unpacking");

            console.log("Downloaded form package:", path);

            zipReader.path = path;
            var addInPath = addInsFolder.filePath(itemId);
            console.log("Unpacking addIn path:", addInPath);
            var result = zipReader.extractAll(addInPath);
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

            if (debug) {
                console.log("itemInfo:", JSON.stringify(itemInfo, undefined, 2));
            }

            var addInFolder = addInsFolder.folder(itemId);
            storeInfo(addInFolder);

            var thumbnailInfo = AppFramework.fileInfo(itemInfo.thumbnail);
            var thumbnailPath = addInFolder.filePath("thumbnail.%1".arg(thumbnailInfo.suffix));

            downloadThumbnail(thumbnailPath);
        }

        onThumbnailRequestComplete: {
            if (succeededPrompt) {
                progressPanel.closeSuccess(qsTr("%1 addIn download completed").arg(itemInfo.title));
            } else {
                progressPanel.close();
            }

            addInDownload.succeeded();
        }

        onProgressChanged: {
            progressPanel.progressBar.value = progress;
        }

        function storeInfo(folder) {
            folder.writeJsonFile("iteminfo.json", itemInfo);
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

            addInItem.requestInfo();
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
