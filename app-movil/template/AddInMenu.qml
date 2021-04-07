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
import QtQuick.Controls 2.4
import QtQuick.Controls 1.4 as QC1

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"


AppMenu {
    id: menu

    //--------------------------------------------------------------------------

    property AddInContainer container

    property AddIn addIn: container.addIn
    property var instance: container.instance

    property bool showAddInSettings: true
    property bool showAddInAbout: true

    //--------------------------------------------------------------------------

    showAppAbout: false
    showAppSettings: false
    
    //--------------------------------------------------------------------------

    Connections {
        target: container

        onLoaded: {
            addMenuItems();
        }
    }

    //--------------------------------------------------------------------------

    QC1.MenuItem {
        text: qsTr("%1 Settings").arg(addIn.title)
        iconSource: Icons.icon("gear")
        visible: addIn.hasSettingsPage && showAddInSettings
        
        onTriggered: {
            page.QC1.Stack.view.push(addInSettingsPage);
        }
    }
    
    //--------------------------------------------------------------------------

    QC1.MenuItem {
        text: qsTr("About %1").arg(addIn.title)
        iconSource: Icons.icon("information")
        visible: showAddInAbout
        
        onTriggered: {
            page.QC1.Stack.view.push(addInAboutPage);
        }
    }

    //--------------------------------------------------------------------------

    function addMenuItems() {
        console.log("addMenuItems:", addIn.title);
        var addInMenu = instance.menu;

        if (!addInMenu) {
            return;
        }

        console.log("Add-in menu:", addInMenu, addInMenu.contentData.length);

        for (var i = 0; i < addInMenu.contentData.length; i++) {
            var addInMenuItem = addInMenu.contentData[i];
            console.log("Menu:", i, addInMenuItem, addInMenuItem.text);
            var menuItem = menuItemComponent.createObject(menu,
                                                          {
                                                              addInMenuItem: addInMenuItem
                                                          });

            menu.insertItem(0, menuItem);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: menuItemComponent

        QC1.MenuItem {
            property bool noColorOverlay: true

            property MenuItem addInMenuItem
            readonly property AddIn addIn: container.addIn

            visible: addInMenuItem.enabled //visible
            enabled: addInMenuItem.enabled

            text: addInMenuItem.text
            iconSource: addInMenuItem.icon.source

            onTriggered: {
                addInMenuItem.triggered();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInAboutPage

        AddInAboutPage {
            addIn: menu.addIn
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        AddInSettingsPage {
            addIn: menu.addIn
            instance: menu.instance
        }
    }

    //--------------------------------------------------------------------------
}
