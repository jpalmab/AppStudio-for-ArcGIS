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

    readonly property var kRelatedAreaTypes: [
        "Web Map"
    ]

    //--------------------------------------------------------------------------

    signal found(var relatedItems)
    signal relatedItem(var itemInfo)

    //--------------------------------------------------------------------------

    onFound: {
        relatedItems.forEach(function (itemInfo) {
            relatedItem(itemInfo);
        });
    }

    //--------------------------------------------------------------------------

    onRelatedItem: {
        if (kRelatedAreaTypes.indexOf(itemInfo.type) >= 0) {
            var request = requestsManager.createRequestObject(relatedAreasRequest);
            request.mapItemInfo = itemInfo;
            request.requestRelatedItems(itemInfo.id);
        }
    }

    //--------------------------------------------------------------------------

    function requestRelatedItems(itemId) {
        startRequests();
        var request = requestsManager.createRequestObject(relatedDataRequest);
        request.requestRelatedItems(itemId);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(requestsManager, true)
    }

    //--------------------------------------------------------------------------

    Component {
        id: relatedDataRequest
        
        RelatedItemsRequest {
            portal: requestsManager.portal

            relationshipType: kRelationshipSurvey2Data

            onFound: {
                requestsManager.found(relatedItems);
            }

            onFailed: {
                requestsManager.failed(error);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: relatedAreasRequest
        
        RelatedItemsRequest {
            property var mapItemInfo

            portal: requestsManager.portal
            
            relationshipType: kRelationshipMap2Area
            
            onFound: {
                relatedItems.forEach(function (relatedItem) {
                    if (debug) {
                        console.log(logCategory, relationshipType, JSON.stringify(relatedItem, undefined, 2));
                    }

                    var request = requestsManager.createRequestObject(relatedPackagesRequest);
                    request.mapItemInfo = mapItemInfo;
                    request.areaItemInfo = relatedItem;
                    request.requestRelatedItems(relatedItem.id);
                });
            }
            
            onFailed: {
                requestsManager.failed(error);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: relatedPackagesRequest
        
        RelatedItemsRequest {
            property var mapItemInfo
            property var areaItemInfo

            portal: requestsManager.portal
            
            relationshipType: kRelationshipArea2Package
            
            onFound: {
                var items = [];

                relatedItems.forEach(function (itemInfo) {
                    itemInfo.itemTitle = itemInfo.title;
                    itemInfo.title = areaItemInfo.title;
                    itemInfo.mapItemInfo = mapItemInfo;
                    itemInfo.areaItemInfo = areaItemInfo;

                    items.push(itemInfo);
                });

                requestsManager.found(items);
            }
            
            onFailed: {
                requestsManager.failed(error);
            }
        }
    }

    //--------------------------------------------------------------------------
}
