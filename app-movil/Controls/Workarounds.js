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

.pragma library

.import ArcGIS.AppFramework 1.0 as AF

//--------------------------------------------------------------------------
// Workaround for incorrect keyboard appearing on certain Asian locales

var kPrediciveTextScriptCodes = [
            "Kore", // Korean north and south
            "Jpan", // Japanese
            "Hans", // Simplified Chinese
            "Hant", // Traditional Chinese"
        ]

function checkInputMethodHints(control, locale) {
    if (Qt.platform.os === "android") {
        var localeInfo = AF.AppFramework.localeInfo(locale.name);

        if (localeInfo && kPrediciveTextScriptCodes.indexOf(localeInfo.scriptCode) >= 0) {
            control.inputMethodHints &= ~Qt.ImhNoPredictiveText;
        } else {
            control.inputMethodHints |= Qt.ImhNoPredictiveText;
        }
    }
}

//--------------------------------------------------------------------------
