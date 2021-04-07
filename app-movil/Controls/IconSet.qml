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
import ArcGIS.AppFramework 1.0

QtObject {
    //--------------------------------------------------------------------------

    property url source: "icons"

    property int iconResolution: 24
    property int bigIconResolution: 32
    property bool bold: false

    //--------------------------------------------------------------------------

    function icon(name, filled, resolution) {
        if (filled === undefined) {
            filled = bold;
        }

        return icon = source + "/%1-%2%3.svg"
        .arg(name)
        .arg(resolution ? resolution : iconResolution)
        .arg(filled ? "-f" : "");
    }

    //--------------------------------------------------------------------------

    function bigIcon(name, filled) {
        if (filled === undefined) {
            filled = bold;
        }

        return icon(name, filled, bigIconResolution);
    }

    //--------------------------------------------------------------------------
}

