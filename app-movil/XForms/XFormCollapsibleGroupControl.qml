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

import ArcGIS.AppFramework 1.0

import "../Controls"
import "XForm.js" as XFormJS

XFormGroupBox {
    id: control

    //--------------------------------------------------------------------------

    property bool isPage: false
    property var formElement
    property XFormData formData
    property XFormBinding binding

    readonly property bool relevant: parent.relevant && (binding ? binding.isRelevant : true)
    readonly property bool relevantIsDynamic: parent.relevantIsDynamic || (binding ? binding.relevantIsDynamic : false)
    readonly property bool editable: parent.editable

    property alias headerItems: headerLayout
    property alias contentItems: itemsLayout

    property bool hidden: false

    property var labelControl
    property var hintControl

    readonly property bool collapsed: labelControl && typeof labelControl.collapsed === "boolean" ? labelControl.collapsed : false
    readonly property string labelText: labelControl ? labelControl.labelText : ""

    property alias controlColumns: itemsLayout.columns
    property int span: 1
    property real controlSpacing: 5 * AppFramework.displayScaleFactor

    property var errorInfo
    readonly property bool hasError: errorInfo !== null && errorInfo !== undefined

    property bool debug: false

    //--------------------------------------------------------------------------

    property color controlBorderColor: kDefaultBorderColor
    property real controlBorderWidth: kDefaultBorderWidth

    //--------------------------------------------------------------------------

    readonly property string kPropertyBackgroundColor: "backgroundColor"
    readonly property string kPropertyBorderColor: "borderColor"
    readonly property string kPropertyBorderWidth: "borderWidth"

    //--------------------------------------------------------------------------

    readonly property color kDefaultBackgroundColor: isPage ? "transparent" : xform.style.groupBackgroundColor
    readonly property color kDefaultBorderColor: xform.style.groupBorderColor
    readonly property real kDefaultBorderWidth: xform.style.groupBorderWidth

    //--------------------------------------------------------------------------

    flat: isPage
    visible: relevant && !hidden
    //title: text

    border {
        color: hasError ? xform.style.errorBorderColor : controlBorderColor
        width: hasError ? xform.style.errorBorderWidth : controlBorderWidth
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    function resetStyle(element) {
        controlStyle.element = element;
        controlStyle.initialize(true);
    }


    //--------------------------------------------------------------------------

    function setError(error) {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        errorInfo = error;
    }

    //--------------------------------------------------------------------------

    function clearError() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        errorInfo = null;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    Column {
        id: column

        anchors {
            left: parent.left
            right: parent.right
        }

        spacing: 5 * AppFramework.displayScaleFactor

        ColumnLayout {
            id: headerLayout

            anchors {
                left: parent.left
                right: parent.right
            }

            spacing: parent.spacing
        }

        XFormControlsLayout {
            id: itemsLayout

            readonly property alias relevant: control.relevant
            readonly property alias relevantIsDynamic: control.relevantIsDynamic
            readonly property alias editable: control.editable

            anchors {
                left: parent.left
                right: parent.right
            }

            columnSpacing: controlSpacing
            rowSpacing: controlSpacing
            visible: !collapsed
            enabled: binding ? !binding.isReadOnly : true
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

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

    function collapse(collapsed) {
        if (typeof collapsed !== "boolean") {
            collapsed = true;
        }

        if (labelControl) {
            labelControl.collapsed = collapsed;
        }
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        element: formElement
        attribute: kAttributeStyle

        debug: control.debug

        Component.onCompleted: {
            initialize();
        }

        function initialize(reset) {
            if (debug) {
                console.log(logCategory, JSON.stringify(element));
            }

            if (reset) {
                parseParameters();
            }

            bind(control, undefined, kPropertyBackgroundColor, kDefaultBackgroundColor);
            bind(control, "controlBorderColor", kPropertyBorderColor, kDefaultBorderColor);
            bind(control, "controlBorderWidth", kPropertyBorderWidth, kDefaultBorderWidth);
        }
    }

    //--------------------------------------------------------------------------
}
