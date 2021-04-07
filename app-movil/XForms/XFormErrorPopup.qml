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
import QtQuick.Controls 2.5

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls"
import "../Controls/Singletons"

XFormPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    property var errorInfo

    property bool debug

    property alias message: messageText.text

    //--------------------------------------------------------------------------

    onAboutToShow: {
        console.log(logCategory, "errorInfo:", JSON.stringify(errorInfo, undefined, 2));

        message = (errorInfo.isDefaultMessage && errorInfo.field)
                ? "%1: %2".arg(errorInfo.field.name).arg(errorInfo.message)
                : errorInfo.message;
    }

    //--------------------------------------------------------------------------

    onOpened: {
        popup.style.errorFeedback();
    }

    //--------------------------------------------------------------------------

    //    width: 200 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    backgroundRectangle {
        border {
            color: popup.style.requiredColor
            width: 2 * AppFramework.displayScaleFactor
        }
    }

    contentWidth: 250 * AppFramework.displayScaleFactor
    contentHeight: layout.height //250 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: availableWidth
        spacing: 5 * AppFramework.displayScaleFactor

        StyledImageButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            source: Icons.icon("exclamation-mark-circle", true)
            color: popup.style.requiredColor
            height: width

            onPressAndHold: {
                popup.width = Qt.binding(function() { return popup.parent.width * 0.75; });
                popup.height = Qt.binding(function() { return popup.parent.height * 0.75; });
                debug = true;
            }
        }

        Text {
            id: messageText

            Layout.fillWidth: true

            color: popup.style.popupTextColor
            font {
                family: popup.font.family
                bold: popup.style.boldText
                pointSize: 18 * popup.style.textScaleFactor
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true

            visible: text > ""
            text: errorInfo.detailedText || ""
            color: popup.style.popupTextColor
            font {
                family: popup.font.family
                bold: popup.style.boldText
                pointSize: 14 * popup.style.textScaleFactor
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }


        Rectangle {
            Layout.fillWidth: true

            visible: debugTextView.visible
            height: style.popupSeparatorWidth
            color: style.popupSeparatorColor
        }

        ScrollView {
            id: debugTextView

            Layout.fillWidth: true
            Layout.preferredHeight: debugText.height
            Layout.maximumHeight: 150 * AppFramework.displayScaleFactor

            visible: debug && debugText.text > ""
            clip: true

            Text {
                id: debugText

                text: errorInfo.debugText || ""
                color: popup.style.popupTextColor
                font {
                    family: popup.font.family
                    bold: popup.style.boldText
                    pointSize: 14 * popup.style.textScaleFactor
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
