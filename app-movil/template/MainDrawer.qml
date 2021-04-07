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

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../Controls"
import "../Controls/Singletons"

AppDrawer {
    id: popup

    //--------------------------------------------------------------------------

    property Portal portal
    property var actions
    
    //--------------------------------------------------------------------------

    signal debugToggle()

    //--------------------------------------------------------------------------

    palette {
        base: "#eee"
        alternateBase: "#eee"
        text: "black"

        window: "#fefefe"
        windowText: "black"

        mid: "#ddd"
    }

    //--------------------------------------------------------------------------

    onDebugToggle: {
        offlineSwitch.visible = !offlineSwitch.visible;
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

        implicitHeight: userLayout.height + userLayout.anchors.margins * 2
        
        visible: portal.signedIn

        color: portal.isOnline ? popup.palette.base : popup.palette.alternateBase

        ColumnLayout {
            id: userLayout
            
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
                margins: 10 * AppFramework.displayScaleFactor
            }

            PortalUserView {
                Layout.fillWidth: true
                
                portal: popup.portal
                palette: popup.palette
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10 * AppFramework.displayScaleFactor
                Layout.bottomMargin: 10 * AppFramework.displayScaleFactor
                
                layoutDirection: localeProperties.layoutDirection
                
                Item {
                    Layout.fillWidth: true
                }
                
                AppButton {
                    text: qsTr("Sign out")
                    textPointSize: 15
                    
                    iconSource: Icons.bigIcon("sign-out")
                    
                    onClicked: {
                        confirmSignOut();
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                }
            }
        }
        
        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

        implicitHeight: offlineLayout.height + offlineLayout.anchors.margins * 2
        color: portal.isOnline ? popup.palette.base : popup.palette.alternateBase

        visible: !portal.signedIn

        ColumnLayout {
            id: offlineLayout

            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            StyledImage {
                Layout.alignment: Qt.AlignHCenter

                source: Icons.bigIcon(portal.isOnline ? "online" : "offline")
                color: "black"
            }

            AppText {
                Layout.fillWidth: true

                text: portal.isOnline
                      ? qsTr("Your device is online")
                      : qsTr("Your device is offline")

                horizontalAlignment: Text.AlignHCenter
                font {
                    pointSize: 15
                }
            }

            AppButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10 * AppFramework.displayScaleFactor

                visible: portal.isOnline

                text: qsTr("Sign in")
                textPointSize: 15

                iconSource: Icons.bigIcon("sign-in")

                onClicked: {
                    portal.signIn();
                    popup.close();
                }
            }
        }

        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------

    ActionsView {
        id: scrollView

        Layout.fillHeight: true
        Layout.fillWidth: true

        actions: popup.actions

        onTriggered: {
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    HorizontalSeparator {
        Layout.fillWidth: true

        opacity: 0.5
    }

    Switch {
        id: offlineSwitch

        Layout.alignment: Qt.AlignHCenter

        visible: false

        checked: portal.isOnline

        onClicked: {
            portal.isOnline = !portal.isOnline;
        }
    }

    //--------------------------------------------------------------------------

    AppText {
        Layout.fillWidth: true
        Layout.topMargin: 5 * AppFramework.displayScaleFactor
        Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

        text: qsTr("Version %1").arg(app.info.version + app.features.buildTypeSuffix)
        color: palette.windowText
        font {
            pointSize: 10
        }
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent

            onPressAndHold: {
                debugToggle()
            }
        }
    }

    //--------------------------------------------------------------------------

    function confirmSignOut() {
        var confirmPopup = signoutPopupComponent.createObject(popup.parent);
        popup.close();
        confirmPopup.open();
    }

    Component {
        id: signoutPopupComponent

        ColumnLayoutPopup {
            id: signoutPopup

            layout {
                spacing: 15 * AppFramework.displayScaleFactor
            }

            width: 250 * AppFramework.displayScaleFactor

            StyledImage {
                Layout.alignment: Qt.AlignHCenter

                source: Icons.icon("sign-out")
            }

            AppText {
                Layout.fillWidth: true

                visible: !portal.isOnline

                text: qsTr("Your device is offline. You will not be able to sign in again until you are online.")
                horizontalAlignment: Text.AlignHCenter
                color: "#a80000"

                font {
                    pointSize: 14
                }
            }

            RowLayout {
                Layout.fillWidth: true

                layoutDirection: localeProperties.layoutDirection
                spacing: 5 * AppFramework.displayScaleFactor

                PortalUserIcon {
                    portal: popup.portal
                    onlineIndicator.visible: false

                    palette {
                        window: signoutPopup.palette.window
                        windowText: signoutPopup.palette.windowText
                    }
                }

                AppText {
                    Layout.fillWidth: true

                    property string name: portal.user.fullName || portal.username

                    text: qsTr("Are you sure you want to sign out as <b>%1</b>?").arg(name)
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        pointSize: 14
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                layoutDirection: localeProperties.layoutDirection

                spacing: 10 * AppFramework.displayScaleFactor

                StandardButton {
                    buttonRole: DialogButtonBox.YesRole

                    onClicked: {
                        portal.signOut();
                        close();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StandardButton {
                    buttonRole: DialogButtonBox.NoRole

                    onClicked: {
                        close();
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
