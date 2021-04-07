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

Item {
    id: searchRequest

    //--------------------------------------------------------------------------

    property alias portal: portalSearch.portal
    property alias url: portalSearch.url
    property alias num: portalSearch.num
    property alias q: portalSearch.q
    property alias sortField: portalSearch.sortField
    property alias sortOrder: portalSearch.sortOrder
    property alias bbox: portalSearch.bbox

    property var search: portalSearch.search

    //--------------------------------------------------------------------------
    
    signal results(var results)
    signal success(var request)
    signal failed(var request, var error)
    
    //--------------------------------------------------------------------------

    PortalSearch {
        id: portalSearch
        
        onResults: {
            searchRequest.results(results);
            searchNext();
        }
        
        onFailed: {
            searchRequest.failed(searchRequest, error);
        }
        
        onFinished: {
            searchRequest.success(searchRequest);
        }
    }

    //--------------------------------------------------------------------------
}
