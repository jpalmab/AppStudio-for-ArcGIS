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

import ArcGIS.AppFramework 1.0

import "../Controls"

ColumnLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias statusText: statusText.text
    property bool indeterminate: true
    property color textColor: "white"
    property date startTime: new Date()
    property date endTime: new Date()
    property int elapsedTime: endTime - startTime;

    //--------------------------------------------------------------------------

    closePolicy: Popup.NoAutoClose

    background: null
    enter: null

    //--------------------------------------------------------------------------

    onAboutToHide: {
        endTime = new Date(0);
        console.log(logCategory, "Elaspsed time:", elapsedTime);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    AppBusyIndicator {
        Layout.alignment: Qt.AlignHCenter
    }

    AppText {
        id: statusText

        Layout.fillWidth: true

        font {
            pointSize: 18
            bold: true
        }

        horizontalAlignment: Text.AlignHCenter
        color: textColor
    }

    //--------------------------------------------------------------------------
}
