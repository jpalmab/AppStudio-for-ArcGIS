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

import "../Controls"
import "../Controls/Singletons"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property alias currentTab: mainView.currentTab

    readonly property QC1.StackView pageStackView: QC1.Stack.view

    //--------------------------------------------------------------------------

    signal addInSelected(var addInItem)
    signal selected(string surveyPath, bool pressAndHold, int indicator, var parameters, var surveyInfo)

    //--------------------------------------------------------------------------

    title: mainView.currentTab
           ? mainView.currentTab.title
           : app.info.title//qsTr("My Survey123")//app.info.title

    layoutDirection: app.localeProperties.layoutDirection
    contentMargins: 0

    backButton {
        visible: mainStackView.depth > 1
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        currentTab.titleClicked();
    }

    onTitlePressAndHold: {
        currentTab.titlePressAndHold();
    }

    //--------------------------------------------------------------------------

    PortalLogoButton {
        parent: backButton.parent

        anchors.fill: backButton

        visible: !backButton.visible && sharedTheme.logoSmall > ""
    }

    //--------------------------------------------------------------------------

    actionComponent: PortalUserButton {
        id: userButton

        portal: app.portal
        popup: MainDrawer {
            portal: userButton.portal
            actions: (currentTab && currentTab.actionGroup) ? currentTab.actionGroup : null

            onActionsChanged: {
                if (actions && typeof actions.stackView === "object") {
                    actions.stackView = pageStackView;
                }
            }
        }
        signedOutIcon: ControlsSingleton.menuIcon
        padding: 4 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    contentItem: MainView {
        id: mainView
    }

    //--------------------------------------------------------------------------
}
