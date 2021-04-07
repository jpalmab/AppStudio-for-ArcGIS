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

import ArcGIS.AppFramework 1.0

RadioButton {
    id: control

    //--------------------------------------------------------------------------

    LayoutMirroring.enabled: xform.localeInfo.isRightToLeft

    //--------------------------------------------------------------------------

    property int orientation: Qt.Horizontal
    property color textColor: xform.style.selectTextColor
    property real indicatorSize: xform.style.selectIndicatorSize
    property real implicitIndicatorSize: xform.style.selectImplicitIndicatorSize

    readonly property bool isHorizontal: orientation == Qt.Horizontal

    //--------------------------------------------------------------------------

    locale: xform.localeInfo.locale

    focusPolicy: Qt.StrongFocus

    font {
        pointSize: xform.style.selectPointSize
        bold: xform.style.selectBold
        family: xform.style.selectFontFamily
    }

    padding: 0
    spacing: 6 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    indicator: indicatorLoader.item

    Loader {
        id: indicatorLoader

        active: display != RadioButton.TextOnly // Use TextOnly for indicator visibility

        sourceComponent: Rectangle {
            implicitWidth: implicitIndicatorSize
            implicitHeight: implicitIndicatorSize

            x: (!isHorizontal || display == RadioButton.IconOnly)
               ? control.leftPadding + (control.availableWidth - width) / 2
               : (text
                  ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                  : control.leftPadding + (control.availableWidth - width) / 2)

            y: isHorizontal
               ? control.topPadding + (control.availableHeight - height) / 2
               : control.topPadding

            radius: width / 2
            color: control.down ? control.palette.light : control.palette.base
            border {
                width: control.visualFocus ? xform.style.selectActiveBorderWidth : xform.style.selectBorderWidth
                color: control.visualFocus ? xform.style.selectActiveBorderColor : xform.style.selectBorderColor
            }

            Rectangle {
                anchors.centerIn: parent

                width: indicatorSize
                height: indicatorSize
                radius: width / 2
                color: control.textColor
                visible: control.checked
            }
        }
    }

    //--------------------------------------------------------------------------

    contentItem: contentLoader.item

    Loader {
        id: contentLoader

        active: display != RadioButton.IconOnly  // Use IconOnly for content visibility

        sourceComponent: Text {
            text: control.text
            font: control.font
            //opacity: enabled ? 1.0 : 0.5
            color: control.textColor

            verticalAlignment: isHorizontal ? Text.AlignVCenter : Text.AlignTop
            horizontalAlignment: (!isHorizontal || display === RadioButton.TextOnly)
                                 ? Text.AlignHCenter
                                 : xform.localeInfo.textAlignment

            elide: xform.localeInfo.textElide
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            leftPadding: isHorizontal && control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
            rightPadding: isHorizontal && control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
            topPadding: !isHorizontal && control.indicator ? control.indicator.height + control.spacing : 0

            onLinkActivated: {
                xform.openLink(link);
            }
        }
    }

    //--------------------------------------------------------------------------

    background: MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            toggle();
            control.clicked();
        }
    }

    //--------------------------------------------------------------------------
}
