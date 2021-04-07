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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Positioning 1.0

Item {
    id: controller

    // -------------------------------------------------------------------------

    enum ConnectionType {
        Internal = 0,
        External = 1,
        Network = 2
    }

    // -------------------------------------------------------------------------

    property PositioningSources sources

    readonly property PositionSource positionSource: sources.positionSource
    readonly property SatelliteInfoSource satelliteInfoSource: sources.satelliteInfoSource
    readonly property NmeaSource nmeaSource: sources.nmeaSource
    readonly property TcpSocket tcpSocket: sources.tcpSocket
    readonly property DeviceDiscoveryAgent discoveryAgent: sources.discoveryAgent
    readonly property Device currentDevice: sources.currentDevice

    readonly property string currentNetworkAddress: sources.currentNetworkAddress
    readonly property string integratedProviderName: sources.integratedProviderName

    readonly property bool isConnecting: positionSource.valid && !useInternalGPS && sources.isConnecting
    readonly property bool isConnected: positionSource.valid && (useInternalGPS || sources.isConnected)

    property bool discoverBluetooth: true
    property bool discoverBluetoothLE: false
    property bool discoverSerialPort: false

    property int connectionType: PositioningSourcesController.ConnectionType.Internal
    property string storedDeviceName: ""
    property string storedDeviceJSON: ""
    property string hostname: ""
    property int port: Number.NaN

    readonly property bool useInternalGPS: connectionType === PositioningSourcesController.ConnectionType.Internal
    readonly property bool useExternalGPS: connectionType === PositioningSourcesController.ConnectionType.External
    readonly property bool useTCPConnection: connectionType === PositioningSourcesController.ConnectionType.Network

    readonly property string currentName:
        useInternalGPS ? integratedProviderName :
        useExternalGPS && currentDevice ? currentDevice.name :
        useTCPConnection && currentNetworkAddress > "" ? currentNetworkAddress : ""

    readonly property string noExternalReceiverError: qsTr("No external GNSS receiver configured.")
    readonly property string noNetworkProviderError: qsTr("No network location provider configured.")

    property bool errorWhileConnecting
    property bool onDetailedSettingsPage
    property bool onSettingsPage
    property bool stayConnected
    property bool initialized

    signal startPositionSource()
    signal stopPositionSource()
    signal startDiscoveryAgent()
    signal stopDiscoveryAgent()
    signal networkHostSelected(string hostname, int port)
    signal deviceSelected(Device device)
    signal deviceDeselected()
    signal disconnect()
    signal reconnect()
    signal fullDisconnect()
    signal error(string errorString)

    // -------------------------------------------------------------------------

    Component.onCompleted: {
        // prepare to connect to device that was used previously
        if (storedDeviceJSON > "") {
            sources.currentDevice = Device.fromJson(storedDeviceJSON);
        }

        initialized = true;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(controller, true)
    }

    // -------------------------------------------------------------------------

    onIsConnectedChanged: {
        if (initialized) {
            if (isConnected) {
                if (connectionType === PositioningSourcesController.ConnectionType.External && currentDevice) {
                    console.log(logCategory, "Connected to device:", currentDevice.name, "address:", currentDevice.address);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Network) {
                    console.log(logCategory, "Connected to remote host:", tcpSocket.remoteName, "port:", tcpSocket.remotePort);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Internal) {
                    console.log(logCategory, "Connected to system location source:", integratedProviderName);
                }

                errorWhileConnecting = false;
            } else {
                if (connectionType === PositioningSourcesController.ConnectionType.External && currentDevice) {
                    console.log(logCategory, "Disconnecting device:", currentDevice.name, "address", currentDevice.address);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Network) {
                    console.log(logCategory, "Disconnecting from remote host:", tcpSocket.remoteName, "port:", tcpSocket.remotePort);
                } else if (connectionType === PositioningSourcesController.ConnectionType.Internal) {
                    console.log(logCategory, "Disconnecting from system location source:", integratedProviderName);
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    onReconnect: {
        if (!reconnectTimer.running) {
            reconnectTimer.start();
        }
    }

    function reconnectNow() {
        if (useExternalGPS) {
            if (!discoveryAgent.running && !isConnecting && !isConnected) {
                if (currentDevice) {
                    deviceSelected(currentDevice)
                } else if (!onSettingsPage) {
                    error(noExternalReceiverError);
                }
            }
        } else if (useTCPConnection) {
            if (!isConnecting && !isConnected) {
                if (hostname > "" && port > "") {
                    sources.networkHostSelected(hostname, port);
                } else if (!onSettingsPage) {
                    error(noNetworkProviderError);
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    onStartPositionSource:  {
        positionSource.start();
    }

    // -------------------------------------------------------------------------

    onStopPositionSource:  {
        positionSource.stop();
    }

    // -------------------------------------------------------------------------

    onStartDiscoveryAgent: {
        discoveryTimer.start();
    }

    // -------------------------------------------------------------------------

    onStopDiscoveryAgent: {
        discoveryAgent.stop();
    }

    // -------------------------------------------------------------------------

    onNetworkHostSelected: {
        sources.networkHostSelected(hostname, port);
    }

    // -------------------------------------------------------------------------

    onDeviceSelected: {
        sources.deviceSelected(device);
    }

    // -------------------------------------------------------------------------

    onDeviceDeselected: {
        sources.disconnect();
    }

    // -------------------------------------------------------------------------

    onDisconnect: {
        sources.disconnect();
    }

    // -------------------------------------------------------------------------

    onFullDisconnect: {
        sources.disconnect();
        discoveryAgent.stop();
        discoveryTimer.stop();
        reconnectTimer.stop();
    }

    // -------------------------------------------------------------------------

    Connections {
        target: tcpSocket

        onErrorChanged: {
            if (useTCPConnection) {
                console.error(logCategory, "TCP connection error:", tcpSocket.error, tcpSocket.errorString)
                error(tcpSocket.errorString);

//                if (stayConnected && !onSettingsPage) {
//                    errorWhileConnecting = true;
//                    reconnect();
//                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: currentDevice

        onConnectedChanged: {
            if (currentDevice && useExternalGPS) {
                if (stayConnected && !onSettingsPage) {
                    reconnect();
                }
            }
        }

        onErrorChanged: {
            if (currentDevice && useExternalGPS) {
                console.log(logCategory, "Device connection error:", currentDevice.error)

                // showing this dialog if we're not on the settings page proves too distracting
                if (onSettingsPage) {
                    error(currentDevice.error);
                }

                if (stayConnected && !onSettingsPage) {
                    errorWhileConnecting = true;
                    reconnect();
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: discoveryAgent

        onDiscoverDevicesCompleted: {
            console.log(logCategory, "Device discovery completed");
        }

        onRunningChanged: {
            console.log(logCategory, "DeviceDiscoveryAgent running", discoveryAgent.running);
            if (useExternalGPS && !discoveryAgent.running && !isConnecting && !isConnected && stayConnected && !onSettingsPage) {
                if (!discoveryAgent.devices || discoveryAgent.devices.count == 0) {
                    discoveryTimer.start();
                }
            }
        }

        onErrorChanged: {
            console.error(logCategory, "Device discovery agent error:", discoveryAgent.error)
            if (useExternalGPS) {
                error(discoveryAgent.error);
            }
        }

        onDeviceDiscovered: {
            if (discoveryAgent.filter(device)) {
                console.log(logCategory, "Device discovered - Name:", device.name, "Type:", device.deviceType);

                if (useExternalGPS && !isConnecting && !isConnected && storedDeviceName === device.name) {
                    deviceSelected(device);
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: reconnectTimer

        interval: 1000
        running: false
        repeat: false

        onTriggered: {
            reconnectNow();
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: discoveryTimer

        interval: 100
        running: false
        repeat: false

        onTriggered: {
            discoveryAgent.start();
        }
    }

    // -------------------------------------------------------------------------

    Timer {
        id: connectionTimeOutTimer

        interval: 60000
        running: isConnecting
        repeat: false

        onTriggered: {
            console.warn(logCategory, "Connection attempt timed out");
            fullDisconnect();
            reconnect();
        }
    }

    // -------------------------------------------------------------------------
}
