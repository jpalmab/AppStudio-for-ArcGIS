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

Item {
    id: positionSourceConnection

    property XFormPositionSourceManager positionSourceManager

    readonly property bool valid: positionSourceManager.valid
    readonly property int wkid: positionSourceManager.wkid

    property string errorString
    property string listener

    property bool emitNewPositionIfNoFix
    property bool stayActiveOnError
    property bool active

    property bool debug: positionSourceManager.debug

    //--------------------------------------------------------------------------

    signal newPosition(var position)

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        stop();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(positionSourceConnection, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        onNewPosition: {
            if (active) {
                positionSourceConnection.errorString = "";

                if (emitNewPositionIfNoFix || !positionSourceManager.isGNSS || position.fixTypeValid && position.fixType > 0) {
                    newPosition(position);
                }
            }
        }

        onError: {
            if (active) {
                positionSourceConnection.errorString = errorString;

                if (!stayActiveOnError && errorString > "") {
                    console.warn(logCategory, "Position manager error:", errorString, ", listener:", listener);
                    stop();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function start() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "listener:", listener, "active:", active);
        }

        if (active) {
            if (debug) {
                console.warn(logCategory, arguments.callee.name,  "Connection already active - listener:", listener);
            }
            return;
        }

        if (!valid) {
            console.warn(logCategory, arguments.callee.name,  "positionSource not valid");
            return;
        }

        active = true;

        positionSourceManager.listen(listener);
    }

    //--------------------------------------------------------------------------

    function stop() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "listener:", listener, "active:", active);
        }

        if (!active) {
            if (debug) {
                console.warn(logCategory, arguments.callee.name, "Connection not active - listener:", listener);
            }
            return;
        }

        active = false;

        if (!valid) {
            console.warn(logCategory, arguments.callee.name,  "positionSource not valid");
            return;
        }

        positionSourceManager.release(listener);
    }

    //--------------------------------------------------------------------------
}
