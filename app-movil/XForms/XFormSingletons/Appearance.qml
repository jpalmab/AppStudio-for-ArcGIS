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

import "../XForm.js" as XFormJS

QtObject {
    //--------------------------------------------------------------------------

    readonly property string kAutoComplete: "autocomplete"
    readonly property string kCompact: "compact"
    readonly property string kCalculator: "calculator"
    readonly property string kDistress: "distress"
    readonly property string kImageMap: "image-map"
    readonly property string kLabel: "label"
    readonly property string kLikert: "likert"
    readonly property string kListNoLabel: "list-nolabel"
    readonly property string kMinimal: "minimal"
    readonly property string kMonthYear: "month-year"
    readonly property string kMultiline: "multiline"
    readonly property string kNumbers: "numbers"
    readonly property string kQuick: "quick"
    readonly property string kQuickCompact: "quickcompact"
    readonly property string kSignature: "signature"
    readonly property string kSpinner: "spinner"
    readonly property string kThousandsSep: "thousands-sep"
    readonly property string kNoTicks: "no-ticks"
    readonly property string kWeekNumber: "week-number"
    readonly property string kYear: "year"

    //--------------------------------------------------------------------------

    function contains(appearances, apperance) {
        return XFormJS.contains(appearances, apperance);
    }

    //--------------------------------------------------------------------------

    function toArray(appearance) {
        if (appearance > "") {
            return appearance.split(" ").map(name => name.trim()).filter(name => name > "");
        } else {
            return [];
        }
    }

    //--------------------------------------------------------------------------
}

