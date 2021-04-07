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

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

ColumnLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property Portal portal
    property var request
    property var error

    //--------------------------------------------------------------------------

    closePolicy: Popup.NoAutoClose

    title: qsTr("Connecting to %1").arg(portal.name)
    titleSeparator.visible: false

    icon {
        source: Icons.bigIcon(portal.isPortal ? "portal" : "arcgis-online")
    }

    layout.spacing: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            easing {
                type: Easing.InExpo
            }
            duration: 3000
        }
    }

    exit: null

    dim: opacity > 0.75

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    ProgressBar {
        Layout.fillWidth: true

        indeterminate: true
    }

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: localeProperties.layoutDirection

        Item {
            Layout.fillWidth: true
        }

        AppButton {
            text: qsTr("Cancel")
            textPointSize: 15

            onClicked: {
                popup.close();
                request.cancel();
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------
}
