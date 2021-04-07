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

import "../Controls/Singletons"

MainViewTab {
    id: tab

    //--------------------------------------------------------------------------

    property alias path: container.path
    property alias addIn: container.addIn
    property alias instance: container.instance
    property alias currentMode: container.currentMode

    //--------------------------------------------------------------------------

    title: container.title
    iconSource: addIn.iconSource
    iconMonochrome: addIn.iconMonochrome

    actionGroup: actions.actionGroup

    //--------------------------------------------------------------------------

    AddInActions {
        id: actions

        container: container
        stackView: page.QC1.Stack.view
    }

    //--------------------------------------------------------------------------

    AddInContainer {
        id: container

        anchors.fill: parent

        asynchronous: true//false

        opacity: tab.SwipeView.isCurrentItem ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }

        onLoaded: {
            console.log("Add-in tab loaded:", instance, "indicator:", instance.indicator)
            if (instance.indicator) {
                indicator = instance.indicator;
            }
        }
    }

    //--------------------------------------------------------------------------
}
