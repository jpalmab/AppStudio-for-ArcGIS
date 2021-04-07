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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"

AppPage {
    id: page

    title: qsTr("About %1").arg(itemInfo.title)

    //--------------------------------------------------------------------------

    property bool debug: false
    property AddIn addIn
    property var addInInfo: addIn.addInInfo
    property var itemInfo: addIn.itemInfo

    property bool showExtra: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        showExtra = !showExtra;
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Image {
            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            asynchronous: true
            source: addIn.thumbnail
            fillMode: Image.PreserveAspectCrop
            opacity: 0.1
            cache: false
        }

        ScrollView {
            id: scrollView

            anchors {
                fill: parent
            }

            padding: 10 * AppFramework.displayScaleFactor
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Flickable {
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ColumnLayout {
                    width: scrollView.availableWidth
                    spacing: 5 * AppFramework.displayScaleFactor

                    Image {
                        Layout.fillWidth: true
                        height: 133 * AppFramework.displayScaleFactor

                        asynchronous: true
                        source: addIn.thumbnail
                        cache: false
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.paintedWidth
                            height: parent.paintedHeight

                            color: "transparent"
                            border {
                                width: 1
                                color: "#40000000"
                            }
                        }
                    }

                    AboutText {
                        text: itemInfo.snippet || ""

                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pointSize: 15
                        }
                    }

                    AboutText {
                        text: qsTr("Version %1").arg(addIn.version)
                        font {
                            pointSize: 14
                        }
                        horizontalAlignment: Text.AlignHCenter
                    }

                    AboutText {
                        property string owner: itemInfo.owner || ""

                        visible: owner > ""
                        text: qsTr("Owned by %1").arg(owner)

                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pointSize: 12
                        }
                    }

                    AboutText {
                        Layout.fillWidth: true

                        property date modified: new Date(itemInfo.modified)

                        visible: isFinite(modified.valueOf())
                        text: qsTr("Modified: %1 %2").arg(modified.toLocaleDateString(page.locale)).arg(modified.toLocaleTimeString(page.locale))
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pointSize: 12
                        }
                    }

                    HorizontalSeparator {
                        Layout.fillWidth: true
                    }

                    AboutText {
                        text: itemInfo.description || ""
                        horizontalAlignment: Text.AlignHCenter
                    }

                    HorizontalSeparator {
                        Layout.fillWidth: true

                        visible: licenseInfoText.visible
                    }

                    AboutText {
                        text: qsTr("License Agreement")
                        font {
                            pointSize: 15
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                        visible: licenseInfoText.visible
                    }

                    AboutText {
                        id: licenseInfoText

                        text: itemInfo.licenseInfo || ""
                        visible: text > ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        visible: showExtra

                        spacing: 5 * AppFramework.displayScaleFactor

                        HorizontalSeparator {
                            Layout.fillWidth: true
                        }

                        AboutText {
                            visible: addIn.itemInfo.id > ""
                            text: 'Item id: <a href="%2">%1</a>'.arg(addIn.itemInfo.id).arg(addIn.itemUrl)
                        }

                        AboutText {
                            text: "Name: <b>%1</b>".arg(addIn.name)
                        }

                        AboutText {
                            text: 'Installed in: <a href="%2">%1</a>'.arg(addIn.folder.path).arg(addIn.folder.url)
                        }

                        AboutText {
                            text: 'Data folder: <a href="%2">%1</a>'.arg(addIn.dataFolder.path).arg(addIn.dataFolder.url)
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
