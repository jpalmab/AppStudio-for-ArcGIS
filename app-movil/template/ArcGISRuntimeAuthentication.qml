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

import Esri.ArcGISRuntime 100.7

import ArcGIS.AppFramework 1.0

import "../Portal" as AppPortal

Item {
    id: runtimeAuthentication

    //--------------------------------------------------------------------------

    property AppPortal.Portal appPortal: app.portal
    property bool reuseCredential: false

    property bool debug: false
    
    //--------------------------------------------------------------------------

    signal licenseChanged(var licenseInfo)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "enabled:", enabled);
        AuthenticationManager.credentialCacheEnabled = true;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(runtimeAuthentication, true)
    }

    //--------------------------------------------------------------------------

    Credential {
        id: userCredential

        //authenticationType: Enums.AuthenticationTypeToken

        oAuthClientInfo: OAuthClientInfo {
            oAuthMode: Enums.OAuthModeUser
            clientId: appPortal.clientId
        }

        oAuthRefreshToken: appPortal.refreshToken

        referer: appPortal.portalUrl

        //sslRequired: appPortal.sll

        token: appPortal.token
        tokenServiceUrl: appPortal.tokenServicesUrl
        tokenExpiry: appPortal.expires

        /*

        authenticatingHost : url
        oAuthAuthorizationCode : string
        password : string
        pkcs12Info : Pkcs12Info
        username : string
                      */
    }

    //--------------------------------------------------------------------------

    OAuthClientInfo {
        id: clientInfo

        oAuthMode: Enums.OAuthModeUser
        clientId: appPortal.clientId
    }

    //--------------------------------------------------------------------------

    Connections {
        target: AuthenticationManager
        enabled: runtimeAuthentication.enabled

        onAuthenticationChallenge: {
            if (debug) {
                console.log(logCategory, "onAuthenticationChallenge -")
                console.log(logCategory, " - authenticatingHost:", challenge.authenticatingHost );
                console.log(logCategory, " - authenticationChallengeType:", challenge.authenticationChallengeType);
                console.log(logCategory, " - authorizationUrl:", challenge.authorizationUrl);
                console.log(logCategory, " - failureCount:", challenge.failureCount);
                console.log(logCategory, " - requestUrl:", challenge.requestUrl);
            }

            var credential;

            if (reuseCredential) {
                if (debug) {
                    console.log(logCategory, "Reusing credential");
                }

                credential = userCredential;
            } else {
                credential = createCredentialObject();
            }

            if (credential) {
                challenge.continueWithCredential(credential);
            }
        }
    }

    //--------------------------------------------------------------------------

    function createCredentialObject() {
        if (!appPortal.signedIn) {
            console.log(logCategory, arguments.callee.name, "Not signed in");
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "username:", appPortal.user.username);
        }

        var credential = ArcGISRuntimeEnvironment.createObject("Credential",
                                                               {
                                                                   oAuthClientInfo: clientInfo,
                                                                   oAuthRefreshToken: appPortal.refreshToken,
                                                                   referer: appPortal.portalUrl,
                                                                   token: appPortal.token,
                                                                   tokenServiceUrl: appPortal.tokenServicesUrl,
                                                                   tokenExpiry: appPortal.expires,
                                                               });

        return credential;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: appPortal

        onSignedInChanged: {
            if (appPortal.signedIn) {
                licenseUser();
            }
        }
    }

    //--------------------------------------------------------------------------

    function licenseUser() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        var credential = createCredentialObject();
        var portal = ArcGISRuntimeEnvironment.createObject("Portal",
                                                           {
                                                               url: appPortal.portalUrl,
                                                               credential: credential
                                                           });

        function setRuntimeLicence () {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "fetchLicenseInfoStatus:", portal.fetchLicenseInfoStatus);
            }

            if (portal.fetchLicenseInfoStatus === Enums.TaskStatusCompleted) {
                var licenseInfo = portal.fetchLicenseInfoResult;
                var result = ArcGISRuntimeEnvironment.setLicense(licenseInfo);

                console.log(logCategory, arguments.callee.name, "licenseStatus:", result.licenseStatus);

                licenseChanged(result);
            }
        }

        portal.fetchLicenseInfoStatusChanged.connect(setRuntimeLicence);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "Fetching licenseInfo for portal url:", portal.url);
        }

        portal.fetchLicenseInfo();
    }

    //--------------------------------------------------------------------------
}
