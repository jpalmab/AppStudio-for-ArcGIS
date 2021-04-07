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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

import "../Controls"
import "../Controls/Singletons"

XFormPage {
    id: page

    //--------------------------------------------------------------------------

    property var addIn
    property string addInName
    property var addInView
    readonly property var addInInstance: addInView ? addInView.instance : null

    property FileInfo imageFileInfo

    property bool debug: false

    //--------------------------------------------------------------------------

    title: "Settings"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        addIn = xform.addIns.create(addInName, page);

        title = qsTr("%1 Settings").arg(addIn.itemInfo.title);

        loader.setSource(addIn.settingsPageSource,
                         {
                             settings: addIn.settings,
                             dataFolder: addIn.dataFolder
                         });
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    Item {
        anchors.fill: parent

        Loader {
            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            sourceComponent: backgroundComponent
            active: loader.status !== Loader.Ready
            asynchronous: true
        }

        Loader {
            id: loader

            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: backgroundComponent

        Item {
            BusyIndicator {
                anchors.centerIn: parent

                running: true
            }
        }
    }

    //--------------------------------------------------------------------------

    function closeControl() {
        parent.pop();
    }

    //--------------------------------------------------------------------------
}
