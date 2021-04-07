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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

Item {
    //--------------------------------------------------------------------------

    property alias color: primary.color
    property alias alternateColor: alternate.color

    //--------------------------------------------------------------------------

    implicitHeight: 2 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Rectangle {
        id: primary

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: parent.height / 2

        color: "#22000000"
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: alternate

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        height: parent.height / 2
        color: "#33ffffff"
    }

    //--------------------------------------------------------------------------
}

