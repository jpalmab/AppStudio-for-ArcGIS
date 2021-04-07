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
import QtQuick.Controls 2.12
import QtQuick.Controls 1.2 as QC1
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtPositioning 5.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "../XForms/XForm.js" as XFormJS

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    readonly property QC1.StackView stackView: QC1.Stack.view
    property alias surveyPath: surveyInfo.path

    property XForm xform
    property XFormsDatabase xformsDatabase: app.surveysModel
    property var rowid
    property var rowData
    property int rowStatus: -1
    property var parameters: null
    property var initialPosition: null
    property var initialValues: null
    property var favoriteData: null
    property bool isCurrentFavorite: false
    property bool newFavorite: false
    property bool reviewMode: !!rowid && !!rowData
    property SurveyInfoPage surveyInfoPage
    property bool asynchronous: appFeatures.asyncFormLoader

    //--------------------------------------------------------------------------

    property SurveyMapSources surveyMapSources: SurveyMapSources {
        portal: app.portal
        itemId: surveyInfo.itemId
        filePath: surveyInfo.folder.filePath(kFileName)
    }

    //--------------------------------------------------------------------------

    readonly property string kStatusCancel: "cancel"
    readonly property string kStatusDraft: "draft"
    readonly property string kStatusSubmit: "submit"

    readonly property var kRowStatus: [
        "draft",        // 0
        "submitted",    // 1
        "sent",         // 2
        "error",        // 3
        "inbox",        // 4
    ]

    property color kColorWarning: "#a80000"
    property color kColorDraft: "#ff7e00"
    property color kColorOutbox: "#56ad89"

    //--------------------------------------------------------------------------

    color: app.formBackgroundColor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    QC1.Stack.onStatusChanged: {
        console.log(logCategory, "Stack.status:", QC1.Stack.status);

        if (QC1.Stack.status === QC1.Stack.Active) {
            Qt.callLater(initialize);
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (parameters) {
            initializeParameters();
        }

        formLoader.start();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        readonly property int activationMode: appSettings.locationSensorActivationMode

        positionSourceManager: app.positionSourceManager
        stayActiveOnError: activationMode >= appSettings.kActivationModeInSurvey
        listener: "SurveyView"

        Component.onCompleted: {
            checkActivationMode();
        }

        onActivationModeChanged: {
            checkActivationMode();
        }

        function checkActivationMode() {
            if (activationMode >= appSettings.kActivationModeInSurvey) {
                start();
            } else {
                stop();
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: formLoader

        anchors.fill: parent

        active: false
        sourceComponent: formComponent
        asynchronous: page.asynchronous

        function start() {
            console.log(logCategory, arguments.callee.name, "Loader starting asynchronous:", asynchronous);
            console.time("Survey loader");
            active = true;
        }

        onLoaded: {
            console.timeEnd("Survey loader");
            console.log(logCategory, "Survey loaded");
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        asynchronous: true
        anchors.fill: parent

        sourceComponent: ProgressPopup {
            id: progressPopup

            visible: formLoader.status !== Loader.Ready
            statusText: qsTr("Loading Survey")
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: formComponent

        Item {
            id: formItem

            anchors.fill: parent

            //--------------------------------------------------------------------------

            Component.onCompleted: {
                page.xform = xform;
            }

            //--------------------------------------------------------------------------

            XForm {
                id: xform

                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: footerBar.top
                }

                //        source: AppFramework.resolvedPath(surveyPath)
                source: AppFramework.resolvedPathUrl(surveyPath)
                popoverStackView: mainStackView
                positionSourceManager: app.positionSourceManager
                reviewMode: page.reviewMode

                mapSettings {
                    libraryPath: app.mapLibraryPaths
                    includeDefaultMaps: surveyInfo.includeDefaultMaps && !appFeatures.portalBasemaps
                    externalMapSources: page.surveyMapSources.mapSources
                }

                style {
                    textScaleFactor: app.textScaleFactor
                    fontFamily: app.fontFamily
                    boldText: app.appSettings.boldText
                    titleBackgroundColor: app.titleBarBackgroundColor
                    titleTextColor: app.titleBarTextColor
                    hapticFeedback: app.appSettings.hapticFeedback
                }

                extensionsEnabled: isUserOrgItem(app.userInfo, surveyInfo.itemInfo);

                addIns: app.surveyAddIns

                Component.onCompleted: {
                    console.log(logCategory, "extensionsEnabled:", extensionsEnabled);

                    expressionProperties.status = kRowStatus[rowStatus] || "";

                    titleBar.clicked.connect(scrollToTop);
                    footerBar.clicked.connect(scrollToBottom);
                }

                Component {
                    id: languageItem

                    QC1.MenuItem {
                        property string language

                        checkable: true
                        checked: language === xform.language
                        onTriggered: {
                            xform.language = language;
                        }
                    }
                }


                onStatusChanged: {
                    switch (status) {
                    case statusReady:
                        onReady();
                        break;
                    }
                }

                onCloseAction: {
                    forceActiveFocus()
                    formItem.confirmClose();
                }

                onSaveAction: {
                    saveIncomplete();
                }

                function onReady() {
                    favoriteData = xformsDatabase.getFavorite(sourceInfo.filePath);

                    enumerateLanguages(function (language, languageText, locale) {
                        var menuItem = languageItem.createObject(actionsMenu, {
                                                                     language: language,
                                                                     text: languageText
                                                                 });

                        actionsMenu.insertItem(actionsMenu.items.length, menuItem);
                    });

                    if (debug) {
                        console.log(logCategory, "Review mode:", reviewMode, "rowid:", rowid, "rowData:", JSON.stringify(rowData, undefined, 2));
                    }

                    if (reviewMode) {
                        initializeValues(rowData);
                    } else {
                        if (initialPosition) {
                            setPosition(initialPosition, 1);
                        }

                        if (initialValues) {
                            setValues(undefined, initialValues);
                        }
                    }
                }

                function closeSurvey() {
                    console.log(logCategory, "Closing survey");

                    app.deleteAutoSave();

                    stackView.pop();

                    callback(kStatusCancel);
                }

                function submitSurvey() {
                    stackView.submitSurveys(surveyPath, true, surveyInfo.isPublic);
                }

                function collectNew() {
                    stackView.restartSurvey();
                }

                function saveDraft() {
                    console.log(logCategory, "Saving draft");
                    save(xformsDatabase.statusDraft);
                    closeSurvey();
                    app.deleteAutoSave();

                    callback(kStatusDraft);
                }

                //--------------------------------------------------------------

                function saveValidate() {
                    xform.validate(saveCompleted);
                }

                Timer {
                    id: submitSurveyTimer
                }

                function delay(delayTime, cb) {
                    submitSurveyTimer.interval = delayTime;
                    submitSurveyTimer.repeat = false;
                    submitSurveyTimer.triggered.connect(cb);
                    submitSurveyTimer.start();
                }

                function saveCompleted() {
                    function _closeSurvey() {
                        save(xformsDatabase.statusComplete);
                        closeSurvey();
                        app.deleteAutoSave();

                        callback(kStatusSubmit)
                    }

                    function _submitSurvey() {
                        save(xformsDatabase.statusComplete);
                        popup.close()
                        delay(200, function() {
                            submitSurvey();
                            app.deleteAutoSave();

                            callback(kStatusSubmit)
                        })
                    }

                    var popup;

                    if (Networking.isOnline) {
                        popup = sendOnlinePopup.createObject(page);
                        popup.send.connect(_submitSurvey);
                    } else {
                        popup = sendOfflinePopup.createObject(page);
                    }

                    popup.save.connect(_closeSurvey);
                    popup.open();
                }

                function save(status, statusText) {
                    xform.finalize();

                    var rowData = {
                        "name": name,
                        "path": sourceInfo.filePath,
                        "data": xform.formData.instance,
                        "feature": null,
                        "snippet": xform.formData.snippet(),
                        "status": status,
                        "statusText": statusText,
                        "favorite": newFavorite
                    };

                    if (rowid > 0) {
                        rowData.rowid = rowid;
                        xformsDatabase.updateRow(rowData, true);
                    } else {
                        xformsDatabase.addRow([rowData]);
                        xformsDatabase.finalizeAddRows();
                        rowid = rowData.rowid;
                        console.log(logCategory, "row added:", rowid)
                    }
                }

                //--------------------------------------------------------------

                function saveIncomplete() {
                    console.log(logCategory, "Saving incomplete draft");

                    xform.finalize();

                    var data = {
                        "name": name,
                        "path": sourceInfo.filePath,
                        "data": xform.formData.instance,
                        "feature": null,
                        "snippet": xform.formData.snippet(),
                        "rowid": rowid
                    };

                    app.writeAutoSave(data);
                }

                //--------------------------------------------------------------

                function printSend() {
                    xform.validate(function () {
                        stackView.push({
                                                 item: surveyPrintPage,
                                                 properties: {
                                                     xform: xform
                                                 }
                                             });
                    });
                }

                //--------------------------------------------------------------
            }

            DropShadow {
                id: titleShadow

                anchors.fill: source

                visible: false

                verticalOffset: 3 * AppFramework.displayScaleFactor
                radius: 4 * AppFramework.displayScaleFactor
                samples: 9
                color: "#30000000"
                source: titleBar
            }

            DropShadow {
                anchors.fill: source

                visible: titleShadow.visible
                verticalOffset: -titleShadow.verticalOffset
                radius: titleShadow.radius
                samples: titleShadow.samples
                color: titleShadow.color
                source: footerBar
            }

            Rectangle {
                id: titleBar

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: footerBar.height
                color: xform.style.titleBackgroundColor //app.titleBarBackgroundColor

                signal clicked()

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        titleBar.clicked();
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        //margins: footerBar.padding
                    }

                    spacing: footerBar.spacing

                    StyledImageButton {
                        Layout.preferredHeight: footerBar.buttonSize
                        Layout.preferredWidth: footerBar.buttonSize

                        source: ControlsSingleton.closeIcon
                        padding: ControlsSingleton.closeIconPadding
                        color: xform.style.titleTextColor

                        onClicked: {
                            forceActiveFocus()
                            formItem.confirmClose();
                        }
                    }

                    Item {
                        Layout.preferredHeight: footerBar.buttonSize
                        Layout.preferredWidth: footerBar.buttonSize

                        visible: locationSensorButton.visible
                    }

                    Text {
                        id: titleText

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: xform.title
                        font {
                            pointSize: xform.style.titlePointSize
                            family: xform.style.titleFontFamily
                            bold: xform.style.boldText
                        }
                        fontSizeMode: Text.HorizontalFit
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 2
                        color: xform.style.titleTextColor //app.titleBarTextColor
                        elide: Text.ElideRight
                    }

                    XFormLocationSensorButton {
                        id: locationSensorButton

                        Layout.preferredHeight: footerBar.buttonSize
                        Layout.preferredWidth: footerBar.buttonSize

                        positionSourceManager: xform.positionSourceManager

                        settingsTabContainer: SettingsTabContainer {}
                        settingsTabLocation: SettingsTabLocation {}
                    }

                    StyledImageButton {
                        Layout.preferredHeight: footerBar.buttonSize
                        Layout.preferredWidth: footerBar.buttonSize

                        source: ControlsSingleton.menuIcon
                        padding: ControlsSingleton.menuIconPadding
                        color: xform.style.titleTextColor

                        onClicked: {
                            menuPanel.show();
                            //actionsMenu.popup();
                        }

                        visible: actionsMenu.items.length > 0

                        QC1.Menu {
                            id: actionsMenu

                            QC1.MenuItem {
                                property bool hideCheck: true

                                checkable: true
                                checked: newFavorite
                                visible: !isCurrentFavorite
                                iconSource: Icons.icon("star", checked)
                                text: checked ? qsTr("Clear as favorite answers") : qsTr("Set as favorite answers")

                                onTriggered: {
                                    newFavorite = !newFavorite;
                                }
                            }

                            QC1.MenuItem {
                                iconSource: "images/favorite-add.png"
                                text: qsTr("Paste answers from favorite")
                                visible: !isCurrentFavorite && !newFavorite && favoriteData && typeof favoriteData.data === "object"

                                onTriggered: {
                                    forceActiveFocus();
                                    var values = favoriteData.data[xform.schema.schema.name];
                                    xform.pasteValues(values);
                                }
                            }
                        }
                    }
                }
            }

            //--------------------------------------------------------------------------

            FormFooterBar {
                id: footerBar

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                xform: page.xform

                onOkClicked: {
                    xform.saveValidate();
                }

                onPrintClicked: {
                    xform.printSend();
                }
            }

            XFormMenuPanel {
                id: menuPanel

                textColor: xform.style.titleTextColor
                backgroundColor: xform.style.titleBackgroundColor
                fontFamily: xform.style.menuFontFamily

                menu: actionsMenu
            }

            //------------------------------------------------------------------

            function confirmClose() {
                var popup = surveyClosePopup.createObject(page);
                popup.open();
            }

            //------------------------------------------------------------------

            Component {
                id: surveyPrintPage

                SurveyPrintPage {
                }
            }

            //------------------------------------------------------------------
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyClosePopup

        ActionsPopup {
            title: qsTr("Confirm Close");
            message: qsTr("What would you like to do?")

            icon {
                source: Icons.bigIcon("x-circle")
                color: kColorWarning
            }

            Action {
                text: qsTr("Close this survey and lose changes")
                icon {
                    source: Icons.bigIcon("trash")
                    color: kColorWarning
                }

                onTriggered: {
                    xform.closeSurvey();
                }
            }

            Action {
                text: qsTr("Continue this survey")
                icon.source: Icons.bigIcon("move-up")
                property real iconRotation: 90

                onTriggered: {
                    close();
                }
            }

            Action {
                text: qsTr("Save this survey in Drafts")
                icon {
                    source: Icons.bigIcon("save")
                    color: kColorDraft
                }

                onTriggered: {
                    xform.saveDraft();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sendOnlinePopup

        ActionsPopup {
            signal send()
            signal save()

            title: qsTr("Survey Completed")
            message: qsTr("Your device is online.\nWhat would you like to do?")

            icon {
                source: Icons.bigIcon("online")
            }

            Action {
                checked: true
                text: qsTr("Send now")
                icon {
                    source: Icons.bigIcon("send")
                }

                onTriggered: {
                    send();
                }
            }

            Action {
                text: qsTr("Continue this survey")
                icon.source: Icons.bigIcon("move-up")
                property real iconRotation: 90

                onTriggered: {
                    close();
                }
            }

            Action {
                text: qsTr("Save this survey in the Outbox")
                icon {
                    source: Icons.bigIcon("save")
                    color: kColorOutbox
                }

                onTriggered: {
                    save();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: sendOfflinePopup

        ActionsPopup {
            signal save()

            title: qsTr("Survey Completed")
            message: qsTr("Your device is offline.\nWhat would you like to do?")

            icon {
                source: Icons.bigIcon("offline")
                color: kColorWarning
            }

            Action {
                checked: true
                text: qsTr("Save this survey in the Outbox")
                icon {
                    source: Icons.bigIcon("save")
                    color: kColorOutbox
                }

                onTriggered: {
                    save();
                }
            }

            Action {
                text: qsTr("Continue this survey")
                icon.source: Icons.bigIcon("move-up")
                property real iconRotation: 90

                onTriggered: {
                    close();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function initializeParameters() {
        console.log(logCategory, arguments.callee.name, "parameters:", JSON.stringify(parameters, undefined, 2));

        var values = null;

        var keys = Object.keys(parameters);

        keys.forEach(function (key) {
            if (key.substr(0, 6) === "field:") {
                var field = key.substr(6);
                if (!values) {
                    values = {};
                }

                values[field] = parameters[key];
            }
        });

        initialValues = values;
        console.log(logCategory, arguments.callee.name, "initialValues:", JSON.stringify(initialValues, undefined, 2));

        if (parameters.center) {
            var tokens = parameters.center.toString().split(',');

            if (tokens.length >= 2) {
                var latitude = parseFloat(tokens[0]);
                var longitude = parseFloat(tokens[1]);
                var altitude = parseFloat(tokens[2]);

                initialPosition = QtPositioning.coordinate(latitude, longitude, altitude);

                console.log(logCategory, arguments.callee.name, "initialPosition:", initialPosition);
            }
        }
    }

    //--------------------------------------------------------------------------

    function callback(status) {
        console.log(logCategory, arguments.callee.name, "status:", status);

        if (!parameters || !parameters.callback) {
            console.log(logCategory, "Undefined callback");
            return;
        }

        var properties = {
            itemId: parameters.itemId,
            status: status
        };

        var parameterName = "callback-%1".arg(status);
        if (!parameters.hasOwnProperty(parameterName)) {
            parameterName = "callback";
        }

        var callbackParameter = parameters[parameterName];
        if (!callbackParameter) {
            return;
        }

        var callbackType = typeof callbackParameter;
        console.log(logCategory, "parameterName:", parameterName, "callbackType:", callbackType);

        if (callbackType === "string") {
            var urlInfo = AppFramework.urlInfo(callbackParameter);

            if (urlInfo.isValid) {
                callbackUrl(properties, callbackParameter);
            } else {
                console.log(logCategory, "Invalid callback URL:", callbackParameter);
            }
        } else if (callbackType === "function") {
            callbackFunction(properties, callbackParameter);
        } else {
            console.log(logCategory, "Unsupported callback parameter:", JSON.stringify(callbackParameter));
        }
    }

    //--------------------------------------------------------------------------

    function callbackUrl(properties, url) {
        console.log(logCategory, arguments.callee.name, "properties:", JSON.stringify(properties, undefined, 2));

        url = XFormJS.replacePlaceholders(url, properties);

        console.log(logCategory, arguments.callee.name, "url:", url);

        Qt.openUrlExternally(url);
    }

    //--------------------------------------------------------------------------

    function callbackFunction(properties, func) {
        console.log(logCategory, arguments.callee.name, "properties:", JSON.stringify(properties, undefined, 2));

        func(properties);
    }

    //--------------------------------------------------------------------------

    function isUserOrgItem(userInfo, itemInfo) {
        var portalOrgId = "0123456789ABCDEF";

        if (!userInfo) {
            console.log(logCategory, arguments.callee.name, "Null userInfo");
            return false;
        }

        if (!itemInfo) {
            console.log(logCategory, arguments.callee.name, "Null itemInfo");
            return false;
        }

        console.log(logCategory, arguments.callee.name, "userInfo:", JSON.stringify(userInfo, undefined, 2));
        console.log(logCategory, arguments.callee.name, "itemInfo orgId:", itemInfo.orgId, "isOrgItem:", itemInfo.isOrgItem);

        if (userInfo.isPortal) {
            console.log(logCategory, arguments.callee.name, "Portal user check");

            if (!itemInfo.orgId) {
                console.log(logCategory, arguments.callee.name, "Null itemInfo.orgId");
                return true;
            }

            var isPortalItem = itemInfo.orgId === portalOrgId;

            console.log(logCategory, arguments.callee.name, "isPortalItem:", isPortalItem, "portalOrgId:", portalOrgId);

            return isPortalItem;
        }

        return userInfo.orgId > ""
                && itemInfo.orgId > ""
                && userInfo.orgId === surveyInfo.itemInfo.orgId;
    }

    //--------------------------------------------------------------------------
}
