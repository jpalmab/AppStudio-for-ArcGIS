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

import "XForm.js" as XFormJS

QtObject {
    id: binding

    //--------------------------------------------------------------------------

    property XFormData formData

    property var element
    property string elementId

    // Standard attributes - https://en.wikibooks.org/wiki/XForms/Bind

    property string nodeset
    property string type

    // Required

    property bool requiredIsDynamic
    property bool isRequired


    // ReadOnly

    property bool readOnlyIsDynamic
    property bool isReadOnly

    // Calculation

    property bool hasCalculate

    // Relevant

    property bool relevantIsDynamic
    property bool isRelevant: true

    // Constraint

    // Esri attributes

    property string esriFieldType
    //property int esriFieldLength
    property string esriFieldAlias

    //

    property var defaultValue

    //

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kTypeBarcode: "barcode"
    readonly property string kTypeDate: "date"
    readonly property string kTypeDateTime: "dateTime"
    readonly property string kTypeDecimal: "decimal"
    readonly property string kTypeGeoPoint: "geopoint"
    readonly property string kTypeGeoShape: "geoshape"
    readonly property string kTypeGeoTrace: "geotrace"
    readonly property string kTypeInt: "int"
    readonly property string kTypeString: "string"
    readonly property string kTypeTime: "time"

    //--------------------------------------------------------------------------

    readonly property string kBindAttributeRequired: "required"
    readonly property string kBindAttributeReadOnly: "readonly"
    readonly property string kBindAttributeRelevant: "relevant"
    readonly property string kBindAttributeCalculate: "calculate"

    //--------------------------------------------------------------------------

    readonly property LoggingCategory _logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(binding, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!element) {
            console.log(logCategory, "Initializing null binding");

            element = {};

            return;
        }

        if (debug) {
            console.log(logCategory, "initializing element:", JSON.stringify(element, undefined, 2));
        }

        elementId = element["@id"] || "";
        nodeset = element["@nodeset"] || "";
        type = element["@type"] || "undefined";

        esriFieldType = element["@esri:fieldType"] || "";
        //esriFieldLength = Number(element["@esri:fieldLength"]);
        esriFieldAlias = element["@esri:fieldAlias"] || ""

        var requiredBinding = formData.boolBinding(element, kBindAttributeRequired);
        requiredIsDynamic = isDynamic(requiredBinding);
        isRequired = requiredBinding;

        var readOnlyBinding = formData.boolBinding(element, kBindAttributeReadOnly);
        readOnlyIsDynamic = isDynamic(readOnlyBinding);
        isReadOnly = readOnlyBinding;

        var relevantBinding = formData.boolBinding(element, kBindAttributeRelevant, true);
        relevantIsDynamic = isDynamic(relevantBinding);
        isRelevant = relevantBinding;

        hasCalculate = element["@" + kBindAttributeCalculate] > "";

        if (debug) {
            console.log(logCategory,
                        "binding nodeset:", nodeset,
                        "\n - readOnlyIsDynamic:", readOnlyIsDynamic,
                        "\n - requiredIsDynamic:", requiredIsDynamic,
                        "\n - relevantIsDynamic:", relevantIsDynamic);
        }
    }

    //--------------------------------------------------------------------------

    function isDynamic(value) {
        return typeof value === "function";
    }

    //--------------------------------------------------------------------------

    function isRequiredBinding() {
        return requiredIsDynamic ? Qt.binding(function() { return isRequired; }) : isRequired;
    }

    //--------------------------------------------------------------------------
}
