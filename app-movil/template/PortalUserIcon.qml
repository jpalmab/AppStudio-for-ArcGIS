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
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

Control {
    id: control

    //--------------------------------------------------------------------------

    property Portal portal

    property url defaultThumbnail: portal.defaultUserThumbnail
    readonly property bool isDefaultUserThumbnail: portal.isDefaultUserThumbnail
    readonly property url userThumbnail: isDefaultUserThumbnail
                                         ? defaultThumbnail
                                         : portal.userThumbnailUrl


    property alias radius: mask.radius

    readonly property bool isOnline: portal.isOnline
    property real offlineOpacity: 0.4

    property alias onlineIndicator: onlineIndicator

    property string userInitials: !!portal.user && portal.user.firstName > "" && portal.user.lastName > ""
                                  ? portal.user.firstName.substr(0, 1) + portal.user.lastName.substr(0, 1)
                                  : ""

    //--------------------------------------------------------------------------

    implicitWidth: 40 * AppFramework.displayScaleFactor
    implicitHeight: 40 * AppFramework.displayScaleFactor

    palette {
        window: app.titleBarBackgroundColor
        windowText: app.titleBarTextColor

        base: "transparent"
        alternateBase: "#eee"
        text: "#9a9a9a"
        highlight: "#93c259"
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        radius: mask.radius > 0 ? height / 2 : 0
        color: palette.windowText
        opacity: (!isDefaultUserThumbnail && image.status === Image.Ready) ? 0 : 0.2
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        //----------------------------------------------------------------------

        Item {
            id: loadingImage

            anchors {
                fill: parent
                margins: 3 * AppFramework.displayScaleFactor
            }

            Text {
                id: loadingText

                anchors {
                    fill: parent
                }

                visible: text > "" && (image.status === Image.Loading || image.status === Image.Error)
                text: userInitials
                color: image.status === Image.Error ? "red" : palette.windowText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                fontSizeMode: Text.Fit
                font {
                    pixelSize: parent.height
                    family: app.fontFamily
                }
            }

            StyledImage {
                anchors {
                    fill: parent
                }

                visible: !loadingText.visible && (image.status === Image.Loading || image.status === Image.Error)

                color: image.status === Image.Error ? "red" : palette.windowText
                source: defaultThumbnail
            }
        }

        PulseAnimation {
            target: loadingImage
            running: image.status === Image.Loading
            duration: 2000
            from: 0.5
        }

        //----------------------------------------------------------------------

        Text {
            id: initialsText

            anchors {
                fill: parent
                margins: height * 0.15
            }

            visible: isDefaultUserThumbnail && text > ""
            text: userInitials
            color: palette.windowText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            fontSizeMode: Text.Fit
            font {
                pixelSize: parent.height
                family: app.fontFamily
            }
        }

        //----------------------------------------------------------------------

        Image {
            id: image

            anchors {
                fill: parent
                margins: isDefaultUserThumbnail
                         ? 4 * AppFramework.displayScaleFactor
                         : 0
            }

            fillMode: Image.PreserveAspectFit
            visible: !overlay.visible && !desaturate.visible && !initialsText.visible
            asynchronous: true

            source: userThumbnail
            sourceSize {
                width: image.width
                height: image.height
            }

            layer {
                enabled: radius > 0 && visible
                effect: OpacityMask {
                    maskSource: mask
                }
            }
        }

        //----------------------------------------------------------------------

        ColorOverlay {
            id: overlay

            anchors {
                fill: parent
                margins: image.anchors.margins
            }

            source: image
            color: isDefaultUserThumbnail ? palette.windowText : "transparent"
            visible: color !== "transparent" && !initialsText.visible
            opacity: isOnline ? 1 : offlineOpacity

            layer {
                enabled: radius > 0 && visible
                effect: OpacityMask {
                    maskSource: mask
                }
            }
        }

        //----------------------------------------------------------------------

        Desaturate {
            id: desaturate

            anchors.fill: parent

            visible: !isOnline && !isDefaultUserThumbnail

            source: image
            desaturation: 1

            layer {
                enabled: radius > 0 && visible
                effect: OpacityMask {
                    maskSource: mask
                }
            }
        }

        //----------------------------------------------------------------------

        Rectangle {
            id: mask

            anchors {
                fill: parent
            }

            radius: height / 2
            visible: false
        }

        //----------------------------------------------------------------------

        OnlineIndicator {
            id: onlineIndicator

            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            isOnline: control.isOnline
            offlineColor: palette.alternateBase
            border {
                color: palette.window
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------
}
