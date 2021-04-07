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

import "../Controls"
import "../Controls/Singletons"

ColumnLayoutPopup {
    id: popup

    //--------------------------------------------------------------------------

    property alias message: messageText.text

    //--------------------------------------------------------------------------

    closePolicy: Popup.NoAutoClose
    width: Math.min(parent.width * 0.8, 350 * AppFramework.displayScaleFactor)

    titleSeparator.visible: false
    titleItem.font.pointSize: 18
    layout.spacing: 10 * AppFramework.displayScaleFactor

    palette {
        window: "#eee"
        button: "white"
        light: "#f0fff0"
    }

    padding: 1 * AppFramework.displayScaleFactor
    topPadding: 10 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var objects = layout.resources;

        for (var i = 0; i < objects.length; i++) {
            if (AppFramework.instanceOf(objects[i], "QQuickAction")) {
                actionGroup.addAction(objects[i]);
            }
        }
    }

    //--------------------------------------------------------------------------

    ActionGroup {
        id: actionGroup
    }

    //--------------------------------------------------------------------------

    AppText {
        id: messageText

        Layout.fillWidth: true
        Layout.leftMargin: 10 * AppFramework.displayScaleFactor
        Layout.rightMargin: Layout.leftMargin

        visible: text > ""
        horizontalAlignment: Text.AlignHCenter

        font {
            pointSize: 15
        }

        HorizontalSeparator {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: -parent.Layout.leftMargin
                rightMargin: -parent.Layout.rightMargin
                top: parent.bottom
                topMargin: layout.spacing
            }

            opacity: 0.5
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2 * AppFramework.displayScaleFactor

        spacing: 1 * AppFramework.displayScaleFactor

        Repeater {
            id: actionsRepeater

            model: actionGroup.actions

            delegate: ActionsPopupButton {
                Layout.fillWidth: true

                action: actionsRepeater.model[index]

                palette {
                    button: palette.button
                    light: palette.light
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
