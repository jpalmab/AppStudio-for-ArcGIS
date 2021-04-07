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

import ArcGIS.AppFramework 1.0

import "../Controls"

TextBox {
    id: textField

    //--------------------------------------------------------------------------

    locale: app.localeProperties.locale
    textInput {
        horizontalAlignment: app.localeProperties.inputAlignment
    }

    font {
        family: app.fontFamily
        pointSize: 15
    }

    //--------------------------------------------------------------------------
}

/*
import QtQuick.Controls 2.5

import "../Controls"
import "../Controls/Workarounds.js" as Workarounds


TextField {
    id: textField

    //--------------------------------------------------------------------------

    property alias textColor: textField.color
    property var locale: app.locale ? app.locale : Qt.locale()
    property int textDirection: locale.textDirection

    property real horizontalPadding: 10 * AppFramework.displayScaleFactor

    property Item clickedItem: null

    //--------------------------------------------------------------------------

    signal cleared(string oldValue)

    //--------------------------------------------------------------------------

    selectByMouse: true

    font {
        family: app.fontFamily
        pointSize: 15
    }

    padding: 6 * AppFramework.displayScaleFactor
    rightPadding: textDirection == Qt.RightToLeft ? horizontalPadding : clearButton.visible ? clearButton.width : horizontalPadding
    leftPadding: textDirection == Qt.LeftToRight ? horizontalPadding : clearButton.visible ? clearButton.width : horizontalPadding

    renderType: Text.QtRendering

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Workarounds.checkInputMethodHints(textField, textField.locale);

        textDirectionChanged();
    }

    //--------------------------------------------------------------------------

    onTextDirectionChanged: {
        if (textDirection == Qt.RightToLeft) {
            clearButton.anchors.left = textField.left;
            clearButton.anchors.right = undefined;
        } else {
            clearButton.anchors.left = undefined;
            clearButton.anchors.right = textField.right;
        }
    }

    //--------------------------------------------------------------------------

    onPressed: {
        if (clearButton.visible && clearButton.contains(mapToItem(clearButton, event.x, event.y))) {
            clickedItem = clearButton;
        } else {
            clickedItem = null;
        }

        if (event.button === Qt.RightButton) {
            contextMenu.restoreFocus = activeFocus;
            contextMenu.popup();
        }
    }

    onReleased: {
        if (!clickedItem) {
            return;
        }

        if (clickedItem.contains(mapToItem(clickedItem, event.x, event.y))) {
            clickedItem.clicked(event);
        }

        clickedItem = null;
    }

    //--------------------------------------------------------------------------

    Item {
        id: clearButton

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        width: height
        visible: textField.length > 0 && !textField.readOnly

        function clicked() {
            var oldValue = text;

            textField.clear();

            cleared(oldValue);
            editingFinished();
        }

        Loader {
            id: clearButtonLoader

            anchors {
                fill: parent
                margins: textField.padding
            }

            sourceComponent: StyledImage {
                source: "images/clear.png"
                color: textField.placeholderTextColor
            }

            /*
            sourceComponent: StyledImageButton {
                source: "images/clear.png"
                color: textField.placeholderTextColor

                mouseArea.preventStealing: true

                onClicked: {
                    var oldValue = text;

                    textField.clear();

                    cleared(oldValue);
                    editingFinished();
                }
            }
            *//*
        }
    }

    //--------------------------------------------------------------------------

    TextInputContextMenu {
        id: contextMenu

        textInput: textField
        locale: textField.locale
    }

    //--------------------------------------------------------------------------
}
*/
