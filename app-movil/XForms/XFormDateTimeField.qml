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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"
import "XForm.js" as XFormJS

Control {
    id: control

    //--------------------------------------------------------------------------

    property var dateTime
    readonly property bool isValid: dateTime !== null && isFinite(dateTime.valueOf())
    property string appearance


    property bool readOnly: false
    property bool useAltTextColor: false
    property color textColor: readOnly ? style.inputReadOnlyTextColor : useAltTextColor ? style.inputAltTextColor : style.inputTextColor
    property color backgroundColor: readOnly ? style.inputReadOnlyBackgroundColor : style.inputBackgroundColor
    property color labelColor: AppFramework.alphaColor(textColor, isValid ? 1 : 0.3)

    property bool showDate: datePickerItem !== null
    property bool showTime: timePickerItem !== null
    property bool showClearButton: !readOnly

    property Item datePickerItem
    property Item timePickerItem

    readonly property bool datePickerVisible: datePickerItem && datePickerItem.visible
    readonly property bool timePickerVisible: timePickerItem && timePickerItem.visible
    readonly property bool pickerVisible: datePickerVisible || timePickerVisible
    property color pickerVisibleColor: style.inputActiveBorderColor

    property XFormStyle style

    property int layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    signal clicked()
    signal dateClicked()
    signal timeClicked()
    signal cleared();

    //--------------------------------------------------------------------------\

    focusPolicy: Qt.ClickFocus

    padding: 8 * AppFramework.displayScaleFactor
    spacing: padding

    font {
        family: style.inputFontFamily
        pointSize: style.inputPointSize
        bold: style.inputBold
    }

    background: Rectangle {
        color: backgroundColor

        radius: style.inputBackgroundRadius

        border {
            color: (activeFocus || pickerVisible) ? style.inputActiveBorderColor : style.inputBorderColor
            width: activeFocus ? style.inputActiveBorderWidth : style.inputBorderWidth
        }
    }

    //--------------------------------------------------------------------------

    contentItem: RowLayout {
        id: controlLayout

        spacing: control.spacing
        layoutDirection: control.layoutDirection

        GridLayout {
            id: buttonsLayout

            property bool multiRow: dateButton.visible && timeButton.visible && controlLayout.width < (350 * AppFramework.displayScaleFactor)
            columns: multiRow ? 1 : 3
            columnSpacing: control.spacing
            rowSpacing: control.spacing
            layoutDirection: control.layoutDirection


            Button {
                id: dateButton

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: showDate
                enabled: !readOnly
                focusPolicy: Qt.NoFocus

                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                icon {
                    source: Icons.icon("calendar", datePickerVisible)
                    color: datePickerVisible ? pickerVisibleColor : textColor
                }

                display: AbstractButton.TextBesideIcon
                background: null

                text: isValid ? XFormJS.formatDate(dateTime, appearance, locale) : qsTr("Date")

                contentItem: IconLabel {
                    id: iconLabel

                    spacing: control.spacing
                    layoutDirection: control.layoutDirection

                    icon: dateButton.icon
                    text: dateButton.text
                    font: control.font
                    color: labelColor
                    horizontalAlignment: xform.localeInfo.textAlignment
                }

                onClicked: {
                    control.forceActiveFocus();
                    control.clicked();
                    dateClicked();
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.topMargin: -control.padding + control.background.border.width
                Layout.bottomMargin: -control.padding + control.background.border.width

                visible: !buttonsLayout.multiRow && dateButton.visible && timeButton.visible

                width: 2 * AppFramework.displayScaleFactor
                color: style.inputBorderColor
            }

            Button {
                id: timeButton

                Layout.fillWidth: !dateButton.visible || buttonsLayout.multiRow
                Layout.preferredWidth: dateButton.visible ? 120 * AppFramework.displayScaleFactor : -1
                Layout.fillHeight: true

                visible: showTime
                enabled: !readOnly
                focusPolicy: Qt.NoFocus

                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0

                icon {
                    source: Icons.icon("clock", timePickerVisible)
                    color: timePickerVisible ? pickerVisibleColor : textColor
                }

                display: AbstractButton.TextBesideIcon
                background: null

                text: isValid ? XFormJS.formatTime(dateTime, appearance, locale) : qsTr("Time")

                contentItem: IconLabel {
                    spacing: control.spacing
                    layoutDirection: control.layoutDirection

                    icon: timeButton.icon
                    text: timeButton.text
                    font: control.font
                    color: labelColor
                    horizontalAlignment: xform.localeInfo.textAlignment
                }

                onClicked: {
                    control.forceActiveFocus();
                    control.clicked();
                    timeClicked();
                }
            }
        }


        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: -control.padding + control.background.border.width
            Layout.bottomMargin: -control.padding + control.background.border.width

            visible: clearButton.visible

            width: 2 * AppFramework.displayScaleFactor
            color: style.inputBorderColor
        }

        InputClearButton {
            id: clearButton

            implicitWidth: iconLabel.label.height
            implicitHeight: iconLabel.label.height

            visible: showClearButton && isValid && !readOnly
            enabled: !readOnly

            onClicked: {
                control.forceActiveFocus();
                control.clicked();
                cleared();
            }
        }
    }

    //--------------------------------------------------------------------------

    onClicked: {
        style.buttonFeedback();
    }

    //--------------------------------------------------------------------------
}
