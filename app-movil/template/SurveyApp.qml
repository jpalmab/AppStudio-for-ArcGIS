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
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Portal"
import "../Controls"
import "../Controls/Singletons"

App {
    id: app

    readonly property bool isDesktop: (Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.platform.os === "linux" || Qt.platform.os === "osx")

    //--------------------------------------------------------------------------

    property alias surveysFolder: surveysFolder
    property alias portal: portal
    property var userInfo

    property alias sharedTheme: sharedTheme

    readonly property alias textColor: sharedTheme.bodyText
    readonly property alias backgroundColor: sharedTheme.bodyBackground
    property string backgroundImage: app.folder.fileUrl(app.info.propertyValue("backgroundTextureImage", "images/texture.jpg"))

    readonly property alias titleBarTextColor: sharedTheme.headerText
    readonly property alias titleBarBackgroundColor: sharedTheme.headerBackground
    readonly property real titleBarHeight: 40 * AppFramework.displayScaleFactor

    readonly property color formBackgroundColor: app.info.propertyValue("formBackgroundColor", "#f7f8f8")

    property alias surveysModel: surveysDatabase
    property alias positionSourceManager: positionSourceManager

    property bool busy: false

    property alias mapLibraryPaths: appSettings.mapLibraryPaths
    property int captureResolution: settings.numberValue("Camera/captureResolution", 0)

    property StackView activeStackView: mainStackView
    property alias mainStackView: mainStackView
    property int popoverStackDepth
    property var openParameters: null

    property alias metrics: metrics

    property var objectCache: ({})

    readonly property string kAutoSaveFileName: "autosave.json"


    property bool supportClipboard: false

    property bool initialized: false

    readonly property string mapPlugin: appSettings.mapPlugin

    //--------------------------------------------------------------------------

    property alias localeProperties: localeProperties
    property alias locale: localeProperties.locale
    property alias numberLocale: localeProperties.numberLocale

    //--------------------------------------------------------------------------

    property alias appSettings: appSettings

    property alias fontFamily: appSettings.fontFamily
    property alias textScaleFactor: appSettings.textScaleFactor

    property alias alert: appAlert

    //--------------------------------------------------------------------------

    property alias features: appFeatures

    //--------------------------------------------------------------------------

    property alias workFolder: workFolder
    property alias addInsManager: addInsManager
    property alias addInsFolder: addInsManager.addInsFolder
    property alias surveyAddIns: surveyAddIns

    //--------------------------------------------------------------------------

    property alias runtimeInfo: runtimeInfo

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "Initializing");

        if (isDesktop) {
            width = 400 * AppFramework.displayScaleFactor
            height = 650 * AppFramework.displayScaleFactor
        }

        fontManager.loadFonts();

        appSettings.read();
        features.read();

        ControlsSingleton.inputFont.family = Qt.binding(function () { return fontFamily; });
        Icons.bold = Qt.binding(function () { return appSettings.boldText; });

        readUserInfo();

        if (portal.isOnline) {
            portal.connect(
                        function () {
                            console.log(logCategory, "Connection to portal resolved");
                            app.portal.autoSignIn();
                        },
                        function () {
                            console.log(logCategory, "Connection to portal rejected");
                            portal.restoreUser(userInfo);
                        });
        } else {
            portal.restoreUser(userInfo);
        }

        if (features.addIns) {
            addInsManager.initialize();
        } else {
            mainStackView.pushSurveysGalleryPage();
        }

        console.log(logCategory, "Surveys folder:", surveysFolder.path);

        if (!surveysFolder.exists) {
            surveysFolder.makeFolder();
        }

        AppFramework.offlineStoragePath = surveysFolder.path;

        console.log(logCategory, "offlineStoragePath:", AppFramework.offlineStoragePath)

        surveysDatabase.initialize();

        var surveysCount = surveysFolder.forms.length;

        if (!surveysCount && !openParameters) {
            console.log(logCategory, "0 surveys: Opening startPage");

            mainStackView.pushStartPage();
        } else {
            if (!surveysDatabase.validateSchema()) {
                var dialog = invalidSchemaDialog.createObject(mainStackView);
                dialog.open();
            }

            checkAutoSave();
        }

        if (supportClipboard) {
            checkClipboard();
        }

        initialized = true;

        positionSourceConnection.checkActivationMode();
    }


    Component {
        id: invalidSchemaDialog

        MessageDialog {

            icon: StandardIcon.Critical
            text: qsTr("The survey database is out of date and must to be reinitialized before survey data can be collected.\n\nWARNING: Please ensure any survey data already collected has been sucessfully submitted before reinitializing the database.")
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(app, true)
    }

    //--------------------------------------------------------------------------

    onOpenUrl: {
        console.log(logCategory, "onOpenUrl url:", url);

        var urlInfo = AppFramework.urlInfo(localeProperties.replaceNumbers(url, localeProperties.locale));

        if (!urlInfo.host.length) {
            openParameters = urlInfo.queryParameters;

            console.log(logCategory, "onOpenUrl parameters:", JSON.stringify(openParameters, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    backButtonAction: mainStackView.depth == 1 ? App.BackButtonQuit : App.BackButtonSignal

    onBackButtonClicked: {
        goBack();
    }

    /*
    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            event.accepted = true;
            goBack();
        }
    }
    */

    /*
      // Debug only back button on non-Android devices

    Button {
        anchors.centerIn: parent
        z: 999999
        text: "Back"
        onClicked: {
            goBack();
        }
    }
    */

    //--------------------------------------------------------------------------

    function goBack() {
        var stackView = activeStackView;

        if (!stackView) {
            console.log("goBack: No stackView");
            return false;
        }

        if (stackView.popoverStackView) {
            if (stackView.popoverStackView.depth > popoverStackDepth) {
                stackView = stackView.popoverStackView;
            }
        }

        if (stackView.depth <= 1) {
            console.log("goBack: At top of stackView closeAction:", typeof stackView.currentItem.closeAction);

            var closeAction = stackView.currentItem.closeAction;
            if (typeof closeAction === "function") {
                closeAction();
                return true;
            }

            return false;
        }

        var canGoBack = stackView.currentItem.canGoBack;

        var doPop;

        switch (typeof canGoBack) {
        case 'boolean' :
            doPop = canGoBack;
            break;

        case 'function' :
            doPop = canGoBack();
            break;

        default:
            doPop = true;
            break;
        }

        // console.log("stackView:", stackView.depth, "canGoBack:", typeof canGoBack, doPop);

        if (doPop) {
            stackView.pop(); //stackView.currentItem.id);
            return true;
        }

        return false;
    }

    //--------------------------------------------------------------------------

    LocaleProperties {
        id: localeProperties

        Component.onCompleted: {
            console.log(logCategory, "Default locale:", AppFramework.defaultLocale);
            console.log(logCategory, "System locale:", AppFramework.systemLocale);
            log();
        }

        onLocaleChanged: {
            console.log(logCategory, "App locale changed to:", locale.name);

            if (locale.name !== kNeutralLocale.name) {
                console.log("Loading translations for :", locale.name);
                AppFramework.loadTranslator(app.info.json.translations, app.folder.path, locale.name);
            }
        }
    }

    //--------------------------------------------------------------------------

    AppSettings {
        id: appSettings

        app: app
    }

    //--------------------------------------------------------------------------

    AppFeatures {
        id: appFeatures

        app: app
        settings: app.settings
    }

    //--------------------------------------------------------------------------

    Metrics {
        id: metrics
    }

    //--------------------------------------------------------------------------

    FontManager {
        id: fontManager
    }

    //--------------------------------------------------------------------------

    StackView {
        id: mainStackView

        // property var galleryItem

        anchors {
            fill: parent
        }

        delegate: AppPageViewDelegate {}

        //        initialItem: galleryPage

        Component.onCompleted: {
            /*
            galleryItem = push(galleryPage);

            surveysFolder.update();
            var surveysCount = surveysFolder.forms.length;

            if (!surveysCount && !openParameters) {
                console.log("0 surveys: Opening startPage");

                push({
                         item: startPage,
                         immediate: true
                     });
            }
            */
        }


        function pushSurveysGalleryPage() {
            push(galleryPage);
        }

        function pushAddInsPage() {
            push(addInsManager.addInsPage);
        }

        function pushStartPage() {
            push({
                     item: startPage,
                     immediate: true
                 });
        }

        function restartSurvey() {
            var surveyPath = currentItem.surveyPath;

            push({
                     item: surveyView,
                     replace: true,
                     properties: {
                         surveyPath: surveyPath,
                         rowid: null
                     }
                 });
        }

        function submitSurveys(surveyPath, autoSubmit, isPublic) {
            push({
                     item: submitSurveysPage,
                     properties: {
                         surveyPath: surveyPath,
                         autoSubmit: autoSubmit,
                         isPublic: isPublic,
                         actionColor: "#56ad89"
                     },
                     replace: autoSubmit
                 });
        }
    }

    //--------------------------------------------------------------------------

    function surveySelected(surveyPath, pressAndHold, indicator, parameters, surveyInfo) {
        console.log(logCategory, arguments.callee.name, "surveyPath:", surveyPath, "updateAvailable:", surveyInfo.updateAvailable);

        function showSurvey() {
            var count = surveysDatabase.surveyCount(surveyPath);

            if (pressAndHold) {
                var surveyViewPage = {
                    item: surveyView,
                    properties: {
                        surveyPath: surveyPath,
                        rowid: null,
                        parameters: parameters
                    }
                }

                mainStackView.push(surveyViewPage);
            } else {
                var surveyInfoPage = {
                    item: surveyPage,
                    properties: {
                        surveyPath: surveyPath
                    }
                };

                mainStackView.push(surveyInfoPage);
            }
        }

        if (surveyInfo.updateAvailable && portal.isOnline) {
            var fileInfo = AppFramework.fileInfo(surveyPath);
            var itemInfo = fileInfo.folder.readJsonFile(fileInfo.baseName + ".itemInfo");

            var popup = surveyUpdatePopup.createObject(app,
                                                       {
                                                           surveyInfo: surveyInfo,
                                                           itemInfo: itemInfo
                                                       });

            popup.openSurvey.connect(showSurvey);
            popup.open();
        } else {
            showSurvey();
        }
    }

    // TODO Hack until a better way is implemented
    signal broadcastSurveyUpdate(string id)

    Component {
        id: surveyUpdatePopup

        SurveyUpdatePopup {
            portal: app.portal

            onUpdated: {
                broadcastSurveyUpdate(itemInfo.id);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: startPage

        StartPage {
            onSignedIn: {
                mainStackView.pop();

                /*
                var surveysCount = surveysFolder.forms.length;
                if (surveysCount) {
                    mainStackView.pop();
                } else {
//                    if (!app.openParameters) {
//                        mainStackView.push({
//                                               item: downloadSurveysPage,
//                                               properties: {
//                                                   hasSurveysPage: mainStackView.galleryItem
//                                               }
//                                           });
//                    }
                }
            */
            }

            Connections {
                target: app

                onOpenParametersChanged: {
                    if (openParameters) {
                        mainStackView.pop();
                    }
                }
            }
        }
    }

    Component {
        id: galleryPage

        SurveysGalleryPage {
            Component.onCompleted: {
                selected.connect(surveySelected);
            }
        }
    }

    Component {
        id: downloadSurveysPage

        DownloadSurveysPage {
        }
    }

    Component {
        id: surveyPage

        SurveyInfoPage {
        }
    }

    Component {
        id: surveyView

        SurveyView {
            onXformChanged: {
                if (xform) {
                    popoverStackDepth = mainStackView.depth;
                    activeStackView = xform;
                } else {
                    activeStackView = mainStackView;
                }
            }

            Component.onDestruction: {
                activeStackView = mainStackView;
            }
        }
    }

    Component {
        id: submitSurveysPage

        SubmitSurveysPage {
            objectCache: app.objectCache
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appAboutPage

        AboutPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appSettingsPage

        SettingsPage {
        }
    }

    //--------------------------------------------------------------------------

    XFormsFolder {
        id: surveysFolder

        path: "~/ArcGIS/My Surveys"
    }

    XFormsDatabase {
        id: surveysDatabase

        useArraySort: true
    }

    FileFolder {
        id: workFolder

        path: AppFramework.standardPaths.writableLocation(StandardPaths.TempLocation)

        Component.onCompleted: {
            console.log("workFolder:", path);
        }
    }

    //--------------------------------------------------------------------------

    Portal {
        id: portal

        property bool staySignedIn: settings.value(settingsGroup + "/staySignedIn", app.info.propertyValue("staySignedIn", true))
        property var actionCallback: null
        property AppPopup connectPopup: null

        app: app
        settings: app.settings
        clientId: app.info.value("deployment").clientId
        defaultUserThumbnail: Icons.bigIcon("user")

        onCredentialsRequest: {
            console.log("Show sign in page");
            mainStackView.push({
                                   item: portalSignInPage,
                                   immediate: false,
                                   properties: {
                                   }
                               });
        }

        function signInAction(reason, callback) {
            function resolved() {
                validateToken();

                if (signedIn) {
                    actionCallback = null;
                    callback();
                    return;
                }

                actionCallback = callback;
                signIn(reason);
            }

            function rejected() {
                actionCallback = null;
            }

            connect(resolved, rejected);
        }

        function connectAction(reason, callback) {
            console.log(logCategory, arguments.callee.name, reason);

            function resolved() {
                actionCallback = null;
                callback();
            }

            function rejected() {
                actionCallback = null;
            }

            if (!signedIn) {
                console.error(logCategory, arguments.callee.name, "Not signed in");
                rejected();
                return;
            }

            connect(resolved, rejected);
        }

        onSignedInChanged: {
            var callback = actionCallback;
            actionCallback = null;

            app.objectCache["lastGeocoderSearchUrl"] = undefined;

            if (signedIn) {
                if (staySignedIn) {
                    writeSignedInState();
                } else {
                    clearSignedInState();
                }
            } else {
                clearSignedInState();
            }

            if (signedIn) {
                userInfo = portal.user;
                userInfo.isPortal = portal.isPortal;
                writeUserInfo();
            } else {
                clearUserInfo();
            }

            if (signedIn && mainStackView.currentItem.isPortalSignInView) {
                if(user.orgId>"") {
                    //only pop login screen when user is not using free public account
                    mainStackView.pop();
                }
            }

            if (signedIn && callback) {
                callback();
            }
        }

        onConnecting: {
            if (debug) {
                console.log(logCategory, "connecting:", request.readyState);
            }

            switch (request.readyState) {
            case NetworkRequest.ReadyStateSending:
                if (connectPopup) {
                    connectPopup.close();
                }

                connectPopup = hostConnectPopup.createObject(app,
                                                             {
                                                                 request: request
                                                             });

                connectPopup.open();
                break;

            case NetworkRequest.ReadyStateComplete:
                if (connectPopup) {
                    connectPopup.close();
                    connectPopup = null;
                }
                break;
            }
        }

        onConnectError: {
            if (connectPopup) {
                connectPopup.close();
                connectPopup = null;
            }

            var popup = hostErrorPopup.createObject(app,
                                                    {
                                                        request: request,
                                                        error: error
                                                    });

            popup.open();
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalSignInPage

        PortalSignInView {
            property bool isPortalSignInView: true

            portal: app.portal
            bannerColor: app.titleBarBackgroundColor

            onRejected: {
                portal.actionCallback = null;
                mainStackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: hostConnectPopup

        PortalConnectPopup {
            portal: app.portal
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: hostErrorPopup

        PortalErrorPopup {
            portal: app.portal

            title: qsTr("Error connecting to %1").arg(portal.name)
        }
    }

    //--------------------------------------------------------------------------

    SharedTheme {
        id: sharedTheme

        portal: features.useSharedTheme ? app.portal : null

        defaultBodyText: app.info.propertyValue("textColor", "black")
        defaultBodyBackground: app.info.propertyValue("backgroundColor", "lightgrey")

        defaultHeaderText: app.info.propertyValue("titleBarTextColor", "grey")
        defaultHeaderBackground: app.info.propertyValue("titleBarBackgroundColor", "white")
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceManager {
        id: positionSourceManager

        discoverBluetooth: appSettings.discoverBluetooth
        discoverBluetoothLE: appSettings.discoverBluetoothLE
        discoverSerialPort: appSettings.discoverSerialPort

        connectionType: appSettings.locationSensorConnectionType
        activationMode: appSettings.locationSensorActivationMode
        storedDeviceName: appSettings.lastUsedDeviceName
        storedDeviceJSON: appSettings.lastUsedDeviceJSON
        hostname: appSettings.hostname
        port: Number(appSettings.port)

        altitudeType: appSettings.locationAltitudeType
        customGeoidSeparation: appSettings.locationGeoidSeparation
        antennaHeight: appSettings.locationAntennaHeight
        wkid: appSettings.wkid

        onError: {
            connectionErrorDialog.showError(errorString);
        }
    }

    //--------------------------------------------------------------------------

    PositionSourceMonitor {
        positionSourceManager: positionSourceManager

        maximumDataAge: appSettings.locationMaximumDataAge
        maximumPositionAge: appSettings.locationMaximumPositionAge

        onAlert: {
            appAlert.positionSourceAlert(alertType);
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        readonly property int activationMode: appSettings.locationSensorActivationMode

        positionSourceManager: positionSourceManager
        stayActiveOnError: activationMode >= appSettings.kActivationModeAlways
        listener: "SurveyApp"

        onActivationModeChanged: {
            if (initialized) {
                checkActivationMode();
            }
        }

        function checkActivationMode() {
            if (activationMode >= appSettings.kActivationModeAlways) {
                start();
            } else {
                stop();
            }
        }
    }

    //--------------------------------------------------------------------------

    // Dummy to hack global properties

    Item {
        id: xform

        property alias popoverStackView: mainStackView
        property alias style: style

        XFormStyle {
            id: style

            fontFamily: app.fontFamily

            textScaleFactor: app.textScaleFactor

            titleTextColor: app.titleBarTextColor
            titleBackgroundColor: app.titleBarBackgroundColor

            boldText: appSettings.boldText
            hapticFeedback: appSettings.hapticFeedback
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        visible: busy //|| portalSignInDialog.visible
        color: "#80000000"

        AppBusyIndicator {
            anchors.centerIn: parent
            running: busy
        }
    }

    //--------------------------------------------------------------------------

    AppAlert {
        id: appAlert
    }

    //--------------------------------------------------------------------------

    readonly property string kGroupInfo: "Info"
    readonly property string kKeyUserInfo: kGroupInfo + "/user"

    function readUserInfo() {
        var info;

        try {
            info = JSON.parse(settings.value(kKeyUserInfo, ""));
        } catch (e) {
            info = {};
        }

        if (!info || typeof info !== "object") {
            info = {};
        }

        userInfo = info;

        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(userInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function writeUserInfo() {
        if (!userInfo || typeof userInfo !== "object") {
            settings.remove(kKeyUserInfo);
            return;
        }

        var info = {
            username: userInfo.username,
            firstName: userInfo.firstName,
            lastName: userInfo.lastName,
            fullName: userInfo.fullName,
            email: userInfo.email,
            orgId: userInfo.orgId,
            isPortal: userInfo.isPortal
        };

        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(info, undefined, 2));

        settings.setValue(kKeyUserInfo, JSON.stringify(info));
    }

    //--------------------------------------------------------------------------

    function clearUserInfo() {
        userInfo = undefined;
        settings.remove(kKeyUserInfo);
    }

    //--------------------------------------------------------------------------

    function readAutoSave() {
        if (!surveysFolder.fileExists(kAutoSaveFileName)) {
            return;
        }

        var data = surveysFolder.readJsonFile(kAutoSaveFileName);
        if (!data) {
            return;
        }

        if (!Object.keys(data).length) {
            return;
        }

        return data;
    }

    function writeAutoSave(data) {
        surveysFolder.writeJsonFile(kAutoSaveFileName, data);
    }

    function deleteAutoSave() {
        surveysFolder.removeFile(kAutoSaveFileName);
    }

    // -------------------------------------------------------------------------

    ConfirmPanel {
        id: connectionErrorDialog

        function showError(message) {
            connectionErrorDialog.clear();
            connectionErrorDialog.icon = "images/warning.png";
            connectionErrorDialog.title = qsTr("Unable to connect");
            connectionErrorDialog.text = message;
            connectionErrorDialog.button1Text = qsTr("Ok");
            connectionErrorDialog.button2Text = "";
            connectionErrorDialog.show();
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: recoveryPanel

        ConfirmPanel {
            property var data

            icon: "images/survey-autosave.png"
            title: qsTr("Survey Recovered")
            text: qsTr("Data for the survey <b>%1</b> has been recovered. (%2)").arg(data.name).arg(data.snippet)
            question: qsTr("What would you like to do with the recovered survey?")
            button1Text: qsTr("Discard survey")
            button2Text: qsTr("Continue survey")
            verticalLayout: true
        }
    }

    //--------------------------------------------------------------------------

    function checkAutoSave() {
        var data = app.readAutoSave();

        if (!data) {
            return;
        }

        console.log("autosave data:", JSON.stringify(data, undefined, 2));

        var panel = recoveryPanel.createObject(app, {
                                                   data: data
                                               });

        function _continueSurvey() {
            var surveyViewPage = {
                item: surveyView,
                properties: {
                    surveyPath: data.path,
                    rowid: data.rowid > 0 ? data.rowid : -1,
                    rowData: data.data,
                    parameters: null
                }
            }

            mainStackView.push(surveyViewPage);
        }

        panel.show(deleteAutoSave, _continueSurvey);
    }

    //--------------------------------------------------------------------------

    ArcGISRuntimeInfo {
        id: runtimeInfo
    }

    ArcGISRuntimeAuthentication {
        onLicenseChanged: {
            runtimeInfo.update();
        }
    }

    //--------------------------------------------------------------------------

    AddInsManager {
        id: addInsManager
    }

    //--------------------------------------------------------------------------

    SurveyAddIns {
        id: surveyAddIns

        addInsManager: app.addInsManager
    }

    //--------------------------------------------------------------------------

    function checkClipboard() {
        if (!AppFramework.clipboard.dataAvailable) {
            return;
        }

        var text = AppFramework.clipboard.text.trim();

        if (!(text > "")) {
            return;
        }

        console.log("Clipboard text:", text);

        var urlInfo = AppFramework.urlInfo(text);

        if (urlInfo.scheme === app.info.value("urlScheme")) {
            onOpenUrl(urlInfo.url);
        }
    }

    //--------------------------------------------------------------------------
    // Font issue on Windows workaround #3229

    FileDialog {
        visible: false
    }

    //--------------------------------------------------------------------------
}
