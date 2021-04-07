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

import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0

import "../Controls"
import "XForm.js" as XFormJS
import "XFormGeometry.js" as Geometry

XFormPage {
    id: page

    //--------------------------------------------------------------------------

    property bool isPolygon
    property var coordinates
    property bool debug: false

    readonly property var geopath: QtPositioning.path(coordinates)
    property var locale: xform.locale

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 15 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            XFormInfoDataText {
                Layout.fillWidth: true

                label: qsTr("Number of vertices")
                value: coordinates.length
            }

            XFormInfoDataText {
                Layout.fillWidth: true

                label: isPolygon
                       ? qsTr("Perimeter")
                       : qsTr("Length")

                value: Geometry.displayLength(Geometry.geopathLength(geopath, isPolygon), locale);
            }

            XFormInfoDataText {
                Layout.fillWidth: true

                visible: isPolygon
                label: qsTr("Area")

                value: Geometry.displayArea(Geometry.pathArea(geopath.path), locale)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
