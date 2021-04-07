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

import "XForm.js" as XFormJS


RowLayout {
    id: select1Control

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property alias radioGroup: radioGroup
    property alias value: radioGroup.value
    property alias valueLabel: radioGroup.text
    property bool fnedit: false

    property bool required: binding.isRequired
    readonly property bool isReadOnly: !editable || binding.isReadOnly
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property bool showCalculate: !isReadOnly && changeReason === 1 && calculatedValue !== undefined && calculatedValue != value

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property var items
    property var originalitems: []
    property XFormItemset itemset
    property string appearance

    readonly property bool anyMatchFilter: true
    readonly property real padding: 4 * AppFramework.displayScaleFactor
    property bool autoSelect: false

    property bool debug: false

    property bool ensureVisibleOnHeightChange

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection
    visible: parent.visible
    //spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "All Items:", JSON.stringify(items, undefined, 2));
            //console.log(logCategory, "Itemset: " + JSON.stringify(select1Control.itemset));
        }

        if (bindElement["@constraint"]) {
            constraint = formData.createConstraint(this, bindElement);
        }
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        if (debug) {
            console.log(logCategory, "onValueChanged:", value);
        }

        fnedit = true;
        changeReason = 1;
        formData.setValue(bindElement, value);

        selectField.dropdownVisible = false;

        if (value !== "") {
            var matched = false;
            for (var i=0; i<items.length; i++) {
                if (items[i].value === value) {
                    selectField.text = XFormJS.stripHtml(xform.textLookup(items[i].label));
                    radioGroup.valid = true;
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                radioGroup.valid = false;
                selectField.text = (value || "");
            }
        } else {
            selectField.text = "";
        }
        fnedit = false;
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
            fnedit = true;
            if (debug) {
                console.log(logCategory, "onCalculatedValueChanged:", JSON.stringify(binding.nodeset), "value:", JSON.stringify(calculatedValue));
            }

            setValue(calculatedValue, 3);
            fnedit = false;
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

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(select1Control, true)
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

        onFilterChanged: {
            if (debug) {
                console.log(logCategory, "Filterset changed for:", JSON.stringify(bindElement));
            }

            select1Control.items = itemset.filteredItems;

            if (!formData.isInitializing(binding)) {
                setValue(undefined);
            }

            originalitems = select1Control.itemset.filteredItems;
            items = refilter("");
            fnedit = false;

            if (debug) {
                console.log(logCategory, "FILTERCHANGED " + JSON.stringify(originalitems));
            }
        }
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.fillWidth: true

        XFormSelectFieldAuto {
            id: selectField

            anchors {
                left: parent.left
                right: parent.right
            }

            enabled: !isReadOnly
            text: valueLabel
            count: items ? items.length > 0 : 0
            originalCount: originalitems ? originalitems.length > 0 : 0
            altTextColor: changeReason === 3

            valid: textInput.activeFocus
                   ? radioGroup.valid
                   : radioGroup.valid
                        ? (textField.length > 0 && !XFormJS.isEmpty(value)) || (!required && textField.length === 0 && XFormJS.isEmpty(value))
                        : radioGroup.valid

            Component.onCompleted: {
                var imh = Qt.ImhNone;

                if (Qt.platform.os === "android") {
                    imh |= Qt.ImhNoPredictiveText;
                }
                if (appearance.indexOf("nopredictivetext") >= 0) {
                    imh |= Qt.ImhNoPredictiveText;
                } else if (appearance.indexOf("predictivetext") >= 0) {
                    imh &= ~Qt.ImhNoPredictiveText;
                }

                textField.inputMethodHints = imh;
            }

            onCountChanged: {
                if (debug) {
                    console.log(logCategory, "count:", count, JSON.stringify(bindElement), JSON.stringify(items, undefined, 2));
                }
            }

            onCleared: {
                setValue(undefined, 1);
                valueModified(select1Control);
            }

            onTextChanged: {
                if (debug) {
                    console.log(logCategory, "textChanged:", text);
                }

                if (!fnedit) {
                    dropdownVisible = true;
                } else {
                    fnedit = false;
                }

                if (text.length < 1) {
                    dropdownVisible = false;
                }

                items = refilter(text);

                if (text.length === 0) {
                    setValue(undefined, 1);
                }

                // auto-select when 1 choice is left and text is exact match to the label

                if (autoSelect && items.length === 1 && !fnedit && isLabelText(items[0].label, text)) {
                    radioGroup.valid = true;
                    radioGroup.value = items[0].value;
                    selectField.text = xform.textLookup(items[0].label);
                }
            }

            onKeyPressed: {
                if (!isReadOnly) {
                    changeReason = 1;
                    radioGroup.valid = true;
                    valueModified(select1Control);
                }
            }
        }

        Loader {
            id: selectViewLoader

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: select1Control.padding * 3
            }

            sourceComponent: selectViewComponent
            enabled: !isReadOnly
        }
    }

    XFormRecalculateButton {
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: selectField.height
        Layout.preferredHeight: Layout.preferredWidth

        visible: showCalculate

        onClicked: {
            changeReason = 0;
            formData.triggerCalculate(bindElement);
            valueModified(select1Control);
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

    function setValue(value, reason) {
        if (debug) {
            console.log(logCategory, 'setValue:', JSON.stringify(value));
        }

        var _changeReason = changeReason;
        var _value = select1Control.value;

        items = originalitems;
        if (select1Control.itemset) {
            if (select1Control.itemset.filteredItems.length > 0) {
                items = select1Control.itemset.filteredItems;
            }
        }

        radioGroup.value = value;

        if (XFormJS.isEmpty(value)) {
            radioGroup.value = "";
            radioGroup.label = undefined;
            radioGroup.valid = true;
            selectField.text = "";

            //reset for repeats & item clears
            if (select1Control.constraint && select1Control.itemset) {
                items = select1Control.itemset.filteredItems;
            } else {
                items = select1Control.items;
            }
        } else {
            radioGroup.valid = false;
            items = refilter(value, true);

//            if (items.length === 1) {
//                radioGroup.label = item.label;
//                selectField.text = item.label;
//                radioGroup.valid = false;
//            }
        }

        if (reason) {
            if (reason === 1 && _changeReason === 3 && value == _value) {
                if (debug) {
                    console.log(logCategory, "setValue == calculated:", JSON.stringify(value));
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

    function refilter(filterval, isvalue) {

        var refilteredList = [];

        //console.log(logCategory, "Original items: " + JSON.stringify(originalitems));

        var itemLabel ="";
        var labelText = "";
        var itemValue = "";

        var itemsToFilter = originalitems;
        if (select1Control.itemset) {
            if (select1Control.itemset.filteredItems.length > 0) {
//              console.log(logCategory, 'filtered list');
//              console.log(logCategory, select1Control.itemset.filteredItems.length);
                itemsToFilter = select1Control.itemset.filteredItems;
            }
        }
//        } else {
////            console.log(logCategory, 'not cascade');
////            console.log(logCategory, originalitems.length);
//            itemsToFilter = originalitems;
//        }

        if (typeof itemsToFilter !== 'undefined') {
            for (var i = 0; i < itemsToFilter.length; i++) {
                itemLabel = itemsToFilter[i]["label"];
                labelText = xform.textLookup(itemLabel);
//                console.log(logCategory, labelText);
                if (isvalue) {
                    itemValue = itemsToFilter[i]["value"];
                    if (itemValue == filterval) {
                        refilteredList.push(itemsToFilter[i]);
                        fnedit = true;
                        selectField.text = XFormJS.stripHtml(labelText);
                        radioGroup.valid = true;
                        fnedit = false;
                    }
                } else {
                    var matchIndex = XFormJS.stripHtml(labelText.toLowerCase()).indexOf(filterval.toLowerCase());
                    if (matchIndex == 0 || (anyMatchFilter && matchIndex > 0)) {
                        refilteredList.push(itemsToFilter[i]);
                    }
                }
            }
        }
//        console.log(logCategory, "Filtered items: " + JSON.stringify(refilteredList));

        return refilteredList;
    }

    //--------------------------------------------------------------------------

    function isLabelText(label, text) {
        var labelText = XFormJS.stripHtml(xform.textLookup(label)).toLowerCase();

        return text.toLowerCase() === labelText;
    }

    //--------------------------------------------------------------------------

    function lookupLabel(value) {
        var label = "";

        if (XFormJS.isEmpty(value)) {
            return label;
        }

        for (var i = 0; i < originalitems.length; i++) {
            var item = originalitems[i];
            if (item.value == value) {
                label = item.label;
                break;
            }
        }

        return textValue(label);
    }

    //--------------------------------------------------------------------------
}
