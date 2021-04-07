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

import "../Portal"

Item {
    id: surveysRefresh

    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property SurveysModel model
    property bool busy
    property real progress: updateCount > 0 ? updatedCount / updateCount : 0
    property int updateCount
    property int updatedCount
    property int updatesAvailable
    property bool autoRefresh: true
    readonly property bool signedIn: portal.signedIn

    property bool debug: false

    //--------------------------------------------------------------------------

    signal finished()

    //--------------------------------------------------------------------------

    enabled: portal.isOnline

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveysRefresh, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        function refreshCheck() {
            if (!signedIn && !portal.isSigningIn) {
                refresh();
            }
        }

        Qt.callLater(refreshCheck);
    }

    //--------------------------------------------------------------------------

    onEnabledChanged: {
        if (enabled && autoRefresh) {
            refresh();
            autoRefresh = false;
        }
    }

    //--------------------------------------------------------------------------

    onSignedInChanged: {
        if (!signedIn) {
            searchRequest.cancel();
            autoRefresh = true;
            clear();
            finished();
        } else {
            refresh();
        }
    }

    //--------------------------------------------------------------------------

    onUpdatesAvailableChanged: {
        model.updatesAvailable = updatesAvailable;
    }

    //--------------------------------------------------------------------------

    onFinished: {
        busy = false;
    }

    //--------------------------------------------------------------------------

    function clear() {
        console.log(logCategory, arguments.callee.name, model.count);

        for (var i = 0; i < model.count; i++) {
            model.setProperty(i, "updateAvailable", false);
        }

        updatesAvailable = 0;
    }

    //--------------------------------------------------------------------------

    function refresh() {
        console.log(logCategory, arguments.callee.name, "surveys:", model.count);

        if (!enabled) {
            return;
        }

        if (busy) {
            console.warn(logCategory, arguments.callee.name, "busy");
            return;
        }

        var ids = [];

        for (var i = 0; i < model.count; i++) {
            var survey = model.get(i);
            if (survey.itemId > "" && (signedIn || survey.access === "public")) {
                ids.push(survey.itemId);
            }
        }

        console.log(logCategory, arguments.callee.name, "ids:", ids.length);

        if (ids.length < 1) {
            return;
        }

        updateCount = ids.length;
        updatedCount = 0;
        updatesAvailable = 0;
        searchRequest.start(ids);
    }

    //--------------------------------------------------------------------------

    PortalSearch {
        id: searchRequest

        property var idList

        portal: surveysRefresh.portal
        num: 25

        onResults: {
            results.forEach(function (result) {
                updateSurvey(result);
            });

            searchNext();
        }

        onFinished: {
            if (!cancelled && updateQuery()) {
                search();
            } else {
                surveysRefresh.finished();
            }
        }

        function start(ids) {
            searchRequest.idList = ids;
            if (updateQuery()) {
                busy = true;
                search();
            }
        }

        function updateQuery() {
            var query = "";
            var numQuery = 0;

            while (idList.length > 0 && numQuery < num) {
                if (numQuery) {
                    query += " OR ";
                }

                query += "id:%1".arg(idList.shift());
                numQuery++;
            }

            q = query;

            if (debug) {
                console.log(logCategory, arguments.callee.name, "numQuery:", numQuery);
            }

            return numQuery;
        }
    }

    //--------------------------------------------------------------------------

    function updateSurvey(itemInfo) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "id:", itemInfo.id);
        }

        var index = model.findByKeyValue("itemId", itemInfo.id);
        if (index < 0) {
            console.warn(logCategory, arguments.callee.name, "id not found:", itemInfo.id);
            return;
        }

        var survey = model.get(index);

        var updateAvailable = itemInfo.modified > survey.itemModified;
        model.setProperty(index, "updateAvailable", updateAvailable);
        model.setProperty(index, "size", itemInfo.size);

        if (updateAvailable) {
            updatesAvailable++;
        }

        updatedCount++;
    }

    //--------------------------------------------------------------------------
}
