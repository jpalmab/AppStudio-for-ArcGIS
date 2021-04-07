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

import "../Controls"

XFormPage {
    id: gnssInfo

    property XFormPositionSourceManager positionSourceManager
    property string fontFamily: xform.style.fontFamily
    property var position: ({})

    property bool debug: false

    //--------------------------------------------------------------------------

    title: qsTr("GNSS Location Status")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: gnssInfo.positionSourceManager
        emitNewPositionIfNoFix: true
        stayActiveOnError: true
        listener: "XFormGNSSInfoPage"

        onNewPosition: {
            gnssInfo.position = position;
        }
    }

    //--------------------------------------------------------------------------

    SwipeTabView {
        anchors.fill: parent

        fontFamily: gnssInfo.fontFamily
        tabBarBackgroundColor: xform.style.titleBackgroundColor
        selectedTextColor: xform.style.titleTextColor

        color: xform.style.backgroundColor

        XFormGNSSData {
            positionSourceManager: gnssInfo.positionSourceManager
            position: gnssInfo.position
        }

        XFormGNSSSkyPlot {
            positionSourceManager: gnssInfo.positionSourceManager
            fontFamily: gnssInfo.fontFamily
        }

        XFormGNSSDebug {
            positionSourceManager: gnssInfo.positionSourceManager
            fontFamily: gnssInfo.fontFamily
        }
    }

    //--------------------------------------------------------------------------
}
