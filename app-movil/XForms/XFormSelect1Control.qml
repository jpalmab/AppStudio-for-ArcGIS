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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtMultimedia 5.9

import ArcGIS.AppFramework 1.0

import "XFormSingletons"
import "XForm.js" as XFormJS
import "../Controls"

RowLayout {
    id: select1Control

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var groupLabel
    readonly property string imageMapSource: mediaValue(groupLabel, "image", language)

    property alias selectField: selectFieldLoader.item
    property alias radioGroup: radioGroup
    property alias value: radioGroup.value
    property alias valueLabel: radioGroup.text
    property alias valueValid: radioGroup.valid

    property bool required: binding.isRequired
    readonly property bool isReadOnly: !editable || binding.isReadOnly
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property bool showCalculate: !isReadOnly && changeReason === 1 && calculatedValue !== undefined && calculatedValue != value

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable
    //property alias columns: dropdownPanel.columns

    property var items
    property XFormItemset itemset
    property string appearance

    readonly property bool minimal: Appearance.contains(appearance, Appearance.kMinimal)
    readonly property real padding: 4 * AppFramework.displayScaleFactor
    readonly property bool isImageMap: Appearance.contains(appearance, Appearance.kImageMap)
    readonly property bool showControls: !isImageMap
    property bool showImageMapLabel: debug

    property bool debug: false

    property bool ensureVisibleOnHeightChange

    property int buttonDisplay: Appearance.contains(appearance, Appearance.kListNoLabel)
                                ? AbstractButton.IconOnly
                                : Appearance.contains(appearance, Appearance.kLabel)
                                  ? AbstractButton.TextOnly
                                  : AbstractButton.TextBesideIcon

    property bool tableList: false

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    visible: parent.visible
    //spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(select1Control, true)
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        //console.log(logCategory, "onValueChanged:", changeReason)
        changeReason = 1;
        formData.setValue(bindElement, value);

        if (minimal && selectField) {
            selectField.dropdownVisible = false;
        }
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            if (debug) {
                console.log(logCategory, "onCalculatedValueChanged:", JSON.stringify(binding.nodeset), "value:", JSON.stringify(calculatedValue));
            }

            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    onHeightChanged: {
        if (ensureVisibleOnHeightChange && selectField && selectField.dropdownVisible) {
            ensureVisibleOnHeightChange = false;
            ensureVisible();
        }
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        function _ensureVisible() {
            xform.ensureItemVisible(select1Control);
        }

        Qt.callLater(_ensureVisible);
    }

    //--------------------------------------------------------------------------

    XFormRadioGroup {
        id: radioGroup

        required: select1Control.required
    }

    //--------------------------------------------------------------------------

    XFormItemsModel {
        items: select1Control.items
        itemset: select1Control.itemset

        debug: select1Control.debug

        onFilterChanged: {
            if (debug) {
                console.log(logCategory, "onFilterChanged for:", JSON.stringify(bindElement), "value:", value);
            }

            select1Control.items = itemset.filteredItems;

            if (!formData.isInitializing(binding)) {
                setValue(undefined);
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredWidth: select1Control.width * 0.333

        active: tableList
        visible: active

        sourceComponent: XFormTableItemLabel {
            formData: select1Control.formData
            label: groupLabel
            required: select1Control.binding
                      ? select1Control.binding.isRequiredBinding()
                      : false
        }
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.fillWidth: true

        spacing: 0

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: imageMapComponent
            active: isImageMap
        }

        Loader {
            id: selectFieldLoader

            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: selectFieldComponent
            active: minimal && showControls
        }

        Loader {
            id: selectViewLoader

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: select1Control.padding * 3
            }

            sourceComponent: selectViewComponent
            active: selectField && minimal && showControls
            enabled: !isReadOnly
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: selectPanelComponent
            active: !minimal && showControls
            enabled: !isReadOnly
        }
    }

    /*
    ColumnLayout {
        Layout.fillWidth: true

        spacing: 0

        Loader {
            Layout.fillWidth: true

            sourceComponent: imageMapComponent
            active: isImageMap
        }

        Loader {
            id: selectFieldLoader

            Layout.fillWidth: true

            sourceComponent: selectFieldComponent
            active: minimal && showControls
        }

        Loader {
            id: selectViewLoader

            Layout.fillWidth: true
            Layout.leftMargin: select1Control.padding * 3

            sourceComponent: selectViewComponent
            active: selectField && minimal && showControls
            enabled: !isReadOnly
        }

        Loader {
            Layout.fillWidth: true

            sourceComponent: selectPanelComponent
            active: !minimal && showControls
            enabled: !isReadOnly
        }
    }
*/

    //--------------------------------------------------------------------------

    XFormRecalculateButton {
        Layout.alignment: Qt.AlignTop

        visible: showCalculate

        onClicked: {
            changeReason = 0;
            formData.triggerCalculate(bindElement);
            valueModified(select1Control);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectFieldComponent

        XFormSelectField {
            visible: minimal
            text: valueLabel
            valid: valueValid
            count: items ? items.length > 0 : 0
            changeReason: select1Control.changeReason
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectViewComponent

        XFormSelectListView {
            model: items
            radioGroup: select1Control.radioGroup

            visible: selectField.dropdownVisible
            padding: select1Control.padding
            color: selectField.color
            radius: selectField.radius
            border {
                width: selectField.border.width
                color: selectField.border.color
            }

            onVisibleChanged: {
                if (visible) {
                    ensureVisibleOnHeightChange = true;
                }
            }

            onClicked: {
                valueModified(select1Control);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectPanelComponent

        XFormSelectPanel {
            id: selectPanel

            property var selectItems: select1Control.items

            Loader {
                id: likertBarLoader

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    leftMargin: (parent.width / columns) /2
                    rightMargin: (parent.width / columns) /2
                }

                z: parent.z - 1

                sourceComponent: likertBarComponent
                active: Appearance.contains(appearance, Appearance.kLikert)
                visible: active
            }

            Component {
                id: likertBarComponent

                Rectangle {
                    height: 3 * AppFramework.displayScaleFactor
                    color: "#80020202"
                    radius: height / 2
                    y: xform.style.selectImplicitIndicatorSize / 2 - radius
                }
            }

            onSelectItemsChanged: {
                addControls();
            }

            function addControls() {
                controls = null;

                if (!Array.isArray(items)) {
                    return;
                }

                if (tableList || Appearance.contains(appearance, Appearance.kLikert)) {
                    columns = Math.max(selectItems.length, 1);
                } else if (Appearance.contains(appearance, Appearance.kMinimal) || !(appearance > "")) {
                    columns = 1;
                }

                for (var i = 0; i < selectItems.length; i++) {
                    var item = selectItems[i];

                    radioControl.createObject(controlsGrid,
                                              {
                                                  width: controlsGrid.columnWidth,
                                                  bindElement: select1Control.bindElement,
                                                  radioGroup: select1Control.radioGroup,
                                                  label: item.label,
                                                  value: item.value,
                                                  appearance: select1Control.appearance
                                              });
                }
            }
        }
    }

    Component {
        id: radioControl

        XFormRadioControl {
            radioButton {
                display: buttonDisplay
            }

            textColor: (checked && changeReason === 3)
                       ? xform.style.selectAltTextColor
                       : xform.style.selectTextColor

            onClicked: {
                valueModified(select1Control);
            }

            radioButton {
                onVisualFocusChanged: {
                    if (radioButton.visualFocus && !minimal) {
                        xform.ensureItemVisible(radioButton);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageMapComponent

        ColumnLayout {
            XFormText {
                Layout.fillWidth: true

                visible: showImageMapLabel
                text: valueLabel
                horizontalAlignment: Text.AlignHCenter
                color: xform.style.labelColor
                font {
                    pointSize: xform.style.valuePointSize
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            ImageMap {
                id: imageMap

                Layout.fillWidth: true
                Layout.preferredHeight: xform.height / 2

                source: imageMapSource
                multipleSelection: false

                Component.onCompleted: {
                    imageMap.select(value);
                }

                onSelectedIdChanged: {
                    setValue(selectedId, 1);
                }

                onClicked: {
                    valueModified(select1Control);
                }

                Connections {
                    target: select1Control

                    onValueChanged: {
                        imageMap.select(value);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "nodeset:", binding.nodeset, "value:", JSON.stringify(value), "null?", XFormJS.isNullOrUndefined(value), "reason:", reason);
        }

        var _changeReason = changeReason;
        var _value = radioGroup.value;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "_value:", JSON.stringify(_value), "null?", XFormJS.isNullOrUndefined(_value), "eq?", value == _value, "_changeReason:", _changeReason);
        }

        radioGroup.value = value;

        if (XFormJS.isNullOrUndefined(value)) {
            radioGroup.label = undefined;
            radioGroup.valid = true;
        } else {
            var matched = false;

            for (var i = 0; items && i < items.length; i++) {
                var item = items[i];
                if (item.value == value) {
                    radioGroup.label = textValue(item.label);
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                radioGroup.label = value;
            }

            radioGroup.valid = matched;
        }

        if (reason) {
            if (reason === 1 && _changeReason === 3 && value == _value) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "setValue == calculated:", JSON.stringify(value));
                }
                changeReason = 3;
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }
    }

    //--------------------------------------------------------------------------

    function lookupLabel(value) {
        var label = "";

        if (XFormJS.isEmpty(value)) {
            return label;
        }

        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (item.value == value) {
                label = item.label;
                break;
            }
        }

        return textValue(label);
    }

    //--------------------------------------------------------------------------
}

