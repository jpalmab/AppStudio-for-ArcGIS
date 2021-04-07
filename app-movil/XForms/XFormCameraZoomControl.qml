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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtMultimedia 5.9

import ArcGIS.AppFramework 1.0

Item {

    id : zoomControl

    property int currentZoom: 1
    property int minimumZoom: 1
    property int maximumZoom: 1
    property alias sliderValue: cameraZoomSlider.value

    signal zoomTo(real value)

    RowLayout {
        anchors.fill: parent
        spacing: 10 * AppFramework.displayScaleFactor

        // spacer --------------------------------------------------------------

        Item {
            Layout.fillWidth: true
        }

        // zoom out ------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            Text {
                id: minus
                text: "-"
                anchors.centerIn: parent
                color: "white"
                font {
                    bold: true
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (cameraZoomSlider.value > 1) {
                        var currentValue = Math.round(cameraZoomSlider.value);
                        currentValue -= 1.0;
                        cameraZoomSlider.value = currentValue;
                    }
                }
            }
        }

        // slider --------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 100 * AppFramework.displayScaleFactor
            Layout.maximumWidth: 260 * AppFramework.displayScaleFactor

            Slider {
                id: cameraZoomSlider
                anchors.fill: parent
                from: minimumZoom
                to: maximumZoom
                stepSize: 0.0

                background: Rectangle {
                    x: cameraZoomSlider.leftPadding
                    y: cameraZoomSlider.topPadding + cameraZoomSlider.availableHeight / 2 - height / 2
                    implicitWidth: parent.width
                    implicitHeight: 4 * AppFramework.displayScaleFactor
                    width: cameraZoomSlider.availableWidth
                    height: implicitHeight
                    radius: 2 * AppFramework.displayScaleFactor
                    color: "#bdbebf"

                    Rectangle {
                        width: cameraZoomSlider.visualPosition * parent.width
                        height: parent.height
                        color: xform.style.titleBackgroundColor
                        radius: 2 * AppFramework.displayScaleFactor
                    }
                }

                handle: Rectangle {
                    x: cameraZoomSlider.leftPadding + cameraZoomSlider.visualPosition * (cameraZoomSlider.availableWidth - width)
                    y: cameraZoomSlider.topPadding + cameraZoomSlider.availableHeight / 2 - height / 2
                    implicitWidth: 24 * AppFramework.displayScaleFactor
                    implicitHeight: 24 * AppFramework.displayScaleFactor
                    radius: 12 * AppFramework.displayScaleFactor
                    color: cameraZoomSlider.pressed ? "white" : "lightgray"
                    border.color: "gray"
                }

                onValueChanged: {
                    zoomTo(value);
                }
            }
        }

        // zoomIn --------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            Text {
                id: plus
                text: "+"
                anchors.centerIn: parent
                color: "white"
                font {
                    bold: true
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (cameraZoomSlider.value < camera.maximumZoom) {
                        var currentValue = Math.round(cameraZoomSlider.value);
                        currentValue += 1.0;
                        cameraZoomSlider.value = currentValue;
                    }
                }
            }
        }

        // spacer --------------------------------------------------------------

        Item {
            Layout.fillWidth: true
        }
    }

    // Fuctions ////////////////////////////////////////////////////////////////

    function updateZoom(zoomValue) {
        cameraZoomSlider.value = zoomValue;
    }

    // END /////////////////////////////////////////////////////////////////////
}
