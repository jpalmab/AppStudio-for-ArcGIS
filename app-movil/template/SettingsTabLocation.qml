/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.4

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../XForms/GNSS"
import "../Controls"
import "../Controls/Singletons"
import "../XForms"

SettingsTab {
    id: locationSettingsTab

    title: qsTr("Location")
    description: qsTr("Manage location providers")
    icon: Icons.icon("satellite-3")

    property color iconColor: app.textColor
    property color textColor: app.textColor
    property color hoverBackgroundColor: "#e1f0fb"
    property color unselectedColor: app.textColor
    property color selectedColor: app.titleBarBackgroundColor
    property color selectedBackgroundColor: "#FAFAFA"
    property string fontFamily: app.fontFamily

    property bool showDetailedSettingsCog: true

    // Internal properties -----------------------------------------------------

    readonly property PositioningSourcesController controller: app.positionSourceManager.controller
    readonly property Device currentDevice: controller.currentDevice

    readonly property bool isConnecting: controller.isConnecting
    readonly property bool isConnected: controller.isConnected

    readonly property string kConnected: qsTr("Connected")
    readonly property string kConnecting: qsTr("Connecting")
    readonly property string kDisconnected: qsTr("Disconnected")

    readonly property string kDeviceTypeInternal: "Internal"
    readonly property string kDeviceTypeNetwork: "Network"
    readonly property string kDeviceTypeBluetooth: "Bluetooth"
    readonly property string kDeviceTypeBluetoothLE: "BluetoothLE"
    readonly property string kDeviceTypeSerialPort: "SerialPort"
    readonly property string kDeviceTypeUnknown: "Unknown"

    readonly property string kDelegateTypeCachedDevice: "cached_device"
    readonly property string kDelegateTypeAddDevice: "add_device"

    property var currentListTabView: null

    signal selectInternal()

    //--------------------------------------------------------------------------

    Item {
        id: _item

        Accessible.role: Accessible.Pane

        //----------------------------------------------------------------------

        Component.onCompleted: {
            controller.onSettingsPage = true;

            positionSourceConnection.start();
            _item.createListTabView();
        }

        //----------------------------------------------------------------------

        Component.onDestruction: {
            controller.onSettingsPage = false;
        }

        //----------------------------------------------------------------------

        Connections {
            target: appSettings

            onReceiverListUpdated: {
                _item.createListTabView();
            }
        }

        //----------------------------------------------------------------------

        ListModel {
            id: cachedReceiversListModel
        }

        //----------------------------------------------------------------------

        Component {
            id: listTabView

            SortedListTabView {
                anchors.fill: parent

                delegate: deviceListDelegate

                SettingsTabContainer {
                    id: settingsTabContainer
                }

                onSelected: {
                    app.mainStackView.push(settingsTabContainer,
                                         {
                                             settingsTab: item,
                                             title: item.title,
                                             settingsComponent: item.contentComponent
                                         });
                }

                lessThan: function(left, right) {
                    switch (left.deviceType) {
                    case kDeviceTypeInternal:
                        return true;
                    case kDeviceTypeBluetooth:
                    case kDeviceTypeBluetoothLE:
                    case kDeviceTypeNetwork:
                    case kDeviceTypeSerialPort:
                    case kDeviceTypeUnknown:
                        if (right.deviceType === kDeviceTypeInternal) {
                            return false;
                        }

                        return left.deviceLabel.localeCompare(right.deviceLabel) < 0 ? true : false;
                    }

                    // capture the "Add Provider" case
                    return false;
                }
            }
        }

        //----------------------------------------------------------------------

        function createListTabView() {
            if (currentListTabView !== null) {
                currentListTabView.children = null; // This seems to be required
                currentListTabView = null; // destory() method can lead to crashes
            }

            currentListTabView = listTabView.createObject(_item);
            _item.initializeCachedReceivers(appSettings.knownDevices);

            addDeviceTab.createObject(currentListTabView.tabViewContainer);
        }

        //----------------------------------------------------------------------

        function initializeCachedReceivers(devicesList) {

            cachedReceiversListModel.clear();

            var deviceType = "";

            for (var deviceName in devicesList) {

                if (deviceName === "") {
                    continue;
                }

                var receiverSettings = devicesList[deviceName];

                if (receiverSettings.receiver) {
                    deviceType = receiverSettings.receiver.deviceType;
                    cachedReceiversListModel.append({name: deviceName, deviceType: receiverSettings.receiver.deviceType});
                } else if (receiverSettings.hostname > "" && receiverSettings.port) {
                    deviceType = kDeviceTypeNetwork;
                    cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeNetwork});
                } else if (deviceName === appSettings.kInternalPositionSourceName) {
                    deviceType = kDeviceTypeInternal;
                    cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeInternal});
                } else {
                    continue;
                }

                var _deviceTab = deviceTab.createObject(currentListTabView.tabViewContainer, {
                                                            "title": receiverSettings.label && receiverSettings.label > "" ? receiverSettings.label : deviceName,
                                                            "deviceType": deviceType,
                                                            "deviceName": deviceName,
                                                            "deviceLabel": receiverSettings.label && receiverSettings.label > "" ? receiverSettings.label : deviceName,
                                                            "deviceProperties": receiverSettings
                                                        });

                _deviceTab.selectInternal.connect(function(){
                    selectInternal();
                });

                _deviceTab.updateViewAndDelegate.connect(function(){
                    _item.createListTabView();
                });
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: deviceTab

            SettingsTabLocationDevice {
                property string tabType: kDelegateTypeCachedDevice
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: addDeviceTab

            SettingsTabLocationAddDevice {
                property string tabType: kDelegateTypeAddDevice

                // placeholder properties are required since we use a shared delegate
                property string deviceType: ""
                property string deviceName: ""
                property string deviceLabel: ""
                property var deviceProperties: null
            }
        }

        //----------------------------------------------------------------------

        Component {
            id: deviceListDelegate

            Rectangle {
                id: delegate

                Accessible.role: Accessible.Pane

                property string delegateDeviceType: deviceType !== undefined ? deviceType : kDeviceTypeUnknown
                property string delegateDeviceName: deviceName !== undefined ? deviceName : ""
                property string delegateHostname: deviceProperties && deviceProperties.hostname !== undefined
                                            ? deviceProperties.hostname
                                            : ""
                property string delegatePort: deviceProperties && deviceProperties.port !== undefined
                                      ? deviceProperties.port
                                      : ""

                property bool isInternal: delegateDeviceType === kDeviceTypeInternal
                property bool isNetwork: delegateDeviceType === kDeviceTypeNetwork
                property bool isDevice: !isInternal && !isNetwork

                property bool isSelected: isDevice && controller.useExternalGPS
                                          ? currentDevice && currentDevice.name === delegateDeviceName
                                          : isNetwork && controller.useTCPConnection
                                            ? controller.currentNetworkAddress === delegateHostname + ":" + delegatePort
                                            : isInternal && controller.useInternalGPS

                property int delegateHeight: 65 * AppFramework.displayScaleFactor

                width: parent.parent.width
                height: visible ? delegateHeight : 0

                color: isSelected
                       ? selectedBackgroundColor
                       : tabAction.containsMouse
                         ? hoverBackgroundColor
                         : "transparent"

                ColumnLayout {
                    anchors {
                        fill: parent
                    }

                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Accessible.role: Accessible.Pane

                        RowLayout {
                            anchors {
                                fill: parent
                            }
                            spacing: 0

                            Accessible.role: Accessible.Pane

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: height

                                Accessible.role: Accessible.Pane

                                StyledImage {
                                    id: deviceTypeImage

                                    width: 30 * AppFramework.displayScaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    visible: tabType !== kDelegateTypeAddDevice
                                    source: visible && delegate.delegateDeviceType > ""
                                            ? "./images/deviceType-%1.png".arg(delegate.delegateDeviceType)
                                            : ""
                                    color: delegate.isSelected && (isConnecting || isConnected)
                                           ? selectedColor
                                           : unselectedColor

                                    Accessible.role: Accessible.Graphic
                                }

                                StyledImage {
                                    id: addDeviceImage

                                    width: 30 * AppFramework.displayScaleFactor
                                    height: width
                                    anchors.centerIn: parent

                                    visible: tabType === kDelegateTypeAddDevice
                                    source: "./images/plus.png"
                                    color: iconColor

                                    Accessible.role: Accessible.Graphic
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Accessible.role: Accessible.Pane

                                ColumnLayout {
                                    anchors.fill: parent

                                    spacing: 5 * AppFramework.displayScaleFactor

                                    Text {
                                        Layout.fillWidth: true

                                        text: delegate.isSelected
                                              ? "%1<br><span style='font-size:%2pt'>%3</span>".arg(modelData.title).arg(font.pointSize * .8).arg(isConnecting ? kConnecting : isConnected ? kConnected : kDisconnected)
                                              : tabType === kDelegateTypeCachedDevice && modelData.title !== delegate.delegateDeviceName && !delegate.isInternal
                                                ? "%1<br><span style='font-size:%2pt'>%3</span>".arg(modelData.title).arg(font.pointSize * .8).arg(delegate.delegateDeviceName)
                                                : modelData.title

                                        color: delegate.isSelected && (isConnecting || isConnected)
                                               ? selectedColor
                                               : unselectedColor

                                        font {
                                            pointSize: 16
                                            family: fontFamily
                                            bold: true
                                        }

                                        textFormat: Text.RichText

                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                                        Accessible.role: Accessible.StaticText
                                        Accessible.name: text
                                        Accessible.description: text
                                    }

                                    Text {
                                        Layout.fillWidth: true

                                        visible: text > ""

                                        text: modelData.description
                                        color: textColor

                                        font {
                                            pointSize: 12
                                            family: fontFamily
                                        }

                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                                        Accessible.role: Accessible.StaticText
                                        Accessible.name: text
                                        Accessible.description: text
                                    }
                                }

                                MouseArea {
                                    id: tabAction
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    Accessible.role: Accessible.Button

                                    Connections {
                                        target: locationSettingsTab
                                        onSelectInternal: {
                                            if (delegate.delegateDeviceType === kDeviceTypeInternal) {
                                                tabAction.clicked(null);
                                            }
                                        }
                                    }

                                    onClicked: {

                                        // Different actions based on tab type ---------

                                        // Cached Devices Tab Action -------------------
                                        if (tabType === kDelegateTypeCachedDevice) {

                                            if (delegate.isDevice) {
                                                if ( (!isConnecting && !isConnected) || !controller.useExternalGPS || (currentDevice && currentDevice.name !== delegate.delegateDeviceName) ) {

                                                    var device = appSettings.knownDevices[delegate.delegateDeviceName].receiver;
                                                    appSettings.createExternalReceiverSettings(delegate.delegateDeviceName, device);

                                                    controller.deviceSelected(Device.fromJson(JSON.stringify(device)));
                                                } else {
                                                    controller.deviceDeselected();
                                                }
                                            }
                                            else if (delegate.isNetwork) {
                                                if ( (!isConnecting && !isConnected) || !controller.useTCPConnection || (delegate.delegateHostname > "" && delegate.delegatePort > "" && delegate.delegateHostname + ":" + delegate.delegatePort !== delegate.delegateDeviceName) ) {
                                                    var address = delegate.delegateDeviceName.split(":");
                                                    appSettings.createNetworkSettings(address[0], address[1]);
                                                    controller.networkHostSelected(address[0], address[1]);
                                                } else {
                                                    controller.deviceDeselected();
                                                }
                                            }
                                            else if (delegate.isInternal) {
                                                controller.deviceDeselected();
                                                appSettings.createInternalSettings();
                                            }
                                            else {
                                                controller.deviceDeselected();
                                            }

                                            return;
                                        }

                                        // Add Device Tab Action -----------------------
                                        if (tabType === kDelegateTypeAddDevice) {
                                            currentListTabView.selected(modelData);
                                            return;
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: showDetailedSettingsCog && tabType !== kDelegateTypeAddDevice
                                enabled: visible

                                Layout.fillHeight: true
                                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                                color: "#ccc"

                                Accessible.role: Accessible.Separator
                                Accessible.ignored: true
                            }

                            Rectangle {
                                visible: showDetailedSettingsCog && tabType !== kDelegateTypeAddDevice
                                enabled: visible

                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                color: app.backgroundColor

                                Accessible.role: Accessible.Pane

                                StyledImage {
                                    anchors.centerIn: parent
                                    width: 28 * AppFramework.displayScaleFactor
                                    height: width

                                    source: "./images/gear.png"

                                    color: iconColor

                                    Accessible.role: Accessible.Graphic
                                }

                                MouseArea {
                                    id: deviceSettingsMouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: {
                                        currentListTabView.selected(modelData);
                                    }

                                    Accessible.role: Accessible.Button
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1 * AppFramework.displayScaleFactor
                        color: "#ccc"

                        Accessible.role: Accessible.Separator
                        Accessible.ignored: true
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        XFormPositionSourceConnection {
            id: positionSourceConnection

            positionSourceManager: app.positionSourceManager
            stayActiveOnError: true
            listener: "LocationSettings"

            Accessible.ignored: true
        }
    }

    //--------------------------------------------------------------------------
}
