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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: footer

    //--------------------------------------------------------------------------

    property XForm xform

    property real buttonSize: 40 * AppFramework.displayScaleFactor
    property real padding: 2 * AppFramework.displayScaleFactor
    property real pageButtonPadding: 4 * AppFramework.displayScaleFactor
    property alias spacing: layout.spacing

    //--------------------------------------------------------------------------

    signal clicked()
    signal okClicked()
    signal okPressAndHold()
    signal printClicked()

    //--------------------------------------------------------------------------

    height: layout.height + padding * 2 + 1 * AppFramework.displayScaleFactor

    color: xform.style.titleBackgroundColor

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent

        onClicked: {
            footer.clicked();
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            margins: footer.padding
            verticalCenter: parent.verticalCenter
        }

        layoutDirection: xform.layoutDirection

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            enabled: xform.pageNavigator.canGotoPrevious
            opacity: enabled ? 1 : 0

            source: Icons.icon("chevron-left")
            mirror: xform.isRightToLeft
            padding: pageButtonPadding
            mouseArea.anchors.margins: -footer.padding

            color: xform.style.titleTextColor

            onClicked: {
                forceActiveFocus()
                xform.pageNavigator.gotoPreviousPage();
            }

            onPressAndHold: {
                forceActiveFocus()
                xform.pageNavigator.gotoFirstPage();
            }
        }

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: xform.canPrint

            source: "images/send.png"
            mouseArea.anchors.margins: -footer.padding

            color: xform.style.titleTextColor

            onClicked: {
                forceActiveFocus()
                printClicked()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            XFormText {
                anchors.centerIn: parent

                visible: xform.pageNavigator.canGoto
                text: qsTr("%1 of %2").arg(xform.pageNavigator.currentIndex + 1).arg(xform.pageNavigator.count)
                font {
                    pointSize: 14
                }
                color: xform.style.titleTextColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors {
                        fill: parent
                        margins: -footer.padding
                    }

                    onClicked: {
                        xform.showPagesPopup();
                    }
                }
            }
        }

        StyledImageButton {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: xform.pageNavigator.canGotoNext

            source: Icons.icon("chevron-right")
            mirror: xform.isRightToLeft
            padding: pageButtonPadding
            mouseArea.anchors.margins: -footer.padding

            color: xform.style.titleTextColor

            onClicked: {
                forceActiveFocus()
                xform.pageNavigator.gotoNextPage();
            }

            onPressAndHold: {
                forceActiveFocus()
                xform.pageNavigator.gotoLastPage();
            }
        }

        StyledImage {
            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: Layout.preferredHeight / 4

            visible: okButton.visible && xform.formData.editMode > xform.formData.kEditModeAdd

            source: "images/editMode.png"
            color: xform.style.titleTextColor
        }

        StyledImageButton {
            id: okButton

            Layout.preferredHeight: buttonSize
            Layout.preferredWidth: buttonSize

            visible: xform.pageNavigator.atLastPage

            source: Icons.icon("check", app.appSettings.boldText)
            mouseArea.anchors.margins: -footer.padding

            color: xform.style.titleTextColor

            onClicked: {
                forceActiveFocus()
                okClicked();
            }

            onPressAndHold: {
                forceActiveFocus()
                okPressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------
}

