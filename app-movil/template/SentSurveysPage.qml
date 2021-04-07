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

import "../Controls/Singletons"

SurveysListPage {
    //--------------------------------------------------------------------------

    title: qsTr("Sent %1").arg(surveyTitle)
    statusFilter: xformsDatabase.statusSubmitted
    showDelete: false

    mapKey: "sent"

    //--------------------------------------------------------------------------

    listAction: SurveysListButton {
        text: qsTr("Empty")
        icon: Icons.icon("trash")

        onClicked: {
            confirmPanel.clear();
            confirmPanel.icon = "images/warning.png";
            confirmPanel.title = qsTr("Empty");
            confirmPanel.text = qsTr("This action will empty the Sent folder");
            confirmPanel.question = qsTr("Are you sure you want to delete all surveys in the Sent folder?");
            confirmPanel.show(emptySentFolder);
        }
    }

    //--------------------------------------------------------------------------

    function emptySentFolder(){
        xformsDatabase.deleteSurveyBox(surveyInfo.name, xformsDatabase.statusSubmitted);
        closePage();
    }

    //--------------------------------------------------------------------------

    ConfirmPanel {
        id: confirmPanel
    }

    //--------------------------------------------------------------------------
}
