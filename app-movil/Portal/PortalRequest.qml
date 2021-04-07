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

NetworkRequest {
    id: request

    //--------------------------------------------------------------------------

    property Portal portal
    property bool trace: false

    //--------------------------------------------------------------------------

    signal success(var request);
    signal failed(var request, var error)

    //--------------------------------------------------------------------------

    responseType: "json"
    method: "POST"
    ignoreSslErrors: portal && portal.ignoreSslErrors

//    headers {
//        referrer: portal.portalUrl
//    }

    // TODO : This is a work around for above crashing when portal changes

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(request, true)
    }

    //--------------------------------------------------------------------------

    onPortalChanged: {
        if (portal) {
            headers.referrer = portal.portalUrl.toString();
        }
    }

    onReadyStateChanged: {
        //console.log(logCategory, "portalRequest readyState", readyState);

        if (readyState === NetworkRequest.ReadyStateComplete)
        {
            //console.log(logCategory, "portalRequest status", status, statusText, "responseText", responseText);

            if (status === 200) {
                if (responsePath) {
                    success(request);
                } else {
                    if (response.error) {
                        failed(request, response.error);
                    } else {
                        success(request);
                    }
                }
            } else {
                console.error(logCategory, "PortalRequest status:", status, statusText);

                failed(request,
                       {
                           code: status,
                           message: statusText
                       });
            }
        }
    }

    //--------------------------------------------------------------------------

    onErrorTextChanged: {
        console.error(logCategory, "portalRequest:", url, "error", errorText);
    }

    //--------------------------------------------------------------------------

    onFailed: {
        console.error(logCategory, "PortalRequest failed: url", url, "error", JSON.stringify(error, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function sendRequest(formData) {
        if (!formData) {
            formData = {};
        }

        if (portal.token > "") {
            formData.token = portal.token;
        }

        if (responseType === "json") {
            formData.f = "pjson";
        }

        if (trace) {
            console.log(logCategory, "formData:", JSON.stringify(formData, undefined, 2));
        }

        headers.userAgent = portal.userAgent;
        portal.setRequestCredentials(this, "PortalRequest");
        send(formData);
    }

    //--------------------------------------------------------------------------
}
