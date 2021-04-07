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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Notifications 1.0

import "../Controls/Singletons"

Item {
    id: style

    property real textScaleFactor: 1.0

    property string fontFamily
    property bool boldText: false

    property real borderWidth: (boldText ? 2 : 1) * AppFramework.displayScaleFactor

    property color backgroundColor: "transparent"
    property color textColor: "black"
    property string backgroundImage
    property int backgroundImageFillMode: Image.PreserveAspectCrop

    property color titleTextColor: "white"
    property color titleBackgroundColor: "#408c31"
    property real titlePointSize: 22
    property string titleFontFamily: fontFamily
    property real titleButtonSize: 40 * AppFramework.displayScaleFactor

    property string menuFontFamily: fontFamily

    property color headerTextColor: "white"
    property color headerBackgroundColor: "darkgrey"

    property real groupLabelPointSize: 18 * textScaleFactor
    property color groupLabelColor: Qt.lighter(textColor, 1.25) // "darkred
    property bool groupLabelBold: true
    property string groupLabelFontFamily: fontFamily
    property color groupBackgroundColor: "#0a000000"
    property color groupBorderColor: "transparent"
    property real groupBorderWidth: borderWidth

    property real labelPointSize: 16 * textScaleFactor
    property color labelColor: textColor
    property bool labelBold: boldText
    property string labelFontFamily: fontFamily

    property real valuePointSize: 15 * textScaleFactor
    property color valueColor: inputTextColor
    property color valueAltColor: inputAltTextColor
    property bool valueBold: boldText
    property string valueFontFamily: fontFamily

    property real hintPointSize: 12 * textScaleFactor
    property color hintColor: Qt.darker(textColor, 1.25) // "#202020"
    property bool hintBold: boldText
    property string hintFontFamily: fontFamily

    property real guidanceHintPointSize: 13 * textScaleFactor
    property string guidanceHintFontFamily: fontFamily

    //--------------------------------------------------------------------------

    property color inputTextColor: "black"
    property color inputAltTextColor: "darkblue"
    property color inputBackgroundColor: "white"
    property real inputBackgroundRadius: 4 * AppFramework.displayScaleFactor
    property color inputErrorTextColor: "#A80000"
    property color inputErrorBackgroundColor: inputBackgroundColor
    property color inputReadOnlyTextColor: "black"
    property color inputReadOnlyBackgroundColor: "#f7f7f7"
    property color inputPlaceholderTextColor:  AppFramework.alphaColor(inputTextColor, 0.4)
    property bool inputBold: boldText
    property real inputPointSize: 15 * textScaleFactor
    property string inputFontFamily: fontFamily
    property color inputBorderColor: "#ddd"
    property real inputBorderWidth: borderWidth
    property color inputActiveBorderColor: "#47b"
    property real inputActiveBorderWidth: borderWidth
    property color inputCountColor: "#202020"
    property color inputCountWarningColor: "#a00000"

    readonly property alias inputFont: inputControl.font
    readonly property alias inputPalette: inputControl.palette

    Control {
        id: inputControl

        font {
            bold: inputBold
            pointSize: inputPointSize
            family: inputFontFamily
        }

        palette {
            window: backgroundColor
            windowText: textColor

            base: inputBackgroundColor
            text: inputTextColor
            mid: inputBorderColor
            highlight: inputActiveBorderColor
            highlightedText: "white"

            button: "transparent"
            buttonText: buttonColor
        }
    }

    //--------------------------------------------------------------------------

    property color selectTextColor: inputTextColor
    property color selectAltTextColor: inputAltTextColor
    property bool selectBold: boldText
    property real selectPointSize: 15 * textScaleFactor
    property color selectHighlightTextColor: "white"
    property color selectHighlightColor: "#47b"
    property string selectFontFamily: fontFamily
    property color selectIndicatorColor: selectTextColor
    property color selectAltIndicatorColor: selectAltTextColor
    property real selectIndicatorSize: 12 * AppFramework.displayScaleFactor * textScaleFactor
    property real selectImplicitIndicatorSize: selectIndicatorSize + 14 * AppFramework.displayScaleFactor * textScaleFactor
    property color selectBorderColor: "#ddd"
    property real selectBorderWidth: borderWidth
    property color selectActiveBorderColor: "#47b"
    property real selectActiveBorderWidth: borderWidth

    property real imagePreviewHeight: 150 * AppFramework.displayScaleFactor

    property color signatureBackgroundColor: "white"
    property color signaturePenColor: "black"
    property real signaturePenWidth: 3
    property int signatureHeight: 135 * AppFramework.displayScaleFactor

    property int gridColumnWidth: 125 * AppFramework.displayScaleFactor
    property real gridSpacing: 6 * AppFramework.displayScaleFactor

    property int imageButtonSize: 40 * AppFramework.displayScaleFactor * textScaleFactor
    property int playButtonSize: 30 * AppFramework.displayScaleFactor

    property color buttonColor: "#606060"
    property real buttonSize: 35 * AppFramework.displayScaleFactor // Default non-specific button size
    property real buttonTextPointSize: 16

    property color buttonBarBackgroundColor: "#eeeeee"
    property color buttonBarBorderColor: "#ddd"
    property real buttonBarBorderWidth: borderWidth
    property color buttonBarTextColor: "#101010"
    property real buttonBarSize: 35 * AppFramework.displayScaleFactor * xform.style.textScaleFactor // Button size

    property color keyColor: "white"
    property color keyPressedColor: "#bbb"
    property color keyHoverColor: "#e8e8e8"
    property color keyTextColor: "#333"
    property color keyBorderColor: "#ccc"
    property int keyStyle: Text.Normal
    property color keyStyleColor: "#eee"
    property string keyFontFamily: fontFamily
    property color keypadColor: "#d8d8d8"
    property real keySpacing: 5 * AppFramework.displayScaleFactor
    property real keyHeight: 60 * AppFramework.displayScaleFactor
    property real keyWidth: keyHeight * 1.75

    property string calendarFontFamily: fontFamily

    property color iconColor: "#666"
    property color deleteIconColor: "#A80000"

    property color requiredColor: "#A80000"
    property string requiredSymbol: '<font color="%1">*</font>'.arg(requiredColor)

    property color errorColor: "#A80000"
    property color errorBorderColor: "#A80000"
    property real errorBorderWidth: 2 * AppFramework.displayScaleFactor

    property color gridBorderColor: "#d0d0d0"
    property real gridBorderWidth: 1 *  AppFramework.displayScaleFactor

    property color popupTextColor: "#303030"
    property color popupBackgroundColor: "#f2f3ed"
    property color popupBorderColor: "#808080"
    property real popupBorderWidth: 1 * AppFramework.displayScaleFactor
    property color popupSeparatorColor: "#b0b0b0"
    property real popupSeparatorWidth: 1 * AppFramework.displayScaleFactor
    property color popupPressedColor: "grey"
    property color popupHoverColor: "lightgrey"
    property string popupFontFamily: fontFamily
    property real popupPointSize: 16 * textScaleFactor
    property real popupTitlePointSize: 18 * textScaleFactor

    property real lineHeight: inputFontMetrics.height

    //--------------------------------------------------------------------------
    // Accessibility

    property bool hapticFeedback: HapticFeedback.supported

    //--------------------------------------------------------------------------

    readonly property alias implicitText: implicitText
    readonly property alias implicitTextHeight: implicitText.implicitHeight

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        ControlsSingleton.inputFont.family = Qt.binding(function () { return inputFontFamily;} );
        ControlsSingleton.inputFont.pointSize = Qt.binding(function () { return inputPointSize;} );
        ControlsSingleton.inputFont.bold = Qt.binding(function () { return inputBold; } );

        log();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(style, true)
    }

    //--------------------------------------------------------------------------

    FontMetrics {
        id: inputFontMetrics

        font {
            pointSize: inputPointSize
            bold: inputBold
            family: fontFamily
        }
    }

    //--------------------------------------------------------------------------

    Text {
        id: implicitText

        font {
            family: fontFamily
            pointSize: 12 * textScaleFactor
        }
    }

    //--------------------------------------------------------------------------

    function buttonFeedback() {
        if (hapticFeedback) {
            HapticFeedback.send(HapticFeedback.HapticFeedbackTypeHeavy);
        }
    }

    //--------------------------------------------------------------------------

    function selectFeedback() {
        if (hapticFeedback) {
            HapticFeedback.send(HapticFeedback.HapticFeedbackTypeSelect);
        }
    }

    //--------------------------------------------------------------------------

    function slideFeedback() {
        if (hapticFeedback) {
            HapticFeedback.send(HapticFeedback.HapticFeedbackTypeMedium);
        }
    }

    //--------------------------------------------------------------------------

    function errorFeedback() {
        if (hapticFeedback) {
            HapticFeedback.send(HapticFeedback.HapticFeedbackTypeError);
        }
    }

    //--------------------------------------------------------------------------

    function warningFeedback() {
        if (hapticFeedback) {
            HapticFeedback.send(HapticFeedback.HapticFeedbackTypeWarning);
        }
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "XForm style -");
        console.log(logCategory, "* fontFamily:", fontFamily);
        console.log(logCategory, "* textScaleFactor:", textScaleFactor);
        console.log(logCategory, "* implicitText pointSize:", implicitText.font.pointSize);
        console.log(logCategory, "* implicitTextHeight:", implicitTextHeight);
        console.log(logCategory, "* hapticFeedback:", hapticFeedback);
    }

    //--------------------------------------------------------------------------
}
