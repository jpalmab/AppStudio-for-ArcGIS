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
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "../Portal"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property Item contentItem

    property alias title: titleText.text
    property alias backButton: backButton
    property alias actionButton: actionButton
    property Component actionComponent
    property int layoutDirection: Qt.LeftToRight

    property var backPage

    property color textColor: app.textColor
    property color headerBarColor: app.titleBarBackgroundColor
    property color backgroundColor: app.backgroundColor
    property color accentColor: "#88c448"

    property real titlePointSize: 22

    property real headerBarHeight: 45 * AppFramework.displayScaleFactor
    property real contentMargins: 5 * AppFramework.displayScaleFactor
    property real buttonSize: 40 * AppFramework.displayScaleFactor

    property alias positionSourceManager: locationSensorButton.positionSourceManager

    // set these to provide access to location settings (we can't reference these components from here directly)
    property var settingsTabContainer
    property var settingsTabLocation

    //--------------------------------------------------------------------------

    signal titleClicked()
    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    color: backgroundColor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (contentItem) {
            contentItem.parent = page;
            contentItem.anchors.left = page.left;
            contentItem.anchors.right = page.right;
            contentItem.anchors.top = headerBar.bottom;
            contentItem.anchors.bottom = page.bottom;
            contentItem.anchors.margins = contentMargins;
        }
    }

    //--------------------------------------------------------------------------

    DropShadow {
        id: headerShadow

        anchors.fill: source

        visible: false

        verticalOffset: 3 * AppFramework.displayScaleFactor
        radius: 4 * AppFramework.displayScaleFactor
        samples: 9
        color: "#30000000"
        source: headerBar
        z: headerBar.z -  1
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: headerBar

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: headerBarHeight
        color: headerBarColor

        RowLayout {
            anchors {
                fill: parent
            }

            layoutDirection: page.layoutDirection
            spacing: 0

            Item {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize
                Layout.alignment: Qt.AlignVCenter

                StyledImageButton {
                    id: backButton

                    anchors {
                        fill: parent
                    }

                    source: ControlsSingleton.backIcon
                    padding: ControlsSingleton.backIconPadding
                    color: app.titleBarTextColor

                    onClicked: {
                        closePage();
                    }
                }
            }

            Item {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: locationSensorButton.visible && (actionButton.visible || actionButtonLoader.visible)
            }

            AppText {
                id: titleText

                Layout.fillWidth: true
                Layout.fillHeight: true

                font {
                    pointSize: titlePointSize
                }

                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: app.titleBarTextColor
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        titleClicked();
                    }

                    onPressAndHold: {
                        titlePressAndHold();
                    }
                }
            }

            XFormLocationSensorButton {
                id: locationSensorButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize
                Layout.alignment: Qt.AlignVCenter

                positionSourceManager: app.positionSourceManager

                settingsTabContainer: page.settingsTabContainer
                settingsTabLocation: page.settingsTabLocation
            }

            Item {
                Layout.preferredWidth: (actionButton.visible || actionButtonLoader.visible) ? buttonSize : 0
                Layout.preferredHeight: buttonSize
                Layout.alignment: Qt.AlignVCenter

                MenuButton {
                    id: actionButton

                    anchors {
                        fill: parent
                    }

                    color: app.titleBarTextColor
                }

                Loader {
                    id: actionButtonLoader

                    visible: !!actionComponent
                    active: visible

                    anchors {
                        fill: parent
                    }

                    sourceComponent: actionComponent
                }
            }
        }
    }

    XFormMenuPanel {
        id: menuPanel

        menu: actionButton.menu
        backgroundColor: app.titleBarBackgroundColor
        textColor: app.titleBarTextColor
        fontFamily: app.fontFamily
    }

    //--------------------------------------------------------------------------

    function closePage() {
        console.log("backPage", backPage);
        if (backPage) {
            page.parent.pop(backPage);
        } else {
            page.parent.pop();
        }
    }

    //--------------------------------------------------------------------------
}
