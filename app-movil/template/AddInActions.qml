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

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

Item {
    id: actions

    //--------------------------------------------------------------------------

    property AddInContainer container

    property AddIn addIn: container.addIn
    property var instance: container.instance

    property bool showAddInSettings: true
    property bool showAddInAbout: true

    property alias stackView: actionGroup.stackView
    property alias actionGroup: actionGroup

    //--------------------------------------------------------------------------

    onInstanceChanged: {
        if (instance) {
            addActions();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(actions, true)
    }

    //--------------------------------------------------------------------------

    function addActions() {
        console.log(logCategory, arguments.callee.name, "title:", addIn.title);

        var resources = instance.resources;
        for (var i = 0; i < resources.length; i++) {
            var resource = resources[i];

            if (AppFramework.instanceOf(resource, "QQuickAction")) {
                actionGroup.addAction(resource);
            }
        }
    }

    //--------------------------------------------------------------------------

    MainActionGroup {
        id: actionGroup

        showAppAbout: false
        showAppSettings: false

        Action {
            text: qsTr("%1 Settings").arg(addIn.title)
            icon.source: Icons.icon("gear")
            enabled: addIn.hasSettingsPage && showAddInSettings

            onTriggered: {
                stackView.push(addInSettingsPage);
            }
        }

        Action {
            text: qsTr("About %1").arg(addIn.title)
            icon.source: Icons.icon("information")
            enabled: showAddInAbout

            onTriggered: {
                stackView.push(addInAboutPage);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInAboutPage

        AddInAboutPage {
            addIn: actions.addIn
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        AddInSettingsPage {
            addIn: actions.addIn
            instance: actions.instance
        }
    }

    //--------------------------------------------------------------------------
}
