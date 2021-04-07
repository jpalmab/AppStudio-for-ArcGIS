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

import ArcGIS.AppFramework 1.0

QtObject {
    id: localeProperties
    
    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property var systemLocaleInfo: AppFramework.localeInfo(AppFramework.systemLocale)
    readonly property var systemLocale: Qt.locale(AppFramework.systemLocale)

    //--------------------------------------------------------------------------

    property var locale: Qt.locale(AppFramework.defaultLocale)
    property int textDirection: locale.textDirection

    //--------------------------------------------------------------------------

    property var numberLocale: locale.zeroDigit !== "0"
                               ? kNeutralLocale
                               : locale

    //--------------------------------------------------------------------------

    readonly property int layoutDirection: (locale.textDirection === Qt.RightToLeft || textDirection === Qt.RightToLeft)
                                           ? Qt.RightToLeft
                                           : Qt.LeftToRight

    readonly property bool isRightToLeft: layoutDirection === Qt.RightToLeft
    
    readonly property int textAlignment: isRightToLeft ? Text.AlignRight : Text.AlignLeft
    readonly property int textElide: isRightToLeft ? Text.ElideLeft : Text.ElideRight
    readonly property int inputAlignment: isRightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

    //--------------------------------------------------------------------------

    readonly property var kNeutralLocale: Qt.locale("C")

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(localeProperties, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "systemLocale:", systemLocale.name, "textDirection:", systemLocale.textDirection);
        console.log(logCategory, "systemLocaleInfo:", JSON.stringify(systemLocaleInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function isValidDate(date) {
        return date instanceof Date && isFinite(date.valueOf());
    }

    //--------------------------------------------------------------------------

    function formatDate(date, ...format) {
        if (!isValidDate(date)) {
            return "";
        }

        return replaceNumbers(date.toLocaleDateString(locale, ...format));
    }

    //--------------------------------------------------------------------------

    function formatTime(date, ...format) {
        if (!isValidDate(date)) {
            return "";
        }

        return replaceNumbers(date.toLocaleTimeString(locale, ...format));
    }

    //--------------------------------------------------------------------------

    function formatDateTime(date, ...format) {
        if (!isValidDate(date)) {
            return "";
        }

        return replaceNumbers(date.toLocaleString(locale, ...format));
    }

    //--------------------------------------------------------------------------

    function replaceNumbers(text, fromLocale, toLocale) {
        if (!text) {
            return text;
        }

        if (!fromLocale) {
            fromLocale = locale;
        }

        if (!toLocale) {
            toLocale = numberLocale;
        }

        if (fromLocale.zeroDigit === toLocale.zeroDigit) {
            return text;
        }

        text = text.toString();

        for (var i = 0; i <= 9; i++) {
            text = text.replace(new RegExp(i.toLocaleString(fromLocale, "f", 0), "g"), i.toLocaleString(toLocale, "f", 0));
        }

        function replaceSymbol(fromSymbol, toSymbol) {
            text = text.replace(new RegExp('\\' + fromSymbol, "g"), toSymbol);
        }

        replaceSymbol(fromLocale.decimalPoint, toLocale.decimalPoint);
        replaceSymbol(fromLocale.negativeSign, toLocale.negativeSign);
        replaceSymbol(fromLocale.positiveSign, toLocale.positiveSign);

        // Remove Arabic Letter Marks if prefixing a number

        if (fromLocale.textDirection === Qt.RightToLeft) {
            var matches = text.match(new RegExp("\u061c[-\d]", "g"));
            if (Array.isArray(matches)) {
                matches.forEach(match => {
                                    text = text.replace(new RegExp(match, "g"), match.substr(1));
                                });
            }
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "locale:", locale.name, "textDirection:", directionText(locale.textDirection));
        console.log(logCategory, "localeInfo:", JSON.stringify(AppFramework.localeInfo(locale.name), undefined, 2));

        console.log(logCategory, "numberLocale:", numberLocale.name);
        console.log(logCategory, "isRightToLeft:", isRightToLeft);
        console.log(logCategory, "textDirection:", directionText(textDirection));
        console.log(logCategory, "layoutDirection:", directionText(layoutDirection));
        console.log(logCategory, "textAlignment:", textAlignment);
        console.log(logCategory, "textElide:", textElide);
        console.log(logCategory, "inputAlignment:", inputAlignment);
    }

    //--------------------------------------------------------------------------

    function directionText(direction) {
        return "%1 (%2)".arg(direction).arg(direction === Qt.RightToLeft ? "RTL": "LTR");
    }

    //--------------------------------------------------------------------------
}
