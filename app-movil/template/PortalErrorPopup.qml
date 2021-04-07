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

    width: Math.min(parent.width * 0.75, 300 * AppFramework.displayScaleFactor)

    closePolicy: Popup.NoAutoClose

    icon {
        source: Icons.bigIcon("exclamation-mark-triangle")
        color: "#A80000"
    }

    layout.spacing: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    Item {
        Layout.preferredHeight: 20 * AppFramework.displayScaleFactor
    }

    AppText {
        Layout.fillWidth: true

        visible: error.code > 0
        text: qsTr("Error code: %1").arg(error.code)
        horizontalAlignment: Text.AlignHCenter
        font {
            pointSize: 16
        }
    }

    AppText {
        Layout.fillWidth: true

        text: error.message || ""
        horizontalAlignment: Text.AlignHCenter
        font {
            pointSize: 16
        }
    }

    Item {
        Layout.preferredHeight: 20 * AppFramework.displayScaleFactor
    }

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: localeProperties.layoutDirection

        AppButton {
            Layout.fillWidth: true

            text: qsTr("Try again")
            textPointSize: 15

            onClicked: {
                popup.close();
                request.retry();
            }
        }

        Item {
            Layout.fillWidth: true
        }

        AppButton {
            Layout.fillWidth: true

            text: qsTr("Cancel")
            textPointSize: 15

            onClicked: {
                popup.close();
                request.cancel();
            }
        }
    }

    //--------------------------------------------------------------------------
}
