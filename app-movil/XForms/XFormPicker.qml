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

import ArcGIS.AppFramework 1.0

Item {
    id: control

    //--------------------------------------------------------------------------

    property alias contentItem: popup.contentItem
    property alias popup: popup
    property alias closePolicy: popup.closePolicy
    property Component overlay
    property int animationDuration: 100
    property color backgroundColor: xform.style.inputBackgroundColor

    property bool debug

    //--------------------------------------------------------------------------

    visible: false

    //--------------------------------------------------------------------------

    onVisibleChanged: {
        if (visible) {
            popup.open();
        } else {
            popup.close();
        }
    }

    //--------------------------------------------------------------------------

    Popup {
        id: popup

        modal: true
        dim: debug
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        x: Math.round((parent.width - width) / 2)
        width: control.width
        height: control.height
        padding: 8 * AppFramework.displayScaleFactor

        Component.onCompleted: {
            if (overlay) {
                Overlay.modal = overlay;
            }
        }

        onClosed: {
            if (control.visible) {
                control.visible = false;
            }
        }

        background: Rectangle {
            radius: xform.style.inputBackgroundRadius

            color: backgroundColor

            border {
                color: xform.style.inputActiveBorderColor
                width: xform.style.inputActiveBorderWidth
            }
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: animationDuration
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: animationDuration
            }
        }
    }

    //--------------------------------------------------------------------------
}
