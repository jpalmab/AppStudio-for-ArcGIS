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
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls/Singletons"

XFormGroupBox {
    id: imageControl

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var mediatype

    property FileFolder imagesFolder: xform.attachmentsFolder
    property alias imagePath: imageFileInfo.filePath
    property url imageUrl
    property string imagePrefix: "Image"

    readonly property var appearance: formElement ? formElement["@appearance"] : null
    readonly property bool canAnnotate: XFormJS.contains(appearance, "annotate")
    readonly property bool canDraw: XFormJS.contains(appearance, "draw")
    readonly property bool canDrawOrAnnotate: canDraw || canAnnotate

    property Component externalCameraPage: cameraAddInName > ""
                                           ? addInCameraPage
                                           : spikeCameraPage

    property string cameraAddInName
    readonly property bool isSpikeAppearance: XFormJS.contains(appearance, "spike")
                                              || XFormJS.contains(appearance, "spike-full-measure")
                                              || XFormJS.contains(appearance, "spike-point-to-point")
    property url externalCameraIcon: cameraAddInName > ""
                                     ? xform.addIns.icon(cameraAddInName)
                                     : "images/spike-icon.png"

    readonly property bool useExternalCamera: cameraAddInName > "" || isSpikeAppearance

    property bool editing: false
    readonly property bool readOnly: !enabled || binding.isReadOnly || editing
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    readonly property int buttonSize: xform.style.buttonBarSize

    property var calculatedValue
    property var defaultValue
    property url defaultImageUrl

    property real previewHeight: xform.style.imagePreviewHeight

    property bool debug: true//false

    property int maximumWatermarkedImageResolution: 1920 // iOS Only

    //--------------------------------------------------------------------------

    readonly property url kIconCamera: Icons.icon("camera")
    readonly property url kIconPencil: Icons.icon("pencil", true)
    readonly property url kIconFolder: Icons.icon("folder")
    readonly property url kIconRotate: Icons.icon("rotate")
    readonly property url kIconTrash: Icons.icon("trash")
    readonly property url kIconAnnotate: Icons.icon("annotate", true)

    //--------------------------------------------------------------------------

    readonly property string kPropertyPreviewHeight: "previewHeight"
    readonly property string kPropertyAddIn: "addIn"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        imagePrefix = binding.nodeset;
        var i = imagePrefix.lastIndexOf("/");
        if (i >= 0) {
            imagePrefix = imagePrefix.substr(i + 1);
        }

        console.log(logCategory, "image prefix:", imagePrefix);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(imageControl, true)
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement) {
            //console.log(logCategory, "onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setDefaultValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        width: parent.width

        Image {
            id: imagePreview

            Layout.preferredWidth: parent.width
            Layout.maximumHeight: previewHeight > 0
                                  ? previewHeight
                                  : Number.POSITIVE_INFINITY

            autoTransform: true
            width: parent.width
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            source: imageUrl
            cache: false
            smooth: false
            asynchronous: true
            sourceSize {
                width: imagePreview.width
                height: Layout.maximumHeight
            }

            visible: source > ""

            Rectangle {
                anchors.centerIn: parent

                width: parent.paintedWidth
                height: parent.paintedHeight

                border {
                    width: 1
                    color: "darkgrey"
                }
                color: "transparent"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (canDrawOrAnnotate && !imageControl.readOnly) {
                        drawButton.clicked(mouse);
                    } else {
                        xform.popoverStackView.push({
                                                        item: previewPage,
                                                        properties: {
                                                            imageUrl: imageControl.imageUrl,
                                                        }
                                                    });
                    }
                }

                onPressAndHold: {
                    sourceText.visible = !sourceText.visible;
                }
            }

            function refresh() {
                var url = imageUrl;
                imageUrl = "";
                imageUrl = url;
            }
        }

        XFormFileRenameControl {
            Layout.fillWidth: true

            visible: imageUrl > ""
            fileName: imageFileInfo.fileName
            fileFolder: imagesFolder
            readOnly: imageControl.readOnly

            onRenamed: {
                imagePath = imagesFolder.filePath(newFileName);
                imageUrl = imagesFolder.fileUrl(newFileName);
                updateValue();
            }
        }

        XFormButtonBar {
            Layout.alignment: Qt.AlignHCenter

            visible: !readOnly
            spacing: xform.style.buttonBarSize / 2
            leftPadding: visibleItemsCount > 1 ? spacing : padding
            rightPadding: leftPadding

            XFormImageButton {
                id: drawButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize
                Layout.alignment: Qt.AlignHCenter

                source: canAnnotate ? kIconAnnotate : kIconPencil
                visible: canDrawOrAnnotate && !imagePreview.visible && !readOnly

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: sketchPage,
                                                    properties: {
                                                        imageUrl: imageControl.imageUrl,
                                                        annotate: canAnnotate
                                                    }
                                                });
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconPencil
                visible: canAnnotate && imageUrl > "" && false

                onClicked: {
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: !canDrawOrAnnotate && QtMultimedia.availableCameras.length > 0
                source: useExternalCamera ? externalCameraIcon : kIconCamera
                color: useExternalCamera ? "transparent" : xform.style.iconColor

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: useExternalCamera ? externalCameraPage : cameraPage,
                                                    properties: {
                                                    }
                                                });
                }

                onPressAndHold: {
                    if (cameraAddInName > "") {
                        xform.popoverStackView.push({
                                                        item: addInSettingsPage,
                                                        properties: {
                                                        }
                                                    });
                    }
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconFolder
                visible: !canDrawOrAnnotate

                onClicked: {
                    pictureChooser.open();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: imageUrl > "" && !canDrawOrAnnotate
                source: kIconRotate
                mirror: true

                onClicked: {
                    rotateImage(imagePath, -90);
                    imagePreview.refresh();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: imageUrl > "" && !canDrawOrAnnotate
                source: kIconRotate

                onClicked: {
                    rotateImage(imagePath, 90);
                    imagePreview.refresh();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconTrash
                visible: !imageControl.readOnly && imagePreview.visible

                onClicked: {
                    var name = imagesFolder.fileInfo(imagePath).fileName;

                    var panel = confirmPanel.createObject(app, {
                                                              title: qsTr("Confirm Image Delete"),
                                                              question: qsTr("Are you sure you want to delete %1?").arg(name)
                                                          });

                    panel.show(deleteImage, undefined);
                }

                function deleteImage() {
                    imagesFolder.removeFile(imagePath);
                    setValue(null);
                    valueModified(imageControl);
                }
            }
        }
    }

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: imageControl.imagesFolder
        outputPrefix: imageControl.imagePrefix

        onAccepted: {
            var path = AppFramework.resolvedPath(pictureUrl);
            resizeImage(path);
            imagePath = path;
            imageUrl = pictureUrl;
            updateValue();
        }
    }

    Component {
        id: cameraPage

        XFormCameraCapture {
            id: cameraCapture

            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            makerNote: JSON.stringify({
                                          "nodeset": bindElement["@nodeset"]
                                      })

            title: textValue(formElement.label, "", "long")

            autoClose: false
            debug: imageControl.debug

            onCaptured: {
                if (debug) {
                    console.log(logCategory, "onCaptured");
                }

                resizeImage(path);
                finalizeCapture(path, url);
            }

            function finalizeCapture(path, url) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "path:", path);
                }

                function finishedCapture() {
                    if (debug) {
                        console.log(logCategory, arguments.callee.name);
                    }

                    imagePath = path;
                    imageUrl = url;
                    updateValue();
                    closeControl();
                }

                watermarks.paintWatermarks(cameraCapture, path, location, compassAzimuth, finishedCapture);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInCameraPage

        XFormAddInCameraCapture {
            addInName: cameraAddInName
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            appearance: imageControl.appearance || ""

            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                imagePath = path;
                imageUrl = url;
                updateValue();
                imagePreview.refresh();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        XFormAddInSettings {
            addInName: cameraAddInName
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: spikeCameraPage

        XFormExternalCameraCapture {
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            appearance: imageControl.appearance

            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                imagePath = path;
                imageUrl = url;
                updateValue();
                imagePreview.refresh();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sketchPage

        XFormSketchCapture {
            title: textValue(formElement.label, "", "long")

            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            defaultImageUrl: imageControl.defaultImageUrl
            useExternalCamera: imageControl.useExternalCamera
            externalCameraIcon: imageControl.externalCameraIcon
            appearance: imageControl.appearance

            onSaved: {
                imageControl.imagePath = path;
                imageControl.imageUrl = url;
                updateValue();
                imagePreview.refresh();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: previewPage

        XFormImagePreview {
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: imageFileInfo
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            icon: Icons.bigIcon("trash")
            iconColor: xform.style.deleteIconColor
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    function resizeImage(path) {
        var captureResolution = xform.captureResolution;

        /* @TODO - Enable when settings are enabled again
        if (xform.allowCaptureResolutionOverride && app.captureResolution > 0) {
            captureResolution = app.captureResolution;
        }
        */

        if (captureResolution <= 0) {
            // Unrestricted image size
            if (Qt.platform.os !== "ios") {
                // do nothing
                return;
            }
            if (!watermarks.enabledWatermarksCount()) {
                return;
            }
            // If watermark is used, resize to a large image to avoid crash on iOS
            captureResolution = maximumWatermarkedImageResolution;
        }

        if (!captureResolution) {
            console.log(logCategory, "No image resize:", captureResolution);
            return;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, "Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log(logCategory, "File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error(logCategory, "Unable to load image:", path);
            return;
        }

        if (imageObject.width > imageObject.height) {
            if (imageObject.width <= captureResolution) {
                return;
            }
            imageObject.scaleToWidth(captureResolution);
        }
        else {
            if (imageObject.height <= captureResolution) {
                return;
            }
            imageObject.scaleToHeight(captureResolution)
        }

        //        console.log(logCategory, "Rescaling image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        if (!imageObject.save(path)) {
            console.error(logCategory, "Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        //        console.log(logCategory, "Scaled image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    function rotateImage(path, angle) {
        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, "Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log(logCategory, "File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error(logCategory, "Unable to load image:", path);
            return;
        }

        console.log(logCategory, "Rotating image:", angle, imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        imageObject.rotate(angle);

        if (!imageObject.save(path)) {
            console.error(logCategory, "Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        console.log(logCategory, "Rotated image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var imageName = imageFileInfo.fileName;
        console.log(logCategory, "image-updateValue:", imageName);
        console.log(logCategory, "imageUrl:", imageUrl);

        formData.setValue(bindElement, imageName);

        xform.controlFocusChanged(this, false, bindElement);

        valueModified(imageControl);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log(logCategory, "image-editMode:", editMode);

            editing = editMode > formData.kEditModeAdd;
        } else {
            editing = false;
        }

        if (value > "") {
            console.log(logCategory, "image-setValue:", value, "readOnly:", readOnly);

            imagePath = imagesFolder.filePath(value);
            imageUrl = imagesFolder.fileUrl(value);
        } else {
            imagePath = "";
            imageUrl = "";
        }

        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------

    function setDefaultValue(value) {
        defaultValue = value;

        if (defaultValue > "" && mediaFolder.fileExists(defaultValue)) {
            defaultImageUrl = mediaFolder.fileUrl(defaultValue);
        } else {
            defaultImageUrl = "";
        }

        console.log(logCategory, "image defaultValue:", defaultValue, "defaultImageUrl:", defaultImageUrl);
    }

    //--------------------------------------------------------------------------

    XFormImageWatermarks {
        id: watermarks

        debug: imageControl.debug
        element: imageControl.bindElement
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        property string previewHeightDefinition

        element: formElement
        attribute: kAttributeStyle

        debug: imageControl.debug

        Component.onCompleted: {
            initialize();
        }

        function initialize(reset) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, JSON.stringify(element));
            }

            if (reset) {
                parseParameters();
            }

            bind(controlStyle, "previewHeightDefinition", kPropertyPreviewHeight);
            bind(imageControl, "cameraAddInName", kPropertyAddIn);
        }

        onPreviewHeightDefinitionChanged: {
            previewHeight = toHeight(previewHeightDefinition, xform.style.imagePreviewHeight);
        }
    }

    //--------------------------------------------------------------------------
}
