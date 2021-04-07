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

pragma Singleton

import QtQml 2.12

QtObject {
    //--------------------------------------------------------------------------

    readonly property string kTypeString: "string"
    readonly property string kTypeInt: "int"
    readonly property string kTypeBoolean: "boolean"
    readonly property string kTypeDecimal: "decimal"
    readonly property string kTypeDate: "date"
    readonly property string kTypeTime: "time"
    readonly property string kTypeDateTime: "dateTime"
    readonly property string kTypeGeopoint: "geopoint"
    readonly property string kTypeGeotrace: "geotrace"
    readonly property string kTypeGeoshape: "geoshape"
    readonly property string kTypeBinary: "binary"
    readonly property string kTypeBarcode: "barcode"
    readonly property string kTypeIntenet: "intent"

    //--------------------------------------------------------------------------
}

