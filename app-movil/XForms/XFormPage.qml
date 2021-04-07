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

import "../Controls/Singletons"

Rectangle {
    id: page

    property alias title: titleText.text

    default property alias content: content.data

    // set these to provide access to location settings
    property var settingsTabContainer
    property var settingsTabLocation

    //--------------------------------------------------------------------------

    signal titleClicked()
    signal titlePressAndHold()

    //-------------------------------------------------------------------------

    color: xform.style.backgroundColor

    //--------------------------------------------------------------------------

    Rectangle {
        id: header

        anchors {
            fill: headerLayout
            margins: -headerLayout.anchors.margins
        }

        color: xform.style.titleBackgroundColor
    }

    ColumnLayout {
        id: headerLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: 0

        ColumnLayout {
            id: columnLayout

            Layout.fillWidth: true
            Layout.margins: 2 * AppFramework.displayScaleFactor

            RowLayout {
                Layout.fillWidth: true

                XFormImageButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: xform.style.titleButtonSize
                    Layout.preferredHeight: Layout.preferredWidth

                    source: ControlsSingleton.backIcon
                    padding: ControlsSingleton.backIconPadding

                    color: xform.style.titleTextColor

                    onClicked: {
                        xform.popoverStackView.pop();
                    }
                }

                XFormText {
                    id: titleText

                    Layout.fillWidth: true

                    font {
                        pointSize: xform.style.titlePointSize
                        family: xform.style.titleFontFamily
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: xform.style.titleTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    fontSizeMode: Text.HorizontalFit
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

                Item {
                    visible: !configItem.visible

                    Layout.fillHeight: true
                    Layout.preferredWidth: xform.style.titleButtonSize
                    Layout.preferredHeight: Layout.preferredWidth
                }

                Item {
                    id: configItem

                    Layout.fillHeight: true
                    Layout.preferredHeight: xform.style.titleButtonSize
                    Layout.preferredWidth: xform.style.titleButtonSize

                    visible: !(!settingsTabContainer || !settingsTabLocation) // this looks weird, but is correct

                    XFormImageButton {
                        id: configButton

                        anchors.fill: parent

                        source: Icons.icon("gear")
                        padding: 8 * AppFramework.displayScaleFactor

                        onClicked: {
                            forceActiveFocus();
                            Qt.inputMethod.hide();

                            xform.popoverStackView.push({
                                                            item: settingsTabContainer,
                                                            replace: true,
                                                            properties: {
                                                                settingsTab: settingsTabLocation,
                                                                title: settingsTabLocation.title,
                                                                settingsComponent: settingsTabLocation.contentComponent,
                                                            }
                                                        });
                        }
                    }

                    ColorOverlay {
                        visible: configButton.visible
                        anchors.fill: parent
                        source: configButton
                        color: xform.style.titleTextColor
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: headerLayout.bottom
            bottom: parent.bottom //footerLayout.top
        }
    }

    //--------------------------------------------------------------------------
    /*
    Rectangle {
        id: footer

        anchors {
            fill: footerRow
            margins: -footerRow.anchors.margins
        }

        color: xform.style.titleBackgroundColor
    }

    RowLayout {
        id: footerRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        width: parent.width - anchors.margins
    }
*/
    //--------------------------------------------------------------------------
}
