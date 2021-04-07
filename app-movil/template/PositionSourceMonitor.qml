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

import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../XForms"
import "../XForms/GNSS"

Item {
    id: monitor

    property XFormPositionSourceManager positionSourceManager

    readonly property NmeaSource nmeaSource: positionSourceManager.nmeaSource
    readonly property DeviceDiscoveryAgent discoveryAgent: positionSourceManager.discoveryAgent
    readonly property PositioningSourcesController controller: positionSourceManager.controller

    readonly property bool active: positionSourceManager.active

    property bool positionIsCurrent
    property Position currentPosition

    //--------------------------------------------------------------------------

    property int maximumDataAge: 5000
    property int maximumPositionAge: 5000

    //--------------------------------------------------------------------------

    property int kAlertConnected: 1
    property int kAlertDisconnected: 2
    property int kAlertNoData: 3
    property int kAlertNoPosition: 4

    //--------------------------------------------------------------------------

    property date startTime
    property date dataReceivedTime
    property date positionTime

    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    signal alert(int alertType)

    //--------------------------------------------------------------------------

    onActiveChanged: {
        console.log(logCategory, "Position source monitoring active:", active);

        if (active) {
            initialize();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: "PositionSourceMonitor" //AppFramework.typeOf(monitor, true)
    }

    //--------------------------------------------------------------------------

    Timer {
        id: timer

        interval: 10000
        triggeredOnStart: false
        repeat: true
        running: active

        onTriggered: {
            monitorCheck();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        id: nmeaSourceConnections

        target: nmeaSource
        enabled: active && positionSourceManager.isGNSS

        onReceivedNmeaData: {
            dataReceivedTime = new Date();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        id: positionSourceManagerConnections

        target: positionSourceManager
        enabled: active

        onNewPosition: {
            positionTime = new Date();

            if (!positionSourceManager.isGNSS || position.fixTypeValid && position.fixType > 0) {
                currentPosition = position;
                positionIsCurrent = true;
            } else {
                positionIsCurrent = false;
            }
        }

        onIsConnectedChanged: {
            if (positionSourceManager.isGNSS) {
                if (positionSourceManager.isConnected) {
                    alert(kAlertConnected);
                } else {
                    positionIsCurrent = false;
                    alert(kAlertDisconnected);
                }
            }
        }

        onError: {
            positionIsCurrent = false;
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        startTime = new Date();
        dataReceivedTime = new Date();
        positionTime = new Date();
    }

    //--------------------------------------------------------------------------

    function monitorCheck() {
        var now = new Date().valueOf();

        if (debug) {
            console.log(logCategory, arguments.callee.name);
            console.log(logCategory, " startTime:", startTime);
        }

        if (nmeaSourceConnections.enabled && !positionSourceManager.onSettingsPage && !positionSourceManager.isConnecting && !discoveryAgent.running) {
            var dataAge = now - dataReceivedTime.valueOf();

            if (debug) {
                console.log(logCategory, " dataReceivedTime:", dataReceivedTime);
                console.log(logCategory, " dataAge:", dataAge);
            }

            if (dataAge > maximumDataAge) {
                positionIsCurrent = false;
                alert(kAlertNoData);
                return;
            }
        }


        if (positionSourceManagerConnections.enabled && !positionSourceManager.onSettingsPage && !positionSourceManager.isConnecting && !discoveryAgent.running) {
            var positionAge = now - positionTime.valueOf();

            if (debug) {
                console.log(logCategory, " positionTime:", startTime);
                console.log(logCategory, " positionAge:", positionAge);
            }

            if (positionAge > maximumPositionAge || positionSourceManager.isGNSS && (!currentPosition.fixTypeValid || currentPosition.fixType == 0)) {
                positionIsCurrent = false;
                alert(kAlertNoPosition);
                return;
            }
        }
    }

    //--------------------------------------------------------------------------
}
