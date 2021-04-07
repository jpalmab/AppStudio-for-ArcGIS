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
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: delegate

    //--------------------------------------------------------------------------

    property GalleryView galleryView: delegate.GridView.view.parent

    property alias mouseArea: mouseArea
    property alias background: background
    property alias thumbnailSource: thumbnailImage.url
    property alias titleText: titleText
    property alias rowLayout: rowLayout

    property color textColor: "#4c4c4c"
    property color backgroundColor: "white"
    property color hoverColor: "#f8f8f8"
    property color borderColor: "#e5e5e5"
    property color shadowColor: "#12000000"

    property alias font: titleText.font

    property bool updateAvailable: false
    property bool debug: false

    //--------------------------------------------------------------------------

    signal clicked()
    signal doubleClicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    width: galleryView.cellWidth
    height: galleryView.cellHeight

    //--------------------------------------------------------------------------

    onClicked: {
        forceActiveFocus();
    }

    onPressAndHold: {
        forceActiveFocus();
    }

    //--------------------------------------------------------------------------

    DropShadow {
        anchors.fill: background
        horizontalOffset: 3 * AppFramework.displayScaleFactor
        verticalOffset: horizontalOffset

        radius: 5 * AppFramework.displayScaleFactor
        samples: 9
        color: shadowColor
        source: background
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: background

        //        anchors {
        //            fill: parent
        //            margins: 5 * AppFramework.displayScaleFactor
        //        }

        Component.onCompleted: {
            if (galleryView.dynamicSpacing) {
                background.anchors.centerIn = parent;
                background.width = galleryView.cellSize;
                background.height = background.width;
            } else {
                background.anchors.fill = parent;
                background.anchors.margins = 5 * AppFramework.displayScaleFactor;
            }
        }
        
        color: mouseArea.containsMouse
               ? hoverColor
               : backgroundColor

        border {
            width: 1 * AppFramework.displayScaleFactor
            color: borderColor
        }
        radius: 2 * AppFramework.displayScaleFactor

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            hoverEnabled: true
            //cursorShape: Qt.PointingHandCursor

            onClicked: {
                delegate.clicked();
            }

            onDoubleClicked: {
                delegate.doubleClicked();
            }

            onPressAndHold: {
                delegate.pressAndHold();
            }
        }

        Item {
            id: thumbnailItem

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: background.border.width
            }

            height: width * 133/200

            ThumbnailImage {
                id: thumbnailImage

                anchors.fill: parent

                url: thumbnail
                mouseArea: mouseArea
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.bottom
                }

                color: background.border.color
                height: background.border.width
            }
        }

        //--------------------------------------------------------------------------

        RowLayout {
            id: rowLayout

            property real margin: 3 * AppFramework.displayScaleFactor

            layoutDirection: localeProperties.layoutDirection

            anchors {
                left: parent.left
                right: parent.right
                top: thumbnailItem.bottom
                bottom: parent.bottom
                margins: rowLayout.margin
            }

            Text {
                id: titleText

                Layout.fillWidth: true
                Layout.fillHeight: true

                text: title
                font {
                    family: app.fontFamily
                    pixelSize: rowLayout.height / 2 * 0.72
                    bold: app.appSettings.boldText
                    italic: debug && updateAvailable
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: textColor
            }
        }
    }

    //--------------------------------------------------------------------------
}
