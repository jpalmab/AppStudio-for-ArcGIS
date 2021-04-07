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
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

PortalRequest {
    id: portalRequest
    
    //--------------------------------------------------------------------------

    property int num: 10
    property string q
    property string sortField
    property string sortOrder
    property MapRectangle bbox

    readonly property real searchProgress: total > 0 ? Math.min(1, count / total) : -1
    property int count: 0
    property int total: -1

    property bool active: false
    property bool cancelled: false

    property bool debug: false

    //--------------------------------------------------------------------------

    signal started()
    signal results(var results)
    signal finished()

    //--------------------------------------------------------------------------

    url: portal ? portal.restUrl + "/search" : ""
    
    //--------------------------------------------------------------------------

    property LoggingCategory logCategory: LoggingCategory {
        name: AppFramework.typeOf(portalRequest, true)
    }

    //--------------------------------------------------------------------------

    function search(start) {
        if (start < 0) {
            return;
        }

        if (!start) {
            start = 1;
        }

        if (start === 1) {
            count = 0;
            total = -1;
            cancelled = false;
            active = true;
            started();
        }

        var formData = {
            "q": q,
            "start": start,
            "num": num
        };

        if (bbox) {
            formData.bbox = bbox.topLeft.longitude.toString() + "," +
                    bbox.bottomRight.latitude.toString() + "," +
                    bbox.bottomRight.longitude.toString() + "," +
                    bbox.topLeft.latitude.toString();
        }

        if (sortField > "") {
            formData.sortField = sortField;
        }

        if (sortOrder > "") {
            formData.sortOrder = sortOrder;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "data:", JSON.stringify(formData, undefined, 2));
        }

        portalRequest.sendRequest(formData);
    }

    //--------------------------------------------------------------------------

    function searchNext() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "nextStart:", response.nextStart, "cancelled:", cancelled);
        }

        if (!cancelled && response.nextStart > 0) {
            search(response.nextStart);
        } else {
            active = false;
            finished();
        }
    }

    //--------------------------------------------------------------------------

    function cancel() {
        if (!active) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "q:", q);
        cancelled = true;
    }

    //--------------------------------------------------------------------------

    onSuccess: {
        if (response.total) {
            total = response.total;
        }

        if (response.num) {
            count = Math.min(total, count + response.num);
        }

        if (debug) {
//            console.log(logCategory, "searchResponse:", JSON.stringify(response, undefined, 2));
            console.log(logCategory, "Search response: total:", response.total, "start:", response.start, "num:", response.num, "nextStart:", response.nextStart);
            console.log(logCategory, "Search progress:", searchProgress);
        }

        results(response.results);
    }

    //--------------------------------------------------------------------------
}
