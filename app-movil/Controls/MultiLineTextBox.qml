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

import "./Singletons"
import "Workarounds.js" as Workarounds

TextArea {
    id: control

    //--------------------------------------------------------------------------

    property var locale: Qt.locale()
    property int maximumLength: 10000
    property string previousText: text

    //--------------------------------------------------------------------------

    property alias textColor: control.color

    property alias backgroundColor: backgroundRectangle.color
    property color borderColor: "#bdbdbd"
    property real borderWidth: 1 * AppFramework.displayScaleFactor
    property color activeBorderColor: control.palette.highlight
    property real activeBorderWidth: 1 * AppFramework.displayScaleFactor
    property alias radius: backgroundRectangle.radius

    property Popup contextPopup: contextMenu
    readonly property bool contextPopupVisible: contextMenu && contextMenu.visible

    property int layoutDirection: locale ? locale.textDirection : Qt.LeftToRight
    readonly property bool rtl: layoutDirection === Qt.RightToLeft
    property bool showClearButton: true

    //--------------------------------------------------------------------------

    signal cleared(string previousText)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Workarounds.checkInputMethodHints(control, locale);
    }

    //--------------------------------------------------------------------------

    EnterKey.type: Qt.EnterKeyReturn

    //--------------------------------------------------------------------------

    font {
        pointSize: 15
    }

    padding: ControlsSingleton.inputTextPadding
    leftPadding: (rtl && !readOnly && showClearButton) ? clearButton.width + padding * 2 : padding
    rightPadding: (!rtl && !readOnly && showClearButton) ? clearButton.width + padding * 2 : padding
    topPadding: padding
    bottomPadding: padding

    wrapMode: TextEdit.WrapAnywhere

    selectByMouse: true

    inputMethodHints: Qt.ImhMultiLine

    //--------------------------------------------------------------------------

    onReleased: {
        if (event.button === Qt.RightButton && contextPopup) {
            if (typeof contextPopup.restoreFocus == "boolean") {
                contextPopup.restoreFocus = control.activeFocus;
            }
            contextPopup.popup();
        }
    }

    //--------------------------------------------------------------------------

    onTextChanged: {
        if (text.length > maximumLength) {
            var cursor = cursorPosition;
            text = previousText;
            if (cursor > text.length) {
                cursorPosition = text.length;
            } else {
                cursorPosition = cursor - 1;
            }
        }
        previousText = text;
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: backgroundRectangle

        border {
            color: (control.activeFocus || contextPopupVisible) ? activeBorderColor : borderColor
            width: (control.activeFocus || contextPopupVisible) ? activeBorderWidth : borderWidth
        }

        radius: 2 * AppFramework.displayScaleFactor

        InputClearButton {
            id: clearButton

            anchors {
                top: parent.top
                left: rtl ? parent.left : undefined
                right: !rtl ? parent.right : undefined
                margins: control.padding
            }

            color: control.color
            visible: showClearButton && control.length > 0 && !control.readOnly

            onClicked: {
                var previousText = control.text;
                control.clear();
                cleared(previousText);
                control.forceActiveFocus();
                control.editingFinished();
            }
        }
    }

    //--------------------------------------------------------------------------

    TextBoxContextMenu {
        id: contextMenu

        inputControl: control
        locale: control.locale
    }

    //--------------------------------------------------------------------------
}
