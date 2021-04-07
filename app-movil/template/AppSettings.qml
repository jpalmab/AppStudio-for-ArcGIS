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
import ArcGIS.AppFramework.Notifications 1.0

QtObject {
    id: object

    //--------------------------------------------------------------------------

    property App app
    property Settings settings: app.settings

    property bool debug: false

    //--------------------------------------------------------------------------

    // Map

    property string mapPlugin: kDefaultMapPlugin

    // Accessibility

    property bool boldText: false
    property bool plainBackgrounds: true
    property bool hapticFeedback: HapticFeedback.supported

    // Text

    property string defaultFontFamily: app.info.propertyValue(kKeyFontFamily, fontFamily)
    property string fontFamily: Qt.application.font.family
    property real textScaleFactor: 1

    // Storage

    property string mapLibraryPaths: kDefaultMapLibraryPath

    // Spatial reference

    property int defaultWkid: 4326
    property int wkid: defaultWkid

    // Location

    // default settings - allow the user to set the GNSS defaults needed in the app
    property bool defaultShowActivationModeSettings: false

    property bool defaultDiscoverBluetooth: true
    property bool defaultDiscoverBluetoothLE: false
    property bool defaultDiscoverSerialPort: false

    property bool defaultLocationAlertsVisualInternal: false
    property bool defaultLocationAlertsSpeechInternal: false
    property bool defaultLocationAlertsVibrateInternal: false

    property bool defaultLocationAlertsVisualExternal: true
    property bool defaultLocationAlertsSpeechExternal: true
    property bool defaultLocationAlertsVibrateExternal: true

    property int defaultLocationMaximumDataAge: 5000
    property int defaultLocationMaximumPositionAge: 5000
    property int defaultLocationSensorActivationMode: kActivationModeAlways
    property int defaultLocationSensorConnectionType: kConnectionTypeInternal
    property int defaultLocationAltitudeType: kAltitudeTypeMSL

    property real defaultLocationGeoidSeparation: Number.NaN
    property real defaultLocationAntennaHeight: Number.NaN

    // current settings state
    property bool showActivationModeSettings: defaultShowActivationModeSettings

    property bool discoverBluetooth: defaultDiscoverBluetooth
    property bool discoverBluetoothLE: defaultDiscoverBluetoothLE
    property bool discoverSerialPort: defaultDiscoverSerialPort

    property bool locationAlertsVisual: defaultLocationAlertsVisualInternal
    property bool locationAlertsSpeech: defaultLocationAlertsSpeechInternal
    property bool locationAlertsVibrate: defaultLocationAlertsVibrateInternal

    property int locationMaximumDataAge: defaultLocationMaximumDataAge
    property int locationMaximumPositionAge: defaultLocationMaximumPositionAge
    property int locationSensorActivationMode: defaultLocationSensorActivationMode
    property int locationSensorConnectionType: defaultLocationSensorConnectionType
    property int locationAltitudeType: defaultLocationAltitudeType

    property real locationGeoidSeparation: defaultLocationGeoidSeparation
    property real locationAntennaHeight: defaultLocationAntennaHeight

    property string lastUsedDeviceLabel: ""
    property string lastUsedDeviceName: ""
    property string lastUsedDeviceJSON: ""
    property string hostname: ""
    property string port: ""

    property var knownDevices: ({})

    //--------------------------------------------------------------------------

    // Map

    readonly property string kKeyMapPlugin: "mapPlugin"
    readonly property string kDefaultMapPlugin: app.info.propertyValue(kKeyMapPlugin, kPluginAppStudio)

    readonly property string kPluginAppStudio: "AppStudio"
    readonly property string kPluginArcGISRuntime: "ArcGISRuntime"


    // Accessibility

    readonly property string kKeyAccessibilityPrefix: "Accessibility/"
    readonly property string kKeyAccessibilityBoldText: kKeyAccessibilityPrefix + "boldText"
    readonly property string kKeyAccessibilityPlainBackgrounds: kKeyAccessibilityPrefix + "plainBackgrounds"
    readonly property string kKeyAccessibilityHapticFeedback: kKeyAccessibilityPrefix + "hapticFeedback"

    // Text

    readonly property string kKeyFontFamily: "fontFamily"
    readonly property string kKeyTextScaleFactor: "textScaleFactor"

    // Storage

    readonly property string kDefaultMapLibraryPath: "~/ArcGIS/My Surveys/Maps"
    readonly property string kKeyMapLibraryPaths: "mapLibraryPaths"

    // Spatial reference

    readonly property string kKeyWkid: "wkid"

    // Location

    readonly property string kKeyShowActivationModeSettings: "ShowActivationModeSettings"

    // this is used to access the integrated provider settings, DO NOT CHANGE
    readonly property string kInternalPositionSourceName: "IntegratedProvider"

    // this is the (translated) name of the integrated provider as it appears on the settings page
    readonly property string kInternalPositionSourceNameTranslated: qsTr("Integrated Provider")

    readonly property string kKeyLocationPrefix: "Location/"
    readonly property string kKeyLocationKnownDevices: kKeyLocationPrefix + "knownDevices"
    readonly property string kKeyLocationLastUsedDevice: kKeyLocationPrefix + "lastUsedDevice"
    readonly property string kKeyLocationDiscoverBluetooth: kKeyLocationPrefix + "discoverBluetooth"
    readonly property string kKeyLocationDiscoverBluetoothLE: kKeyLocationPrefix + "discoverBluetoothLE"
    readonly property string kKeyLocationDiscoverSerialPort: kKeyLocationPrefix + "discoverSerialPort"

    readonly property int kActivationModeAsNeeded: 0
    readonly property int kActivationModeInSurvey: 1
    readonly property int kActivationModeAlways: 2

    readonly property int kConnectionTypeInternal: 0
    readonly property int kConnectionTypeExternal: 1
    readonly property int kConnectionTypeNetwork: 2

    readonly property int kAltitudeTypeMSL: 0
    readonly property int kAltitudeTypeHAE: 1

    //--------------------------------------------------------------------------

    property bool updating

    signal receiverListUpdated()

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(object, true)
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    // update the current global settings on receiver change
    onLastUsedDeviceNameChanged: {
        updating = true;

        if (knownDevices && lastUsedDeviceName > "") {
            var receiverSettings = knownDevices[lastUsedDeviceName];

            if (debug) {
                console.log(logCategory, "knownDevices:", JSON.stringify(knownDevices, undefined, 2));
                console.log(logCategory, "receiverSettings:", JSON.stringify(receiverSettings, undefined, 2));
            }

            if (receiverSettings) {
                switch (receiverSettings.connectionType) {
                case kConnectionTypeInternal:
                    lastUsedDeviceLabel = receiverSettings.label;
                    lastUsedDeviceJSON = "";
                    hostname = "";
                    port = "";
                    break;

                case kConnectionTypeExternal:
                    lastUsedDeviceLabel = receiverSettings.label;
                    lastUsedDeviceJSON = receiverSettings.receiver > "" ? JSON.stringify(receiverSettings.receiver) : "";
                    hostname = "";
                    port = "";
                    break;

                case kConnectionTypeNetwork:
                    lastUsedDeviceLabel = receiverSettings.label;
                    lastUsedDeviceJSON = ""
                    hostname = receiverSettings.hostname;
                    port = receiverSettings.port;
                    break;

                default:
                    console.log(logCategory, "Error: unknown connectionType", receiverSettings.connectionType);
                    updating = false;
                    return;
                }

                function receiverSetting(name, defaultValue) {
                    if (!receiverSettings) {
                        return defaultValue;
                    }

                    var value = receiverSettings[name];
                    if (value !== null && value !== undefined) {
                        return value;
                    } else {
                        return defaultValue;
                    }
                }

                locationAlertsVisual = receiverSetting("locationAlertsVisual", defaultLocationAlertsVisualInternal);
                locationAlertsSpeech = receiverSetting("locationAlertsSpeech", defaultLocationAlertsSpeechInternal);
                locationAlertsVibrate = receiverSetting("locationAlertsVibrate", defaultLocationAlertsVibrateInternal);
                locationMaximumDataAge = receiverSetting("locationMaximumDataAge", defaultLocationMaximumDataAge);
                locationMaximumPositionAge = receiverSetting("locationMaximumPositionAge", defaultLocationMaximumPositionAge);
                locationSensorActivationMode = receiverSetting("activationMode", defaultLocationSensorActivationMode);
                locationSensorConnectionType = receiverSetting("connectionType", defaultLocationSensorConnectionType);
                locationAltitudeType = receiverSetting("altitudeType", defaultLocationAltitudeType);
                locationGeoidSeparation = receiverSetting("geoidSeparation", defaultLocationGeoidSeparation);
                locationAntennaHeight = receiverSetting("antennaHeight", defaultLocationAntennaHeight);
            }
        }

        updating = false;
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log(logCategory, "Reading app settings");

        // Map

        mapPlugin = settings.value(kKeyMapPlugin, kDefaultMapPlugin);

        // Accessibility

        boldText = settings.boolValue(kKeyAccessibilityBoldText, false);
        plainBackgrounds = settings.boolValue(kKeyAccessibilityPlainBackgrounds, true);
        hapticFeedback = settings.boolValue(kKeyAccessibilityHapticFeedback, HapticFeedback.supported);

        // Text

        fontFamily = settings.value(kKeyFontFamily, defaultFontFamily);
        textScaleFactor = settings.value(kKeyTextScaleFactor, 1);

        // Storage

        mapLibraryPaths = settings.value(kKeyMapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        wkid = settings.numberValue(kKeyWkid, defaultWkid);

        // Location

        showActivationModeSettings = settings.boolValue(kKeyShowActivationModeSettings, defaultShowActivationModeSettings);

        discoverBluetooth = settings.boolValue(kKeyLocationDiscoverBluetooth, defaultDiscoverBluetooth);
        discoverBluetoothLE = settings.boolValue(kKeyLocationDiscoverBluetoothLE, defaultDiscoverBluetoothLE);
        discoverSerialPort = settings.boolValue(kKeyLocationDiscoverSerialPort, defaultDiscoverSerialPort);

        try {
            knownDevices = JSON.parse(settings.value(kKeyLocationKnownDevices, "{}"));
        } catch (e) {
            console.log(logCategory, "Error while parsing settings file.", e);
        }

        var internalFound = false;
        for (var deviceName in knownDevices) {
            // add default internal position source if necessary
            if (deviceName === kInternalPositionSourceName) {
                internalFound = true;
            }

            // clean up device settings if necessary (activationMode was previously connectionMode)
            if (!knownDevices[deviceName].activationMode && knownDevices[deviceName].activationMode !== 0) {
                knownDevices[deviceName].activationMode = kActivationModeAlways;
                delete knownDevices[deviceName].connectionMode;
            }
        }

        if (!internalFound) {
            createInternalSettings();
        } else {
            // update the label of the internal position source provider in case the system
            // language has changed since last using the app
            var receiverSettings = knownDevices[kInternalPositionSourceName];
            if (receiverSettings && receiverSettings["label"] !== kInternalPositionSourceNameTranslated) {
                receiverSettings["label"] = kInternalPositionSourceNameTranslated;
            }

            // this triggers an update of the global settings using the last known receiver
            lastUsedDeviceName = settings.value(kKeyLocationLastUsedDevice, kInternalPositionSourceName)
        }

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log(logCategory, "Writing app settings");

        // Map

        settings.setValue(kKeyMapPlugin, mapPlugin, kDefaultMapPlugin);

        // Accessibility

        settings.setValue(kKeyAccessibilityBoldText, boldText, false);
        settings.setValue(kKeyAccessibilityPlainBackgrounds, plainBackgrounds, true);
        settings.setValue(kKeyAccessibilityHapticFeedback, hapticFeedback, HapticFeedback.supported);

        // Text

        settings.setValue(kKeyFontFamily, fontFamily, defaultFontFamily);
        settings.setValue(kKeyTextScaleFactor, textScaleFactor, 1);

        // Storage

        settings.setValue(kKeyMapLibraryPaths, mapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        settings.setValue(kKeyWkid, wkid, defaultWkid);

        // Location

        settings.setValue(kKeyShowActivationModeSettings, showActivationModeSettings, defaultShowActivationModeSettings);

        settings.setValue(kKeyLocationDiscoverBluetooth, discoverBluetooth, defaultDiscoverBluetooth);
        settings.setValue(kKeyLocationDiscoverBluetoothLE, discoverBluetoothLE, defaultDiscoverBluetoothLE);
        settings.setValue(kKeyLocationDiscoverSerialPort, discoverSerialPort, defaultDiscoverSerialPort);

        settings.setValue(kKeyLocationLastUsedDevice, lastUsedDeviceName, kInternalPositionSourceName);
        settings.setValue(kKeyLocationKnownDevices, JSON.stringify(knownDevices), ({}));

        log();
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "App settings -");

        // Map

        console.log(logCategory, "* mapPlugin:", mapPlugin);

        // Accessibility

        console.log(logCategory, "* boldText:", boldText);
        console.log(logCategory, "* plainBackgrounds:", plainBackgrounds);
        console.log(logCategory, "* hapticFeedback:", hapticFeedback);

        // Text

        console.log(logCategory, "* fontFamily:", fontFamily);
        console.log(logCategory, "* textScaleFactor:", textScaleFactor);

        // Storage

        console.log(logCategory, "* mapLibraryPaths:", mapLibraryPaths);

        // Spatial reference

        console.log(logCategory, "* wkid:", wkid);

        // Location

        console.log(logCategory, "* showActivationModeSettings", showActivationModeSettings);

        console.log(logCategory, "* discoverBluetooth:", discoverBluetooth);
        console.log(logCategory, "* discoverBluetoothLE:", discoverBluetoothLE);
        console.log(logCategory, "* discoverSerialPort:", discoverSerialPort);

        console.log(logCategory, "* locationAlertsVisual:", locationAlertsVisual);
        console.log(logCategory, "* locationAlertsSpeech:", locationAlertsSpeech);
        console.log(logCategory, "* locationAlertsVibrate:", locationAlertsVibrate);

        console.log(logCategory, "* locationMaximumDataAge:", locationMaximumDataAge);
        console.log(logCategory, "* locationMaximumPositionAge:", locationMaximumPositionAge);
        console.log(logCategory, "* locationSensorActivationMode:", locationSensorActivationMode);
        console.log(logCategory, "* locationSensorConnectionType:", locationSensorConnectionType);
        console.log(logCategory, "* locationAltitudeType:", locationAltitudeType);

        console.log(logCategory, "* locationGeoidSeparation:", locationGeoidSeparation);
        console.log(logCategory, "* locationAntennaHeight:", locationAntennaHeight);

        console.log(logCategory, "* lastUsedDeviceName:", lastUsedDeviceName);
        console.log(logCategory, "* lastUsedDeviceLabel:", lastUsedDeviceLabel);

        console.log(logCategory, "* knownDevices:", JSON.stringify(knownDevices, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function createDefaultSettingsObject(connectionType) {
        return {
            "locationAlertsVisual": connectionType === kConnectionTypeInternal ? defaultLocationAlertsVisualInternal : defaultLocationAlertsVisualExternal,
            "locationAlertsSpeech": connectionType === kConnectionTypeInternal ? defaultLocationAlertsSpeechInternal : defaultLocationAlertsSpeechExternal,
            "locationAlertsVibrate": connectionType === kConnectionTypeInternal ? defaultLocationAlertsVibrateInternal : defaultLocationAlertsVibrateExternal,
            "locationMaximumDataAge": defaultLocationMaximumDataAge,
            "locationMaximumPositionAge": defaultLocationMaximumPositionAge,
            "altitudeType": defaultLocationAltitudeType,
            "antennaHeight": defaultLocationAntennaHeight,
            "geoidSeparation": defaultLocationGeoidSeparation,
            "activationMode": defaultLocationSensorActivationMode,
            "connectionType": connectionType
        }
    }

    function createInternalSettings() {
        if (knownDevices) {
            // use the fixed internal provider name as the identifier
            var name = kInternalPositionSourceName;

            if (!knownDevices[name]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeInternal);

                // use the localised internal provider name as the label
                receiverSettings["label"] = kInternalPositionSourceNameTranslated;

                knownDevices[name] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = name;

            return name;
        }

        return "";
    }

    function createExternalReceiverSettings(deviceName, device) {
        if (knownDevices && device && deviceName > "") {

            if (!knownDevices[deviceName]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeExternal);
                receiverSettings["receiver"] = device;
                receiverSettings["label"] = deviceName;

                knownDevices[deviceName] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = deviceName;

            return deviceName;
        }

        return "";
    }

    function createNetworkSettings(hostname, port) {
        if (knownDevices && hostname > "" && port > "") {
            var networkAddress = hostname + ":" + port;

            if (!knownDevices[networkAddress]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeNetwork);
                receiverSettings["hostname"] = hostname;
                receiverSettings["port"] = port;
                receiverSettings["label"] = networkAddress;

                knownDevices[networkAddress] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = networkAddress;

            return networkAddress;
        }

        return "";
    }

    function deleteKnownDevice(deviceName) {
        try {
            delete knownDevices[deviceName];
            receiverListUpdated();
        }
        catch(e){
            console.log(logCategory, e);
        }
    }

    //--------------------------------------------------------------------------
}
