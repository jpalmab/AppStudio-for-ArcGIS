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

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: startPage

    signal signedIn()

    color: app.info.propertyValue("startBackgroundColor", "#e0e0df")

//    Image {
//        anchors.fill: parent
//        source: app.folder.fileUrl(app.info.propertyValue("startBackgroundImage", ""))
//        fillMode: Image.PreserveAspectCrop
//        visible: source > ""
//    }

    Image {
        anchors.fill: parent
        source: app.folder.fileUrl(app.info.propertyValue("startOverlayImage", "images/start-overlay.png"))
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        anchors.fill: parent
        color: app.info.propertyValue("startForegroundColor", "transparent")
    }

    MouseArea {
        anchors.fill: parent

        onPressAndHold: {
            startPage.signedIn();
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 20 * AppFramework.displayScaleFactor
        }

        spacing: 5

        Item {
            height: 20
            width: parent.width
        }

        ConfirmButton {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: portal.isOnline && !portal.isSigningIn
            text: qsTr("Sign in")
            iconSource: Icons.bigIcon("sign-in")
            textPointSize: 20

            onClicked: {
                if (portal.signedIn) {
                    portal.signOut();
                }
                portal.signIn(undefined, true);
            }
        }

        StyledImage {
            id: signingInImage

            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: 50 * AppFramework.displayScaleFactor
            implicitHeight: 50 * AppFramework.displayScaleFactor

            visible: portal.isSigningIn
            source: Icons.bigIcon("sign-in")
            color: app.titleBarTextColor
        }

        PulseAnimation {
            target: signingInImage
            running: signingInImage.visible
        }

        Text {
            width: parent.width
            visible: !portal.isOnline
            font {
                pointSize: 20
                bold: true
                family: app.fontFamily
            }
            color: "red"
            text: qsTr("Please connect to a network to get started")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn && portal.user.orgId) {
                startPage.signedIn();
            }
        }
    }
}
