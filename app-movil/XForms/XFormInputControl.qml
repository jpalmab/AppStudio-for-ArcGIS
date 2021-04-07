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
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "XFormSingletons"
import "Calculator"

import "../Controls"
import "../Controls/Singletons"
import "../Controls/Workarounds.js" as Workarounds

RowLayout {
    id: inputLayout

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias textInput: textField.textInput
    property alias currentValue: textField.text
    readonly property bool showCalculate: !isReadOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedValue, currentValue)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    // readonly property XFormControlContainer controlGroup: XFormJS.findParent(this, undefined, xform.kObjectTypeControlContainer)
    property bool showInputValidatorError: true

    property alias emptyText: textField.emptyText
    property var appearance: (formElement ? formElement["@appearance"] : "") || ""
    property bool showCharacterCount: binding.type === binding.kTypeString || (isBarcode && !isMinimalBarcode)

    property string scannerAddInName
    readonly property bool isBarcode: binding.type === binding.kTypeBarcode && (scannerAddInName > "" || QtMultimedia.availableCameras.length > 0)

    property Component scannerPage: scannerAddInName > ""
                                           ? addInScannerPage
                                           : scanBarcodePage

    readonly property url scannerIcon: scannerAddInName > ""
                                     ? xform.addIns.icon(scannerAddInName)
                                     : Icons.icon("qr-code", true, isMinimalBarcode ? 32 : 16)


    readonly property bool isReadOnly: !editable || binding.isReadOnly
    readonly property bool showSpinners: Appearance.contains(appearance, Appearance.kSpinner) && !isReadOnly
    readonly property bool isMinimalBarcode: isBarcode && Appearance.contains(appearance, Appearance.kMinimal)
    property real spinnerScale: 2
    property real spinnerMargin: 15 * AppFramework.displayScaleFactor

    property int barcodeButtonSize: 40 * AppFramework.displayScaleFactor

    property Loader keypadLoader
    property string keypadIcon
    readonly property bool keypadVisible: !!keypadLoader && keypadLoader.showKeypad
    property Component keypadComponent
    property real keypadColumns
    property real keypadRows

    readonly property var numberLocale: xform.numberLocale
    readonly property bool showGroupSeparators: Appearance.contains(appearance, Appearance.kThousandsSep)

    property string valueType
    property var currentTypedValue

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kPropertyAddIn: "addIn"

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    layoutDirection: xform.layoutDirection

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!isReadOnly) {
            if (showInputValidatorError || showCharacterCount) {
                statusInfo.createObject(parent);
            }

            if (Appearance.contains(appearance, Appearance.kNumbers)) {
                keypadComponent = numbersKeypadComponent;
                keypadIcon = "keypad";
                keypadColumns = 4;
                keypadRows = 4;
            } else if (Appearance.contains(appearance, Appearance.kCalculator)) {
                keypadComponent = calculatorKeypadComponent;
                keypadIcon = "calculator";
                keypadColumns = 5;
                keypadRows = 5.5;
            }

            if (keypadComponent) {
                keypadLoader = keypadContainer.createObject(parent);
            }
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
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    onNumberLocaleChanged: {
        if (debug) {
            console.log("onNumberLocaleChanged:", numberLocale.name);
        }

        if (!XFormJS.isNullOrUndefined(currentTypedValue)) {
            currentValue = valueToText(currentTypedValue);
        }
    }

    //--------------------------------------------------------------------------

    onCurrentValueChanged: {
        var value = textToValue(currentValue, Number.NEGATIVE_INFINITY);
        if (value === Number.NEGATIVE_INFINITY) {
            currentTypedValue = undefined;
        } else {
            currentTypedValue = value;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(inputLayout, true)
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.rightMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        active: showSpinners
        visible: showSpinners

        onLoaded: {
            item.step = -1;
        }
    }

    //--------------------------------------------------------------------------

    Item {
        Layout.fillWidth: true
        visible: isMinimalBarcode
    }

    TextBox {
        id: textField

        Layout.fillWidth: !isMinimalBarcode

        readonly property bool hasError: !textInput.acceptableInput && textInput.text !== emptyText && (textInput.inputMask > "" || textInput.validator)

        enterKeyType: Qt.EnterKeyReturn

        readOnly: isReadOnly
        textInput {
            visible: !isMinimalBarcode
            horizontalAlignment: xform.localeInfo.inputAlignment
        }

        locale: xform.locale
        layoutDirection: xform.layoutDirection

        placeholderTextColor: xform.style.inputPlaceholderTextColor

        font {
            bold: xform.style.inputBold
            pointSize: xform.style.inputPointSize
            family: xform.style.inputFontFamily
        }

        textColor: acceptableInput
                   ? (changeReason === 3)
                     ? xform.style.inputAltTextColor
                     : (readOnly ? xform.style.inputReadOnlyTextColor : xform.style.inputTextColor)
        : xform.style.inputErrorTextColor

        activeBorderColor: xform.style.inputActiveBorderColor
        activeBorderWidth: xform.style.inputActiveBorderWidth
        borderColor: xform.style.inputBorderColor
        borderWidth: xform.style.inputBorderWidth
        radius: xform.style.inputBackgroundRadius
        backgroundColor: readOnly
                         ? xform.style.inputReadOnlyBackgroundColor
                         : xform.style.inputBackgroundColor

        inputRequired: binding.isRequired

        Component.onCompleted: {
            var fieldLength = 255;

            var imh = inputMethodHints;
            valueType = typeof "";

            switch (binding.type) {
            case binding.kTypeString:
                if (appearance.indexOf("nopredictivetext") >= 0) {
                    imh |= Qt.ImhNoPredictiveText;
                } else if (appearance.indexOf("predictivetext") >= 0) {
                    imh &= ~Qt.ImhNoPredictiveText;
                }
                break;

            case binding.kTypeInt:
                if (Qt.platform.os === "ios") {
                    imh = Qt.ImhPreferNumbers;
                } else {
                    imh = Qt.ImhDigitsOnly;
                }
                validator = intValidatorComponent.createObject(this);
                valueType = typeof 0;
                break;

            case binding.kTypeDecimal:
                if (Qt.platform.os === "ios") {
                    imh = Qt.ImhPreferNumbers;
                } else {
                    imh = Qt.ImhFormattedNumbersOnly;
                }
                validator = doubleValidatorComponent.createObject(this);
                valueType = typeof 0;
                break;

            case binding.kTypeDate:
                imh = Qt.ImhDate;
                break;

            case binding.kTypeTime:
                imh = Qt.ImhTime;
                validator = timeValidatorComponent.createObject(this);
                placeholderText = "hh:mm:ss";
                break;

            case binding.kTypeDateTime:
                imh = Qt.ImhDate | Qt.ImhTime;
                break;

            case binding.kTypeBarcode:
                imh = Qt.ImhNoPredictiveText;
                break;

            default:
                console.log("Unhandled input bind type:", binding.type);
                break;
            }

            var esriProperty = bindElement["@esri:fieldLength"];
            if (esriProperty > "") {
                var n = Number(esriProperty);
                if (isFinite(n)) {
                    fieldLength = n;
                }
            }

            if (fieldLength > 0) {
                maximumLength = fieldLength;
            }

            var mask = formElement["@esri:inputMask"];
            if (mask > "") {
                textField.inputMask = mask;
                imh |= Qt.ImhNoPredictiveText;
            }

            inputMethodHints = imh;

            constraint = formData.createConstraint(this, bindElement);

            if (showSpinners) {
                horizontalAlignment = TextInput.AlignHCenter;
            }
        }

        onCleared: {
            setValue(undefined, 1);
            changeReason = 1;
            xform.style.buttonFeedback();
            valueModified(inputLayout);
        }

        onEditingFinished: {
            var value;

            if (text > "") {
                switch (binding.type) {
                case binding.kTypeInt:
                    value = XFormJS.numberFromLocaleString(numberLocale, text);
                    break;

                case binding.kTypeDecimal:
                    value = XFormJS.numberFromLocaleString(numberLocale, text);
                    break;

                case binding.kTypeDate:
                case binding.kTypeDateTime:
                    break;

                default:
                    value = text;
                    break;
                }
            }

            formData.setValue(bindElement, value);
        }

        onLengthChanged: {
            if (length === 0) {
                formData.setValue(bindElement, undefined);
            }
        }

        textInput.onActiveFocusChanged: {
            var activeFocus = textInput.activeFocus;

            if (activeFocus) {
                if (keypadLoader) {
                    keypadLoader.showKeypad = true;
                } else {
                    ensureVisible();
                }
            }

            xform.controlFocusChanged(this, activeFocus, bindElement);
        }

        onKeysPressed: {
            if (!readOnly) {
                changeReason = 1;
                valueModified(inputLayout);
            }

            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (!readOnly && !(hasError || (inputRequired && text == emptyText))) {
                    xform.nextControl(textInput);
                }
                break;
            }
        }

        leftIndicator: isBarcode
                       ? barcodeButtonComponent
                       : keypadIcon > ""
                         ? keypadButtonComponent
                         : null
    }

    Item {
        Layout.fillWidth: true
        visible: isMinimalBarcode
    }

    //--------------------------------------------------------------------------

    Component {
        id: statusInfo

        RowLayout {
            Layout.fillWidth: true

            visible: textInput.activeFocus || hasError || keypadVisible
            layoutDirection: xform.layoutDirection

            readonly property bool hasError: textField.hasError

            Item {
                Layout.fillWidth: true

                visible: !parent.hasError
            }

            Text {
                id: errorText

                Layout.fillWidth: true

                visible: parent.hasError

                color: xform.style.inputErrorTextColor

                font {
                    family: xform.style.fontFamily
                    pointSize: 12 * xform.style.textScaleFactor
                }

                text: textInput.inputMask > ""
                      ? qsTr("Input format not satisfied")
                      : textInput.validator && textInput.validator.invalidMessage
                        ? textInput.validator.invalidMessage
                        : qsTr("Invalid input")

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            XFormInputCharacterCount {
                locale: xform.locale
                inputControl: textInput
                enabled: showCharacterCount && inputControl.inputMask === ""
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: intValidatorComponent

        IntegerValidator {
            property string invalidMessage: qsTr("Invalid integer")

            locale: numberLocale.name
        }
    }

    Component {
        id: doubleValidatorComponent

        DoubleValidator {
            property string invalidMessage: qsTr("Invalid number")

            notation: DoubleValidator.StandardNotation
            locale: numberLocale.name
        }
    }

    Component {
        id: timeValidatorComponent

        RegExpValidator {
            property string invalidMessage: qsTr("Invalid time")

            regExp: /^[0-9][0-9]:[0-5][0-9]:[0-5][0-9]$/
        }
    }

    //--------------------------------------------------------------------------

    XFormRecalculateButton {
        visible: showCalculate

        onClicked: {
            changeReason = 0;
            formData.triggerCalculate(bindElement);
            valueModified(inputLayout);
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.leftMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        active: showSpinners
        visible: showSpinners
    }

    Component {
        id: spinnerButtonComponent

        Rectangle {
            id: spinnerButton

            property double step: 1
            property bool playSound: false
            property url soundSource: "audio/" + (step < 0 ? "click-down.mp3" : "click-up.mp3")
            property int repeatCount: 0

            signal clicked
            signal repeat

            color: mouseArea.pressed
                   ? border.color
                   : mouseArea.containsMouse
                     ? xform.style.keyHoverColor
                     : xform.style.keyColor

            border {
                width: 1 * AppFramework.displayScaleFactor
                color: xform.style.keyBorderColor
            }

            radius: height / 2 //* 0.16

            onClicked: {
                //textField.forceActiveFocus();
                spinValue(playSound);
                xform.style.buttonFeedback();
                valueModified(inputLayout);
            }

            onRepeat: {
                repeatCount++;
                spinValue(playSound && repeatCount == 1);
                xform.style.buttonFeedback();
            }

            function spinValue(sound) {
                if (sound) {
                    if (audio.playbackState === Audio.PlayingState) {
                        audio.stop();
                    }

                    audio.play();
                }

                var textValue = currentValue;
                var stepValue = step;
                var precision;
                var decimalPointIndex = textValue.indexOf(numberLocale.decimalPoint);
                if (decimalPointIndex >= 0) {
                    precision = textValue.length - decimalPointIndex - 1;
                    if (precision > 0) {
                        stepValue = Math.pow(10, -precision) * step;
                    }
                }

                var value = XFormJS.numberFromLocaleString(numberLocale, textValue);
                if (!isFinite(value)) {
                    value = 0;
                }
                value += stepValue;
                setValue(value, 1);

                if (precision > 0) {
                    currentValue = XFormJS.numberToLocaleString(numberLocale, value, precision, showGroupSeparators);
                }
            }

            Text {
                anchors {
                    centerIn: parent
                    verticalCenterOffset: -paintedHeight * 0.05
                }

                text: step > 0 ? "+" : "-"
                color: xform.style.keyTextColor
                style: xform.style.keyStyle
                styleColor: xform.style.keyStyleColor

                font {
                    bold: xform.style.boldText
                    pixelSize: parent.height * 0.8
                    family: xform.style.keyFontFamily
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    spinnerButton.clicked();
                }

                onPressAndHold: {
                    repeatCount = 0;
                    repeatTimer.start();
                }

                onReleased: {
                    repeatTimer.stop();
                }

                onExited: {
                    repeatTimer.stop();
                }

                onCanceled: {
                    repeatTimer.stop();
                }
            }

            Audio {
                id: audio

                autoLoad: false
                source: spinnerButton.soundSource
            }

            Timer {
                id: repeatTimer

                running: false
                interval: 100
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    spinnerButton.repeat();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: barcodeButtonComponent

        StyledImageButton {
            property real buttonSize: ControlsSingleton.inputTextHeight * (isMinimalBarcode ? 2 : 1)

            implicitHeight: buttonSize
            implicitWidth: buttonSize

            source: scannerIcon
            mouseArea.anchors.margins: -textField.padding
            enabled: !(xform.popoverStackView.get(xform.popoverStackView.depth - 1) instanceof XFormBarcodeScan )

            onClicked: {
                scanBarcode();
            }

            onPressAndHold: {
                if (scannerAddInName > "") {
                    xform.popoverStackView.push({
                                                    item: addInSettingsPage,
                                                    properties: {
                                                    }
                                                });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function scanBarcode() {
        if (!scannerAddInName && QtMultimedia.availableCameras.length <= 0) {
            console.log(logCategory, arguments.calee.name, "No cameras available to scan barcode");
            return;
        }

        Qt.inputMethod.hide();

        xform.popoverStackView.push({
                                        item: scannerPage,
                                        properties: {
                                            formElement: formElement,
                                        }
                                    });
    }

    //--------------------------------------------------------------------------

    Component {
        id: scanBarcodePage

        XFormBarcodeScan {
            onCodeScanned: {
                setValue(code, 1);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInScannerPage

        XFormAddInScanner {
            addInName: scannerAddInName
            title: textValue(formElement.label, "", "long")

            onCodeScanned: {
                setValue(code, 1);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        XFormAddInSettings {
            addInName: scannerAddInName
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: keypadButtonComponent

        StyledImageButton {
            property real buttonSize: ControlsSingleton.inputTextHeight

            implicitHeight: buttonSize
            implicitWidth: buttonSize

            source: Icons.icon(keypadIcon, keypadVisible)
            mouseArea.anchors.margins: -textField.padding
            color: keypadVisible
                   ? xform.style.inputActiveBorderColor
                   : xform.style.textColor

            onClicked: {
                keypadLoader.showKeypad = !keypadLoader.showKeypad;
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: keypadContainer

        Loader {
            Layout.alignment: Qt.AlignHCenter

            Layout.maximumWidth: parent.width
            Layout.minimumWidth: calcWidth(xform.style.keyHeight)
            Layout.preferredWidth: calcWidth(xform.style.keyWidth)
            Layout.preferredHeight: (xform.style.keyHeight + xform.style.keySpacing) * keypadRows

            property bool showKeypad: false

            function calcWidth(keyWidth, columns) {
                return (keyWidth + xform.style.keySpacing) * keypadColumns + xform.style.keySpacing;
            }

            active: showKeypad
            visible: active

            sourceComponent: XFormPicker {
                id: picker

                visible: true
                debug: inputLayout.debug
                backgroundColor: xform.style.keypadColor


                popup {
                    dim: true

                    onAboutToShow: {
                        Qt.inputMethod.hide();
                        forceActiveFocus();
                    }

                    onOpened: {
                        Qt.inputMethod.hide();
                        forceActiveFocus();
                        ensureVisible();
                        textField.contextPopup = picker.popup;
                    }

                    onClosed: {
                        keypadLoader.showKeypad = false;
                        textField.editingFinished();
                        textField.contextPopup = textField.defaultContextPopup;
                    }
                }

                overlay: MouseArea {
                        hoverEnabled: true
                }

                contentItem: Item {
                    Loader {
                        anchors.fill: parent

                        sourceComponent: keypadComponent
                    }
                }

                Canvas {
                    anchors {
                        bottom: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }

                    width: 20 * AppFramework.displayScaleFactor
                    height: 10 * AppFramework.displayScaleFactor

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.fillStyle = xform.style.inputActiveBorderColor
                        ctx.beginPath();
                        ctx.moveTo(width/2, 0);

                        ctx.lineTo(width, height);
                        ctx.lineTo(0, height);
                        ctx.lineTo(width/2,0);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: numbersKeypadComponent

        XFormNumericKeypad {
            readonly property bool numericInput: binding.type === binding.kTypeInt || binding.type === binding.kTypeDecimal
            readonly property bool decimalInput: !(binding.type === binding.kTypeInt)
            property bool firstKey: true

            showPoint: decimalInput
            showGroupSeparator: decimalInput && showGroupSeparators
            canDelete: currentValue > ""
            //zeroEnabled: !numericInput || (firstKey || (currentValue !== "-" && currentValue !== "0"))
            locale: numberLocale

            Component.onCompleted: {
                if (textField.inputMask > "") {
                    showSign = false;
                    showPoint = false;
                }
            }

            onKeyPressed: {
                if (firstKey) {
                    textField.textInput.selectAll();
                    textField.textInput.cut();
                    firstKey = false;
                }

                var textValue = currentValue;
                var updateTextField = true;

                if (textField.inputMask > "") {
                    textValue = textValue.replace(/[^\d]/g, '').trim();
                }

                switch (key) {
                case Qt.Key_plusminus:
                    if (textValue.substring(0, 1) === "-") {
                        textValue = textValue.substring(1);
                    } else {
                        textValue = "-" + textValue;
                    }
                    break;

                case Qt.Key_Enter:
                    updateTextField = false;
                    keypadLoader.showKeypad = false;
                    break;

                case Qt.Key_Delete:
                    if (pressAndHold) {
                        textValue = "";
                    } else {
                        if (textField.length > 0) {
                            textValue = textValue.slice(0, -1);
                        }
                    }
                    break;

                case Qt.Key_Return:
                    updateTextField = false;
                    textField.editingFinished();
                    break;

                case Qt.Key_Period:
                    if (textValue.indexOf(".") < 0) {
                        textValue += ".";
                    }
                    break;

                default:
                    textValue += text;
                    break;
                }

                if (updateTextField) {
                    currentValue = textValue;
                    if (textField.inputMask > "") {
                        textField.cursorPosition = currentValue.trim().length;
                    }
                    valueModified(inputLayout);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculatorKeypadComponent

        Item {
            ColumnLayout {
                anchors.fill: parent

                RowLayout {
                    Layout.fillWidth: true

                    //visible: isFinite(calculator.alu.memory) || calculator.alu.currentExpression > ""

                    Text {
                        visible: isFinite(calculator.alu.memory)
                        color: xform.style.hintColor
                        font.pointSize: 10
                        text: "M %1".arg(calculator.alu.memory)
                    }

                    Text {
                        Layout.fillWidth: true

                        color: xform.style.hintColor
                        font.pointSize: 10
                        text: calculator.alu.currentExpression
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                Calculator {
                    id: calculator

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    display.visible: false
                    color: "transparent"
                    locale: numberLocale
                    keypad.spacing: xform.style.keySpacing

                    alu.onInputChanged: {
                        currentValue = alu.input;
                        if (textField.inputMask > "") {
                            textField.cursorPosition = currentValue.trim().length;
                        }
                        valueModified(inputLayout);
                    }

                    //                        keypad {
                    //                            equalsKey {
                    //                                operation: alu.kOperationEnter
                    //                                color: "#007aff"
                    //                            }
                    //                        }
                }
            }

            Connections {
                target: textField

                onEditingFinished: {
                    calculator.alu.setInput(currentValue);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    /*
    function validateInput() {
        controlGroup.clearError();

        if (!relevant) {
            console.log(logCategory, arguments.callee.name, "Not relevant:", JSON.stringify(bindElement));
            return;
        }

        var isEmpty = currentValue == emptyText;

        if (!isEmpty && constraint) {
            var error = constraint.validate();
            if (error) {
                return error;
            }
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name,
                        "nodeset:", binding.nodeset,
                        "isEmpty:", isEmpty,
                        "currentValue:", JSON.stringify(currentValue),
                        "emptyText:", JSON.stringify(emptyText),
                        "acceptableInput:", textField.acceptableInput,
                        "inputMask:", JSON.stringify(textField.inputMask),
                        "relevant:", relevant,
                        "isRequired:", binding.isRequired);
        }

        var nodeset = binding.nodeset;
        var required = binding.isRequired;

        var field = schema.fieldNodes[nodeset];
        var controlNode = controlNodes[nodeset];

        var label = binding.nodeset;
        if (controlGroup && controlGroup.labelControl) {
            label = controlGroup.labelControl.labelText;
        } else if (field) {
            label = field.label;
        }

        var message;

        if (!message && !isEmpty && !textField.acceptableInput) {
            if (textField.validator && textField.validator.invalidMessage) {
                message = textField.validator.invalidMessage;
            } else {
                message = qsTr("<b>%1</b> input is invalid").arg(label);
            }
        }

        if (!message && required && isEmpty) {
            message = field.requiredMsg > "" ? textLookup(field.requiredMsg) : qsTr("<b>%1</b> is required.").arg(label);
        }

        if (!message) {
            return;
        }

        error = {
            "binding": bindElement,
            "message": message,
            "expression": textField.inputMask,
            "activeExpression": currentValue,
            "nodeset": nodeset,
            "field": field,
            "controlNode": controlNode
        };

        if (debug) {
            console.log(logCategory, arguments.callee.name, "validation error:", error.message);
        }

        return error;
    }
*/

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "value:", JSON.stringify(value), "typeof:", typeof value, "valueType:", valueType, "reason:", reason, "numberLocale:", numberLocale.name);
        }

        if (typeof value !== valueType && typeof value === "string") {
            value = textToValue(value, value);

            if (debug) {
                console.log(arguments.callee.name, "textToValue value:", JSON.stringify(value));
            }
        }

        var textValue = valueToText(value);

        if (debug) {
            console.log(arguments.callee.name, "valueToText value:", JSON.stringify(value), "textValue:", textValue);
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && isEqual(textValue, currentValue)) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        currentValue = textValue;
        if (textValue === "") {
            textField.cursorPosition = 0;
        }

        formData.setValue(bindElement, XFormJS.toBindingType(value, bindElement));
    }

    //--------------------------------------------------------------------------

    function valueToText(value) {
        if (XFormJS.isEmpty(value)) {
            return "";
        }

        if (typeof value === "string") {
            return value;
        }

        var text;

        switch (typeof value) {
        case "number":
            switch (binding.type) {
            case binding.kTypeInt:
            case binding.kTypeDecimal:
                if (isFinite(value)) {
                    text = XFormJS.numberToLocaleString(
                                numberLocale,
                                value,
                                binding.type === binding.kTypeInt ? 0 : undefined,
                                showGroupSeparators);
                } else {
                    text = "";
                }
                break;

            default:
                text = value.toString();
                break;
            }
            break;

        default:
            text = value.toString();
            break;
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function textToValue(text, invalidValue) {
        var value;

        switch (binding.type) {
        case binding.kTypeInt:
            try {
                value = XFormJS.numberFromLocaleString(numberLocale, text);
                if (isFinite(value)) {
                    value = Math.round(value);
                } else {
                    value = invalidValue;
                }
            } catch (e1) {
                value = parseInt(text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            }
            break;

        case binding.kTypeDecimal:
            try {
                value = XFormJS.numberFromLocaleString(numberLocale, text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            } catch (e2) {
                value = parseFloat(text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            }
            break;

        case binding.kTypeDate:
        case binding.kTypeDateTime:
            break;

        default:
            break;
        }

        if (update)

            return value;
    }

    //--------------------------------------------------------------------------

    function typedValue(value) {
        if (typeof value === valueType) {
            return value;
        }

        var tValue = value;

        switch (valueType) {
        case "number":
            tValue = textToValue(value);
            break;

        case "string":
            tValue = valueToText(value);
            break;
        }

        return tValue;
    }

    //--------------------------------------------------------------------------

    function isEqual(value1, value2) {
        return typedValue(value1) === typedValue(value2);
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        function _ensureVisible() {
            xform.ensureItemVisible(inputLayout.parent);
        }

        Qt.callLater(_ensureVisible);
    }

    //--------------------------------------------------------------------------

    XFormControlParameters {
        id: controlStyle

        element: formElement
        attribute: kAttributeStyle

        debug: inputLayout.debug

        Component.onCompleted: {
            initialize();
        }

        function initialize(reset) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, JSON.stringify(element));
            }

            if (reset) {
                parseParameters();
            }

            bind(inputLayout, "scannerAddInName", kPropertyAddIn);
        }
    }

    //--------------------------------------------------------------------------
}
