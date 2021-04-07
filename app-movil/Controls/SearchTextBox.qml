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
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

import "Singletons"

TextBox {
    id: control

    //--------------------------------------------------------------------------

    property alias editTimeout: editTimer.interval
    property string __text
    property bool busy
    property alias progressBar: progressBar

    //--------------------------------------------------------------------------

    signal pressAndHold()

    signal start()
    signal cancel()

    //--------------------------------------------------------------------------

    radius: height / 2

    placeholderText: qsTr("Search")
    enterKeyType: Qt.EnterKeySearch

    //--------------------------------------------------------------------------

    onCleared: {
        __text = "";
        editTimer.stop();
        editingFinished();
        start();
    }

    //--------------------------------------------------------------------------

    onTextChanged: {
        if (text > "") {
            if (editTimeout) {
                editTimer.restart();
            }
        } else {
            editTimer.stop();
            editingFinished();
        }
    }

    onEditingFinished: {
        editTimer.stop();
    }

    //--------------------------------------------------------------------------

    leftIndicator: Item {
        implicitWidth: height
        width: height

        Button {
            id: searchButton

            anchors.fill: parent

            padding: 0
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0

            icon {
                source: Icons.icon("magnifying-glass")
                color: textInput.color
                height: textInput.height
                width: textInput.height
            }

            display: AbstractButton.IconOnly
            background: null
            //opacity: busyIndicator.running ? 0 : 1

            onClicked: {
                if (busy) {
                    cancel();
                } else {
                    start();
                    textInput.textChanged();
                }
            }

            onPressAndHold: {
                control.pressAndHold();
            }

            PulseAnimation {
                target: searchButton
                running: busy
            }
        }

//        ColorBusyIndicator {
//            id: busyIndicator

//            anchors {
//                fill: parent
//                margins: -control.padding / 2
//            }

//            backgroundColor: activeBorderColor
//            running: busy
//        }
    }

    //--------------------------------------------------------------------------

    ProgressBar {
        id: progressBar

        property alias indicatorColor: progressIndicator.color

        anchors {
            left: parent.left
            leftMargin: parent.radius
            right: parent.right
            rightMargin: parent.radius
            verticalCenter: parent.bottom
        }

        visible: false
        height: 3 * AppFramework.displayScaleFactor

        background: Rectangle {
            color: "transparent"
            radius: height / 2
        }

        contentItem: Item {
            Rectangle {
                id: progressIndicator

                width: progressBar.visualPosition * parent.width
                height: parent.height
                radius: height / 2
                color: Qt.lighter(control.activeBorderColor, 1.75)
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: editTimer

        interval: 500
        running: false
        repeat: false

        onTriggered: {
            if (text !== __text) {
                __text = text;
                editingFinished();
                control.start();
            }
        }
    }

    //--------------------------------------------------------------------------
}
