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

AddInConfig {
    id: config

    //--------------------------------------------------------------------------

    property string mode: defaultMode
    readonly property var toolInfo: addIn.addInInfo.tool || {}
    readonly property var availableModes: (toolInfo.modes || kModeTile).split(",")
    readonly property var defaultMode: availableModes[0]

    //--------------------------------------------------------------------------

    readonly property string kKeyMode: "mode"

    readonly property string kModeTile: "tile"
    readonly property string kModeTab: "tab"
    readonly property string kModeService: "service"
    readonly property string kModeHidden: "hidden"

    //--------------------------------------------------------------------------

    onRead: {
        mode = settings.value(kKeyMode, defaultMode);
    }

    //--------------------------------------------------------------------------

    onWrite: {
        settings.setValue(kKeyMode, mode, defaultMode);
    }

    //--------------------------------------------------------------------------

    onLog: {
        console.log(logCategory, " * availableModes:", JSON.stringify(availableModes));
        console.log(logCategory, " * mode:", mode);
    }

    //--------------------------------------------------------------------------
}
