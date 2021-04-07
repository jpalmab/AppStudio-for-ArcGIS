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

import "../Controls"

CheckBox {
    id: control

    //--------------------------------------------------------------------------

    LayoutMirroring.enabled: xform.localeInfo.isRightToLeft

    //--------------------------------------------------------------------------

    property color textColor: xform.style.selectTextColor
    property color indicatorColor: xform.style.selectIndicatorColor
    property real indicatorSize: xform.style.selectIndicatorSize
    property real implicitIndicatorSize: xform.style.selectImplicitIndicatorSize

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

    onClicked: {
        xform.style.selectFeedback();
    }

    //--------------------------------------------------------------------------

    indicator: Rectangle {
        implicitWidth: implicitIndicatorSize
        implicitHeight: implicitIndicatorSize

        x: text
           ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
           : control.leftPadding + (control.availableWidth - width) / 2

        y: control.topPadding + (control.availableHeight - height) / 2

        color: control.down ? control.palette.light : control.palette.base
        border {
            width: control.visualFocus ? xform.style.selectActiveBorderWidth : xform.style.selectBorderWidth
            color: control.visualFocus ? xform.style.selectActiveBorderColor : xform.style.selectBorderColor
        }

        StyledImage {
            anchors {
                fill: parent
                margins: 2 * AppFramework.displayScaleFactor
            }

            color: indicatorColor
            source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/check.png"
            visible: control.checkState === Qt.Checked
        }

        Rectangle {
            anchors.centerIn: parent

            width: 16
            height: 3
            color: control.palette.text
            visible: control.checkState === Qt.PartiallyChecked
        }
    }

    //--------------------------------------------------------------------------

    contentItem: Text {
        text: control.text
        font: control.font
        //opacity: enabled ? 1.0 : 0.5
        color: xform.style.selectTextColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: xform.localeInfo.textAlignment
        elide: xform.localeInfo.textElide
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0

        onLinkActivated: {
            xform.openLink(link);
        }
    }

    //--------------------------------------------------------------------------
}
