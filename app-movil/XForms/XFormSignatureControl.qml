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

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var mediatype

    property FileFolder imagesFolder: xform.attachmentsFolder
    property alias imagePath: imageFileInfo.filePath
    property url imageUrl
    property string imagePrefix: "Signature"

    property bool debug: false

    //--------------------------------------------------------------------------

    property bool editing: false
    readonly property bool readOnly: !enabled || binding.isReadOnly || editing
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    readonly property bool rtl: xform.isRightToLeft

    //--------------------------------------------------------------------------

    readonly property string kPropertyHeight: "height"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    implicitHeight: xform.style.signatureHeight

    border {
        color: sketchCanvas.penDown
               ? xform.style.inputActiveBorderColor
               : xform.style.inputBorderColor

        width: sketchCanvas.penDown
               ? xform.style.inputActiveBorderWidth
               : xform.style.inputBorderWidth
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        imagePrefix = binding.nodeset;
        var i = imagePrefix.lastIndexOf("/");
        if (i >= 0) {
            imagePrefix = imagePrefix.substr(i + 1);
        }

        console.log("signature prefix:", imagePrefix);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    XFormSignatureCanvas {
        id: sketchCanvas

        anchors {
            fill: parent
            margins: parent.border.width
        }

        color: xform.style.signatureBackgroundColor
        penColor: xform.style.signaturePenColor
        penWidth: xform.style.signaturePenWidth
        enabled: !readOnly

        InputClearButton {
            anchors {
                top: parent.top
                left: rtl ? parent.left : undefined
                right: !rtl ? parent.right : undefined
                margins: ControlsSingleton.inputTextPadding
            }

            visible: !readOnly && imagePath > ""

            onClicked: {
                clear();
            }
        }

        onPenReleased: {
            updateValue();
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: imageFileInfo
    }

    //--------------------------------------------------------------------------

    function zeroPad(num, places) {
        var zero = places - num.toString().length + 1;
        return new Array(+(zero > 0 && zero)).join("0") + num;
    }

    function save() {
        if (sketchCanvas.isNull) {
            console.log("Null sketch:", imagePrefix);
            return undefined;
        }

        if (!imageFileInfo.exists) {
            /*
            var imageDate = new Date();
            var imageName = imagePrefix + "_" +
                    imageDate.getUTCFullYear().toString() +
                    zeroPad(imageDate.getUTCMonth(), 2) +
                    zeroPad(imageDate.getUTCDate(), 2) +
                    "-" +
                    zeroPad(imageDate.getUTCHours(), 2) +
                    zeroPad(imageDate.getUTCMinutes(), 2) +
                    zeroPad(imageDate.getUTCSeconds(), 2) +
                    ".jpg";
            */

            var imageName = imagePrefix + "-" + AppFramework.createUuidString(2) + ".jpg";

            imagePath = imagesFolder.filePath(imageName);
        }

        console.log("store signature:", imagePath);

        sketchCanvas.save(imagePath);

        return imageFileInfo.fileName;
    }


    //--------------------------------------------------------------------------

    function clear() {
        sketchCanvas.clear();
        if (imageFileInfo.exists) {
            if (imagesFolder.removeFile(imageFileInfo.fileName)) {
                console.log("Deleted signature:", imageFileInfo.filePath);
            } else {
                console.error("Failed to delete:", imageFileInfo.filePath);
            }
        }

        imagePath = ""
        imageUrl = "";

        updateValue();
    }

    //--------------------------------------------------------------------------
    /*
    function storeValue() {
        save();
    }
*/
    //--------------------------------------------------------------------------

    function updateValue() {
        save();

        var imageName = imageFileInfo.fileName;
        console.log("signature-updateValue", imageName);

        if (!imageName.length) {
            imageName = undefined;
        }

        formData.setValue(bindElement, imageName);

        xform.controlFocusChanged(this, false, bindElement);
        valueModified(control);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log("signature-editMode:", editMode);

            editing = editMode > formData.kEditModeAdd;
        } else {
            editing = false;
        }

        console.log("signature-setValue", value, "readOnly:", readOnly);

        sketchCanvas.clear();

        if (value > "") {
            imagePath = imagesFolder.filePath(value);
            imageUrl = imagesFolder.fileUrl(value);

            sketchCanvas.load(imagePath);
        } else {
            imagePath = "";
            imageUrl = "";
        }

        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        property string heightDefinition

        element: formElement
        attribute: kAttributeStyle

        debug: control.debug

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

            bind(controlStyle, "heightDefinition", kPropertyHeight);
        }

        onHeightDefinitionChanged: {
            control.implicitHeight = toHeight(heightDefinition, xform.style.signatureHeight);
        }
    }

    //--------------------------------------------------------------------------
}
