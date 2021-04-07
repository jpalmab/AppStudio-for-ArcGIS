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

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as QC1

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls/Singletons"

ActionGroup {
    id: actionGroup
    
    //--------------------------------------------------------------------------

    property Portal portal: app.portal

    property bool showAppSettings: true
    property bool showAppAbout: true
    property bool showDownloadSurveys: false
    property SurveysModel surveysModel

    property QC1.StackView stackView

    //--------------------------------------------------------------------------

    exclusive: false

    //--------------------------------------------------------------------------

    Action {
        enabled:showDownloadSurveys && portal.isOnline && portal.signedIn

        // property bool updatesAvailable: surveysModel ? surveysModel.updatesAvailable > 0 : false

        icon.source: Icons.bigIcon("download")
        text: qsTr("Download Surveys")

        onTriggered: {
            portal.connectAction(text, showDownloadPage);
        }
    }
    
    Action {
        enabled: showAppSettings

        icon.source: Icons.bigIcon("gear")
        text: qsTr("Settings")
        
        onTriggered: {
            pushPage(appSettingsPage);
        }
    }
    
    Action {
        enabled: showAppAbout

        icon.source: Icons.bigIcon("information")
        text: qsTr("About")
        
        onTriggered: {
            pushPage(appAboutPage);
        }
    }

    //--------------------------------------------------------------------------

    function pushPage(page, properties) {
        stackView.push({
                           item: page,
                           properties: properties
                       });
    }

    //--------------------------------------------------------------------------

    function showSignInOrDownloadPage() {
        portal.signInAction(qsTr("Please sign in to download surveys"), showDownloadPage);
    }

    //--------------------------------------------------------------------------

    function showDownloadPage(updatesFilter) {
        pushPage(downloadSurveysPage,
                 {
                     surveysModel: surveysModel,
                     updatesFilter: !!updatesFilter
                 });
    }

    //--------------------------------------------------------------------------
}
