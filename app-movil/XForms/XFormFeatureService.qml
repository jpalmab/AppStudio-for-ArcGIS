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

import QtQuick 2.12
import QtQml 2.12

import ArcGIS.AppFramework 1.0

import "../Portal"

import "XForm.js" as XFormJS
import "XFormSingletons"

Item {
    id: xformFeatureService

    property Portal portal
    property bool debug: false

    property string featureServiceItemId
    property url featureServiceUrl
    property var featureServiceInfo: null
    property var layerInfos
    property bool useUploadIds: true//false
    property bool useGlobalIds: true//useUploadIds

    property string progressMessage
    property real progress: 0

    property var objectCache: app.objectCache // @TODO don't use global

    property XFormSchema schema

    property XFormWebhooks webhooks

    //--------------------------------------------------------------------------

    signal serviceReady();
    signal applied(var edits, var response, var instanceData);
    signal failed(var error);

    //--------------------------------------------------------------------------

    readonly property var kContentTypes: ({
                                              "jpg": "image/jpeg",
                                              "jfif": "image/jpeg",
                                              "jpeg": "image/jpeg",
                                              "png": "image/png",
                                              "gif": "image/gif",
                                              "tif": "image/tiff",
                                              "tiff": "image/tiff",
                                              "txt": "text/plain",
                                              "csv": "text/plain",
                                              "zip": "application/zip",
                                              "mp3": "audio/basic",
                                              "mpeg": "audio/basic",
                                              "wav": "audio/wav",
                                              "xml": "text/xml",
                                          });

    readonly property string kDefaultContentType: "application/octet-stream"

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(xformFeatureService, true)
    }

    //--------------------------------------------------------------------------

    onApplied: {
        if (webhooks) {
            webhooks.submit(surveyInfo, featureServiceInfo, edits, response);
        }
    }

    //--------------------------------------------------------------------------

    onServiceReady: {
        if (true) {//debug) {
            console.log(logCategory, "onServiceReady:", JSON.stringify(featureServiceInfo, undefined, 2));
            console.log(logCategory, "layerInfos:", JSON.stringify(layerInfos, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function applyData(instanceData) {
//        if (true) { //!portal.isPortal) {
//            useUploadIds = XFormJS.toBoolean(featureServiceInfo.supportsApplyEditsWithGlobalIds);

//            layerInfos.forEach(function(layerInfo) {
//                console.log(logCategory, "layer:", layerInfo.name, "supportsAttachmentsByUploadId:", layerInfo.supportsAttachmentsByUploadId);
//                useUploadIds = useUploadIds && XFormJS.toBoolean(layerInfo.supportsAttachmentsByUploadId);
//            });
//        }

        console.log(logCategory, "Adding attachments by upload id:", useUploadIds);

        var editsInfo = toEdits(instanceData);

        if (debug) {
            console.log(logCategory, "applyData edits:", JSON.stringify(editsInfo.edits, undefined, 2));
            console.log(logCategory, "applyData attachments:", JSON.stringify(editsInfo.attachments, undefined, 2));
        }

        console.log(logCategory, "Applying edits to:", featureServiceUrl);

        //----------------------------------------------------------------------

        function doApplyEdits() {
            var formData = {
                "edits": XFormJS.encode(JSON.stringify(editsInfo.edits)),
                "rollbackOnFailure": true,
                "useGlobalIds": useGlobalIds
            }

            progressMessage = qsTr("Sending Data");

            applyEditsRequest.editsInfo = editsInfo;
            applyEditsRequest.sendRequest(formData);
        }

        //----------------------------------------------------------------------

        if (useUploadIds) {
            var uploadsList = buildUploadsList(editsInfo);

            uploadAttachments(uploadsList, function() {
                uploadsList.forEach(function(upload) {
                    //var edit = edits[upload.editId];

                    var edit;

                    for (var i = 0; i < editsInfo.edits.length; i++) {
                        if (editsInfo.edits[i].id == upload.editId) {
                            edit = editsInfo.edits[i];
                            break;
                        }
                    }

                    if (!edit) {
                        console.error(logCategory, "Unable to find an edit for id:", upload.editId, "in:", JSON.stringify(editsInfo.edits, undefined, 2));
                    }

                    if (!edit.attachments) {
                        edit.attachments = {};
                    }

                    if (!Array.isArray(edit.attachments.adds)) {
                        edit.attachments.adds = [];
                    }

                    var attachment = {
                        uploadId: upload.itemID,
                        globalId: AppFramework.createUuidString(0).toUpperCase(),
                        parentGlobalId: upload.parentGlobalId,
                        name: upload.fileName,
                        contentType: upload.contentType,
                        keywords: upload.keywords
                    };

                    console.log(logCategory, "upload info:", JSON.stringify(upload, undefined, 2));
                    console.log(logCategory, "upload attachment:", JSON.stringify(attachment, undefined, 2));

                    edit.attachments.adds.push(attachment);
                });
                doApplyEdits()
            });
        } else {
            doApplyEdits();
        }
    }

    //--------------------------------------------------------------------------

    function toEdits(instanceData) {
        xformData.instance = instanceData;

        var editLayers = {};
        var instanceDataXref = [];

        //----------------------------------------------------------------------

        function addFeature(table, layer, feature, data) {
            if (!editLayers[layer.id]) {
                editLayers[layer.id] = {
                    table: table,
                    layer: layer,
                    features: [],
                    attachments: []
                };
            }

            var editMode = xformData.metaValue(feature, xformData.kMetaEditMode, xformData.kEditModeAdd);

            var globalId = feature.attributes[layer.globalIdField]
            if (!(globalId  > "")) {
                globalId = AppFramework.createUuidString(0).toUpperCase();
                feature.attributes[layer.globalIdField] = globalId;
            }

            if (layer.type === Layer.kTypeFeatureLayer) {
                if (!XFormJS.isEsriGeometry(layer.geometryType, feature.geometry)) {
                    console.error(logCategory, "Removing mismatched geometry geometryType:", layer.geometryType, "geometry:", JSON.stringify(feature.geometry));
                    feature.geometry = undefined;
                }

            } else {
                if (debug) {
                    console.log(logCategory, "Removing geometry for non \"Feature Layer\":", layer.type);
                }
                feature.geometry = undefined;
            }

            if (feature.geometry) {
                if (!layer.hasZ) {
                    feature.geometry.z = undefined;
                }

                if (!layer.hasM) {
                    feature.geometry.m = undefined;
                }
            }

            var attachments = feature.attachments;
            feature.attachments = undefined;

            editLayers[layer.id].features.push(feature);

            // TODO Current only supports adding attachment for new features

            if (Array.isArray(attachments)) {
                attachments.forEach(function (attachment) {
                    attachment.parentGlobalId = globalId;
                });
            }

            if (editMode === xformData.kEditModeAdd) {
                editLayers[layer.id].attachments.push(attachments);
            }

            instanceDataXref[globalId.toUpperCase()] = data;
        }

        //----------------------------------------------------------------------

        function addChildFeatures(parentTable, parentLayer, parentFeature) {

            console.log(logCategory, "parent table:", parentTable.name, "layer:", parentLayer.id);

            parentTable.relatedTables.forEach(function (relatedTable) {
                var relatedLayer = findLayer(relatedTable.name);

                console.log(logCategory, "related table:", relatedTable.name, "layer:", relatedLayer.id);

                if (!relatedLayer) {
                    internalFail(-203,
                                 qsTr("Related layer '%1' not found in feature service.")
                                 .arg(relatedTable.name));
                    return;
                }

                var parentRelationship = findRelationship(parentLayer, relatedLayer);
                if (!parentRelationship) {
                    internalFail(-200,
                                 qsTr("Incompatible feature service. Parent to child relationship not found from %2 (%1) to %4 (%3)")
                                 .arg(parentLayer.id)
                                 .arg(parentLayer.name)
                                 .arg(relatedLayer.id)
                                 .arg(relatedLayer.name));
                    return;
                }

                var childRelationship = findRelationship(relatedLayer, parentLayer);
                if (!childRelationship) {
                    internalFail(-201,
                                 qsTr("Incompatible feature service. Child to parent relationship not found from %2 (%1) to %4 (%3)")
                                 .arg(relatedLayer.id)
                                 .arg(relatedLayer.name)
                                 .arg(parentLayer.id)
                                 .arg(parentLayer.name));
                }

                var parentKeyField = parentRelationship.keyField;
                var childKeyField = childRelationship.keyField;

                console.log(logCategory, "parentKeyField:", parentKeyField);
                console.log(logCategory, "childKeyField:", childKeyField);

                var relationshipKeyValue = parentFeature.attributes[parentKeyField];
                if (!(relationshipKeyValue > "")) {
                    relationshipKeyValue = AppFramework.createUuidString(0).toUpperCase();
                    parentFeature.attributes[parentKeyField] = relationshipKeyValue;
                    console.log(logCategory, "New relationshipKeyValue:", relationshipKeyValue);
                }

                console.log(logCategory, "relationshipKeyValue:", relationshipKeyValue);

                var esriParameters = relatedTable.esriParameters;
                var allowAdds = XFormJS.toBoolean(esriParameters.allowAdds, true);
                var allowUpdates = XFormJS.toBoolean(esriParameters.allowUpdates, false);
                var allowDeletes = XFormJS.toBoolean(esriParameters.allowDeletes, false);

                var rows = xformData.getTableRows(relatedTable.name);
                for (var i = 0; i < rows.length; i++) {
                    var rowData = rows[i];

                    if (!rowData) {
                        console.log(logCategory, arguments.callee.name, "Skipping null child row:", i);
                        continue;
                    }

                    var editMode = xformData.metaValue(rowData, xformData.kMetaEditMode, xformData.kEditModeAdd);

                    if (xformData.isEmptyData(rowData) && editMode === xformData.kEditModeAdd) {
                        console.log(logCategory, "Skipping add empty child row:", i, JSON.stringify(rowData, undefined, 2));
                        continue;
                    }

                    var relatedFeature = xformData.toFeature(relatedTable, rowData);

                    if (!allowUpdates && editMode === xformData.kEditModeUpdate) {
                        console.log(logCategory, "Skipping edit child row:", i);
                        continue;
                    }

                    if (!allowDeletes && editMode === xformData.kEditModeDelete) {
                        console.log(logCategory, "Skipping delete child row:", i);
                        continue;
                    }

                    relatedFeature.attributes[childKeyField] = parentFeature.attributes[parentKeyField];

                    addFeature(relatedTable, relatedLayer, relatedFeature, rowData);

                    xformData.setTableRowIndex(relatedTable.name, i);
                    addChildFeatures(relatedTable, relatedLayer, relatedFeature);
                }
            });
        }

        //----------------------------------------------------------------------

        var rootTable = schema.schema;
        var rootLayer = findLayer(rootTable.tableName);

        if (!rootLayer) {
            internalFail(-202,
                         qsTr("Layer '%1' not found in feature service.")
                         .arg(rootTable.tableName));
            return;
        }

        var rootData = xformData.instance[rootTable.name];
        var rootFeature = xformData.toFeature(rootTable, rootData);

        addFeature(rootTable, rootLayer, rootFeature, rootData);
        addChildFeatures(rootTable, rootLayer, rootFeature);

        //----------------------------------------------------------------------

        var edits = [];

        var keys = Object.keys(editLayers);
        keys.forEach(function (key) {
            var adds = [];
            var updates = [];
            var deletes = [];

            var editLayer = editLayers[key];

            editLayer.features.forEach(function (feature) {
                var editMode = xformData.metaValue(feature, xformData.kMetaEditMode, xformData.kEditModeAdd);

                xformData.setMetaValue(feature, undefined);

                switch (editMode) {
                case xformData.kEditModeUpdate:
                    updates.push(feature);
                    break;

                case xformData.kEditModeDelete:
                    deletes.push(feature.globalid);
                    break;

                case xformData.kEditModeAdd:
                default:
                    adds.push(feature);
                    break;
                }
            });


            var edit = {
                "id": editLayer.layer.id,
                "level": editLayer.table.level,
                "attachments": editLayer.attachments
            };

            if (adds.length) {
                edit.adds = adds;
            }

            if (updates.length) {
                edit.updates = updates;
            }

            if (deletes.length) {
                edit.deletes = deletes;
            }

            edits.push(edit);
        });

        //----------------------------------------------------------------------

        var attachments = {};

        edits.sort(function (a, b) {
            return a.level - b.level;
        });

        edits.forEach(function (edit) {
            if (debug) {
                console.log(logCategory, "edit layer:", edit.id, "level:", edit.level);
            }

            edit.level = undefined;

            if (Array.isArray(edit.attachments) && edit.attachments.length > 0) {
                attachments[edit.id] = edit.attachments;
            }
            // delete edit.attachments;
            edit.attachments = undefined;
        });

        //----------------------------------------------------------------------

        if (debug) {
            console.log(logCategory, "edits:", JSON.stringify(edits, undefined, 2));
        }

        //----------------------------------------------------------------------

        var editsInfo = {
            edits: edits,
            attachments: attachments,
            instanceData: instanceData,
            instanceDataXref: instanceDataXref
        }

        return editsInfo;
    }

    //--------------------------------------------------------------------------

    function buildUploadsList(editsInfo) {

        console.log(logCategory, "buildUploadsList");

        var list = [];

        for (var editIndex = 0; editIndex < editsInfo.edits.length; editIndex++) {
            var edit = editsInfo.edits[editIndex];
            if (!edit) {
                continue;
            }

            if (edit.adds) {
                var layer = findLayer(edit.id, true);

//                if (!layer.supportsAttachmentsByUploadId) {
//                    console.log(logCategory, "Uploads not supported for layer:", layer.name);
//                    continue;
//                }

                var editAttachments = editsInfo.attachments[edit.id];
                if (!Array.isArray(editAttachments)) {
                    console.log(logCategory, "No attachments for edit.id:", edit.id);
                    continue;
                }

                editAttachments.forEach(function (attachments) {
                    if (!attachments) {
                        return;
                    }

                    attachments.forEach(function (attachment) {
                        if (!attachment) {
                            return;
                        }

                        if (attachment.editMode) {
                            return;
                        }

                        var upload = {
                            editId: edit.id,
                            parentGlobalId: attachment.parentGlobalId
                        };

                        if (typeof attachment === "object") {
                            upload.fieldName = attachment.fieldName;
                            upload.fileName = attachment.fileName;
                            upload.keywords = attachment.fieldName;
                        } else {
                            upload.fileName = attachment;
                        }

                        var description = "Attachment";
                        if (upload.fieldName) {
                            description += " field=" + upload.fieldName;
                        }

                        upload.description = description;

                        if (debug) {
                            console.log(logCategory, "attachment:", JSON.stringify(attachment, undefined, 2));
                            console.log(logCategory, "upload:", JSON.stringify(upload, undefined, 2));
                        }

                        if (attachmentsFolder.fileExists(upload.fileName)) {
                            list.push(upload);
                        } else {
                            console.error(logCategory, "upload file not found:", attachmentsFolder.filePath(upload.fileName));
                        }
                    });
                });
            }
        }

        console.log(logCategory, "uploads list:", JSON.stringify(list, undefined, 2));

        return list;
    }

    //--------------------------------------------------------------------------

    function uploadAttachments(uploads, callback) {
        if (uploads.length <= 0) {
            callback();
            return;
        }

        uploadRequest.uploads = uploads;
        uploadRequest.uploadIndex = 0;
        uploadRequest.callback = callback;

        uploadRequest.uploadItem(0);
    }

    PortalRequest {
        id: uploadRequest

        property var uploads
        property int uploadIndex: 0
        property var callback

        portal: xformFeatureService.portal
        url: featureServiceUrl + "/uploads/upload"
        method: "POST"
        responseType: "json"
        trace: debug

        onSuccess: {
            console.log(logCategory, "upload response:", JSON.stringify(response, undefined, 2));

            if (response.error) {
                xformFeatureService.failed(response.error);
            } else {
                var item = response.item;

                var upload = uploads[uploadIndex];

                upload.itemID = item.itemID;
                upload.itemName = item.itemName;
                upload.date = item.date;
                upload.committed = item.committed;

                uploadIndex++;
                if (uploadIndex < uploads.length) {
                    uploadItem(uploadIndex);
                } else {
                    callback();
                }
            }
        }

        onFailed: {
            console.log(logCategory, "upload error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function uploadItem(index) {
            var upload = uploads[index];

            var filePath = attachmentsFolder.filePath(upload.fileName);
            var fileInfo = attachmentsFolder.fileInfo(upload.fileName);

            var contentType = kContentTypes[fileInfo.suffix.toLowerCase()];
            if (!contentType) {
                contentType = kDefaultContentType;
            }

            upload.contentType = contentType;

            var formData = {
                file: uploadPrefix + filePath, // + ";type=application/octet",
                description: upload.description
            }

            console.log(logCategory, "uploading:", JSON.stringify(formData, undefined, 2));

            progressMessage = qsTr("Uploading attachment %1 of %2").arg(index + 1).arg(uploads.length);
            sendRequest(formData);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: applyEditsRequest

        url: featureServiceUrl + "/applyEdits"
        portal: xformFeatureService.portal
        trace: debug
        property var editsInfo

        onSuccess: {
            console.log(logCategory, "applyEdits response:", JSON.stringify(response, undefined, 2));

            var errors = [];
            var summary = {
                adds: 0,
                updates: 0,
                deletes: 0
            };

            function syncResults(tableId, edits, results, attachmentsResults) {
                for (var i = 0; i < results.length; i++) {
                    var edit = edits[i];
                    var editResult = results[i];

                    edit.result = editResult;

                    if (editResult.error) {
                        var error = editResult.error;

                        error.tableId = tableId;
                        errors.push(error);
                    }
                }

                if (Array.isArray(attachmentsResults)) {
                    attachmentsResults.forEach(function (attachmentResult) {
                        if (attachmentResult.error) {
                            var error = attachmentResult.error;

                            error.tableId = tableId;

                            console.log(logCategory, "Attachment error:", JSON.stringify(error, undefined, 2))
                            errors.push(error);
                        }
                    });
                }
            }

            var instanceData = editsInfo.instanceData;
            var edits = editsInfo.edits;

            response.forEach(function (editResult) {
                console.log(logCategory, "editResult:", JSON.stringify(editResult, undefined, 2));

                var edit;
                for (var i = 0; i < edits.length; i++) {
                    if (edits[i].id == editResult.id) {
                        edit = edits[i];

                        var layerInfo = findLayer(editResult.id, true);

                        edit.layerInfo = {
                            "id": layerInfo.id,
                            "name": layerInfo.name,
                            "type": layerInfo.type,
                            "objectIdField": layerInfo.objectIdField,
                            "globalIdField": layerInfo.globalIdField,
                            "relationships": layerInfo.relationships
                        };

                        break;
                    }
                }

                if (!edit) {
                    console.error(logCategory, "Edit not found for layer id:", editResult.id, "editResult:", JSON.stringify(editResult, undefined, 2));
                }

                var attachmentsResult = editResult.attachments || {};

                if (editResult.addResults) {
                    summary.adds += editResult.addResults.length;
                    syncResults(editResult.id, edit.adds, editResult.addResults, attachmentsResult.addResults);
                }

                if (editResult.updateResults) {
                    summary.updates += editResult.updateResults.length;
                    syncResults(editResult.id, edit.updates, editResult.updateResults, attachmentsResult.updateResults);
                }

                if (editResult.deleteResults) {
                    summary.deletes += editResult.deleteResults.length;
                    syncResults(editResult.id, edit.deletes, editResult.deleteResults, attachmentsResult.deleteResults);
                }
            });


            console.log(logCategory, "applyEdits edit results:", JSON.stringify(edits, undefined, 2));

            if (errors.length > 0) {
                console.log(logCategory, "applyEdits:errors:", JSON.stringify(errors, undefined, 2));

                xformFeatureService.failed(errors);

                if (webhooks) {
                    webhooks.submit(surveyInfo, featureServiceInfo, edits, response);
                }
            } else {
                edits.summary = summary;

                syncInstanceData(editsInfo);

                console.log(logCategory, "applyEdits:edits:", JSON.stringify(edits, undefined, 2));

                if (useUploadIds) {
                    xformFeatureService.applied(edits, response, instanceData);
                } else {
                    var attachmentsList = buildAttachmentsList(edits, editsInfo.attachments, response);

                    if (attachmentsList.length > 0) {
                        addAttachments(edits, attachmentsList, instanceData);
                    } else {
                        xformFeatureService.applied(edits, response, instanceData);
                    }
                }
            }
        }

        onFailed: {
            console.log(logCategory, "applyEdits error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }
    }

    //--------------------------------------------------------------------------

    function buildAttachmentsList(edits, attachments, results) {

        //        console.log(logCategory, "edits:", JSON.stringify(edits, undefined, 2),
        //                    "attachments:", JSON.stringify(attachments, undefined, 2),
        //                    "results:", JSON.stringify(results, undefined, 2));

        var list = [];

        for (var editIndex = 0; editIndex < edits.length; editIndex++) {
            var edit = edits[editIndex];
            if (!edit) {
                continue;
            }

            if (edit.adds) {
                for (var addIndex = 0; addIndex < edit.adds.length; addIndex++) {
                    var objectId = results[editIndex].addResults[addIndex].objectId;

                    var addAttachments = attachments[edit.id][addIndex];
                    if (Array.isArray(addAttachments)) {
                        addAttachments.forEach(function (attachment) {
                            var item = {
                                id: edit.id,
                                objectId: objectId
                            };

                            if (typeof attachment === "object") {
                                item.fieldName = attachment.fieldName;
                                item.fileName = attachment.fileName;
                            } else {
                                item.fileName = attachment;
                            }

                            if (attachmentsFolder.fileExists(item.fileName)) {
                                list.push(item);
                            } else {
                                console.error(logCategory, "attachment file not found:", attachmentsFolder.filePath(item.fileName));
                            }
                        });
                    }
                }
            }
        }

        console.log(logCategory, "attachmentsList:", JSON.stringify(list, undefined, 2));

        return list;
    }

    //--------------------------------------------------------------------------

    function addAttachments(edits, attachments, instanceData) {
        addAttachmentRequest.edits = edits;
        addAttachmentRequest.attachments = attachments;
        addAttachmentRequest.attachmentIndex  = 0;
        addAttachmentRequest.instanceData = instanceData;

        addAttachmentRequest.addAttachment(0);
    }

    FileFolder {
        id: attachmentsFolder

        path: "~/ArcGIS/My Survey Attachments"

        Component.onCompleted: {
            makeFolder();
        }
    }

    PortalRequest {
        id: addAttachmentRequest

        property var edits
        property var attachments
        property int attachmentIndex: 0
        property var instanceData

        portal: xformFeatureService.portal
        method: "POST"
        responseType: "json"
        trace: debug

        onSuccess: {
            console.log(logCategory, "addAttachment:", JSON.stringify(response, undefined, 2));

            var addAttachmentResult = response.addAttachmentResult;

            if (addAttachmentResult.error) {
                xformFeatureService.failed(addAttachmentResult.error);
            } else {
                attachmentIndex++;
                if (attachmentIndex < attachments.length) {
                    addAttachment(attachmentIndex);
                } else {
                    xformFeatureService.applied(edits, response, instanceData);
                }
            }
        }

        onFailed: {
            console.log(logCategory, "addAttachment error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function addAttachment(index) {
            var attachment = attachments[index];

            url = featureServiceUrl + "/" + attachment.id.toString() + "/" + attachment.objectId.toString() + "/addAttachment";

            var filePath = attachmentsFolder.filePath(attachment.fileName);

            console.log(logCategory, "addAttachment:", filePath, "url", url);

            var formData = {
                attachment: uploadPrefix + filePath,
            }

            if (attachment.fieldName) {
                formData.keywords = attachment.fieldName;
            }

            progressMessage = qsTr("Adding Attachment %1 of %2").arg(index + 1).arg(attachments.length);
            sendRequest(formData);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: serviceInfoRequest

        portal: xformFeatureService.portal
        method: "POST"
        responseType: "json"

        onSuccess: {
            featureServiceInfo = response;
            objectCache[url] = featureServiceInfo;
        }

        onFailed: {
            featureServiceInfo = undefined;
            objectCache[url] = undefined;
            xformFeatureService.failed(error);
        }
    }

    onFeatureServiceUrlChanged: {
        featureServiceInfo = null;

        if (featureServiceUrl > "") {
            serviceInfoRequest.url = featureServiceUrl;

            var info = objectCache[featureServiceUrl];
            if (info) {
                console.log(logCategory, "Using cached featureServiceInfo:", featureServiceUrl);
                featureServiceInfo = info;
            } else {
                console.log(logCategory, "Requesting featureServiceInfo:", featureServiceUrl);
                serviceInfoRequest.sendRequest();
            }
        }
    }

    onFeatureServiceInfoChanged: {
        console.log(logCategory, "featureServiceInfo:", JSON.stringify(featureServiceInfo, undefined, 2));

        if (featureServiceInfo) {
            featureServiceInfo.itemId = featureServiceItemId;
            featureServiceInfo.url = featureServiceUrl.toString();

            var layers = featureServiceInfo.layers;
            if (!Array.isArray(layers)) {
                layers = [];
            }

            if (Array.isArray(featureServiceInfo.tables)) {
                layers = layers.concat(featureServiceInfo.tables);
            }

            layers = layers.filter(function (layer) {
                if (!layer) {
                    return false;
                }

                return !layer.type ||
                        layer.type === Layer.kTypeFeatureLayer ||
                        layer.type === Layer.kTypeTable;
            });

            if (!layers.length) {
                var error = {
                    "code": 0,
                    "description": "Invalid feature service information - Empty or missing layers"
                };

                failed(error);
            }

            layerInfosRequest.requestInfos(featureServiceUrl, layers);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: layerInfosRequest

        portal: xformFeatureService.portal

        property string serviceUrl
        property var requestQueue: []
        property var currentLayer

        onSuccess: {
            var layerInfo = addLayerInfo(response);
            if (layerInfo) {
                objectCache[url] = layerInfo;
            }
            getNext();
        }

        onFailed: {
            objectCache[url] = undefined;
            xformFeatureService.failed(error);
        }

        function getNext() {
            if (!requestQueue.length) {
                if (updateRelationships()) {
                    var error = checkRequirements();
                    if (error) {
                        failed(error);
                    } else {
                        serviceReady();
                    }
                }
                return;
            }

            currentLayer = requestQueue.shift();

            progressMessage = currentLayer.name;

            url = serviceUrl + "/" + currentLayer.id.toString();

            var layerInfo = objectCache[url];
            if (layerInfo) {
                console.log(logCategory, "Using cached layerInfo:", url);
                addLayerInfo(layerInfo);
                Qt.callLater(layerInfosRequest.getNext);
            } else {
                console.log(logCategory, "Requesting layerInfo:", url);
                sendRequest();
            }
        }

        function requestInfos(serviceUrl, requestQueue) {
            layerInfos = [];

            layerInfosRequest.serviceUrl = serviceUrl;
            layerInfosRequest.requestQueue = requestQueue;

            getNext();
        }
    }

    //--------------------------------------------------------------------------

    function addLayerInfo(layerInfo) {

        if (layerInfo.type !== Layer.kTypeFeatureLayer && layerInfo.type !== Layer.kTypeTable) {
            console.warn(logCategory, arguments.callee.name, "Skipping layer type:", layerInfo.type);
            return;
        }

        layerInfo.drawingInfo = undefined;
        layerInfo.templates = undefined;
        layerInfo.indexes = undefined;
        for (var i = 0; i < layerInfo.fields.length; i++) {
            layerInfo.fields[i].domain = undefined;
        }

        layerInfo.parentRelationships = [];
        layerInfo.childRelationships = [];

        console.log(logCategory, "Feature layerInfo:", JSON.stringify(layerInfo, undefined, 2));

        layerInfos[layerInfo.id] = layerInfo;

        return layerInfo;
    }

    //--------------------------------------------------------------------------

    function findLayer(name, searchIds) {
        for (var i = 0; i < featureServiceInfo.layers.length; i++) {
            var info = featureServiceInfo.layers[i];

            if (searchIds ? info.id == name : info.name === name) {
                return layerInfos[info.id];
            }
        }

        for (i = 0; i < featureServiceInfo.tables.length; i++) {
            info = featureServiceInfo.tables[i];

            if (searchIds ? info.id == name : info.name === name) {
                return layerInfos[info.id];
            }
        }

        console.warn(logCategory, arguments.callee.name, "No match for layer:", name);

        return null;
    }

    //--------------------------------------------------------------------------

    function findField(layerInfo, name) {
        for (var i = 0; i < layerInfo.fields.length; i++) {
            var layerField = layerInfo.fields[i];

            if (name === layerField.name) {
                return layerField;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    function findRelationship(layerInfo, relatedLayerInfo) {

        var relationships = layerInfo.relationships.filter(function(relationship) {
            return relationship.relatedTableId === relatedLayerInfo.id;
        });

        if (relationships.length <= 0) {
            console.error(logCategory, "Relationship not found in:", JSON.stringify(layerInfo.id), layerInfo.name, "for relatedTable:", JSON.stringify(relatedLayerInfo.id), relatedLayerInfo.name, "relationships:", JSON.stringify(layerInfo.relationships, undefined, 2));
            return;
        }

        return relationships[0];
    }

    //--------------------------------------------------------------------------

    function updateRelationships() {
        function updateChildRelationship(childLayerInfo) {
            if (XFormJS.isNullOrUndefined(childLayerInfo.relationships)) {
                return;
            }

            var childRelationship;

            for (var i = 0; i < childLayerInfo.relationships.length; i++) {
                var relationship = childLayerInfo.relationships[i];

                if (relationship.cardinality === "esriRelCardinalityOneToMany" &&
                        relationship.role === "esriRelRoleDestination") {
                    childRelationship = relationship;
                    break;
                }
            }

            if (!childRelationship) {
                return;
            }

            var childKeyField = findField(childLayerInfo, childRelationship.keyField);
            if (!childKeyField) {
                console.error(logCategory, "Child keyField not found:", childRelationship.keyField);
                return;
            }

            if (childKeyField.type !== "esriFieldTypeGUID") {
                console.error(logCategory, "Unsupported childKeyField type:", childKeyField.type);
                return;
            }

            childRelationship.keyFieldInfo = childKeyField;

            var parentLayerInfo = layerInfos[childRelationship.relatedTableId];
            if (!parentLayerInfo) {
                return;
            }

            var parentRelationship;

            for (i = 0; i < parentLayerInfo.relationships.length; i++) {
                relationship = parentLayerInfo.relationships[i];

                if (relationship.id === childRelationship.id) {
                    if (relationship.cardinality === "esriRelCardinalityOneToMany" &&
                            relationship.role === "esriRelRoleOrigin") {
                        parentRelationship = relationship;
                        console.log(logCategory, "relationship:", parentRelationship.id, parentRelationship.name, "<==>", childRelationship.name);
                        break;
                    } else {
                        return;
                    }
                }
            }

            if (!parentRelationship) {
                return;
            }

            var parentKeyField = findField(parentLayerInfo, parentRelationship.keyField);
            if (!parentKeyField) {
                console.error(logCategory, "Parent keyField not found:", parentRelationship.keyField);
                return;
            }

            if (parentKeyField.type !== "esriFieldTypeGUID" && parentKeyField.type !== "esriFieldTypeGlobalID") {
                console.error(logCategory, "Unsupported parentKeyField type:", parentKeyField.type);
                return;
            }

            if (parentKeyField.type === "esriFieldTypeGlobalID" && !featureServiceInfo.supportsApplyEditsWithGlobalIds) {
                console.error(logCategory, "Feature service requires supportsApplyEditsWithGlobalIds for parent keyField type:", parentKeyField.type);
                return;
            }

            parentRelationship.keyFieldInfo = parentKeyField;

            console.log(logCategory, "child name:", childLayerInfo.name, "childRelationship:", JSON.stringify(childRelationship, undefined, 2));
            console.log(logCategory, "parent name:", parentLayerInfo.name, "parentRelationship:", JSON.stringify(parentRelationship, undefined, 2));

            childLayerInfo.parentRelationships[parentLayerInfo.name] = childRelationship;
            parentLayerInfo.childRelationships[childLayerInfo.name] = parentRelationship;

            if (parentKeyField.type === "esriFieldTypeGlobalID") {
                useGlobalIds = true;
            }

            return true;
        }


        for (var i = 0; i < layerInfos.length; i++) {
            var layerInfo = layerInfos[i];
            // layerInfos[] is a sequence of values based on layer id; 
            // null values can be present if id numbers are skipped
            if (layerInfo) {
                console.log(logCategory, "Updating relationship for:", layerInfo.name);
                updateChildRelationship(layerInfo);
            }
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function findProperty(object, name, purpose) {
        if (!object) {
            console.error(logCategory, arguments.callee.name, purpose, "Invalid object parameter");
            return;
        }

        if (typeof name !== "string") {
            console.error(logCategory, arguments.callee.name, purpose, "Invalid name parameter");
            return;
        }

        var keys = Object.keys(object);

        for (var i = 0; i < keys.length; i++) {
            if (name === keys[i]) {
                return object[keys[i]];
            }
        }

        // console.debug(arguments.callee.name, purpose, "Trying case insensitive search for:", name);

        for (i = 0; i < keys.length; i++) {
            if (name.toLowerCase() === keys[i].toLowerCase()) {
                return object[keys[i]];
            }
        }

        //console.error(logCategory, arguments.callee.name, purpose, "Unable to match name:", name, "in:", JSON.stringify(keys));

        //As in resolveLayerReferences(), assume a non-match is layer 0
        //This occurs only with the parent form so should be 1 length array
        console.warn(logCategory, "No match for relationship to:", name, "default to layer 0:")
        return object[keys[0]];
    }

    //--------------------------------------------------------------------------

    function removeMetaProperties(edits) {
        console.log(logCategory, "removing meta properties:", edits.length);

        function _removeMetaProperties(a) {
            if (!Array.isArray(a)) {
                return;
            }

            for (var i = 0; i < a.length; i++) {
                var atts = a[i].attributes;

                var keys = Object.keys(atts);
                for (var j = 0; j < keys.length; j++) {
                    var key = keys[j];
                    var c = key.substring(0, 1);
                    if (c === ">" || c === "<") {
                        atts[key] = undefined;
                    }
                }
            }
        }

        for (var i = 0; i < edits.length; i++) {
            var edit = edits[i];

            _removeMetaProperties(edit.adds);
            _removeMetaProperties(edit.updates);
            _removeMetaProperties(edit.deletes);
        }
    }

    //--------------------------------------------------------------------------

    function syncInstanceData(editsInfo) {
        console.log(logCategory, arguments.callee.name, "instanceName:", schema.instanceName);
        console.log(logCategory, "instanceData:", JSON.stringify(editsInfo.instanceData, undefined, 2));

        xformData.instance = editsInfo.instanceData;

        editsInfo.edits.forEach(function (edit) {

            var layer = findLayer(edit.id, true);

            console.log(logCategory, "edit.id", JSON.stringify(edit.id), "layer.name:", layer.name);
            console.log(logCategory, "syncing layer:", layer.id, "name:", layer.name, "type:", layer.type);
            console.log(logCategory, "edit:", JSON.stringify(edit, undefined, 2));

            if (Array.isArray(edit.adds)) {

                console.log(logCategory, "Processing adds:", edit.adds.length);

                edit.adds.forEach(function (add, addIndex) {

                    console.log(logCategory, "edit.id:", JSON.stringify(edit.id), "add:", JSON.stringify(add));

                    var globalId = add.result["globalId"];
                    var objectId = add.result["objectId"];
                    var globalIdField = edit.layerInfo.globalIdField;
                    var objectIdField = edit.layerInfo.objectIdField;
                    var data = editsInfo.instanceDataXref[globalId.toUpperCase()];

                    if (globalIdField > "" && globalId) {
                        data[globalIdField] = globalId;
                        xformData.setMetaValue(data, xformData.kMetaGlobalIdField, globalIdField);
                    }

                    if (objectIdField > "" && objectId) {
                        data[edit.layerInfo.objectIdField] = objectId;
                        xformData.setMetaValue(data, xformData.kMetaObjectIdField, objectIdField);
                    }

                    xformData.setMetaValue(data, xformData.kMetaEditMode, xformData.kEditModeUpdate);

                    if (Array.isArray(edit.layerInfo.relationships)) {
                        edit.layerInfo.relationships.forEach(function (relationship) {
                            data[relationship.keyField] = add.attributes[relationship.keyField];
                        });
                    }
                });
            }

            if (Array.isArray(edit.updates)) {

                console.log(logCategory, "Processing updates:", edit.updates.length);

                edit.updates.forEach(function (update) {
                });
            }

            if (Array.isArray(edit.deletes)) {

                console.log(logCategory, "Processing deletes:", edit.deletes.length);

                edit.deletes.forEach(function (del) {
                });
            }
        });

        if (debug) {
            console.log(logCategory, "synced instanceData:", JSON.stringify(editsInfo.instanceData, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    function checkRequirements() {
        console.log(logCategory, "Checking feature service requirements");

        var error;

        if (!featureServiceInfo.supportsApplyEditsWithGlobalIds) {
            error = {
                "code": 0,
                "description": "Feature service requirements not met. supportsApplyEditsWithGlobalIds must be true"
            };
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function internalFail(code, description) {
        var error = {
            "code": code,
            "description": description
        };

        console.log(logCategory, "internalFail:", JSON.stringify(error, undefined, 2))

        failed(error);
    }

    //--------------------------------------------------------------------------

    XFormData {
        id: xformData

        schema: xformFeatureService.schema
    }

    //--------------------------------------------------------------------------
}
