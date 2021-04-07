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
    id: requestsManager

    //--------------------------------------------------------------------------

    property Portal portal
    property bool active: false

    property bool debug: false
    property int count: 0

    readonly property bool busy: count > 0

    //--------------------------------------------------------------------------

    signal started()
    signal failed(var error)
    signal finished()

    //--------------------------------------------------------------------------

    onCountChanged: {
        if (debug) {
            console.log(logCategory, "onCountChanged:", count);
        }

        if (active && !count) {
            active = false;
            finished();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(requestsManager, true)
    }

    //--------------------------------------------------------------------------

    function startRequests() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        active = true;
        started();
    }

    //--------------------------------------------------------------------------

    function createRequestObject(component, properties) {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        var request = component.createObject(requestsManager, properties || {});

        if (debug) {
            console.log(logCategory, arguments.callee.name, "request:", request);
        }

        request.success.connect(requestSuccess);
        request.failed.connect(requestFailed);
        request.Component.destruction.connect(requestDestruction);

        count++;

        return request;
    }

    //--------------------------------------------------------------------------

    function requestSuccess(request) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "request:", request);
        }

        destroyRequest(request);
    }

    //--------------------------------------------------------------------------

    function requestFailed(request, error) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "request:", request, "error:", JSON.stringify(error, undefined, 2));
        }

        destroyRequest(request);
    }

    //--------------------------------------------------------------------------

    function destroyRequest(request) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "request:", request);
        }

        count--;

        request.destroy();
    }

    //--------------------------------------------------------------------------

    function requestDestruction() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }
    }

    //--------------------------------------------------------------------------
}
