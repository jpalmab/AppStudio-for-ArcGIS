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

import QtQuick 2.9
import ArcGIS.AppFramework 1.0

NetworkRequest {
    method: "GET"

    property var geocoderData: null
    property int geocoderIndex: -1
    property var cachedObject: null
    property int tryCount: 0

    signal tokenCheckComplete(var spec, int index, bool requiresToken)

    onReadyStateChanged: {

        if (readyState === NetworkRequest.DONE) {

            tryCount++;

            try {
                var serverResponse = JSON.parse(response);

                if (serverResponse.error) {

                    if (serverResponse.error.code === 498 && tryCount === 1) {
                        geocoderData.requiresToken = 0;
                        tokenCheckComplete(geocoderData, geocoderIndex, false);
                        return;
                    }

                    geocoderData.requiresToken = -1;
                    tokenCheckComplete(geocoderData, geocoderIndex, undefined);
                    return;
                }

                geocoderData.requiresToken = 1;
                tokenCheckComplete(geocoderData, geocoderIndex, true);
            }
            catch(e) {
                geocoderData.requiresToken = -1;
                tokenCheckComplete(geocoderData, geocoderIndex, undefined);
            }
        }
    }

    onError: {
    }

    onErrorCodeChanged: {
    }

    onErrorTextChanged: {
    }
}
