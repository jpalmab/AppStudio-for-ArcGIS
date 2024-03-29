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
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"
import "../Controls/Singletons"
import "../template"

//------------------------------------------------------------------------------

Item {
    id: view

    property Portal portal

    property color bannerColor: "black"

    readonly property string kPortalHelpUrl: "http://doc.arcgis.com/en/survey123/desktop/create-surveys/survey123withenterprise.htm"

    property bool showExtraInfo: false

    property string fontFamily

    property int initialIndex: -1
    property url pkiPortalUrl
    property bool pkiAuthentication: false
    property string pkiFile: ""
    property string pkiFileName: ""
    property alias passPhrase: passPhraseField.text
    property bool networkAuthentication: false

    readonly property string newPortalEntryDefaultText: "https://"

    property int buttonHeight: 35 * AppFramework.displayScaleFactor

    signal portalSelected(var portalInfo)
    signal doubleClicked()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        portalsList.read();
        initialIndex = portalsList.find(portal);
        portalsListView.currentIndex = initialIndex;
    }

    //--------------------------------------------------------------------------

    onPortalSelected: {
        portal.setPortal(portalInfo);

        if ( pkiPortalUrl === portal.portalUrl ) {
            portal.pkiFile = pkiFile;
            portal.pkiFileName = pkiFileName;
            portal.passPhrase = passPhrase;
            portal.rememberMe = true;
            portal.writeUserSettings();
        }
    }

    //--------------------------------------------------------------------------

    PortalsList {
        id: portalsList

        settings: portal.settings
        settingsGroup: portal.settingsGroup
        singleInstanceSupport: portal.singleInstanceSupport
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        ColumnLayout {
            Layout.fillWidth: true

            visible: showExtraInfo

            StyledButton {
                Layout.alignment: Qt.AlignHCenter

                visible: !addPortalGroupBox.visible
                text: "Clear Portals"

                fontFamily: view.fontFamily

                onClicked: {
                    portalsList.clear();
                    portal.setPortal(portalsList.kDefaultPortal);
                    initialIndex = -1;
                    portalsListView.currentIndex = 0;
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1

                color: bannerColor
            }
        }

        Text {
            Layout.fillWidth: true

            text: qsTr("Select your active ArcGIS connection")
            font {
                family: fontFamily
                pointSize: 15
            }
            color: "#4c4c4c"
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    showExtraInfo = !showExtraInfo;
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1

            color: bannerColor
        }

        ListView {
            id: portalsListView

            Layout.fillHeight: true
            Layout.fillWidth: true

            model: portalsList.model
            highlightFollowsCurrentItem: true
            highlight: portalHighlight
            spacing: 5 * AppFramework.displayScaleFactor
            clip: true

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && initialIndex >= 0) {
                    var portalInfo = portalsList.model.get(currentIndex);
                    portalSelected(portalInfo);
                }
            }

            delegate: Item {
                width: portalRow.width
                height: portalRow.height

                RowLayout {
                    id: portalRow

                    width: portalsListView.width

                    Image {
                        Layout.preferredWidth: 15 * AppFramework.displayScaleFactor * 2
                        Layout.preferredHeight: Layout.preferredWidth

                        source: isPortal ? Icons.icon("portal") : Icons.icon("arcgis-online")
                        fillMode: Image.PreserveAspectFit
                    }

                    Image {
                        Layout.preferredWidth: 15 * AppFramework.displayScaleFactor * 2
                        Layout.preferredHeight: Layout.preferredWidth

                        source: supportsOAuth ? "images/oauth.png" : "images/builtin.png"
                        fillMode: Image.PreserveAspectFit
                        visible: source > "" && showExtraInfo
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: portalText.height

                        ColumnLayout {
                            id: portalText

                            width: parent.width

                            Text {
                                Layout.fillWidth: true

                                text: name
                                font {
                                    pointSize: 14
                                    bold: index == portalsListView.currentIndex
                                    family: fontFamily
                                }
                                color: "black"
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                visible: index > 0 || showExtraInfo

                                Image {
                                    Layout.preferredWidth: 15 * AppFramework.displayScaleFactor
                                    Layout.preferredHeight: Layout.preferredWidth

                                    source: ignoreSslErrors ? "images/security_unlock.png" : "" //"images/security_lock.png"
                                    fillMode: Image.PreserveAspectFit
                                    visible: source > ""
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: url
                                    font {
                                        pointSize: 12
                                        family: fontFamily
                                    }
                                    color: "#4c4c4c"
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                            }

                            Flow {
                                Layout.fillWidth: true

                                visible: showExtraInfo

                                spacing: 5 * AppFramework.displayScaleFactor

                                Text {
                                    visible: networkAuthentication
                                    text: "NA"
                                }

                                Text {
                                    visible: externalUserAgent
                                    text: "EUA"
                                }

                                Text {
                                    visible: singleSignOn
                                    text: "SSO"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                portalsListView.currentIndex = index;
                            }

                            onDoubleClicked: {
                                portalsListView.currentIndex = index;
                                view.doubleClicked();
                            }

                            onPressAndHold: {
                                Qt.openUrlExternally(url);
                            }
                        }
                    }

                    StyledImageButton {
                        width: 20 * AppFramework.displayScaleFactor
                        height: width

                        source: Icons.icon("trash")
                        visible: index > 0 && index == portalsListView.currentIndex

                        onClicked: {
                            portalsList.remove(index);
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1

            visible: !addPortalGroupBox.visible

            color: bannerColor
        }

        StyledButton {
            Layout.alignment: Qt.AlignHCenter

            visible: !addPortalGroupBox.visible
            text: qsTr("Add Portal")
            fontFamily: view.fontFamily

            onClicked: {
                addPortalGroupBox.visible = true;
            }
        }

        //        GroupBox {
        GroupRectangle {
            id: addPortalGroupBox

            Layout.fillWidth: true

            visible: false

            ColumnLayout {
                id: addPortalLayout

                width: parent.width

                spacing: 5 * AppFramework.displayScaleFactor

                Text {
                    Layout.preferredWidth: addPortalLayout.width

                    text: qsTr("URL of your ArcGIS connection")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent

                        onPressAndHold: {
                            forceBuiltIn.visible = !forceBuiltIn.visible;
                        }
                    }
                }

                UrlTextBox {
                    id: portalUrlField

                    Layout.preferredWidth: addPortalLayout.width

                    Component.onCompleted: {
                        text = newPortalEntryDefaultText;
                    }

                    enabled: !portalInfoRequest.isBusy
                    placeholderText: qsTr("Example: https://webadaptor.example.com/arcgis")
                    inputRequired: true

                    font {
                        family: fontFamily
                        pointSize: 15
                    }

                    onTextChanged: {
                        /*
                        if (text === "") {
                            text = newPortalEntryDefaultText;
                        }
                        */
                    }
                }

                Text {
                    Layout.fillWidth: true

                    visible: pkiAuthentication
                    text: qsTr("Certificate (*.pfx, *.p12)")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }

                RowLayout {
                    id: pkiFileRowLayout
                    Layout.fillWidth: true

                    visible: pkiAuthentication

                    TextBox {
                        id: pkiFileField

                        Layout.fillWidth: true

                        text: pkiFileName
                        placeholderText: qsTr( "Select certificate" )
                        clip: true
                        inputRequired: true
                        _inputEmpty: length === 0
                        readOnly: true

                        font {
                            family: fontFamily
                            pointSize: 15
                        }
                    }

                    StyledImageButton {
                        Layout.preferredWidth: buttonHeight
                        Layout.preferredHeight: buttonHeight

                        source: Icons.icon("folder")
                        color: "black"

                        onClicked: {
                            pkiDocumentDialog.open();
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true

                    visible: pkiAuthentication
                    text: qsTr("Password")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }

                TextBox {
                    id: passPhraseField

                    Layout.fillWidth: true

                    visible: pkiAuthentication
                    placeholderText: qsTr( "Password" )
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    inputRequired: true
                    _inputEmpty: length === 0

                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                Text {
                    Layout.fillWidth: true

                    visible: networkAuthentication
                    text: qsTr("Username")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }

                TextBox {
                    id: userField

                    Layout.fillWidth: true

                    visible: networkAuthentication
                    placeholderText: "DOMAIN\\username"//qsTr("Username")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    inputRequired: true
                    _inputEmpty: length === 0
                    onTextChanged: passwordField.text = ""

                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                Text {
                    Layout.fillWidth: true

                    visible: networkAuthentication
                    text: qsTr("Password")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }

                TextBox {
                    id: passwordField

                    Layout.fillWidth: true

                    visible: networkAuthentication
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    inputRequired: true
                    _inputEmpty: length === 0

                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                AppSwitch {
                    id: externalUserAgent

                    Layout.preferredWidth: addPortalLayout.width

                    visible: !networkAuthentication
                    checked: false //portal.singleInstanceSupport
                    text: qsTr("Use external web browser for sign in")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                AppSwitch {
                    id: sslCheckBox

                    Layout.preferredWidth: addPortalLayout.width

                    visible: false
                    checked: false
                    text: qsTr("Ignore SSL Errors")
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                AppSwitch {
                    id: forceBuiltIn

                    Layout.fillWidth: true

                    visible: false
                    checked: false
                    text: "Force built-in authentication"
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                }

                Text {
                    id: addPortalError

                    Layout.preferredWidth: addPortalLayout.width

                    visible: text > ""
                    color: "red"
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                Text {
                    id: addPortalSslErrors

                    Layout.preferredWidth: addPortalLayout.width

                    text: sslErrorsToText(portalInfoRequest.sslErrors)
                    visible: text > ""
                    color: "red"
                    font {
                        family: fontFamily
                        pointSize: 15
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight

                    function sslErrorToText(sslError) {
                        return qsTr("Error %1: %2").arg(sslError.error).arg(sslError.errorString)
                    }

                    function sslErrorsToText(sslErrors) {
                        if (!sslErrors) {
                            return "";
                        }

                        return sslErrors.map(sslErrorToText).join("\n") + "\n";
                    }
                }

                Text {
                    Layout.preferredWidth: addPortalLayout.width

                    text: qsTr('<a href="%1">Learn more about managing portal connections</a>').arg(kPortalHelpUrl)
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font {
                        family: fontFamily
                        pointSize: 15
                    }

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                Flow {
                    Layout.preferredWidth: addPortalLayout.width

                    StyledButton {
                        id: addPortalButton
                        text: qsTr("Add Portal")
                        enabled: portalUrlField.text.substring(0, 4).toLocaleLowerCase() === "http" && !portalInfoRequest.isBusy
                        fontFamily: view.fontFamily

                        onClicked: tryClick()

                        function tryClick() {
                            addPortalError.text = "";

                            Networking.clearAccessCache();
                            Networking.pkcs12 = null;

                            if ( pkiAuthentication ) {
                                let pkcs12 = Networking.importPkcs12( pkiFileBinary.data, passPhrase );
                                if ( !pkcs12 ) {
                                    addPortalError.text = qsTr( "Invalid certificate or password." );
                                    return;
                                }

                                Networking.pkcs12 = pkcs12;
                            }

                            portalInfoRequest.sendRequest( portalUrlField.text.replace( /\/*\s*$/, "" ) );
                        }
                    }

                    StyledButton {
                        text: qsTr("Cancel")
                        fontFamily: view.fontFamily

                        onClicked: {
                            portalUrlField.text = "";
                            addPortalError.text = "";
                            userField.text = "";
                            passwordField.text = "";
                            sslCheckBox.checked = false;
                            externalUserAgent.checked = false; //portal.singleInstanceSupport;
                            networkAuthentication = false;
                            pkiAuthentication = false;
                            pkiFile = "";
                            pkiFileName = "";
                            passPhrase = "";
                            addPortalGroupBox.visible = false;
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ColorBusyIndicator {
        anchors.centerIn: parent

        backgroundColor: bannerColor
        running: portalInfoRequest.isBusy
        visible: running
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalHighlight

        Rectangle {
            width: ListView.view ? ListView.view.currentItem.width : 0
            height: ListView.view ? ListView.view.currentItem.height : 0
            color: "darkgrey"
            radius: 2
            y: ListView.view ? ListView.view.currentItem.y : 0
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalInfoRequest

        property url portalUrl
        property string text
        property bool isBusy: readyState == NetworkRequest.ReadyStateProcessing || readyState == NetworkRequest.ReadyStateSending
        property var sslErrors: null

        method: "POST"
        responseType: "json"
        ignoreSslErrors: sslCheckBox.checked

        onSslErrors: sslErrors = errors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (status === 200) {

                    console.log("self:", JSON.stringify(response, undefined, 2));

                    if (response.isPortal && !response.supportsHostedServices) {
                        addPortalError.text = qsTr("Survey123 requires Portal for ArcGIS configured with a Hosting Server and Portal for ArcGIS Data Store.");
                    } else {
                        portalVersionRequest.send();
                        infoRequest.send();
                    }
                }
            }
        }

        onErrorTextChanged: {
            console.error("addPortal error:", errorCode, errorText);

            switch (errorCode) {
            case 6:
                if (showExtraInfo) {
                    sslCheckBox.visible = true;
                }
                break;

            case 201:
                pkiAuthentication = true;
                pkiPortalUrl = portalUrl;
                break;

            case 204:
                networkAuthentication = true;
                break;
            }

            if (errorCode) {
                addPortalError.text = "%1 (%2)".arg(errorText).arg(errorCode);
            } else {
                addPortalError.text = "";
            }
        }

        function sendRequest(u) {
            portalUrl = u;
            url = portalUrl + "/sharing/rest/portals/self";
            portalInfoRequest.sslErrors = null;

            var formData = {
                f: "pjson"
            };

            if (networkAuthentication) {
                user = userField.text;
                password =  passwordField.text

                console.log("Setting network user:", user);
            } else {
                user = "";
                password = "";
            }

            send(formData);
        }

        function addPortal(version) {
            var info = response;

            var name = info.name;
            if (!(name > "")) {
                name = qsTr("%1 (%2)").arg(info.portalName).arg(portalUrl);
            }

            var singleSignOn = typeof info.user === "object" && !networkAuthentication && !pkiAuthentication;
            var supportsOAuth = info.supportsOAuth && !(forceBuiltIn.checked && forceBuiltIn.visible) && !networkAuthentication; // && !info.isPortal;

            var portalInfo = {
                url: portalUrl.toString(),
                name: name,
                ignoreSslErrors: sslCheckBox.checked,
                isPortal: info.isPortal,
                supportsOAuth: supportsOAuth,
                externalUserAgent: externalUserAgent.checked, // && supportsOAuth && portal.singleInstanceSupport,
                networkAuthentication: networkAuthentication,
                singleSignOn: singleSignOn
            };

            if ( pkiAuthentication ) {
                portalInfo.pkiAuthentication = true;
                portal.pkiAuthentication = true;
                portal.pkiFile = pkiFile;
                portal.pkiFileName = pkiFileName;
                portal.passPhrase = passPhrase;
                portal.rememberMe = true;
                portal.writeUserSettings();
            }

            var portalIndex = portalsList.append(portalInfo);

            portalsListView.currentIndex = portalIndex;
            portalUrlField.text = "";
            addPortalError.text = "";
            userField.text = "";
            passwordField.text = "";
            sslCheckBox.checked = false;
            externalUserAgent.checked = false; //portal.singleInstanceSupport;
            networkAuthentication = false;
            pkiAuthentication = false;
            pkiFile = "";
            pkiFileName = "";
            passPhrase = "";
            addPortalGroupBox.visible = false;

            console.log("portalInfo:", JSON.stringify(portalsList.model.get(portalIndex), undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalVersionRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.currentVersion) {
                    console.log("Portal version:", response.currentVersion, "response:", JSON.stringify(response, undefined, 2));

                    if (portal.versionCompare(response.currentVersion, portal.minimumVersion) >= 0) {
                        portalInfoRequest.addPortal(response.currentVersion);
                    } else {
                        addPortalError.text = portal.versionError.details;
                    }
                } else {
                    console.error("Invalid version response:", JSON.stringify(response, undefined, 2));
                }
            }
        }

        onErrorTextChanged: {
            console.error("portalVersionRequest error", errorText);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: infoRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest/info?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log("info:", JSON.stringify(response, undefined, 2));
            }
        }

        onErrorTextChanged: {
            console.log("infoRequest error", errorText);
            //addPortalError.text = errorText;
        }
    }

    //--------------------------------------------------------------------------

    DocumentDialog {
        id: pkiDocumentDialog

        onAccepted: pkiRequest.send()
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: pkiRequest

        url: pkiDocumentDialog.fileUrl
        responseType: "base64"

        onReadyStateChanged: {
            if ( readyState !== NetworkRequest.ReadyStateComplete ) {
                return;
            }

            pkiFile = response;
            pkiFileName = AppFramework.urlInfo( url ).fileName;
            passPhrase = "";
        }
    }

    //--------------------------------------------------------------------------

    BinaryData {
        id: pkiFileBinary

        base64: pkiFile
    }

    //--------------------------------------------------------------------------

}
