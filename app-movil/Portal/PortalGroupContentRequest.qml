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

PortalRequestsManager {
    id: requestsManager

    //--------------------------------------------------------------------------

    signal contentItem(var itemInfo)

    //--------------------------------------------------------------------------

    function search(query) {
        console.log(logCategory, arguments.callee.name, "query:", query);

        startRequests();

        // Check if we are searching a specific group id

        var tokens = query.match(/^id:([a-f\d]+)$/i);

        if (Array.isArray(tokens) && tokens.length > 1) {
            requestGroupContent(tokens[1]);
        } else {
            requestGroups(query);
        }
    }

    //--------------------------------------------------------------------------

    function requestGroups(query) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "query:", query);
        }

        var request = createRequestObject(groupSearchRequest,
                                          {
                                              q: query
                                          });

        request.search();
    }

    //--------------------------------------------------------------------------

    function requestGroupContent(groupId) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "groupId:", groupId);
        }

        var request = createRequestObject(groupContentRequest,
                                          {
                                              groupId: groupId
                                          });

        request.search();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(requestsManager, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: groupSearchRequest

        PortalSearchRequest {
            portal: requestsManager.portal
            url: portal.restUrl + "/community/groups"

            onResults: {
                results.forEach(function (itemInfo) {
                    requestGroupContent(itemInfo.id);
                });
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: groupContentRequest

        PortalSearchRequest {
            property string groupId

            portal: requestsManager.portal
            url: portal.restUrl + "/content/groups/%1/search".arg(groupId)

            onResults: {
                results.forEach(function (itemInfo) {
                    contentItem(itemInfo);
                });
            }
        }
    }

    //--------------------------------------------------------------------------
}
