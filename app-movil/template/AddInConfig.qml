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
    id: config

    //--------------------------------------------------------------------------

    property var addIn
    property Settings settings: addIn.configSettings

    property bool debug: false

    //--------------------------------------------------------------------------

    property bool enabled: true

    //--------------------------------------------------------------------------

    readonly property string kKeyEnabled: "enabled"

    //--------------------------------------------------------------------------

    signal read()
    signal write()
    signal log()

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(config, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        read();

        if (debug) {
            log();
        }
    }

    //--------------------------------------------------------------------------

    onRead: {
        if (debug) {
            console.log(logCategory, "Add-In Config read:", addIn.name, "title:", addIn.title);
        }

        settings.synchronize();

        enabled = settings.boolValue(kKeyEnabled, true);
    }

    //--------------------------------------------------------------------------

    onWrite: {
        if (debug) {
            console.log(logCategory, "Add-In Config write:", addIn.name, "title:", addIn.title);
        }

        settings.setValue(kKeyEnabled, enabled, true);
    }

    //--------------------------------------------------------------------------

    onLog: {
        console.log(logCategory, "Add-In Config:", addIn.name, "title:", addIn.title)

        console.log(logCategory, " * enabled:", enabled);
    }

    //--------------------------------------------------------------------------
}
