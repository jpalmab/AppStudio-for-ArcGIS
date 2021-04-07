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
import QtQuick.Shapes 1.13

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    property Portal portal
    property bool busy: portal.isSigningIn
    property alias onlineIndicator: userIcon.onlineIndicator
    property alias isOnline: userIcon.isOnline
    property Component popup: userPopup

    property url signedOutIcon: Icons.bigIcon(isOnline ? "sign-in" : "offline")
    property url signingInIcon: Icons.icon("sign-in")

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    implicitWidth: 40 * AppFramework.displayScaleFactor
    implicitHeight: 40 * AppFramework.displayScaleFactor

    padding: 2 * AppFramework.displayScaleFactor

    palette {
        button: app.titleBarBackgroundColor
        buttonText: app.titleBarTextColor
        highlight: app.titleBarTextColor
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        StyledImage {
            anchors {
                fill: parent
                margins: 4 * AppFramework.displayScaleFactor
            }

            source: signedOutIcon
            visible: !busy && !portal.signedIn
            color: control.palette.buttonText
        }

        Rectangle {
            anchors {
                fill: parent
                margins: -4 * AppFramework.displayScaleFactor
            }

            visible: !busy && control.enabled && mouseArea.containsMouse

            color: palette.highlight

            /*
            border {
                color: !userIcon.isDefaultUserThumbnail ? "transparent" : palette.highlight
                width: 4 * AppFramework.displayScaleFactor
            }
            */

            radius: height / 2
            opacity: 0.1
        }

        PortalUserIcon {
            id: userIcon

            anchors {
                fill: parent
            }

            portal: control.portal
            visible: portal.signedIn
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            enabled: control.enabled
            hoverEnabled: enabled

            cursorShape: busy
                         ? Qt.BusyCursor
                         : (isOnline || portal.signedIn)
                           ? Qt.PointingHandCursor
                           : Qt.ForbiddenCursor

            onClicked: {
                control.clicked();
            }

            onPressAndHold: {
                control.pressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------

    background: Item {
        StyledImage {
            id: signingInImage

            anchors {
                fill: parent
                margins: 8 * AppFramework.displayScaleFactor
            }

            visible: busy
            color: control.palette.buttonText
            source: signingInIcon
        }

        PulseAnimation {
            target: signingInImage
            running: busy
        }
    }

    //--------------------------------------------------------------------------

    onClicked: {
        if (busy) {
            return;
        }

        if (control.popup !== userPopup) {
            var popup = control.popup.createObject(control);
            popup.open();
        } else {
            if (portal.signedIn) {
                popup = control.popup.createObject(control);
                popup.open();
            } else if (isOnline) {
                portal.signIn(undefined, true);
            }
        }
    }

    //--------------------------------------------------------------------------

    onPressAndHold: {
        if (!busy) {
            return;
        }

        portal.signOut();
    }

    //--------------------------------------------------------------------------

    Component {
        id: userPopup

        PortalUserPopup {
            id: popup

            anchors.centerIn: undefined

            y: parent.y + parent.height + 10 * AppFramework.displayScaleFactor
            x: parent.x + parent.width / 2 - 10 * AppFramework.displayScaleFactor

            width: 300 * AppFramework.displayScaleFactor

            portal: control.portal

            Shape {
                id: triShape

                parent: background
                height: 10 * AppFramework.displayScaleFactor
                width: height

                anchors {
                    bottom: parent.top
                    bottomMargin: - 1 * AppFramework.displayScaleFactor
                    left: parent.left
                    leftMargin: width / 2
                }

                ShapePath {
                    id: triPath

                    strokeColor: popup.palette.dark
                    strokeWidth: 1
                    fillColor: popup.palette.window
                    startX: triShape.width / 2
                    startY: 0

                    PathLine { x: triShape.width; y: triShape.height }
                    PathLine { x: 0; y: triShape.height }
                    PathLine { x: triPath.startX; y: triPath.startY }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
