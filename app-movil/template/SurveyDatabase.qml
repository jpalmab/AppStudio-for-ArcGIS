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

import QtQuick 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0

import "../Portal"
import "../XForms"
import "../XForms/XForm.js" as XFormJS
import "SurveyHelper.js" as Helper


XFormSqlDatabase {
    id: database

    //--------------------------------------------------------------------------

    property SurveyInfo surveyInfo
    property url kSqlSchema: "Sql/SurveyDatabaseSchema.sql"
    property url kSqlCreateSpatialIndex: "Sql/CreateSpatialIndex.sql"
    property bool inMemory: true

    //--------------------------------------------------------------------------

    function initialize() {
        databaseName = inMemory ? ":memory:" : surveyInfo.componentFilePath("sqlite");

        console.log("databaseName:", databaseName);

        open();

        initializeProperties();
        initializeSchema();
    }

    //--------------------------------------------------------------------------

    function initializeSchema() {
        var commands = loadSqlCommands(kSqlSchema);

/*
        var createIndexTemplate = loadFile(kSqlCreateSpatialIndex);
        var createIndex = createIndexTemplate.arg("Features").arg("geometry").arg("rowid");
        var createCommands = splitSqlCommands(createIndex, ";;");
        commands = commands.concat(createCommands);
*/

        database.batchExecute(commands, true);

    }

    //--------------------------------------------------------------------------

    function clearFeatures() {
        console.log("Clearing features");

        database.query("DELETE FROM Layers");
        database.query("DELETE FROM Features");
    }


    //--------------------------------------------------------------------------

    function insertFeatureServices(featureServiceInfo) {
    }

    //--------------------------------------------------------------------------

    function insertLayer(layer) {
        if (!layer) {
            console.error(logCategory, arguments.callee.name, "Undefined layer");
            return;
        }

        console.log(logCategory, arguments.callee.name, "id:", layer.id);

        var query = database.query("INSERT INTO Layers (layerId, info) VALUES (?, ?)",
                                   layer.id,
                                   JSON.stringify(layer));
    }

    //--------------------------------------------------------------------------

    function insertFeature(layer, feature, parentLayer, parentObjectId) {

        if (debug) {
            console.log("Inserting feature:", JSON.stringify(feature), "parentLayer:", parentLayer, parentObjectId);
        }

        var attributes = feature.attributes;

        var editFieldsInfo = layer.editFieldsInfo || {};

        var geometry;

//        if (feature.geometry && layer.geometryFieldType === "esriGeometryPoint") {
//            geometry = ST.point(feature.geometry.x, feature.geometry.y, 4326);
//        }


        var query = database.query("INSERT INTO Features (layerId, objectId, globalId, creationDate, creator, editDate, editor, parentLayerId, parentObjectId, geometry, feature) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                   layer.id,
                                   attributes[layer.objectIdField],
                                   (layer.globalIdField > "" ? attributes[layer.globalIdField] : null),
                                   (editFieldsInfo.creationDateField > "" ? attributes[editFieldsInfo.creationDateField] : null),
                                   (editFieldsInfo.creatorField > "" ? attributes[editFieldsInfo.creatorField] : null),
                                   (editFieldsInfo.editDateField > "" ? attributes[editFieldsInfo.editDateField] : null),
                                   (editFieldsInfo.editorField > "" ? attributes[editFieldsInfo.editorField] : null),
                                   (parentLayer ? parentLayer.id : null),
                                   parentObjectId,
                                   geometry,
                                   JSON.stringify(feature));

        if (!query) {
            console.log("Null feature insert");
            return;
        }

        if (query.error) {
            console.log("Invalid feature insert:", query.error.toString());
            return;
        }

        query.finish();
    }

    //--------------------------------------------------------------------------
    /*
    function insertSurvey(layer, feature, data, snippet) {

        var featureId = insertFeature(layer, feature);

        console.log("Inserting survey:", featureId);

        var query = database.query("INSERT INTO Surveys (layerId, objectId, data, snippet) VALUES (?, ?, ?, ?)",
                                   layer.id,
                                   featureId,
                                   JSON.stringify(data),
                                   snippet);

        if (!query) {
            console.log("Null survey insert");
            return;
        }

        if (query.error) {
            console.log("Invalid survey insert:", query.error.toString());
            return;
        }

        query.finish();
    }
*/
    //--------------------------------------------------------------------------
}
