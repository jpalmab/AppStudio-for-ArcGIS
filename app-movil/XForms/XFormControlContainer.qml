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

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "../Controls"

XFormGroupBox {
    id: container

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property bool relevant: parent.relevant && (binding ? binding.isRelevant : true)
    readonly property bool relevantIsDynamic: parent.relevantIsDynamic || (binding ? binding.relevantIsDynamic : false)
    readonly property bool editable: parent.editable

    property alias contentItems: itemsColumn

    property var labelControl
    property var hintControl

    property var errorInfo
    readonly property bool hasError: errorInfo !== null && errorInfo !== undefined
    property int span: -1

    property bool isGridTheme: xform.isGridTheme

    property bool debug: false

    //--------------------------------------------------------------------------

    visible: relevant

    padding: 8 * AppFramework.displayScaleFactor
    leftPadding: isGridTheme ? 12 * AppFramework.displayScaleFactor : 0
    rightPadding: leftPadding
    backgroundColor: "transparent"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (isGridTheme) {
            span = xform.parseWidth(formElement["@appearance"], 1)

            if (debug) {
                console.log("span:", span, "parent:", parent, parent["columns"], "ref:", formElement["@ref"]);
            }
        }
    }

    /*
    Text {
        parent: background

        text: "span: %1 columnSpan: %2 fillWidth: %3 preferredWidth: %4"
        .arg(span)
        .arg(container.Layout.columnSpan)
        .arg(container.Layout.fillWidth)
        .arg(container.Layout.preferredWidth)
    }
    */

    //--------------------------------------------------------------------------

    function setError(error) {
        errorInfo = error;
    }

    //--------------------------------------------------------------------------

    function clearError() {
        errorInfo = null;
    }

    //--------------------------------------------------------------------------

    Loader {
        parent: background

        anchors {
            fill: parent
            leftMargin: isGridTheme ? 0 : -container.padding
            rightMargin: isGridTheme ? 0 : -container.padding
        }

        active: hasError
        visible: active

        sourceComponent: Rectangle {
            color: "transparent"
            radius: container.radius

            border {
                color: xform.style.errorBorderColor
                width: xform.style.errorBorderWidth
            }
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: itemsColumn

        readonly property alias relevant: container.relevant
        readonly property alias relevantisDynamic: container.relevantIsDynamic
        readonly property alias editable: container.editable

        anchors {
            left: parent.left
            right: parent.right
            top: isGridTheme ? parent.top : undefined
            bottom: isGridTheme ? parent.bottom : undefined
        }

        spacing: 5 * AppFramework.displayScaleFactor

        Loader {
            Layout.fillWidth: true

            active: hasError
            visible: active

            sourceComponent: XFormErrorMessage {
                text: errorInfo.message
                style: xform.style
                locale: xform.locale

                Component.onCompleted: {
                    xform.style.errorFeedback();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
