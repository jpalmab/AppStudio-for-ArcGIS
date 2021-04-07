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

import "../Portal"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal

    property alias container: container
    property alias addIn: container.addIn
    property alias addInPath: container.path

    //--------------------------------------------------------------------------

    title: container.title

    backButton {
        visible: mainStackView.depth > 1
    }

    //--------------------------------------------------------------------------

    actionButton {
        visible: true

        menu: AddInMenu {
            container: page.container
            page: page
        }
    }

    //--------------------------------------------------------------------------

    contentMargins: 0
    contentItem: Item {
        AddInContainer {
            id: container

            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            canClose: backButton.visible
        }
    }

    //--------------------------------------------------------------------------
    /*
    DownloadSurvey {
        id: downloadSurvey

        portal: app.portal
        succeededPrompt: false
        debug: debug

        onSucceeded: {
            downloaded();
        }
    }
    */

    //--------------------------------------------------------------------------
}
