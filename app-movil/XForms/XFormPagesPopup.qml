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
import QtQuick 2.5
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls"

XFormPopup {
    id: popup

    //--------------------------------------------------------------------------

    property XFormPageNavigator pageNavigator
    property var relevantPages: []

    //--------------------------------------------------------------------------

    signal pageSelected(var page, bool close)

    //--------------------------------------------------------------------------

    contentWidth: 250 * AppFramework.displayScaleFactor
    contentHeight: layout.height

    //--------------------------------------------------------------------------

    onAboutToShow: {
        pageField.text = pageNavigator.currentIndex + 1;
        pageField.forceActiveFocus();

        var pages = [];

        pageNavigator.pages.forEach(function (page) {
            if (page.relevant) {
                pages.push(page);
            }
        });

        relevantPages = pages;
    }

    //--------------------------------------------------------------------------

    onPageSelected: {
        pageNavigator.gotoPage(page);

        if (close) {
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: availableWidth
        spacing: 5 * AppFramework.displayScaleFactor

        XFormText {
            Layout.fillWidth: true

            text: qsTr("Go to page")

            color: popup.style.popupTextColor
            font {
                family: popup.font.family
                pointSize: popup.style.popupTitlePointSize
                bold: true
            }

            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Rectangle {
            Layout.fillWidth: true

            height: style.popupSeparatorWidth
            color: style.popupSeparatorColor
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.maximumHeight: popup.parent.height * 0.6

            clip: true

            ListView {
                id: listView

                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                width: availableWidth
                spacing: layout.spacing

                model: relevantPages
                delegate: pageDelegate
            }
        }

        Rectangle {
            Layout.fillWidth: true

            height: style.popupSeparatorWidth
            color: style.popupSeparatorColor
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            layoutDirection: xform.layoutDirection

            XFormTextField {
                id: pageField

                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor

                property real pageNo: Number(text) - 1
                property int relevantIndex: relevantPages.indexOf(pageNavigator.pages[pageNo])

                placeholderText: qsTr("Page")

                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntegerValidator {
                    bottom: 1
                    top: xform.pageNavigator.count
                }

                onEditingFinished: {
                    Qt.inputMethod.hide();
                    if (length && pageNo && acceptableInput) {
                        pageNavigator.gotoPage();
                        popup.close();
                    }
                }
            }

            XFormText {
                text: qsTr("of %1").arg(pageNavigator.count)
                color: popup.style.popupTextColor
                font: pageField.font
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: pageDelegate

        Rectangle {
            readonly property XFormCollapsibleGroupControl page: listView.model[index]
            readonly property int pageNo: pageNavigator.pages.indexOf(page) + 1

            width: listView.width
            height: layout.height + 2 * layout.anchors.margins

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    pageSelected(page, true);
                }

                onPressAndHold: {
                    pageSelected(page, false);
                }
            }

            color: mouseArea.pressed
                   ? style.popupPressedColor
                   : mouseArea.containsMouse
                     ? style.popupHoverColor
                     : popup.backgroundRectangle.color

            border {
                width: 2 * AppFramework.displayScaleFactor
                color: pageField.textInput.activeFocus && pageField.acceptableInput && pageField.relevantIndex === index
                       ? popup.style.inputActiveBorderColor
                       : "transparent"
            }

            radius: 3 * AppFramework.displayScaleFactor

            RowLayout {
                id: layout

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: 8 * AppFramework.displayScaleFactor
                    verticalCenter: parent.verticalCenter
                }

                layoutDirection: xform.layoutDirection

                XFormText {
                    Layout.fillWidth: true

                    text: page.labelControl ? XFormJS.stripHtml(page.labelControl.labelText) : qsTr("Page %1").arg(pageNo)

                    color: popup.style.popupTextColor
                    font {
                        family: popup.font.family
                        pointSize: 16 * popup.style.textScaleFactor
                    }

                    maximumLineCount: 1
                    horizontalAlignment: xform.localeInfo.textAlignment
                    elide: xform.localeInfo.textElide
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
