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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtLocation 5.12

import ArcGIS.AppFramework 1.0

import ".."
import "../../Controls"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias map: mapTypesView.map
    property alias token: mapTypesView.token

    property bool debug: false
    property alias page: page
    property alias header: page.header
    property alias footer: page.footer

    //--------------------------------------------------------------------------

    signal mapTypeChanged(var mapType)

    //--------------------------------------------------------------------------

    width: parent.width * 0.75
    height: parent.height * 0.75

    backgroundRectangle.color: "#f4f4f4";

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    contentItem: Page {
        id: page

        background: null

        ScrollView {
            id: scrollView

            anchors.fill: parent

            MapTypesView {
                id: mapTypesView

                width: scrollView.availableWidth
                height: scrollView.availableHeight

                onClicked: {
                    if (debug) {
                        console.log(logCategory, "mapType:", JSON.stringify(mapType, undefined, 2));
                    }

                    map.activeMapType = mapType;
                    mapTypeChanged(mapType);

                    popup.close();
                }

                onPressAndHold: {
                    console.log(logCategory, "mapType:", JSON.stringify(mapType, undefined, 2));
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
