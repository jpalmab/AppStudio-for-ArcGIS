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

import QtQml 2.11
import QtQuick 2.11

QtObject {
    id: helper

    //--------------------------------------------------------------------------

    property UnitsModels unitsModels
    property Locale locale: Qt.locale()
    property int measurementSystem: locale.measurementSystem
    property var typeInfos: kMeasurementSystemTypes[measurementSystem]
    property var defaultTypeInfos: kMeasurementSystemTypes[measurementSystem]

    //--------------------------------------------------------------------------

    property var kMeasurementSystemTypes: [
        kMetricTypes,       // Locale.MetricSystem
        kImperialTypes,     // Locale.ImperialUSSystem
        kImperialTypes      // Locale.ImperialUKSystem
    ]

    //--------------------------------------------------------------------------

    readonly property var kMetricTypes:
        ({
             "length": {
                 type: "linear",
                 minorUnit: "m",
                 minorPrecision: 0,
                 threshold: 1000,
                 majorUnit: "km",
                 majorPrecision: 1,
             },

             "area": {
                 type: "area",
                 minorUnit: "m2",
                 minorPrecision: 0,
                 threshold: 10000,
                 majorUnit: "ha",
                 majorPrecision: 1,
             },

             "speed": {
                 type: "speed",
                 minorUnit: "m/s",
                 minorPrecision: 0,
                 threshold: 10,
                 majorUnit: "km/h",
                 majorPrecision: 1,
             },

             "height": {
                 type: "linear",
                 minorUnit: "m",
                 minorPrecision: 1,
                 threshold: 100,
                 majorUnit: "m",
                 majorPrecision: 0,
             },

             "horizontalAccuracy": {
                 type: "linear",
                 minorUnit: "cm",
                 minorPrecision: 0,
                 threshold: 10,
                 majorUnit: "m",
                 majorPrecision: 1,
             },

             "verticalAccuracy": {
                 type: "linear",
                 minorUnit: "cm",
                 minorPrecision: 0,
                 threshold: 10,
                 majorUnit: "m",
                 majorPrecision: 1,
             },
         })

    //--------------------------------------------------------------------------

    readonly property var kImperialTypes:
        ({
             "length": {
                 type: "linear",
                 minorUnit: "ft",
                 minorPrecision: 0,
                 threshold: 2000,
                 majorUnit: "mi",
                 majorPrecision: 1,
             },

             "area": {
                 type: "area",
                 minorUnit: "ft2",
                 minorPrecision: 0,
                 threshold: 10000,
                 majorUnit: "ac",
                 majorPrecision: 1,
             },

             "speed": {
                 type: "speed",
                 minorUnit: "ft/s",
                 minorPrecision: 0,
                 threshold: 10,
                 majorUnit: "mph",
                 majorPrecision: 1,
             },

             "height": {
                 type: "linear",
                 minorUnit: "ft",
                 minorPrecision: 1,
                 threshold: 100,
                 majorUnit: "ft",
                 majorPrecision: 0,
             },

             "horizontalAccuracy": {
                 type: "linear",
                 minorUnit: "in",
                 minorPrecision: 0,
                 threshold: 12,
                 majorUnit: "ft",
                 majorPrecision: 1,
             },

             "verticalAccuracy": {
                 type: "linear",
                 minorUnit: "in",
                 minorPrecision: 0,
                 threshold: 12,
                 majorUnit: "ft",
                 majorPrecision: 1,
             },
         })

    //--------------------------------------------------------------------------

    onTypeInfosChanged: {
        typeInfos.forEach(function (type) {
            if (!type.minorInfo) {
                type.minorInfo = unitsModels.typeUnit(type.type, type.minorUnit);
            }

            if (!type.majorInfo) {
                type.majorInfo = unitsModels.typeUnit(type.type, type.majorUnit);
            }
        });
    }

    //--------------------------------------------------------------------------

    function displayValue(siValue, type, locale) {
        if (siValue === undefined || siValue === null) {
            return "--";
        }

        if (!type) {
            console.warn("Undefined type");
            return siValue.toString();
        }

        if (!locale) {
            locale = helper.locale;
        }

        var typeInfo = typeInfos[type];
        if (!typeInfo) {
            typeInfo = defaultTypeInfos[type];
        }

        var displayValue = siValue / typeInfo.minorInfo.factor;
        var displayAbbreviation = typeInfo.minorInfo.abbreviation;
        var displayPrecision = typeInfo.minorPrecision;

        if (displayValue > typeInfo.threshold) {
            displayValue = siValue / typeInfo.majorInfo.factor;
            displayAbbreviation = typeInfo.majorInfo.abbreviation;
            displayPrecision = typeInfo.majorPrecision;
        }

        return "%1 %2"
        .arg(localeRound(displayValue, displayPrecision, locale))
        .arg(displayAbbreviation);
    }

    //--------------------------------------------------------------------------

    function localeRound(value, precision, locale) {
        if (!locale) {
            locale = helper.locale;
        }

        if (!precision) {
            precision = 0;
        }

        var p = Math.pow(10, precision);

        return trimTrailingZeros((Math.round(value * p) / p).toLocaleString(locale, "f", precision), locale);
    }

    //--------------------------------------------------------------------------

    function trimTrailingZeros(text, locale) {
        if (!locale) {
            locale = helper.locale;
        }

        var decimalPoint = locale ? locale.decimalPoint : ".";
        var zeroDigit = locale ? locale.zeroDigit : "0";

        if (text.indexOf(decimalPoint) <= 0) {
            return text;
        }

        var l = text.length;
        while (l > 0) {
            var c = text.charAt(l - 1);
            if (c === decimalPoint || c === zeroDigit) {
                l--;
            } else {
                break;
            }
        }

        return l < text.length ? text.substr(0, l) : text;
    }

    //--------------------------------------------------------------------------
}
