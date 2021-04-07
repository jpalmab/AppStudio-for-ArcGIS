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

RowLayout {
    id: view

    //--------------------------------------------------------------------------

    property Portal portal
    property var palette
    property bool expandedUserInfo: false
    property bool expandedPortalInfo: false
    property LocaleProperties localeProperties: app.localeProperties
    property alias isOnline: userIcon.isOnline

    readonly property var portalInfo: portal.info || {}
    readonly property var userInfo: portal.user || {}
    readonly property var orgInfo: portal.orgInfo || {}
    property var contactInfo: ({})

    property int defaultLineCount: 2
    property int maximumLineCount: 10

    //--------------------------------------------------------------------------

    layoutDirection: localeProperties.layoutDirection

    spacing: 10 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    onPortalInfoChanged: {
        var info = {};

        if (portalInfo) {
            try {
                info = portalInfo.portalProperties.links.contactUs;
            } catch (e) {
            }
        }

        if ((info.url || "").startsWith("mailto:") >= 0) {
            info.icon = "envelope";
            info.name = info.url.substr(7)
        } else {
            info.icon = "web";
            info.name = qsTr("Contact");
        }

        contactInfo = info;
    }

    onContactInfoChanged: {
        console.log("contactInfo:", JSON.stringify(contactInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(view, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        Layout.alignment: Qt.AlignTop

        spacing: 6 * AppFramework.displayScaleFactor

        PortalUserIcon {
            id: userIcon

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 60 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            portal: view.portal
            onlineIndicator {
                visible: false
            }

            palette {
                window: view.palette.window
                windowText: view.palette.windowText
            }

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    console.log(logCategory, "portal:", JSON.stringify(portal.info, undefined, 2));
                }
            }
        }

        StyledImage {
            Layout.alignment: Qt.AlignHCenter

            Layout.preferredWidth: 25 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            source: Icons.icon(isOnline ? "online" : "offline")
            color: palette.windowText

            MouseArea {
                anchors.fill: parent

                enabled: isOnline

                onPressAndHold: {
                    portal.renew();
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true

        spacing: 6 * AppFramework.displayScaleFactor

        AppText {
            Layout.fillWidth: true

            text: userInfo.fullName || ""
            color: palette.windowText
            font {
                pointSize: 16
                bold: true
            }
            horizontalAlignment: localeProperties.textAlignment

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    expandedUserInfo = !expandedUserInfo;
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: userDescriptionText.height

            visible: expandedUserInfo && userDescriptionText.text > ""

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    userDescriptionText.maximumLineCount = userDescriptionText.maximumLineCount === defaultLineCount ? maximumLineCount : defaultLineCount;
                }
            }

            AppText {
                id: userDescriptionText

                width: parent.width

                text: userInfo.description || ""
                color: palette.windowText
                maximumLineCount: defaultLineCount
                horizontalAlignment: localeProperties.textAlignment
                elide: localeProperties.textElide
                font {
                    pointSize: 13
                }
            }
        }

        IconText {
            Layout.fillWidth: true

            icon: Icons.icon("user")
            text: "<a href=\"%2\">%1</a>"
            .arg(userInfo.username || "")
            .arg("%1/home/user.html?user=%2".arg(portal.portalUrl).arg(userInfo.username))

            palette: view.palette
        }

        IconText {
            Layout.fillWidth: true

            visible: text > ""
            icon: Icons.icon("envelope")
            text: "<a href=\"%2\">%1</a>"
            .arg(userInfo.email || "")
            .arg("mailto:" + userInfo.email)
            palette: view.palette
        }

        HorizontalSeparator {
            Layout.fillWidth: true

            visible: expandedPortalInfo
        }

        IconText {
            Layout.fillWidth: true

            icon: Icons.icon(portal.isPortal ? "portal" : "arcgis-online")
            text: orgInfo.name || portal.name
            palette: view.palette

            onClicked: {
                expandedPortalInfo = !expandedPortalInfo;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            visible: expandedPortalInfo

            ColumnLayout {
                Layout.fillWidth: true

                visible: expandedPortalInfo
                spacing: 6 * AppFramework.displayScaleFactor

                IconText {
                    Layout.fillWidth: true

                    property string url: (portalInfo.urlKey > "" && portalInfo.customBaseUrl > "")
                                         ? AppFramework.urlInfo(portal.portalUrl).scheme + "://" + portalInfo.urlKey + "." + portalInfo.customBaseUrl
                                         : portal.portalUrl

                    icon: Icons.icon("web")
                    text: '<a href="%1">%2</a>'.arg(url).arg(AppFramework.urlInfo(url).host)
                    palette: view.palette
                }

                IconText {
                    Layout.fillWidth: true

                    visible: !!contactInfo.visible
                    icon: Icons.icon(contactInfo.icon)
                    text: qsTr("<a href=\"%2\">%1</a>")
                    .arg(contactInfo.name)
                    .arg(contactInfo.url)
                    palette: view.palette
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: portalDescriptionText.height

                    visible: portalDescriptionText.text > ""

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            portalDescriptionText.maximumLineCount = portalDescriptionText.maximumLineCount === defaultLineCount ? maximumLineCount : defaultLineCount;
                        }
                    }

                    AppText {
                        id: portalDescriptionText

                        width: parent.width

                        text: orgInfo.description || ""
                        color: palette.windowText
                        maximumLineCount: defaultLineCount
                        horizontalAlignment: localeProperties.textAlignment
                        elide: localeProperties.textElide
                        font {
                            pointSize: 13
                        }

                        onLinkActivated: {
                            Qt.openUrlExternally(link);
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

}
