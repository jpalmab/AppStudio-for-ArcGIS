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
import ArcGIS.AppFramework.Networking 1.0

import "../Portal"

PortalRequest {
    id: relateditemsRequest
    
    //--------------------------------------------------------------------------

    property string relationshipType
    property string direction: kDirectionForward
    property bool busy: false
    property bool debug

    //--------------------------------------------------------------------------

    readonly property string kDirectionForward: "forward"
    readonly property string kDirectionReverse: "reverse"

    readonly property string kRelationshipSurvey2Data: "Survey2Data"
    readonly property string kRelationshipMap2Area: "Map2Area"
    readonly property string kRelationshipArea2Package: "Area2Package"

    //--------------------------------------------------------------------------

    signal found(var relatedItems);

    //--------------------------------------------------------------------------

    onSuccess: {
        busy = false;
        
        if (debug) {
            console.log(logCategory, relationshipType, JSON.stringify(response, undefined, 2));
        }

        var relatedItems = response.relatedItems || [];

        found(relatedItems);
    }
    
    //--------------------------------------------------------------------------

    onFailed: {
        busy = false;
    }
    
    //--------------------------------------------------------------------------

    function requestRelatedItems(itemId) {
        busy = true;
        
        if (debug) {
            console.log(logCategory, arguments.callee.name, "relationshipType:", relationshipType, "itemId:", itemId);
        }
        
        url = portal.restUrl + "/content/items/" + itemId + "/relatedItems";
        
        sendRequest({
                        "relationshipType": relationshipType,
                        "direction": direction
                    });
    }

    //--------------------------------------------------------------------------
}
