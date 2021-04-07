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


Item {
    id: _portal

    //--------------------------------------------------------------------------

    property bool debug: false
    property bool isOnline: Networking.isOnline

    readonly property url kDefaultPortalUrl: "https://www.arcgis.com"

    readonly property bool signedIn: user && token > "" && versionCompare(currentVersion, minimumVersion) >= 0 && validAppAccess

    property string name: "ArcGIS Online"
    property url portalUrl: kDefaultPortalUrl
    property url tokenServicesUrl
    property url owningSystemUrl: portalUrl
    readonly property url restUrl: owningSystemUrl + "/sharing/rest"
    property string username
    property string password
    property bool rememberMe: false
    property string token
    property bool ssl: false
    property bool ignoreSslErrors: false
    property bool isPortal: false
    property bool busy: false
    property bool isBusy: false
    property bool clientMode: true
    property bool canPublish: false
    property bool supportsOAuth: true
    property bool externalUserAgent: false //singleInstanceSupport
    property bool networkAuthentication: false
    property string networkUsername
    property string networkPassword
    property bool singleSignOn: false
    property bool validAppAccess: true
    property bool pkiAuthentication: false
    property string pkiFile: ""
    property string pkiFileName: ""
    property string passPhrase: ""

    readonly property bool isSigningIn: isBusyReadyState(oAuthAccessTokenFromAuthCodeRequest.readyState)
                                        || isBusyReadyState(generateToken.readyState)
                                        || isBusyReadyState(versionRequest.readyState)
                                        || isBusyReadyState(selfRequest.readyState)


    //--------------------------------------------------------------------------

    property App app
    property Settings settings
    property SecureSettings secureSettings: _secureSettings
    property string settingsGroup: "Portal"

    readonly property string kSettingUrl: "url"
    readonly property string kSettingName: "name"
    readonly property string kSettingIgnoreSslErrors: "ignoreSslErrors"
    readonly property string kSettingIsPortal: "isPortal"
    readonly property string kSettingSupportsOAuth: "supportsOAuth"
    readonly property string kSettingExternalUserAgent: "externalUserAgent"
    readonly property string kSettingNetworkAuthentication: "networkAuthentication"
    readonly property string kSettingSingleSignOn: "singleSignOn"

    readonly property string kSettingUsername: "username"
    readonly property string kSettingPassword: "password"
    readonly property string kSettingRememberMe: "rememberMe"

    readonly property string kSettingRefreshToken: "refreshToken"
    readonly property string kSettingDateSaved: "dateSaved"

    readonly property string kSettingPkiAuthentication: "pkiAuthentication"
    readonly property string kSettingPkiFile: "pkiFile"
    readonly property string kSettingPkiFileName: "pkiFileName"
    readonly property string kSettingPassPhrase: "passPhrase"

    //--------------------------------------------------------------------------

    property url surveySystemRequirementsUrl: "http://doc.arcgis.com/en/survey123/reference/systemrequirements.htm#ESRI_SECTION1_E952F56D52B74B21B6108FBCFA444BDB"
    property string currentVersion
    property string minimumVersion: "3.10"
    property var versionError: {
        "message": qsTr("Unsupported version of Portal for ArcGIS"),
        "details": qsTr("Unsupported portal version. <a href=\"%1\">Please see the Survey123 system requirements.</a>").arg(surveySystemRequirementsUrl)
    }

    //--------------------------------------------------------------------------

    property date expires
    readonly property int defaultExpiration: 120

    property int expiryMargin: 60000

    property var info: null
    property var user: null
    property var orgInfo: null

    property url defaultUserThumbnail: "images/user.png"
    readonly property bool isDefaultUserThumbnail: userThumbnailUrl === defaultUserThumbnail

    //    readonly property url userThumbnailUrl: (token > "" && user && user.thumbnail)
    //                                            ? restUrl + "/community/users/" + user.username + "/info/" + user.thumbnail + "?token=" + token
    //                                            : defaultUserThumbnail

    readonly property url userThumbnailUrl: (user && user.thumbnail)
                                            ? authenticatedImageUrl(restUrl + "/community/users/" + user.username + "/info/" + user.thumbnail)
                                            : defaultUserThumbnail

    readonly property string kRedirectOOB: "urn:ietf:wg:oauth:2.0:oob"

    property string redirectUri: kRedirectOOB
    property string authorizationCode: ""
    property var locale: Qt.locale()
    property string localeName: AppFramework.localeInfo(locale.uiLanguages[0]).esriName
    readonly property string authorizationEndpoint: portalUrl + "/sharing/rest/oauth2/authorize"
    readonly property string authorizationUrl: authorizationEndpoint + "?client_id=" + clientId + "&grant_type=code&response_type=code&expiration=-1&locale=%1&redirect_uri=%2".arg(localeName).arg(redirectUri)
    property string clientId: ""
    property string refreshToken: ""
    property date lastLogin
    property date lastRenewed

    property string signInReason
    property bool autoReSignIn: false

    property string userAgent

    property string redirectFileName: "approval"
    property string redirectHostPath: "localhost/oauth2/" + redirectFileName

    property string appInstallName: app ? app.info.title.replace(/[&\/\\#,+()\[\]$~%.'":*@^=\-_<>?!|;{}\s]/g, '') : ""
    property bool singleInstanceSupport: true//!(Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.platform.os === "linux")
    property bool isStandaloneApp: Qt.application.name === appInstallName
    property string appScheme: app ? app.info.value("urlScheme") || "" : ""
    property string appRedirectUri: "%1://%2".arg(appScheme).arg(redirectHostPath)
    property bool useAppRedirectUri: singleInstanceSupport && isStandaloneApp && appScheme > ""

    property var checkUserPrivileges: _checkUserPrivileges
    property string appAccessClientId1: "arcgisWebApps"
    property string appAccessClientId2: "survey123"

    property bool useImageProvider: false

    //--------------------------------------------------------------------------

    readonly property string kPortalOrgId: "0123456789ABCDEF"

    //--------------------------------------------------------------------------

    signal error(var error)
    signal credentialsRequest()
    signal connecting(var request)
    signal connectError(var request, var error)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        userAgent = buildUserAgent(app);
        readSettings();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(_portal, true)
    }

    //--------------------------------------------------------------------------

    SecureSettings {
        id: _secureSettings

        app: _portal.app
    }

    //--------------------------------------------------------------------------

    onPortalUrlChanged: {
        //signOut(true);
    }

    onSignedInChanged: {
        busy = false;
    }

    //--------------------------------------------------------------------------

    onIsOnlineChanged: {
        if (isOnline && autoReSignIn) {
            autoReSignIn = false;
            autoSignIn();
        }
    }

    //--------------------------------------------------------------------------

    onInfoChanged: {
        if (info) {
            orgInfo = {
                "name": info.name,
                "description": info.description
            };
        } else {
            orgInfo = null;
        }
    }

    onOrgInfoChanged: {
        console.log(logCategory, "orgInfo:", JSON.stringify(orgInfo, undefined, 2))
    }

    //--------------------------------------------------------------------------

    function signIn(reason, prompt) {

        validAppAccess = false;
        signInReason = reason || ""

        console.log(logCategory, "signIn reason:", signInReason,
                    "canAutoSignIn:", canAutoSignIn(),
                    "singleSignOn:", singleSignOn,
                    "prompt:", prompt);

        if (singleSignOn) {
            console.log(logCategory, "Single sign-on");

            autoSignIn();
        } else {
            if (!prompt && canAutoSignIn()) {
                autoSignIn();
            } else {
                credentialsRequest();
            }
        }
    }

    //--------------------------------------------------------------------------

    function signOut(reset) {
        Networking.clearAccessCache();
        Networking.pkcs12 = null;

        console.log(logCategory, "signOut");
        token = "";
        user = null;
        canPublish = false;
        refreshToken = "";
        networkUsername = "";
        networkPassword = "";
        validAppAccess = false;

        expiryTimer.stop();

        clearSignedInState();

        if (reset) {
            tokenServicesUrl = "";
        }
    }

    //--------------------------------------------------------------------------

    function authenticatedImageUrl(url) {
        var authUrl;

        if (typeof url !== "string") {
            url = url.toString();
        }

        if (!useImageProvider || versionToNumber(AppFramework.version) < 4.002) { // < AppStudio V4.2 ?
            if (token > "") {
                authUrl = url + (!AppFramework.urlInfo(url).hasQuery ? "?" : ":") + "token=" + token;
            } else {
                authUrl = url;
            }
        } else {
            authUrl = "image://arcgis/" + url;
        }

        if (debug || useImageProvider) {
            console.log(logCategory, arguments.callee.name, "authUrl:", authUrl);
        }

        return authUrl;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenUrl: {
            processApprovalUrl(url);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: Qt.application

        onStateChanged: {
            console.log(logCategory, "Application state changed:", Qt.application.state);
            switch (Qt.application.state) {
            case Qt.ApplicationActive:
                expiryTimer.reset();
                break;

                //            case Qt.ApplicationInactive:
                //            case Qt.ApplicationSuspended:
                //                expiryTimer.stop();
                //                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function setCredentials(username, password, rememberMe) {
        console.log(logCategory, "Setting credentials:", username);

        _portal.username = username;
        _portal.password = password;
        _portal.rememberMe = rememberMe;

        networkUsername = username;
        networkPassword = password;

        if (!isOnline) {
            return;
        }

        busy = true;

        builtInSignIn();
    }

    //--------------------------------------------------------------------------

    function setAuthorizationCode(authorizationCode) {
        busy = true;
        getTokenFromCode(clientId, redirectUri, authorizationCode);
    }

    //--------------------------------------------------------------------------

    function setRefreshToken(token) {
        refreshToken = token;

        if (refreshToken > "") {
            busy = true;
            getTokenFromRefreshToken(clientId, refreshToken);
        }
    }

    //--------------------------------------------------------------------------

    function setRequestCredentials(networkRequest, purpose) {
        if (networkAuthentication) {
            networkRequest.user = _portal.networkUsername;
            networkRequest.password = _portal.networkPassword;

            console.log(logCategory, "Setting network credentials for:", purpose, "user:", networkRequest.user);
        } else {
            //console.log(logCategory, "Clearing network credentials for:", purpose);

            networkRequest.user = "";
            networkRequest.password = "";
        }
    }

    //--------------------------------------------------------------------------

    function builtInSignIn() {
        if (!isOnline) {
            console.log(logCategory, "Not online")
            return;
        }

        console.log(logCategory, "Single sign-on");

        if (tokenServicesUrl > "") {
            generateToken.generateToken(username, password);
        } else {
            infoRequest.sendRequest();
        }
    }

    //--------------------------------------------------------------------------

    function canAutoSignIn() {
        if (!secureSettings) {
            return false;
        }

        if (pkiAuthentication) {
            return false;
        }

        if (networkAuthentication) {
            return false;
        }

        if (!supportsOAuth) {
            return false;
        }

        var refreshToken = secureSettings.value(settingName(kSettingRefreshToken), "");

        return refreshToken > "";
    }

    function autoSignIn() {
        console.log(logCategory, arguments.callee.name);

        if (!isOnline) {
            console.log(logCategory, arguments.callee.name, "Network is offline");
            return;
        }

        if (!settings || !secureSettings) {
            return;
        }

        console.log(logCategory, "Portal:: Trying to auto-sign-in ...");

        readSettings();

        Networking.clearAccessCache();
        Networking.pkcs12 = null;

        if ( pkiAuthentication ) {
            if ( pkiFile !== "" && pkiFileName !== "" && passPhrase !== "" ) {
                pkiBinaryData.base64 = pkiFile;
                let pkcs12 = Networking.importPkcs12( pkiBinaryData.data, passPhrase );
                if ( pkcs12 ) {
                    Networking.pkcs12 = pkcs12;
                    builtInSignIn();
                }
            }
            return;
        }

        if ( networkAuthentication ) {
            builtInSignIn();
            return;
        }

        if ( singleSignOn ) {
            builtInSignIn();
        } else {
            var refreshToken = secureSettings.value(settingName(kSettingRefreshToken),"")
            var dateSaved = settings.value(settingName(kSettingDateSaved),"")

            lastLogin = dateSaved > "" ? new Date(dateSaved) : new Date()

            console.log(logCategory, "Portal:: Getting saved OAuth info: ", dateSaved, refreshToken);

            if (refreshToken > "") {
                console.log(logCategory, "Portal:: Found stored info, getting token now ...");
                getTokenFromRefreshToken(clientId, refreshToken);
            }
        }
    }

    //--------------------------------------------------------------------------

    function restoreUser(userInfo) {
        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(userInfo, undefined, 2));

        readSettings();

        var refreshToken = secureSettings.value(settingName(kSettingRefreshToken), "");
        if (!refreshToken) {
            console.log(logCategory, arguments.callee.name, "Null refresh token");
            return;
        }

        var dateSaved = settings.value(settingName(kSettingDateSaved), "");

        var user = {
            username: userInfo.username,
            firstName: userInfo.firstName,
            lastName: userInfo.lastName,
            fullName: userInfo.fullName,
            email: userInfo.email,
            description: ""
        }

        var info = {
            name: _portal.name,
            description: "",
            orgId: userInfo.orgId,
            isPortal: _portal.isPortal,

            user: user
        }

        autoReSignIn = true;
        currentVersion = minimumVersion;
        validAppAccess = true;

        _portal.info = info;
        _portal.user = info.user;
        _portal.username = user.username;

        _portal.refreshToken = refreshToken;
        lastLogin = dateSaved > "" ? new Date(dateSaved) : new Date();

        expires = new Date();
        token = "*InvalidToken*";
    }

    //--------------------------------------------------------------------------

    function processApprovalUrl(url) {
        var urlInfo = AppFramework.urlInfo(url);

        // console.log(logCategory, "processApprovalUrl:", url, "fileName:", urlInfo.fileName, urlInfo.fileName.toLowerCase() !== redirectFileName);

        if (urlInfo.fileName.toLowerCase() !== redirectFileName) {
            return false;
        }

        var parameters = urlInfo.queryParameters;

        // console.log(logCategory, "Approval url parameters:", JSON.stringify(parameters, undefined, 2));

        if (parameters.code) {
            setAuthorizationCode(parameters.code);
        }
        else if (parameters.error) {
            var error = {
                message: parameters.error,
                details: [parameters.error_description]
            }

            _portal.error(error);
        }
        else {
            console.error(logCategory, "Unhandled approval url parameters:", JSON.stringify(parameters, undefined, 2));
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function writeSignedInState() {
        if (!settings || !secureSettings) {
            return;
        }

        console.log(logCategory, "Storing signed in values:", settingsGroup);

        secureSettings.setValue(settingName(kSettingRefreshToken), _portal.refreshToken);
        settings.setValue(settingName(kSettingDateSaved), new Date().toString());

        writeUserSettings();
    }

    //--------------------------------------------------------------------------

    function clearSignedInState() {
        if (!settings || !secureSettings) {
            return;
        }

        console.log(logCategory, "Clearing signed in values:", settingsGroup);

        secureSettings.remove(settingName(kSettingRefreshToken));
        settings.remove(settingName(kSettingDateSaved));

        clearUserSettings();
    }

    //--------------------------------------------------------------------------

    function autoLogin() {
        console.log(logCategory, "Portal:: Trying to auto-sign-in ...");

        if (localStorage) {
            var client_id = localStorage.value(settingsGroup + "/client_id","")
            var refresh_token = localStorage.value(settingsGroup + "/refresh_token","")
            var date_saved = localStorage.value(settingsGroup + "/date_saved","")

            _portal.lastLogin = date_saved > "" ? new Date(date_saved) : new Date()

            console.log(logCategory, "Portal:: Getting saved OAuth info: ", client_id, date_saved, refresh_token);

            if(client_id > "" && refresh_token > "") {
                console.log(logCategory, "Portal:: Found stored info, getting token now ...");
                _portal.getTokenFromRefreshToken(client_id, refresh_token);
            }
        }
    }

    //--------------------------------------------------------------------------

    function getTokenFromCode(client_id, redirect_uri, auth_code) {
        if(auth_code > "" && client_id > "") {
            _portal.refreshToken = "";
            _portal.clientId = client_id;

            var params = {
                grant_type: "authorization_code",
                code: auth_code,
                redirect_uri: redirect_uri
            };

            //console.log(logCategory, "getTokenFromCode:", JSON.stringify(params, undefined, 2));

            oAuthAccessTokenFromAuthCodeRequest.sendRequest(params);
        }
    }

    //--------------------------------------------------------------------------

    function getTokenFromRefreshToken(client_id, refresh_token) {
        if(refresh_token > "" && client_id > "") {
            _portal.refreshToken = refresh_token;
            _portal.clientId = client_id;

            var params = {
                grant_type: "refresh_token",
                refresh_token: refresh_token
            };

            //console.log(logCategory, "getTokenFromRefreshToken:", JSON.stringify(params, undefined, 2));

            oAuthAccessTokenFromAuthCodeRequest.sendRequest(params);
        }
    }

    //--------------------------------------------------------------------------

    function renew() {
        if (!isOnline) {
            console.log(logCategory, "Offline, skipping renew");

            return;
        }

        console.log(logCategory, "!!! Inside portal renew !!!");
        console.log(logCategory, _portal.refreshToken, _portal.clientId)
        if (_portal.refreshToken > "" && _portal.clientId > "") {
            getTokenFromRefreshToken(_portal.clientId, _portal.refreshToken)
        }
        else {
            signOut();
        }
    }

    NetworkRequest {
        id: oAuthAccessTokenFromAuthCodeRequest

        url: portalUrl + "/sharing/rest/oauth2/token"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log(logCategory, "oauth token info:", JSON.stringify(response, undefined, 2));

                if (response.error) {
                    _portal.error(response.error);
                    _portal.isBusy = false;
                    signOut();
                } else {
                    if (response.refresh_token) {
                        _portal.refreshToken = response.refresh_token;
                    }
                    _portal.username = response.username || "";
                    _portal.owningSystemUrl = portalUrl;

                    var now = new Date();
                    _portal.lastRenewed = now;

                    setToken(response.access_token || "", new Date(now.getTime() + response.expires_in*1000));

                    logAdditionalInformation.sendRequest({ "f": "json" });

                    _portal.isBusy = false;

                    versionRequest.headers.userAgent = _portal.userAgent;
                    versionRequest.send();
                    selfRequest.sendRequest();
                    _validateAppAccess();
                }
            }
        }

        onErrorTextChanged: {
            _portal.isBusy = false;
            console.log(logCategory, "oAuthAccessTokenRequest error", errorText);
        }

        function sendRequest(params) {
            expiryTimer.stop();

            headers.userAgent = _portal.userAgent;
            params.client_id =  _portal.clientId;

            // console.log(logCategory, "Requesting oauth token:", JSON.stringify(params, undefined, 2));

            _portal.isBusy = true;

            send(params);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: logAdditionalInformation
        url: restUrl + "/community/users/%1".arg(_portal.username)
        method: "POST"

        onReadyStateChanged: {
        }

        function sendRequest(params){
            headers.userAgent = _portal.userAgent;
            params.client_id =  _portal.clientId;
            send(params);
        }
    }

    //--------------------------------------------------------------------------

    function setToken(token, expires) {
        _portal.token = token;
        _portal.expires = expires;

        expiryTimer.reset();
    }

    //--------------------------------------------------------------------------

    function validateToken() {
        if (token > "" && (expires - Date.now()) < expiryMargin) {
            console.log(logCategory, "Clearing expired token");
            token = "";
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: expiryTimer

        onRunningChanged: {
            if (running) {
                console.log(logCategory, "Token expiry timer will trigger in %1 minutes".arg(interval/60000));
            } else {
                console.log(logCategory, "Token expiry timer disabled");
            }
        }

        onTriggered: {
            renew();
        }

        function reset() {
            stop();

            if (token > "" && expires.valueOf()) {
                var msec = expires - Date.now() - expiryMargin;
                if (msec > expiryMargin) {
                    interval = msec;
                    restart();
                    console.log(logCategory, "Reset token expiry timer:", expires, "minutes:", interval / 60000);
                } else {
                    console.log(logCategory, "Triggering expiry action:", msec, "<", expiryMargin);
                    triggered();
                }
            } else {
                console.log(logCategory, "Token expiry timer not restarted");
            }
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: infoRequest

        url: portalUrl + "/sharing/rest/info?f=json"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                //console.log(logCategory, "info:", JSON.stringify(response, undefined, 2));

                if (response.authInfo) {
                    tokenServicesUrl = response.authInfo.tokenServicesUrl;
                    owningSystemUrl = response.owningSystemUrl;
                    generateToken.generateToken(_portal.username, _portal.password);
                }
            }
        }

        onErrorTextChanged: {
            console.log(logCategory, "infoRequest error", errorText);

            var details = "";

            if (errorCode === 201) {
                details = responseText;

                console.error(logCategory, "infoRequest user:", user);

                pkiAuthentication = true;
                writeSettings();

                credentialsRequest();
            }

            if (errorCode === 204) {
                details = responseText;

                console.error(logCategory, "infoRequest user:", user);
            }

            _portal.error( { message: errorText, details: details });
        }

        function sendRequest() {
            console.log(logCategory, "infoRequest sendRequest", url);

            if ( pkiAuthentication ) {
                if ( !Networking.pkcs12 ) {
                    console.error(logCategory, "sendRequest missing PKCS#12 Authentication" );
                    return;
                }
            }

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "infoRequest");
            send();
        }
    }

    NetworkRequest {
        id: generateToken

        url: tokenServicesUrl
        method: "POST"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors
        uploadPrefix: ""

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.error) {
                    console.error(logCategory, "genetateToken error for:", user, username, "error:", JSON.stringify(response.error, undefined, 2));
                    _portal.error(response.error);
                } else if (response.token) {
                    console.log(logCategory, "username", username, "generateToken:", JSON.stringify(response, undefined, 2));
                    ssl = response.ssl;
                    setToken(response.token, new Date(response.expires));

                    // Adjusting our URLS to be SSL-only based on the SSL property obtained from getToken call

                    if (ssl) {
                        portalUrl = httpsUrl(portalUrl);
                        owningSystemUrl = httpsUrl(owningSystemUrl);
                    }

                    versionRequest.sendRequest();
                    selfRequest.sendRequest();
                    _validateAppAccess();
                } else {
                    //
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "generateToken error:", errorText);

            var details = "";
            if (errorCode === 201) {
                details = responseText;

                console.error(logCategory, "generateToken user:", user);

                pkiAuthentication = true;
                writeSettings();

                credentialsRequest();
            }

            if (errorCode === 204) {
                details = responseText;

                console.error(logCategory, "generateToken user:", user);
            }

            _portal.error( { message: errorText, details: details });
        }

        function httpsUrl(url) {
            var urlInfo = AppFramework.urlInfo(url);

            urlInfo.scheme = "https";

            console.log(logCategory, "httpsUrl", url, "->", urlInfo.url);

            return urlInfo.url;
        }

        function generateToken(username, password, expiration, referer) {
            if (!expiration) {
                expiration = defaultExpiration;
            }

            if (!referer) {
                referer = portalUrl;
            }

            var formData = {
                "username": username,
                "password": password,
                "referer": referer,
                "expiration": expiration,
                "f": "json"
            };

            headers.userAgent = _portal.userAgent;

            setRequestCredentials(this, "generateToken");
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: selfRequest

        url: restUrl + "/portals/self"
        method: "POST"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                // console.log(logCategory, "portal self:", JSON.stringify(response, undefined, 2));

                _portal.info = response;

                orgPropertiesRequest.sendRequest();

                if (_portal.info && _portal.info.allSSL) {
                    ssl = _portal.info.allSSL;
                }

                if (_portal.info.user) {
                    var privilegeError = checkUserPrivileges
                            ? checkUserPrivileges(_portal.info.user)
                            : undefined;

                    if (privilegeError) {
                        _portal.error(privilegeError);
                        _portal.signOut();
                    } else {
                        if (isPortal && !_portal.info.user.orgId) {
                            _portal.info.user.orgId = kPortalOrgId;
                        }

                        _portal.username = _portal.info.user.username;
                        _portal.user = _portal.info.user;

                        console.log(logCategory, "portal user:", JSON.stringify(_portal.user, undefined, 2));
                    }
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "selfRequest error:", errorText);
        }

        function sendRequest() {
            var formData = {
                f: "pjson"
            };

            if (_portal.token > "") {
                formData.token = _portal.token;
            }

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "portalSelf");
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: orgPropertiesRequest

        url: restUrl + "/portals/self/resources/localizedOrgProperties?f=json"
        method: "POST"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log(logCategory, "orgProperties:", JSON.stringify(response, undefined, 2));

                if (response.default) {
                    orgInfo = response.default;
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "orgProperties error:", errorText);
        }

        function sendRequest() {
            var formData = {
                f: "pjson"
            };

            if (_portal.token > "") {
                formData.token = _portal.token;
            }

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "orgProperties");
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: versionRequest

        url: restUrl + "?f=json"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.currentVersion) {
                    currentVersion = response.currentVersion;
                    console.log(logCategory, "Portal currentVersion:", currentVersion);

                    if (versionCompare(currentVersion, minimumVersion) < 0) {
                        console.error(logCategory, "Version error:",currentVersion, "<", minimumVersion);
                        _portal.error(versionError);
                    }
                } else {
                    console.error(logCategory, "Invalid version response:", JSON.stringify(response, undefined, 2));
                    currentVersion = "";
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "versionRequest error", errorText);
        }

        function sendRequest() {
            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "versionRequest");
            send();
        }
    }

    //--------------------------------------------------------------------------

    function _validateAppAccess() {
        if (clientMode || (isPortal && versionCompare(currentVersion, "7.1") < 0)) {
            validAppAccess = true;
        } else {
            validateAppAccessRequest.sendRequest(appAccessClientId1);
        }
    }

    NetworkRequest {
        id: validateAppAccessRequest

        url: restUrl + "/oauth2/validateAppAccess"
        responseType: "json"

        property string client_id

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete) {
                console.log(logCategory, "validateAppAccess response:", JSON.stringify(response, undefined, 2));

                if (response.valid) {
                    validAppAccess = true;
                } else {
                    if (client_id === appAccessClientId1) {
                        sendRequest(appAccessClientId2);
                        return;
                    }

                    var error = response.error;
                    if (!error) {
                        error = {
                            message: qsTr("Your account <b>%1</b> is not licensed for Survey123.").arg(_portal.user ? _portal.user.username : ""),
                            details: qsTr("Please ask your organization administrator to assign you a user type that includes Field/Essential Apps, an add-on Field/Essential Apps license, or an add-on Survey123 license.")
                        }
                    }

                    _portal.error(error);
                }
            }
        }

        onErrorTextChanged: {
            console.error(logCategory, "validateAppAccess error", errorText);
        }

        function sendRequest(_client_id) {
            client_id = _client_id;

            var formData = {
                f: "pjson",
                client_id: client_id,
                token: _portal.token
            };

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "validateAppAccess");

            console.log(logCategory, "validateAppAccess:", JSON.stringify(formData, undefined, 2));
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    function settingName(name) {
        return settingsGroup + "/" + name;
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        if (!settings) {
            return false;
        }

        portalUrl = settings.value(settingName(kSettingUrl), "https://www.arcgis.com");
        name = settings.value(settingName(kSettingName), "ArcGIS Online");
        ignoreSslErrors = settings.boolValue(settingName(kSettingIgnoreSslErrors), false);
        isPortal = settings.boolValue(settingName(kSettingIsPortal), false);
        supportsOAuth = settings.boolValue(settingName(kSettingSupportsOAuth), true);
        externalUserAgent = settings.boolValue(settingName(kSettingExternalUserAgent), false); //singleInstanceSupport);
        networkAuthentication = settings.boolValue(settingName(kSettingNetworkAuthentication), false);
        singleSignOn = settings.boolValue(settingName(kSettingSingleSignOn), false);
        pkiAuthentication = settings.boolValue(settingName(kSettingPkiAuthentication), false);

        updateRedirectUri();

        console.log(logCategory, "Portal settings:", name,
                    "url:", portalUrl,
                    "isPortal:", isPortal,
                    "ignoreSslErrors:", ignoreSslErrors,
                    "supportsOAuth:", supportsOAuth,
                    "redirectUri:", redirectUri,
                    "externalUserAgent:", externalUserAgent,
                    "networkAuthentication:", networkAuthentication,
                    "pkiAuthentication:", pkiAuthentication,
                    "pkiFileName:", pkiFileName,
                    "singleSignOn:", singleSignOn);

        readUserSettings();

        console.log(logCategory, "appName:", Qt.application.name, "installName:", appInstallName, "standalone:", isStandaloneApp, "singleInstance:", singleInstanceSupport, "appRedirect:", appRedirectUri, useAppRedirectUri);

        return true;
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        if (!settings) {
            return false;
        }

        console.log(logCategory, "Write portal settings:", name,
                    "url:", portalUrl,
                    "isPortal:", isPortal,
                    "ignoreSslErrors:", ignoreSslErrors,
                    "supportsOAuth:", supportsOAuth,
                    "redirectUri:", redirectUri,
                    "externalUserAgent:", externalUserAgent,
                    "networkAuthentication:", networkAuthentication,
                    "pkiAuthentication:", pkiAuthentication,
                    "pkiFileName:", pkiFileName,
                    "singleSignOn:", singleSignOn);

        settings.setValue(settingName(kSettingUrl), portalUrl);
        settings.setValue(settingName(kSettingName), name);
        settings.setValue(settingName(kSettingIgnoreSslErrors), ignoreSslErrors);
        settings.setValue(settingName(kSettingIsPortal), isPortal);
        settings.setValue(settingName(kSettingSupportsOAuth), supportsOAuth);
        settings.setValue(settingName(kSettingExternalUserAgent), externalUserAgent);
        settings.setValue(settingName(kSettingNetworkAuthentication), networkAuthentication);
        settings.setValue(settingName(kSettingPkiAuthentication), pkiAuthentication);
        settings.setValue(settingName(kSettingPkiFile), pkiFile);
        settings.setValue(settingName(kSettingPkiFileName), pkiFileName);
        settings.setValue(settingName(kSettingSingleSignOn), singleSignOn);

        return true;
    }

    //--------------------------------------------------------------------------

    function readUserSettings() {
        if (!secureSettings) {
            return false;
        }

        networkUsername = username = secureSettings.value(settingName(kSettingUsername), "");
        rememberMe = secureSettings.value(settingName(kSettingRememberMe), "false") === "true";

        if (autoSignIn) {
            networkPassword = password = secureSettings.value(settingName(kSettingPassword), "");
        }

        pkiFile = secureSettings.value(settingName(kSettingPkiFile), "");
        pkiFileName = secureSettings.value(settingName(kSettingPkiFileName), "");
        passPhrase = secureSettings.value(settingName(kSettingPassPhrase), "");

        return true;
    }

    function writeUserSettings() {
        if (!secureSettings) {
            return false;
        }

        secureSettings.setValue(settingName(kSettingRememberMe), _portal.rememberMe ? "true" : "false");

        if (rememberMe && autoSignIn) {
            secureSettings.setValue(settingName(kSettingUsername), _portal.username);
            secureSettings.setValue(settingName(kSettingPassword), _portal.password);
            secureSettings.setValue(settingName(kSettingPkiFile), _portal.pkiFile);
            secureSettings.setValue(settingName(kSettingPkiFileName), _portal.pkiFileName);
            secureSettings.setValue(settingName(kSettingPassPhrase), _portal.passPhrase);
        } else {
            secureSettings.remove(settingName(kSettingUsername));
            secureSettings.remove(settingName(kSettingPassword));
            secureSettings.remove(settingName(kSettingPkiFile));
            secureSettings.remove(settingName(kSettingPkiFileName));
            secureSettings.remove(settingName(kSettingPassPhrase));
        }
    }

    function clearUserSettings() {
        if (!secureSettings) {
            console.warn(logCategory, "clearUserSettings: Sign in settings not persisted");
            return false;
        }

        console.log(logCategory, "Clearing user credentials");

        secureSettings.remove(settingName(kSettingUsername));
        secureSettings.remove(settingName(kSettingPassword));
        secureSettings.remove(settingName(kSettingPkiFile));
        secureSettings.remove(settingName(kSettingPkiFileName));
        secureSettings.remove(settingName(kSettingPassPhrase));
    }

    //--------------------------------------------------------------------------

    function getOSPrettyName(os){
        var niceName = "";

        switch(os) {
        case "osx":
        case "macos":
            niceName = "macOS";
            break;
        case "android":
            niceName = "Android";
            break;
        case "ios":
            niceName = "iOS";
            break;
        case "windows":
            niceName = "Windows";
            break;
        case "linux":
            niceName = "Linux";
            break;
        case "tvos":
            niceName = "tvOS";
            break;
        case "unix":
            niceName = "Unix Other";
            break;
        case "winrt":
            niceName = "WinRT | UWP";
            break;
        default:
            niceName = "Unknown OS";
            break;
        }

        return niceName;
    }

    function buildUserAgent(app) {
        var appName = Qt.application.name > "" ? Qt.application.name : "_appName";
        var appVersion = Qt.application.version > "" ? Qt.application.version : "_appVersion";
        var udid = app.settings.value("udid", "_udidNotAvailable");

        if (app) {
            var deployment = app.info.value("deployment");
            if (!deployment || typeof deployment !== 'object') {
                deployment = {};
            }

            appName = deployment.shortcutName > ""
                    ? deployment.shortcutName
                    : app.info.title;

            appVersion = app.info.version;
        }

        // SDK
        var sdkName = "AppFramework";
        var sdkVersion = AppFramework.version;

        // OS
        var osPrettyName = getOSPrettyName(Qt.platform.os);
        var osVersion = AppFramework.osVersion > "" ? AppFramework.osVersion : "_osVersion";
        var osLocale = Qt.locale().name > "" ? Qt.locale().name : "_unknownLocale";
        var cpuArchitecture = AppFramework.currentCpuArchitecture > "" ? AppFramework.currentCpuArchitecture : "_cpuArchitecture";

        // App
        var qtVersion = "Qt %1".arg(AppFramework.qtVersion);
        var buildAbi = AppFramework.buildAbi > "" ? AppFramework.buildAbi : "_buildAbi";
        var kernalType = AppFramework.kernelType > "" ? AppFramework.kernelType : "_kernalType";
        var kernalVersion = AppFramework.kernelVersion > "" ? AppFramework.kernelVersion : "_kernalVersion"
        var osDisplayName = AppFramework.osDisplayName > "" ? AppFramework.osDisplayName : "_osDisplayName";

        var userAgent = "%1/%2 (%3 %4; %5; %6; %7) %8/%9 (%10; %11; %12) %13/%14"
        .arg(sdkName)
        .arg(sdkVersion)
        .arg(osPrettyName)
        .arg(osVersion)
        .arg(osLocale)
        .arg(cpuArchitecture)
        .arg(udid)
        .arg(appName)
        .arg(appVersion)
        .arg(qtVersion)
        .arg(buildAbi)
        .arg(osDisplayName)
        .arg(kernalType)
        .arg(kernalVersion);

        console.log(logCategory, "userAgent: ", userAgent);

        return userAgent;
    }

    //    function _buildUserAgent(app) {

    //        var userAgent = "";

    //        function addProduct(name, version, comments) {
    //            console.log(logCategory, "name: ", name);
    //            console.log(logCategory, "version: ", version);
    //            console.log(logCategory, "comments: ", comments);

    //            if (!(name > "")) {
    //                return;
    //            }

    //            if (userAgent > "") {
    //                userAgent += " ";
    //            }

    //            name = name.replace(/\s/g, "");
    //            userAgent += name;

    //            if (version > "") {
    //                userAgent += "/" + version.replace(/\s/g, "");
    //            }

    //            if (comments) {
    //                userAgent += " (";

    //                for (var i = 2; i < arguments.length; i++) {
    //                    var comment = arguments[i];

    //                    if (!(comment > "")) {
    //                        continue;
    //                    }

    //                    if (i > 2) {
    //                        userAgent += "; "
    //                    }

    //                    userAgent += arguments[i];
    //                }

    //                userAgent += ")";
    //            }

    //            return name;
    //        }

    //        function addAppInfo(app) {
    //            var deployment = app.info.value("deployment");
    //            if (!deployment || typeof deployment !== 'object') {
    //                deployment = {};
    //            }

    //            var appName = deployment.shortcutName > ""
    //                    ? deployment.shortcutName
    //                    : app.info.title;

    //            var udid = app.settings.value("udid", "");

    //            appName = addProduct(appName, app.info.version, Qt.locale().name, AppFramework.currentCpuArchitecture, udid)

    //            return appName;
    //        }

    //        if (app) {
    //            addAppInfo(app);
    //        } else {
    //            addProduct(Qt.application.name, Qt.application.version, Qt.locale().name, AppFramework.currentCpuArchitecture, Qt.application.organization);
    //        }

    //        addProduct(Qt.platform.os, AppFramework.osVersion, AppFramework.osDisplayName);
    //        addProduct("AppFramework", AppFramework.version, "Qt " + AppFramework.qtVersion, AppFramework.buildAbi);
    //        addProduct(AppFramework.kernelType, AppFramework.kernelVersion);

    //        console.log(logCategory, "userAgent:", userAgent);

    //        return userAgent;
    //    }

    //--------------------------------------------------------------------------

    function setPortal(portalInfo) {

        console.log(logCategory, "setPortal:", JSON.stringify(portalInfo, undefined, 2));

        signOut(true);

        name = portalInfo.name;
        ignoreSslErrors = portalInfo.ignoreSslErrors;
        isPortal = portalInfo.isPortal;
        supportsOAuth = portalInfo.supportsOAuth;
        portalUrl = portalInfo.url;
        externalUserAgent = portalInfo.externalUserAgent;
        networkAuthentication = portalInfo.networkAuthentication;
        pkiAuthentication = portalInfo.pkiAuthentication || false;
        pkiFile = portalInfo.pkiFile || "";
        pkiFileName = portalInfo.pkiFileName || "";
        passPhrase = portalInfo.passPhrase || "";
        singleSignOn = portalInfo.singleSignOn;

        writeSettings();

        updateRedirectUri();
    }

    //--------------------------------------------------------------------------

    function updateRedirectUri() {
        redirectUri = kRedirectOOB;
        if (externalUserAgent && supportsOAuth) {
            if (useAppRedirectUri) {
                redirectUri = appRedirectUri;
            }
        }

        console.log(logCategory, "updateRedirectUri:", redirectUri);
        console.log(logCategory, "appName:", Qt.application.name, "installName:", appInstallName, "standalone:", isStandaloneApp, "singleInstance:", singleInstanceSupport, "appRedirect:", appRedirectUri, useAppRedirectUri);
    }

    //--------------------------------------------------------------------------

    function _checkUserPrivileges(userInfo) {
        console.log(logCategory, "Checking privileges for:", userInfo.username);

        //Need to handle three usecases
        //1. Public Account Free user (no ORG ID) #242
        //2. Survey123 client app needs atleast feature editing permissions #new
        //3. Survey123 Connect app needs atleast 3 permission #154

        var privileges = userInfo.privileges;
        if (!Array.isArray(privileges)) {
            privileges = [];
        }

        var canPublish = privileges.indexOf("portal:publisher:publishFeatures") >= 0;
        var canShare = privileges.indexOf("portal:user:shareToGroup") >= 0;
        var canCreate = privileges.indexOf("portal:user:createItem") >= 0;
        var canEdit = privileges.indexOf("features:user:edit") >= 0;

        var error;

        if (clientMode) {
            if (!canEdit) {
                console.warn(logCategory, "Insufficient Client Privileges");

                error = {
                    message: qsTr("Insufficient Client Privileges"),
                    details: qsTr("Need minimum privileges of Features Edit in your Role. Please contact your ArcGIS Administrator to resolve this issue.")
                }
            }
        } else {
            //this is the connect app and need more privileges
            if (!canCreate || !canPublish || !canShare) {
                //need to alert that this account does not have sufficient privileges
                console.warn(logCategory, "Insufficient Privileges")

                error = {
                    message: qsTr("Insufficient Client Privileges"),
                    details: qsTr("Need minimum privileges of Create content, Publish hosted feature layers and Share with groups in your Role. Please contact your ArcGIS Administrator to resolve this issue.")
                }

                _portal.canPublish = false
            } else {
                _portal.canPublish = true
            }
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function versionToNumber(version) {
        var parts = version.split(".");

        var major = parts.length > 0 ? Number(parts[0]) : 0;
        var minor = parts.length > 1 ? Number(parts[1]) : 0;

        var versionNumber = major + minor / 1000;

        return versionNumber;
    }

    function versionCompare(version1, version2) {
        var num1 = versionToNumber(version1);
        var num2 = versionToNumber(version2);

        if (!isFinite(num1) || !isFinite(num2)) {
            console.error(logCategory, arguments.callee.name, "Invalid version numbers version1:", version1, "version2:", version2);
            return Number.NaN;
        }

        if (num1 < num2) {
            return -1;
        } else if (num1 > num2) {
            return 1;
        } else {
            return 0;
        }
    }

    //--------------------------------------------------------------------------

    function connect(resolved, rejected) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "signedIn:", signedIn);
        }

        if (!signedIn) {
            Qt.callLater(resolved);
            return;
        }

        connectRequest.resolved = resolved;
        connectRequest.rejected = rejected;
        connectRequest.sendRequest();
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: connectRequest

        property var resolved
        property var rejected

        objectName: "connectRequest"

        url: restUrl + "?f=json"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (debug) {
                console.log(logCategory, objectName, "readyState:", readyState);
            }

            connecting(connectRequest);

            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (debug) {
                    console.log(logCategory, objectName, "state:", state, "response:", JSON.stringify(response, undefined, 2));
                }

                if (response.currentVersion) {
                    if (resolved) {
                        Qt.callLater(resolved);
                        resolved = null;
                        rejected = null;
                    }
                } else if (response.error) {
                    sendError(response.error);
                }
            }
        }

        onErrorTextChanged: {
            if (errorText > "") {
                sendError({
                              code: errorCode,
                              message: errorText
                          });
            }
        }

        function sendRequest() {
            if (!isOnline) {
                sendError({
                              code: 0,
                              message: qsTr("Network is offline")
                          });

                return;
            }

            if (debug) {
                console.log(logCategory, objectName, "url:", url);
            }

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, objectName);
            send();
        }

        function retry() {
            sendRequest();
        }

        function cancel() {
            if (rejected) {
                Qt.callLater(rejected);
                resolved = null;
                rejected = null;
            }
        }

        function sendError(error) {
            connectError(connectRequest, error);
        }
    }

    onConnectError: {
        console.error(logCategory, objectName, "error:", JSON.stringify(error, undefined, 2));
    }

    //--------------------------------------------------------------------------

    BinaryData {
        id: pkiBinaryData
    }

    //--------------------------------------------------------------------------

    function isBusyReadyState(readyState) {
        return readyState === NetworkRequest.ReadyStateSending
                || readyState === NetworkRequest.ReadyStateProcessing;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: Networking

        onAuthenticationChallenge: {
            console.log(logCategory, "onAuthenticationChallenge:", authChallenge.authenticationChallengeType, "requestUrl:", authChallenge.requestUrl);

            if (token > "" && authChallenge.authenticationChallengeType === AuthenticationChallenge.AuthenticationChallengeTypeToken) {
                console.info(logCategory, "Authenticating with portal token");

                var credential = {
                    "token": token
                };

                authChallenge.continueWithCredential(credential);
            } else {
                console.error(logCategory, "Token not available");
            }
        }
    }

    //--------------------------------------------------------------------------
}
