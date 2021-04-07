/* Copyright 2015 Esri
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

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Item {
    id: pictureChooser

    property string title: qsTr("Pictures")
    property FileFolder outputFolder
    property string outputPrefix: "image"
    property bool copyToOutputFolder: true
    property bool useFileDialog: Qt.platform.os != "android" //Qt.platform.os == "ios" //

    property url pictureUrl

    signal accepted()
    signal rejected()

    //--------------------------------------------------------------------------

    QtObject {
        id: internal

        property var uiComponent
    }

    //--------------------------------------------------------------------------

    Component {
        id: fileDialogComponent

        FileDialog {
            title: pictureChooser.title

            folder: Qt.platform.os == "ios"
                    ? "file:assets-library://"
                    : AppFramework.resolvedPathUrl(AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0])

            nameFilters: ["Image files (*.jpg *.png *.gif *.jpeg *.tif *.tiff)", "All files (*)"]

            onAccepted: {
                pictureUrl = fileUrl;
                pictureChooser.accepted();
            }

            onRejected: {
                pictureChooser.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: pictureChooserComponent

        XFormPictureChooserAndroid {
            id: androidPictureChooser

            onRejected: {
                pictureChooser.rejected();
                xform.popoverStackView.pop();
            }

            onAccepted: {
                pictureChooser.pictureUrl = fileUrl;
                pictureChooser.accepted();
                xform.popoverStackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    //--------------------------------------------------------------------------

    onAccepted: {
        internal.uiComponent = null;

        var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
        var picturePath = pictureUrlInfo.localFile;
        var assetInfo = AppFramework.urlInfo(picturePath);

        var outputFileName;

        var suffix = AppFramework.fileInfo(picturePath).suffix;
        var a = suffix.match(/&ext=(.+)/);
        if (Array.isArray(a) && a.length > 1) {
            suffix = a[1];
        }

        if (assetInfo.scheme === "assets-library") {
            pictureUrl = assetInfo.url;
        }

        outputFileName = imagePrefix + "-" + AppFramework.createUuidString(2) + "." + suffix;

        if (copyToOutputFolder) {
            var outputFileInfo = outputFolder.fileInfo(outputFileName);
            var copied = false;

            if (outputFileName.match(/\.hei(c|f)$/i)) {
                var copyParameters = {
                    "picturePath": picturePath,
                    "outputFileName": outputFileName
                };

                copied = imageObjectCopy(copyParameters);

                if (copied) {
                    outputFileName = copyParameters.outputFileName;
                }
            }

            if (!copied) {
                outputFolder.removeFile(outputFileName);
                outputFolder.copyFile(picturePath, outputFileInfo.filePath);
            }

            pictureUrl = outputFolder.fileUrl(outputFileName);
        }
    }

    onRejected: {
        internal.uiComponent = null;
    }

    //--------------------------------------------------------------------------

    function open() {
        if (useFileDialog) {
            internal.uiComponent = fileDialogComponent.createObject(pictureChooser.parent);
            internal.uiComponent.open();
        } else {
            xform.popoverStackView.push({
                                            item: pictureChooserComponent
                                        });
        }
    }

    //--------------------------------------------------------------------------

    function close() {
        if (internal.uiComponent) {
            internal.uiComponent.close();
            internal.uiComponent = null;
        }
    }

    //--------------------------------------------------------------------------

    function imageObjectCopy(copyParameters) {
        if (!imageObject.load(copyParameters.picturePath)) {
            console.error("Unable to load image:", copyParameters.picturePath);
            return false;
        }

        copyParameters.outputFileName = copyParameters.outputFileName.replace(/\.[a-z]*$/i, ".jpg");

        var outputFileInfo = outputFolder.fileInfo(copyParameters.outputFileName);

        outputFolder.removeFile(copyParameters.outputFileName);

        if (!imageObject.save(outputFileInfo.filePath)) {
            console.error("Unable to save image:", outputFileInfo.filePath);
            return false;
        }

        return true;
    }

    //--------------------------------------------------------------------------
}

