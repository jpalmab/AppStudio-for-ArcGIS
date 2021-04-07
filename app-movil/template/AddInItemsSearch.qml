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

import ArcGIS.AppFramework 1.0

import "../Portal"

PortalSearch {
    id: searchRequest
    
    property bool busy: false
    property AddInsModel addInsModel

    //--------------------------------------------------------------------------

    readonly property string kType: "Survey123 Add In"

    readonly property string kSurvey123OrgId: "jMCHJcLe13FaKCFB" // TODO Make this an appinfo/appschema property
    property bool allowFromEsri: true

    //--------------------------------------------------------------------------

    //        sortField: searchModel.sortProperty
    //        sortOrder: searchModel.sortOrder
    num: 25
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }
    
    //--------------------------------------------------------------------------

    onSuccess: {
        console.log(logCategory, "# results:", response.results.length);

        response.results.forEach(function (result) {
            addInsModel.appendItem(result);
        });
        
        if (response.nextStart > 0) {
            addInsModel.sort();
            search(response.nextStart);
        } else {
            addInsModel.sort();
            addInsModel.updated();
            busy = false;
        }
    }

    //--------------------------------------------------------------------------

    function startSearch() {
        var query = 'type:"%1"'.arg(kType);

        if (allowFromEsri) {
            query += ' AND (orgid:%1 OR orgid:%2)'.arg(kSurvey123OrgId).arg(portal.user.orgId);
        } else {
            query += ' AND orgid:%1'.arg(portal.user.orgId);
        }

        q = query;

        console.log(logCategory, "Searching for add-ins:", query);

        addInsModel.updateLocal();
        busy = true;
        search();
    }

    //--------------------------------------------------------------------------
}
