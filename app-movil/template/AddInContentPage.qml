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

import "../Portal"

AppPage {
    id: page

    //--------------------------------------------------------------------------

    property Component contentComponent
    property var properties

    //--------------------------------------------------------------------------

    backButton {
        visible: true
    }

    //--------------------------------------------------------------------------

    contentMargins: 0
    contentItem: Item {
        Component.onCompleted: {
            addInLoader.sourceComponent = contentComponent;
            addInLoader.active = true;
        }

        Loader {
            id: addInLoader

            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            active: false

            onLoaded: {
                var keys = Object.keys(properties);
                keys.forEach(function (key) {
                    if (typeof item[key] !== "undefined") {
                        item[key] = properties[key];
                    }
                });
            }
        }
    }

    //--------------------------------------------------------------------------
}
