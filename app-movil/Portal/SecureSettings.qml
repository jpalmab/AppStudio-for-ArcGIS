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
import ArcGIS.AppFramework.SecureStorage 1.0

Item {
    id: secureSettings

    //--------------------------------------------------------------------------

    property App app
    property string appKey: app ? app.info.itemId : ""
    property var secureStorage: SecureStorage
    readonly property int maxValueLength: SecureStorage.maximumValueLength
    property bool debug: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "Maximum secure value length:", maxValueLength);
            console.log(logCategory, "SecureSettings appKey:", appKey);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: secureStorage

        onError: {
            console.error(logCategory, "SecureStorage error:", errorMessage);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(secureSettings, true)
    }

    //--------------------------------------------------------------------------

    function keyId(key) {
        var _key = appKey > ""
                ? "%1-%2".arg(appKey).arg(key)
                : key;


        // Replace any / with - on Android

        if (Qt.platform.os === "android") {
            _key = _key.replace(new RegExp('/', 'g'), '-');
        }

        return _key;
    }

    //--------------------------------------------------------------------------

    function partKey(storageKey, index) {
        return "%1-%2".arg(storageKey).arg(index);
    }

    //--------------------------------------------------------------------------

    function setValue(key, value) {
        remove(key);

        var storageKey = keyId(key);
        var numValueParts = Math.floor(value.length / maxValueLength + 1);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "storageKey:", storageKey, "numValueParts:", numValueParts);
        }

        if (numValueParts > 1) {
            for (var i = 0; i < numValueParts; i++) {
                var partValue = value.slice(i * maxValueLength, (i + 1) * maxValueLength);

                secureStorage.setValue(partKey(storageKey, i), partValue);
            }

            secureStorage.setValue(storageKey, "###%1###".arg(numValueParts));
        } else {
            secureStorage.setValue(storageKey, value);
        }
    }

    //--------------------------------------------------------------------------

    function value(key, defaultValue) {
        var storageKey = keyId(key);
        var numValueParts = getNumValueParts(storageKey);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "storageKey:", storageKey, "numValueParts:", numValueParts);
        }

        if (!numValueParts) {
            return defaultValue;
        }

        var value;

        if (numValueParts > 1) {
            value = "";

            for (var i = 0; i < numValueParts; i++) {
                var v = secureStorage.value(partKey(storageKey, i));
                if (v) {
                    value += v;
                }
            }
        } else {
            value = secureStorage.value(storageKey);
        }

        return (value === undefined || value === null) ? defaultValue : value;
    }

    //--------------------------------------------------------------------------

    function remove(key) {
        var storageKey = keyId(key);
        var numValueParts = getNumValueParts(storageKey);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "key:", key, "storageKey:", storageKey, "numValueParts:", numValueParts);
        }

        if (!numValueParts) {
            return;
        }

        secureStorage.setValue(storageKey, "");

        if (numValueParts > 1) {
            for (var i = 0; i < numValueParts; i++) {
                secureStorage.setValue(partKey(storageKey, i), "");
            }
        }
    }

    //--------------------------------------------------------------------------

    function getNumValueParts(storageKey) {
        var value = secureStorage.value(storageKey, "");

        if (!value) {
            return 0;
        }

        var num;
        var tokens = value.match(/###(\d+)###/);
        if (tokens && tokens.length > 1) {
            num = Number(tokens[1]);
        }

        return isFinite(num) ? num : 1;
    }

    //--------------------------------------------------------------------------
}
