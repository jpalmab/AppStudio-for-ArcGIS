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

import ArcGIS.AppFramework 1.0

Item {
    //--------------------------------------------------------------------------

    property bool showTilesTab: true
    property bool showAddInTilesTab: false
    property bool addServicesTab: true
    property bool showServicesTab: settings.boolValue("AddIns/showServicesTab", false) // TODO mmove to settings
    property bool showTabTitles: settings.boolValue("AddIns/showTabText", true) // TODO mmove to settings
    property alias currentTab: tabs.currentTab
    property alias tabsView: tabs.view

    property bool debug: false

    //--------------------------------------------------------------------------

    MainViewTabs {
        id: tabs

        anchors.fill: parent
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInTilesModel

        addInsFolder: app.addInsFolder
        type: kTypeTool
        mode: kToolModeTab

        onUpdated: {
            var tabItem;

            tabs.clear();

            if (showTilesTab) {
                tabItem = tilesTab.createObject(tabsView);
                tabsView.addItem(tabItem);
            }

            if (showAddInTilesTab) {
                tabItem = addInTilesTab.createObject(tabsView);
                tabsView.addItem(tabItem);
            }

            for (var i = 0; i < count; i++) {
                var addInItem = get(i);
                tabItem = addInTabComponent.createObject(
                            tabsView,
                            {
                                path: addInItem.path,
                                currentMode: kToolModeTab
                            });

                console.log("Adding add-in tab:", i, "path:", addInItem.path);

                tabsView.addItem(tabItem);
            }

            if (addServicesTab) {// && app.addInsManager.servicesManager.count > 0) {
                tabItem = addInServicesTab.createObject(tabsView);
                tabsView.addItem(tabItem);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: tilesTab

        MainViewTilesTab {
            onIndicatorPressAndHold: {
                showServicesTab = !showServicesTab;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInTilesTab

        AddInTilesTab {
            onIndicatorPressAndHold: {
                showServicesTab = !showServicesTab;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInServicesTab

        AddInServicesTab {
            manager: app.addInsManager.servicesManager
            visible: count > 0 && showServicesTab
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInTabComponent

        AddInTab {
        }
    }

    //--------------------------------------------------------------------------
}
