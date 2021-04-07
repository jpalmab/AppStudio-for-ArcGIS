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

import "../Portal"
import "../XForms"

Item {
    id: addInContext
    
    //----------------------------------------------------------------------

    property AddIn addIn
    property Portal portal
    property Item instance

    //----------------------------------------------------------------------

    property alias surveysModel: surveysModel
    property var position: ({})
    property string currentMode

    readonly property string databasePath: AppFramework.fileFolder(AppFramework.offlineStoragePath).folder("Databases").filePath(Qt.md5(surveysDatabase.dbIdentifer) + ".sqlite")

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addInContext, true)
    }

    //----------------------------------------------------------------------

    function openPage(name, parameters) {
        if (typeof name === "object") {
            var params = parameters || {};

            console.log(logCategory,arguments.callee.name,  "name:", name, "parameters:", JSON.stringify(params));

            mainStackView.push(contentPage,
                               {
                                   contentComponent: name,
                                   title: params.title
                               });
            return;
        }
        
        switch (name) {
        case "surveysGallery":
            mainStackView.pushSurveysGalleryPage();
            break;
            
        case "settings":
            showSettingsPage();
            break;

        default:
            console.error(logCategory, arguments.callee.name, "Unknown page name:", name);
            break;
        }
    }
    
    //----------------------------------------------------------------------

    function openWebPage(url) {
        mainStackView.push(webPage,
                           {
                               url: url
                           });
    }

    //----------------------------------------------------------------------
    
    function openView(component) {
        mainStackView.push(component,
                           {
                           });
    }
    
    //----------------------------------------------------------------------

    function openSurvey(itemId, parameters) {
        var surveyItem = findSurveyItem(itemId);

        console.log(logCategory, arguments.callee.name, "id:", itemId, surveyItem);

        if (!surveyItem) {
            return false;
        }

        if (!parameters) {
            parameters = {};
        }

        parameters.itemId = itemId;

        var surveyPath = app.surveysFolder.filePath(surveyItem.survey);

        var surveyViewPage = {
            item: surveyView,
            properties: {
                surveyPath: surveyPath,
                rowid: null,
                parameters: parameters
            }
        }

        var item = mainStackView.push(surveyViewPage);

        return !!item;
    }

    //----------------------------------------------------------------------

    function editSurvey(survey) {

        console.log(logCategory, arguments.callee.name, "survey:", JSON.stringify(survey, undefined, 2));

        var surveyViewPage = {
            item: surveyView,
            properties: {
                surveyPath: survey.path,
                surveyInfoPage: null,//surveyInfoPage,
                rowid: survey.rowid,
                rowData: survey.data,
                isCurrentFavorite: survey.favorite > 0
            }
        }

        mainStackView.push(surveyViewPage);
    }

    //----------------------------------------------------------------------

    function findSurveyItem(itemId) {
        console.log(logCategory, arguments.callee.name, "itemId:", itemId, "count:", surveysModel.count);

        for (var i = 0; i < surveysModel.count; i++) {
            var surveyItem = surveysModel.get(i);
            //console.log("Survey itemId:", surveyItem.itemId, "name:", surveyItem.name, "title:", surveyItem.title);
            if (surveyItem.itemId === itemId || surveyItem.title === itemId || surveyItem.path === itemId) {
                return surveyItem;
            }
        }

        return null;
    }

    //----------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        formsFolder: surveysFolder
    }

    //----------------------------------------------------------------------
    
    function close() {
        page.closePage();
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: contentPage

        AddInContentPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: webPage

        WebPage {
        }
    }

    //----------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: app.positionSourceManager
        listener: "AddIn: %1".arg(addInContext.parent.title)

        onNewPosition: {
            addInContext.position = position;
        }
    }

    function startLocationSensor() {
        positionSourceConnection.start();
    }

    function stopLocationSensor() {
        positionSourceConnection.stop();
    }

    //----------------------------------------------------------------------

    property var surveyCache: ({})

    function getSurvey(path) {
        var survey = surveyCache[path];
        if (survey) {
            return survey;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, arguments.callee.name, "File not found:", fileInfo.pathName);
            return;
        }

        survey = findSurveyItem(path);
        if (!survey) {
            console.error(logCategory, arguments.callee.name, "Path not found:", path);
            return;
        }

        surveyCache[path] = survey;

        return survey;
    }

    //----------------------------------------------------------------------

    property var schemaCache: ({})

    function getSchema(path) {
        //console.log("getSchema:", path);

        var schema = schemaCache[path];
        if (schema) {
            return schema;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error(logCategory, arguments.callee.name, "File not found:", fileInfo.pathName);
            return;
        }

        var xml = fileInfo.folder.readTextFile(fileInfo.fileName);
        var json = AppFramework.xmlToJson(xml);
        //console.log("schema json:", JSON.stringify(json, undefined, 2));

        schema = schemaComponent.createObject(app);
        schema.update(json);

        schemaCache[path] = schema;

        //console.log("getSchema path:", path, "schmema name:", schema.schema.name);

        return schema;
    }

    Component {
        id: schemaComponent

        XFormSchema {
        }
    }

    function querySurveyData(where) {
        var db = surveysDatabase.open();
        var rows = [];

        var xMin;
        var yMin;
        var xMax;
        var yMax;

        db.transaction(function(tx) {
            var result = tx.executeSql("SELECT rowid, * FROM Surveys");

            for (var i = 0; i < result.rows.length; i++) {
                var row = result.rows.item(i);

                var survey = getSurvey(row.path);
                if (!survey) {
                    continue;
                }

                var schema = getSchema(row.path);
                if (!schema) {
                    continue;
                }

                var data = JSON.parse(row.data);
                var table = schema.schema;

                var geometry;
                var coordinate;

                if (table.geometryField) {
                    geometry = data[table.name][table.geometryFieldName];
                    //console.log("data geometry:", JSON.stringify(geometry, undefined, 2))
                }

                if (geometry) {
                    coordinate = QtPositioning.coordinate(geometry.y, geometry.x);
                } else {
                    coordinate = QtPositioning.coordinate();
                }

                if (coordinate.isValid) {
                    if (i) {
                        xMin = Math.min(xMin, coordinate.longitude);
                        xMax = Math.max(xMax, coordinate.longitude);
                        yMin = Math.min(yMin, coordinate.latitude);
                        yMax = Math.max(yMax, coordinate.latitude);
                    } else {
                        xMin = coordinate.longitude;
                        yMin = coordinate.latitude;
                        xMax = xMin;
                        yMax = yMin;
                    }
                }

                var r = {
                    rowid: row.rowid,
                    name: row.name,
                    path: row.path,
                    data: data,
                    snippet: row.snippet,
                    updated: new Date(row.updated),
                    status: row.status,
                    statusText: row.statusText,
                    geometry: geometry,
                    coordinate: coordinate,
                    thumbnail: survey.thumbnail
                };

                rows.push(r);
            }
        });

        var extent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));

        console.log("surveys extent:", JSON.stringify(extent))

        return rows;
    }

    //----------------------------------------------------------------------

    Component {
        id: positionSourceConnectionComponent


        XFormPositionSourceConnection {
            positionSourceManager: app.positionSourceManager
            stayActiveOnError: true
        }
    }

    function createPositionSourceConnection(parent, properties) {
        console.log(arguments.callee.name, "parent:", parent, "properties:", JSON.stringify(properties));

        var connection = positionSourceConnectionComponent.createObject(parent, properties);

        console.log("connection:", connection);

        return connection;
    }

    //----------------------------------------------------------------------

    function showSettingsPage() {
        mainStackView.push(addInSettingsPage);
    }

    //----------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        AddInSettingsPage {
            addIn: addInContext.addIn
            instance: addInContext.instance
        }
    }

    //----------------------------------------------------------------------
}
