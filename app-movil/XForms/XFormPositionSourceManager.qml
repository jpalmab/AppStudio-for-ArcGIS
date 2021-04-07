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
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "GNSS"

Item {
    id: positionSourceManager

    property alias controller: controller
    property alias positionSource: controller.positionSource
    property alias satelliteInfoSource: controller.satelliteInfoSource
    property alias discoveryAgent: controller.discoveryAgent
    property alias nmeaSource: controller.nmeaSource

    //--------------------------------------------------------------------------
    // Configuration properties

    property bool discoverBluetooth: true
    property bool discoverBluetoothLE: false
    property bool discoverSerialPort: false

    property int connectionType: PositioningSourcesController.ConnectionType.Internal
    property int activationMode: 0
    property string storedDeviceName: ""
    property string storedDeviceJSON: ""
    property string hostname: ""
    property int port: Number.NaN

    property int altitudeType: 0 // 0=MSL, 1=HAE
    property real customGeoidSeparation: Number.NaN
    property real antennaHeight: Number.NaN
    property int wkid: 4326

    //--------------------------------------------------------------------------

    property date activatedTimestamp    // Time when activated
    property real timeOffset: 0         // correction for system clock running fast/late

    property int referenceCount: 0      // Number of connections
    property int warmupCount: controller.connectionType > PositioningSourcesController.ConnectionType.Internal ? 3 : 1
    property int positionCount: 0

    //--------------------------------------------------------------------------

    readonly property bool valid: positionSource.valid
    readonly property bool active: positionSource.active
    readonly property bool isGNSS: !controller.useInternalGPS
    readonly property bool isConnecting: controller.isConnecting || controller.errorWhileConnecting
    readonly property bool isConnected: controller.isConnected
    readonly property bool isWarmingUp: isConnected && positionCount <= warmupCount
    property alias stayConnected: controller.stayConnected
    property alias onSettingsPage: controller.onSettingsPage
    property alias onDetailedSettingsPage: controller.onDetailedSettingsPage

    //--------------------------------------------------------------------------

    readonly property int status: !active
                                  ? kStatusNull
                                  : isConnecting
                                    ? kStatusConnecting
                                    : isWarmingUp
                                      ? kStatusWarmingUp
                                      : isConnected
                                        ? kStatusInUse
                                        : kStatusNull // connection to external device lost

    readonly property int kStatusNull: 0            // Not active
    readonly property int kStatusConnecting: 1      // Connecting to position source
    readonly property int kStatusWarmingUp: 2       // Connected, warming up
    readonly property int kStatusInUse: 3           // Connected, warmed up, and in use

    //--------------------------------------------------------------------------

    property var listeners: ({})

    property bool debug: false

    //--------------------------------------------------------------------------

    enum PositionSourceType {
        Unknown = 0,
        User = 1,
        System = 2,
        External = 3,
        Network = 4
    }

    //--------------------------------------------------------------------------

    signal startPositionSource()
    signal stopPositionSource()
    signal newPosition(var position)
    signal error(string errorString)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        AppFramework.environment.setValue("APPSTUDIO_POSITION_DESIRED_ACCURACY", "HIGHEST");
        AppFramework.environment.setValue("APPSTUDIO_POSITION_ACTIVITY_MODE", "OTHERNAVIGATION");
    }

    //-------------------------------------------------------------------------

    onStartPositionSource: {
        controller.startPositionSource();
        controller.reconnect();
    }

    //-------------------------------------------------------------------------

    onStopPositionSource: {
        controller.stopPositionSource();
    }

    //-------------------------------------------------------------------------

    onStatusChanged: {
        console.log(logCategory, "Position source manager status:", status);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(positionSourceManager, true)
    }

    //--------------------------------------------------------------------------

    PositioningSources {
        id: sources

        connectionType: controller.connectionType
        discoverBluetooth: controller.discoverBluetooth
        discoverBluetoothLE: controller.discoverBluetoothLE
        discoverSerialPort: controller.discoverSerialPort
    }

    PositioningSourcesController {
        id: controller

        sources: sources
        stayConnected: referenceCount > 0

        discoverBluetooth: positionSourceManager.discoverBluetooth
        discoverBluetoothLE: positionSourceManager.discoverBluetoothLE
        discoverSerialPort: positionSourceManager.discoverSerialPort

        connectionType: positionSourceManager.connectionType
        storedDeviceName: positionSourceManager.storedDeviceName
        storedDeviceJSON: positionSourceManager.storedDeviceJSON
        hostname: positionSourceManager.hostname
        port: Number(positionSourceManager.port)

        onIsConnectedChanged: {
            if (initialized && isGNSS) {
                // (de)activate position source after connection change
                positionSource.active = referenceCount > 0;

                // require warm-up after disconnect
                if (!isConnected) {
                    positionCount = 0;
                }
            }
        }

        onError: {
            positionSourceManager.error(errorString);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSource

        onActiveChanged: {
            console.log(logCategory, "positionSource.active:", positionSource.active);

            // require warm-up after activation
            if (positionSource.active) {
                positionCount = 0;
            }
        }

        onPositionChanged: {
            if (referenceCount <= 0) {
                // stale positions coming through after positionSource has been deactivated
                console.warn(logCategory, "Position changed when inactive:", referenceCount, "coordinate:", positionSource.position.coordinate);
                return;
            }

            var position = positionSource.position;
            timeOffset = ((new Date()).valueOf() - position.timestamp.valueOf()) / 1000;

            // TODO - comparison with activatedTimestamp will delay position updates if the system clock is running fast
            if (position.latitudeValid && position.longitudeValid && position.timestamp >= activatedTimestamp) {
                positionCount++;

                addPositionSource(position);

                updateAltitude(position);

                if (isWarmingUp) {
                    console.log(logCategory, "Cold position source - count:", positionCount, "of", warmupCount, "coordinate:", position.coordinate, "timestamp:", position.timestamp, "referenceCount:", referenceCount, "connectionType:", controller.connectionType);
                } else if (isConnected) {
                    if (debug) {
                        console.log(logCategory, "New position - count:", positionCount, "coordinate:", position.coordinate, "timestamp:", position.timestamp, "referenceCount:", referenceCount, "connectionType:", controller.connectionType);
                    }

                    newPosition(position);
                }
            }
        }

        onSourceErrorChanged: {
            if (referenceCount > 0) {
                console.error(logCategory, "Positioning Source Error:", positionSource.sourceError);

                var errorString = "";

                switch (positionSource.sourceError) {
                case PositionSource.AccessError :
                    errorString = qsTr("Position source access error");
                    break;

                case PositionSource.ClosedError :
                    errorString = qsTr("Position source closed error");
                    break;

                case PositionSource.SocketError :
                    errorString = qsTr("Position source error");
                    break;

                case PositionSource.NoError :
                    errorString = "";
                    break;

                default:
                    errorString = qsTr("Unknown position source error %1").arg(positionSource.sourceError);
                    break;
                }

                error(errorString);
            }
        }
    }

    //--------------------------------------------------------------------------

    function listen(listener) {
        console.log(logCategory, "Activating positionSource - referenceCount:", referenceCount, "active:", active, "listener:", listener);

        if (!valid) {
            console.error(logCategory, arguments.callee.name, "listen: positionSource invalid - listener:", listener);
            return;
        }

        if (!referenceCount) {
            activatedTimestamp = new Date();
        }

        referenceCount++;

        if (isGNSS) {
            controller.reconnect();
        } else {
            positionSource.active = referenceCount > 0;
        }

        if (listener) {
            if (listeners[listener]) {
                console.error(logCategory, "Multiple activations for listener:", listener);
            }

            listeners[listener] = true;
        }

        log();
    }

    //--------------------------------------------------------------------------

    function release(listener) {
        console.log(logCategory, "Releasing positionSource - referenceCount:", referenceCount, "active:", active, "listener:", listener);

        if (listener) {
            listeners[listener] = undefined;
        }

        if (!valid) {
            console.error(logCategory, "release: positionSource invalid - listener:", listener);
            return;
        }

        if (referenceCount > 0) {
            referenceCount--;
        } else {
            console.error(logCategory, "GeoPosition referenceCount <= 0 mismatch:", referenceCount, "listener:", listener);
            referenceCount = 0;
        }

        positionSource.active = referenceCount > 0;

        if (isGNSS && referenceCount <= 0) {
            controller.fullDisconnect();
        }

        log();
    }

    //--------------------------------------------------------------------------

    function addPositionSource(info) {

        switch (controller.connectionType) {
        case PositioningSourcesController.ConnectionType.Internal:
            info.positionSourceType = XFormPositionSourceManager.PositionSourceType.System;
            info.positionSourceInfo = systemSourceInfo();
            break;

        case PositioningSourcesController.ConnectionType.External:
            info.positionSourceType = XFormPositionSourceManager.PositionSourceType.External;
            info.positionSourceInfo = deviceSourceInfo(controller.currentDevice);
            break;

        case PositioningSourcesController.ConnectionType.Network:
            info.positionSourceType = XFormPositionSourceManager.PositionSourceType.Network;
            info.positionSourceInfo = networkSourceInfo(controller.tcpSocket);
            break;

        default:
            console.error(logCategory, "Unknown connectionType:", controller.connectionType);

            info.positionSourceType = XFormPositionSourceManager.PositionSourceType.Unknown;
            info.positionSourceInfo = undefined;
            break;
        }

        info.positionSourceTypeValid = true;
        info.positionSourceInfoValid = typeof info.positionSourceInfo === "object";
    }

    function systemSourceInfo() {
        var info = {
            "pluginName": controller.integratedProviderName,

            "connectionMode": activationMode,
            "antennaHeight": antennaHeight,
            "altitudeType": altitudeType,
            "geoidSeparationCustom": altitudeType == 0 ? customGeoidSeparation : Number.NaN,
        }

        return info;
    }

    function deviceSourceInfo(device) {
        if (!device) {
            console.error(logCategory, "Null device");
            return;
        }

        var info = {
            "deviceType": device.deviceType,
            "deviceName": device.name,
            "deviceAddress": device.address,
            // TODO: not yet available from AppFramework
            // "deviceDescription": device.description,
            // "deviceManufacturer": device.manufacturer,
            // "deviceSerialNumber": device.serialNumber,
            // "deviceSystemLocation": device.systemLocation,

            "connectionMode": activationMode,
            "antennaHeight": antennaHeight,
            "altitudeType": altitudeType,
            "geoidSeparationCustom": altitudeType == 0 ? customGeoidSeparation : Number.NaN,
        }

        return info;
    }

    function networkSourceInfo(socket) {
        if (!socket) {
            console.error(logCategory, "Null network socket");
            return;
        }

        var info = {
            "networkAddress": socket.remoteAddress.address,
            "networkPort": socket.remotePort,
            "networkName": socket.remoteName,

            "connectionMode": activationMode,
            "antennaHeight": antennaHeight,
            "altitudeType": altitudeType,
            "geoidSeparationCustom": altitudeType == 0 ? customGeoidSeparation : Number.NaN,
        }

        return info;
    }

    //--------------------------------------------------------------------------

    /*
      The height above the ellipsoid (HAE) of a point is determined by its altitude above
      mean sea-level (MSL) and the geoid separation (N) at this location:

          HAE = MSL + N

      where N > 0 if the geoid lies above the ellipsoid, and N < 0 if the geoid lies below.

      The geoid separation can be reported by the device (Ngps) or it can be user defined (Nuser).

      If Ngps is defined then the altitude reported by the device is altitude above mean sea-level
      (GPS_MSL), otherwise it is height above ellipsoid (GPS_HAE).

      If Ngps or Nuser are undefined, they will be set to 0. If Nuser is defined it takes precedence
      over Ngps on the assumption that the user is working with a more accurate geoid separation
      model. In this case, mean sea level altitudes have to be corrected for the geoid separation
      reported by the device.

      -----------------+----------------------------------+--------------------------------
                       |          Ngps undefined          |          Ngps defined
      -----------------+----------------------------------+--------------------------------
                       |  MSL = GPS_HAE (+ Ngps) - Nuser  |  MSL = GPS_MSL + Ngps - Nuser
      Nuser defined    |                                  |
                       |  HAE = GPS_HAE (+ Npgs)          |  HAE = GPS_MSL + Ngps
      -----------------+----------------------------------+--------------------------------
                       |  MSL ~ GPS_HAE                   |  MSL = GPS_MSL
      Nuser undefined  |                                  |
                       |  HAE = GPS_HAE (+ Ngps)          |  HAE = GPS_MSL + Ngps
      -----------------+----------------------------------+--------------------------------
    */

    function updateAltitude(position) {
        if (!position.altitudeValid) {
            return
        }

        var Ngps = position.geoidSeparationValid ? position.geoidSeparation : 0.0;
        var Nuser = isFinite(customGeoidSeparation) ? customGeoidSeparation : 0.0;
        var altitude = position.coordinate.altitude;

        switch (altitudeType) {
        case 0: // MSL
        default:
            if (isFinite(customGeoidSeparation)) {
                altitude += Ngps - Nuser;
            }
            break;

        case 1: // HAE;
            altitude += Ngps;
            break;
        }

        // Subtract antenna height
        if (isFinite(antennaHeight)) {
            position.antennaHeight = antennaHeight;
            position.antennaHeightValid = true;

            altitude -= antennaHeight;
        }

        position.coordinate.altitude = altitude;
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "positionSourceManager referenceCount:", referenceCount, "active", active, "listeners:", JSON.stringify(listeners, undefined, 2));
    }

    //--------------------------------------------------------------------------
}
