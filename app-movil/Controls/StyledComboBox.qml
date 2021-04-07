/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

ComboBox {
    id: control

    opacity: enabled ? 1 : .6
    property int dropdownHeight: -1
    property color backgroundColor: "#F7F8F8"
    property color borderColor: "#cbcbcb"
    property color highlightColor: "#fff"
    property color indicatorColor: app.titleBarBackgroundColor
    property color foregroundColor: "#4c4c4c"
    property bool rtl: false
    property string fontFamily: app.fontFamily

    //--------------------------------------------------------------------------

    Accessible.role: Accessible.ComboBox

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        canvas.requestPaint();
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: control.width
        background: Rectangle {
            color: highlighted ? highlightColor : backgroundColor
        }

        contentItem: Text {
            text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData

            color: foregroundColor
            font {
                family: control.fontFamily
                pointSize: 13 * app.textScaleFactor
            }
            elide: Text.ElideRight
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: !rtl ? Text.AlignLeft : Text.AlignRight
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: Canvas {
        id: canvas
        x: !rtl ? control.width - width - control.rightPadding : 0 + control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12 * AppFramework.displayScaleFactor
        height: 8 * AppFramework.displayScaleFactor
        contextType: "2d"

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width / 2, height);
            ctx.closePath();
            ctx.fillStyle = indicatorColor
            ctx.fill();
        }
    }

    contentItem: Text {
        leftPadding: !rtl ? 8 * AppFramework.displayScaleFactor : control.indicator.width + control.spacing
        rightPadding: !rtl ? control.indicator.width + control.spacing : 8 * AppFramework.displayScaleFactor
        text: control.displayText
        font.family: control.fontFamily
        font.pointSize: 13 * app.textScaleFactor
        color: foregroundColor
        horizontalAlignment: !rtl ? Text.AlignLeft : Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 120 * AppFramework.displayScaleFactor
        implicitHeight: 40 * AppFramework.displayScaleFactor
        border.color: borderColor
        border.width: control.visualFocus ? 2 : 1
        color: backgroundColor
        radius: 2 * AppFramework.displayScaleFactor
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: dropdownHeight > -1 ? dropdownHeight : contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            border.color: borderColor
            color: backgroundColor
            radius: 0
        }
    }

    //--------------------------------------------------------------------------
}
