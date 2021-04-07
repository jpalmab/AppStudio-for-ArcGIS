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
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtQuick.Controls 1.4 as QC1

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "SurveyHelper.js" as Helper

AppPage {
    id: page

    //--------------------------------------------------------------------------

    readonly property QC1.StackView pageStackView: QC1.Stack.view

    property bool debug: false

    //--------------------------------------------------------------------------

    signal selected(string surveyPath, bool pressAndHold, int indicator, var parameters, var surveyInfo)

    //--------------------------------------------------------------------------

    title: qsTr("My Surveys")

    layoutDirection: app.localeProperties.layoutDirection
    contentMargins: 0

    //--------------------------------------------------------------------------

    backButton {
        visible: mainStackView.depth > 1
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        galleryView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    actionComponent: PortalUserButton {
        id: userButton

        portal: app.portal
        popup: MainDrawer {
            portal: userButton.portal
            actions: mainActionGroup
        }

        signedOutIcon: ControlsSingleton.menuIcon
        padding: 4 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    PortalLogoButton {
        parent: backButton.parent

        anchors.fill: backButton

        visible: !backButton.visible && sharedTheme.logoSmall > ""
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent

            UpdatesNotification {
                Layout.fillWidth: true

                updatesAvailable: surveysModel.updatesAvailable
                busy: surveysRefresh.busy

                onClicked: {
                    mainActionGroup.showDownloadPage(true);
                }

                onPressAndHold: {
                    page.debug = !page.debug;
                }
            }

            SurveysGalleryView {
                id: galleryView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: galleryView.model.count

                model: surveysModel

                delegate: galleryDelegateComponent

                progressBar {
                    visible: surveysRefresh.busy
                    value: surveysRefresh.progress
                }

                refreshHeader {
                    enabled: surveysRefresh.enabled
                    refreshing: surveysRefresh.busy
                }

                onRefresh: {
                    surveysFolder.update();
                    surveysRefresh.refresh();
                }

                onClicked: {
                    if (currentSurvey) {
                        selected(app.surveysFolder.filePath(currentSurvey), false, -1, null, getSurveyItem(currentIndex));
                    }
                }

                onPressAndHold: {
                    if (currentSurvey) {
                        selected(app.surveysFolder.filePath(currentSurvey), true, -1, null, getSurveyItem(currentIndex));
                    }
                }
            }

            NoSurveysView {
                Layout.fillHeight: true
                Layout.fillWidth: true

                canDownload: !app.openParameters
                portal: app.portal
                visible: !galleryView.model.count && canDownload
                actionGroup: mainActionGroup
            }

            OpenParametersPanel {
                id: openParametersPanel

                Layout.fillWidth: true
                Layout.margins: 5 * AppFramework.displayScaleFactor

                progressPanel: progressPanel

                onDownloaded: {
                    surveysFolder.update();
                    checkOpenParameters();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        formsFolder: surveysFolder

        onUpdated: {
            galleryView.forceLayout();
            checkOpenParameters();
        }
    }

    SurveysRefresh {
        id: surveysRefresh

        model: surveysModel
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenParametersChanged: {
            checkOpenParameters();
        }
    }

    function checkOpenParameters() {
        console.log("Checking openParameters", JSON.stringify(app.openParameters, undefined, 2));

        if (app.openParameters) {
            var parameters = app.openParameters;
            var surveyItem = findSurveyItem(parameters);
            if (surveyItem) {
                app.openParameters = null;
                parameters.itemId = surveyItem.itemId;
                selected(app.surveysFolder.filePath(surveyItem.survey), true, -1, parameters, surveyItem);
            } else {
                openParametersPanel.enabled = true;
            }
        }
    }

    function findSurveyItem(parameters) {
        var itemId = Helper.getPropertyValue(parameters, "itemId");
        if (!itemId) {
            return undefined;
        }

        console.log("Searching for survey itemId:", itemId);

        for (var i = 0; i < galleryView.model.count; i++) {
            var surveyItem = galleryView.getSurveyItem(i);
            if (surveyItem.itemId === itemId) {
                return surveyItem;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    MainActionGroup {
        id: mainActionGroup

        stackView: pageStackView
        showDownloadSurveys: true
        surveysModel: surveysModel
    }

    //--------------------------------------------------------------------------

    Component {
        id: galleryDelegateComponent

        SurveysGalleryDelegate {
            id: galleryDelegate

            debug: page.debug
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0
    }

    //--------------------------------------------------------------------------
}
