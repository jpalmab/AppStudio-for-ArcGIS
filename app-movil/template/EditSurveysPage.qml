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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls/Singletons"

import "../Portal"
import "../XForms"
import "../XForms/XFormSingletons"
import "../XForms/XForm.js" as XFormJS

import "../template/SurveyHelper.js" as Helper

SurveysListPage {
    id: page

    //--------------------------------------------------------------------------

    property bool isPublic: false
    property bool refreshing: false

    property alias objectCache: xformFeatureService.objectCache

    readonly property date invalidDate: new Date("");

    property bool debug: false

    //--------------------------------------------------------------------------

    title: qsTr("%1 Inbox").arg(surveyTitle)
    statusFilter: xformsDatabase.statusInbox
    showDelete: false
    closeOnEmpty: false
    emptyMessage: qsTr("The inbox is empty")
    refreshEnabled: true

    mapKey: "inbox"

    listAction: SurveysListButton {
        visible: Networking.isOnline

        text: qsTr("Refresh")
        icon: Icons.icon("refresh")

        onClicked: {
            refreshDatabase();
        }
    }

    onRefresh: {
        refreshDatabase();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    Rectangle {
        parent: app
        anchors.fill:  parent
        color: "#40000000"
        visible: refreshing

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }
    }

    //--------------------------------------------------------------------------

    function refreshDatabase() {
        if (isPublic) {
            refreshStart();
        } else {
            portal.signInAction(qsTr("Please sign in to refresh surveys"), refreshStart);
        }
    }

    function refreshStart() {
        refreshing = true;
        progressPanel.open();

        surveyDatabase.initialize();

        if (xformFeatureService.isReady(surveyPath)) {
            xformFeatureService.serviceReady();
        } else {
            getServiceInfo(surveyPath);
        }
    }


    function refreshComplete() {
        updateSurveyData();
        refreshing = false;
        progressPanel.close();
        refreshList();
    }

    function refreshError(error) {
        refreshing = false;
        progressPanel.closeError(progressPanel.title, error.message, "Code %1".arg(error.code));
    }

    //--------------------------------------------------------------------------

    function getServiceInfo(surveyPath) {

        function setFeatureServiceUrl(url) {
            var urlInfo = AppFramework.urlInfo(url);

            if (portal.ssl) {
                urlInfo.scheme = "https";
            }

            console.log(logCategory, "setFeatureServiceUrl:", urlInfo.url);

            xformFeatureService.surveyPath = surveyPath;
            xformFeatureService.featureServiceUrl = urlInfo.url;
        }

        function getSurveyInfoUrl() {
            var submissionUrl = getSubmissionUrl(surveyPath);
            if (submissionUrl > "") {
                return submissionUrl;
            }

            // Fallback for backwards compatibility for old surveys

            console.warn(logCategory, "Falling back to service url in .info");

            var surveyInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".info");

            return surveyInfo.serviceInfo.url;
        }

        var surveyFileInfo = AppFramework.fileInfo(surveyPath);
        var surveyItemInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".itemInfo");

        progressPanel.title = qsTr("Getting service information");

        if (surveyItemInfo.id > "" && surveyItemInfo.type === "Form") {
            survey2ServiceRequest.requestUrl(surveyItemInfo.id, function(url) {
                console.log(logCategory, "Survey2Service url:", url);
                if (url > "") {
                    setFeatureServiceUrl(url);
                } else {
                    setFeatureServiceUrl(getSurveyInfoUrl())
                }
            });
        } else {
            setFeatureServiceUrl(getSurveyInfoUrl())
        }
    }

    //--------------------------------------------------------------------------

    function getSubmissionUrl(surveyPath) {
        var xml = AppFramework.userHomeFolder.readTextFile(surveyPath);
        var json = AppFramework.xmlToJson(xml);

        var submission = {};

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;
        }

        console.log(logCategory, "submission:", JSON.stringify(submission, undefined, 2));

        return submission["@action"];
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: survey2ServiceRequest

        property var callback

        portal: app.portal

        onSuccess: {
            // console.log(logCategory, Survey2Service:", JSON.stringify(response, undefined, 2));

            if (response.total > 0) {
                callback(response.relatedItems[0].url);
            } else {
                callback();
            }
        }

        onFailed: {
            callback();
        }

        onProgressChanged: {
        }

        function requestUrl(itemId, callback) {
            survey2ServiceRequest.callback = callback;
            url = portal.restUrl + "/content/items/" + itemId + "/relatedItems";

            sendRequest({
                            "relationshipType": "Survey2Service",
                            "direction": "forward"
                        });
        }
    }

    //--------------------------------------------------------------------------

    XFormFeatureService {
        id: xformFeatureService

        property string surveyPath

        portal: app.portal
        schema: page.schema

        onServiceReady: {
            queryFeatures();
        }

        onFailed: {
            refreshError(error);
        }

        function isReady(path) {
            return surveyPath === path && featureServiceUrl > "" && featureServiceInfo;
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: queryRequest

        property int layerId
        url: xformFeatureService.featureServiceUrl + "/%1/query".arg(layerId)
        portal: xformFeatureService.portal
        trace: true

        onSuccess: {
            var features = response.features;

            //console.log(logCategory, "query success:", JSON.stringify(response, undefined, 2));

            if (!Array.isArray(features)) {
                console.error(logCategory, "No features array in response:", JSON.stringify(response, undefined, 2));
                features = [];
            }

            addRootFeatures(features);
        }

        onFailed: {
            refreshError(error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: relatedQueryRequest

        property var rowIds;
        property var relatedQueries
        property var relatedQuery

        portal: xformFeatureService.portal
        trace: true

        onSuccess: {
            addRelatedFeatures(relatedQuery, response);
            next();
        }

        onFailed: {
            refreshError(error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function next() {
            if (!relatedQueries.length) {
                refreshComplete();
                return;
            }

            relatedQuery = relatedQueries.shift();
            url = xformFeatureService.featureServiceUrl + "/%1/queryRelatedRecords".arg(relatedQuery.parentLayer.id);

            progressPanel.title = qsTr("Searching for related data (%1)").arg(relatedQuery.name);

            //console.log(logCategory, "related query:", JSON.stringify(relatedQuery, undefined, 2));

            var parentObjectIds = getParentObjectIds(relatedQuery);

            if (parentObjectIds.length <= 0) {
                console.log(logCategory, "Skip related query, no objectIds:", relatedQuery.parentLayer.id, relatedQuery.parentLayer.name)
                Qt.callLater(next);
                return;
            }

            var body = {
                "objectIds": parentObjectIds.join(","),
                "relationshipId": relatedQuery.relationship.id,
                "outFields": relatedQuery.outFields.join(","),
                "outSR": 4326,
                "returnGeometry": true,
                "returnZ": true,
                "returnM": false,
            };

            if (typeof relatedQuery.query === "string" && relatedQuery.query > "") {
                var expression = relatedQuery.query.trim();
                switch (expression.toLowerCase()) {
                case "*" :
                case "yes" :
                case "true" :
                case "true()" :
                    console.log(logCategory, "related query:", relatedQuery.parentLayer.id, relatedQuery.parentLayer.name, "expression:", expression);
                    expression = "";
                    break;

                case "no" :
                case "false" :
                case "false()" :
                    console.log(logCategory, "Skip related query:", relatedQuery.parentLayer.id, relatedQuery.parentLayer.name, "expression:", expression);
                    Qt.callLater(next);
                    return;
                }

                body.definitionExpression = replaceWhereVars(expression);
            }

            if (relatedQuery.orderBy > "") {
                body.orderByFields = relatedQuery.orderBy;
            }


            console.log(logCategory, "related query body:", JSON.stringify(body, undefined, 2));

            sendRequest(body);
        }
    }

    //--------------------------------------------------------------------------

    function getParentObjectIds(relatedQuery) {
        var query = surveyDatabase.query("SELECT objectId FROM Features WHERE layerId = ?",
                                         relatedQuery.parentLayer.id);

        var objectIds = [];

        if (query.first()) {
            do {
                objectIds.push(query.value("objectId"));
            } while (query.next());
        }

        query.finish();

        return objectIds;
    }

    //--------------------------------------------------------------------------

    function queryFeatures() {
        console.log(logCategory, "Refreshing");

        surveyDatabase.clearFeatures();

        console.log(logCategory, arguments.callee.name, "featureServiceInfo:", JSON.stringify(xformFeatureService.featureServiceInfo, undefined, 2));

        surveyDatabase.insertFeatureServices(xformFeatureService.featureServiceInfo);

        xformFeatureService.featureServiceInfo.layers.forEach(function (layer) {
            if (!layer.type || layer.type === Layer.kTypeFeatureLayer) {
                surveyDatabase.insertLayer(xformFeatureService.layerInfos[layer.id]);
            }
        });

        xformFeatureService.featureServiceInfo.tables.forEach(function (table) {
            if (!table.type || table.type === Layer.kTypeTable) {
                surveyDatabase.insertLayer(xformFeatureService.layerInfos[table.id]);
            }
        });

        progressPanel.title = qsTr("Searching for surveys");

        var table = xformFeatureService.schema.schema;
        var layer = xformFeatureService.findLayer(table.tableName);
        if (!layer) {
            console.warn(logCategory, "Default to layer 0 for table:", xformFeatureService.schema.schema.tableName);
            layer = xformFeatureService.findLayer(0, true);
        }

        progressPanel.message = layer.name;

        var outFields = getOutFields(table, layer);

        table.relatedTables.forEach(function (relatedTable) {
            var relatedLayer = xformFeatureService.findLayer(relatedTable.tableName);

            console.log(logCategory, "relatedTable:", relatedTable.tableName, "id:", relatedLayer.id);

            var relationship = xformFeatureService.findRelationship(layer, relatedLayer);

            if (relationship) {
                pushUnique(outFields, relationship.keyField);
            } else {
                console.error(logCategory, "Relationship to child not found for:", relatedTable.tableName);
            }
        });

        function queryProperty(name, defaultValue) {
            return surveyInfo.queryInfo.hasOwnProperty(name) ? surveyInfo.queryInfo[name] : defaultValue;
        }

        var where = replaceWhereVars(queryProperty("where", ""));
        if (!(where > "")) {
            where = "1=1";
        }

        var body = {
            "outFields": queryProperty("outFields", outFields.join(",")),
            "where": where,
            "outSR": queryProperty("outSR", 4326),
            "returnGeometry": queryProperty("returnGeometry", true),
            "returnZ": queryProperty("returnZ", true),
            "returnM": queryProperty("returnM", false),
        };

        var applySpatialFilter = queryProperty("applySpatialFilter", true);
        console.log(logCategory, "applySpatialFilter:", applySpatialFilter, "tabIndex:", tabView.currentIndex, "map:", page.map);

        if (applySpatialFilter && tabView.currentIndex === 1 && page.map) {
            var extent = map.visibleRegion.boundingGeoRectangle();

            body.spatialRel = "esriSpatialRelIntersects";
            body.inSR = 4326;
            body.geometryType = "esriGeometryEnvelope";
            body.geometry = "%1,%2,%3,%4"
            .arg(extent.topLeft.longitude.toString())
            .arg(extent.bottomRight.latitude.toString())
            .arg(extent.bottomRight.longitude.toString())
            .arg(extent.topLeft.latitude.toString());
        }

        console.log(logCategory, "query body:", JSON.stringify(body, undefined, 2));

        queryRequest.layerId = layer.id;
        queryRequest.sendRequest(body);
    }

    //--------------------------------------------------------------------------

    function addRootFeatures(features) {
        console.log(logCategory, "Adding root feature rows:", features.length);

        progressPanel.title = qsTr("Adding %1 rows to inbox").arg(features.length);
        progressPanel.progressBar.minimumValue = 0;
        progressPanel.progressBar.maximumValue = features.length;
        progressPanel.progressBar.value = 0;

        var table = schema.schema;
        var layer = xformFeatureService.findLayer(table.tableName);

        features.forEach(function (feature) {
            progressPanel.progressBar.value++;

            surveyDatabase.insertFeature(layer, feature);
        });

        if (features.length <= 0) {
            refreshComplete();
            return;
        }

        relatedQueryRequest.relatedQueries = [];

        addRelatedQueries(relatedQueryRequest.relatedQueries, table);

        relatedQueryRequest.next();
    }

    //--------------------------------------------------------------------------

    function addRelatedQueries(relatedQueries, parentTable) {
        console.log(logCategory, "addRelatedQueries table:", parentTable.tableName);

        parentTable.relatedTables.forEach(function (relatedTable) {
            addRelatedQuery(relatedQueries, parentTable, relatedTable);
        });

        console.log(logCategory, "relatedQueries:", relatedQueries.length);
    }

    //--------------------------------------------------------------------------

    function addRelatedQuery(relatedQueries, parentTable, relatedTable) {
        var parentLayer = xformFeatureService.findLayer(parentTable.tableName);
        var relatedLayer = xformFeatureService.findLayer(relatedTable.tableName);

        console.log(logCategory, "relatedTable:", relatedTable.tableName, "id:", relatedLayer.id, "esriParameters:", JSON.stringify(relatedTable.esriParameters));

        var query = relatedTable.esriParameters.query;

        if (!(XFormJS.toBoolean(query) || typeof query === "string")) {
            console.log(logCategory, "Skipping related data download:", relatedTable.tableName, "query:", query);
            return;
        }

        var relationship = xformFeatureService.findRelationship(parentLayer, relatedLayer);
        var parentRelationship = xformFeatureService.findRelationship(relatedLayer, parentLayer);

        if (relationship && parentRelationship) {
            var outFields = getOutFields(relatedTable, relatedLayer);

            pushUnique(outFields, parentRelationship.keyField);

            var relatedQuery = {
                parentTable: parentTable,
                parentLayer: parentLayer,
                name: relatedTable.tableName,
                table: relatedTable,
                layer: relatedLayer,
                relationship: relationship,
                parentRelationship: parentRelationship,
                outFields: outFields,
                query: query,
                orderBy: relatedTable.esriParameters.orderBy
            };

            relatedQueries.push(relatedQuery);
        } else {
            console.error(logCategory, "Relationships not found for:", parentTable.tableName, "<=>", relatedTable.tableName);
        }
    }

    //--------------------------------------------------------------------------

    function addRelatedFeatures(relatedQuery, response) {
        console.log(logCategory, "relatedFeatures response:", JSON.stringify(response, undefined, 2));

        var relatedRecordGroups = response.relatedRecordGroups;

        relatedRecordGroups.forEach(function (relatedRecordGroup) {
            var parentObjectId = relatedRecordGroup.objectId;

            console.log(logCategory, "related records:", relatedRecordGroup.relatedRecords.length, "parentObjectId:", parentObjectId);

            relatedRecordGroup.relatedRecords.forEach(function (relatedRecord) {
                surveyDatabase.insertFeature(relatedQuery.layer, relatedRecord, relatedQuery.parentLayer, parentObjectId);
            });
        });

        addRelatedQueries(relatedQueryRequest.relatedQueries, relatedQuery.table);
    }

    //--------------------------------------------------------------------------

    function getOutFields(table, layer) {

        var outFields = [];

        function pushField(name) {
            if (name > "") {
                outFields.push(name);
            }
        }

        pushField(layer.objectIdField);
        pushField(layer.globalIdField);

        var editFieldsInfo = layer.editFieldsInfo || {};

        pushField(editFieldsInfo.editDateField);
        pushField(editFieldsInfo.editorField);
        pushField(editFieldsInfo.creationDateField);
        pushField(editFieldsInfo.creatorField);

        table.fields.forEach(function(field) {

            if (field.esriGeometryType) {
                return;
            }

            if (field.attachment) {
                return;
            }

            var fieldInfo;
            for (var i = 0; i < layer.fields.length; i++) {
                if (layer.fields[i].name === field.name) {
                    fieldInfo = layer.fields[i];
                    break;
                }
            }

            if (fieldInfo) {
                pushUnique(outFields, fieldInfo.name);
            }
        });

        return outFields;
    }

    //--------------------------------------------------------------------------

    function pushUnique(array, value) {
        if (array.indexOf(value) < 0) {
            array.push(value);
        }
    }

    //--------------------------------------------------------------------------

    function replaceWhereVars(where) {
        console.log(logCategory, arguments.callee.name, "where:", JSON.stringify(where));

        var names = ["username", "email", "firstName", "lastName"];

        names.forEach(function (name) {
            var varName = "${" + name + "}";
            var value = "'" + XFormJS.userProperty(app, name) + "'";
            where = XFormJS.replaceAll(where, varName, value);
        });

        return where;
    }

    //--------------------------------------------------------------------------

    function featureToInstance(feature, layer) {
        var instance = {};

        instance[schema.instanceName] = featureToInstanceData(feature, schema.schema, layer);

        return instance;
    }

    //--------------------------------------------------------------------------

    function featureToInstanceData(feature, table, layer) {
        var data = {}

        var keys = Object.keys(feature.attributes);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            data[key] = feature.attributes[key];
        }

        if (table.geometryFieldName && feature.geometry) {
            data[table.geometryFieldName] = feature.geometry;
        }

        formData.setMetaValue(data, formData.kMetaObjectIdField, layer.objectIdField);
        formData.setMetaValue(data, formData.kMetaGlobalIdField, layer.globalIdField);
        formData.setMetaValue(data, formData.kMetaEditMode, formData.kEditModeUpdate);

        // console.log(logCategory, "table:", table.tableName, "feature:", JSON.stringify(feature, undefined, 2), "instanceData:", JSON.stringify(data, undefined, 2));

        return data;
    }

    //--------------------------------------------------------------------------

    function updateSurveyData() {
        xformsDatabase.deleteSurveyBox(surveyInfo.name, xformsDatabase.statusInbox);

        var instanceNameNodeset = "/" + schema.instanceName + "/meta/instanceName";
        formData.instanceNameBinding = schema.findBinding(instanceNameNodeset);

        var table = xformFeatureService.schema.schema;
        var layer = xformFeatureService.findLayer(table.tableName);
        if (!layer) {
            console.log(logCategory, "Default to layer 0 for table:", xformFeatureService.schema.schema.tableName);
            layer = xformFeatureService.findLayer(0, true);
        }

        console.log(logCategory, "Updating survey data:", layer.id, layer.name);

        var jobs = [];
        var query = surveyDatabase.query("SELECT * FROM Features WHERE layerId = ?", layer.id);

        if (query.first()) {
            do {
                var objectId = query.value("objectId");

                if (debug) {
                    console.log(logCategory, "root objectId:", JSON.stringify(objectId));
                }

                jobs.push(buildSurveyInstance(table, layer, objectId, query.values))
            } while (query.next());
        }

        xformsDatabase.addRow(jobs);

        xformsDatabase.finalizeAddRows();

        query.finish();
    }

    //--------------------------------------------------------------------------

    function buildSurveyInstance(table, layer, objectId, values) {
        if (debug) {
            console.log(logCategory, "Build survey values:", JSON.stringify(values, undefined, 2));
        }

        var creationDateField;
        var editDateField;
        if (layer.editFieldsInfo) {
            creationDateField = layer.editFieldsInfo.creationDateField;
            editDateField = layer.editFieldsInfo.editDateField;
        }

        var feature = JSON.parse(values.feature);

        formData.instance = featureToInstance(feature, layer);

        buildRelatedData(table, objectId);


        var rowData = {
            "name": surveyInfo.name,
            "path": surveyPath,
            "data": formData.instance,
            "feature": null, //JSON.stringify(feature),
            "snippet": formData.snippet(layer),
            "status": xformsDatabase.statusInbox,
            "statusText": "",
            "favorite": 0
        };

        if (creationDateField > "") {
            var creationDate = feature.attributes[creationDateField];
            rowData.created = new Date(creationDate);
        } else {
            rowData.updated = invalidDate;
        }

        if (editDateField > "") {
            var editDate = feature.attributes[editDateField];
            rowData.updated = new Date(editDate);
        } else {
            rowData.updated = invalidDate;
        }

        if (debug) {
            console.log(logCategory, "rowData:", JSON.stringify(rowData, undefined, 2));
        }

        return rowData;
    }

    //--------------------------------------------------------------------------

    function buildRelatedData(parentTable, parentObjectId) {
        parentTable.relatedTables.forEach(function (relatedTable) {
            getRelatedData(parentTable, parentObjectId, relatedTable);
        });
    }

    //--------------------------------------------------------------------------

    function getRelatedData(parentTable, parentObjectId, relatedTable) {
        var parentLayer = xformFeatureService.findLayer(parentTable.tableName);
        var relatedLayer = xformFeatureService.findLayer(relatedTable.tableName);

        var tableRows = formData.getTableRows(relatedTable.tableName);

        var query = surveyDatabase.query("SELECT * FROM Features WHERE parentLayerId = ? AND parentObjectId = ? AND layerId = ?",
                                         parentLayer.id,
                                         parentObjectId,
                                         relatedLayer.id);

        if (query.first()) {
            do {
                var objectId = query.value("objectId");
                var feature = JSON.parse(query.value("feature"));
                var featureData = featureToInstanceData(feature, relatedTable, relatedLayer);

                tableRows.push(featureData);

                formData.setTableRowIndex(relatedTable.tableName, tableRows.length - 1);

                buildRelatedData(relatedTable, objectId);
            } while (query.next());
        }

        query.finish();

        console.log(logCategory, "getRelatedData:", parentObjectId, relatedLayer.name, tableRows.length);
    }

    //--------------------------------------------------------------------------

    XFormData {
        id: formData

        schema: page.schema
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        parent: app
        message: xformFeatureService.progressMessage
        progressBar.value: xformFeatureService.progress
        progressBar.visible: progressBar.value > 0

        z: 99999
    }

    //--------------------------------------------------------------------------

    SurveyDatabase {
        id: surveyDatabase

        surveyInfo: page.surveyInfo
        debug: page.debug
        inMemory: true
    }

    //--------------------------------------------------------------------------
}
