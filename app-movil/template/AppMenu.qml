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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Portal"
import "../Controls/Singletons"

AppPageMenu {
    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property bool showSignIn: true
    property bool showDownloadSurveys: false
    property bool showAppSettings: true
    property bool showAppAbout: true
    property AppPage page

    //--------------------------------------------------------------------------

    /*
    MenuItem {
        property bool noColorOverlay: portal.signedIn

        visible: showSignIn && portal.signedIn || Networking.isOnline
        enabled: visible

        text: portal.signedIn ? qsTr("Sign out %1").arg(portal.user ? portal.user.fullName : "") : qsTr("Sign in")
        iconSource: portal.signedIn ? portal.userThumbnailUrl : Icons.icon("sign-in")

        onTriggered: {
            if (portal.signedIn) {
                portal.signOut();
            } else {
                portal.signIn(undefined, true);
            }
        }
    }
    */

    //--------------------------------------------------------------------------

    MenuItem {
        visible: Networking.isOnline && showDownloadSurveys

        text: qsTr("Download Surveys")
        iconSource: Icons.icon("download")
        enabled: visible
        onTriggered: {
            showSignInOrDownloadPage();
        }
    }

    //--------------------------------------------------------------------------

    MenuItem {
        visible: showAppSettings

        text: qsTr("Settings")
        iconSource: Icons.icon("gear")

        onTriggered: {
            showSettingsPage();
        }
    }

    //--------------------------------------------------------------------------

    MenuItem {
        visible: showAppAbout

        text: qsTr("About")
        iconSource: Icons.icon("information")

        onTriggered: {
            showAboutPage();
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

    function showSettingsPage() {
        page.Stack.view.push(appSettingsPage);
    }

    //--------------------------------------------------------------------------

    function showAboutPage() {
        page.Stack.view.push(appAboutPage);
    }

    //--------------------------------------------------------------------------

    function showSignInOrDownloadPage() {
        portal.signInAction(qsTr("Please sign in to download surveys"), showDownloadPage);
    }

    function showDownloadPage() {
        page.Stack.view.push({
                                 item: downloadSurveysPage
                             });
    }

    //--------------------------------------------------------------------------
}
