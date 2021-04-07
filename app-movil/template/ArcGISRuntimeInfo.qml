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
import Esri.ArcGISRuntime 100.5

Item {
    id: runtimeInfo

    //--------------------------------------------------------------------------

    readonly property string version: ArcGISRuntimeEnvironment.version

    property License license: ArcGISRuntimeEnvironment.license

    readonly property string licenseTypeString: kLicenseTypeStrings[license.licenseType]
    readonly property string licenseLevelString: kLicenseLevelStrings[license.licenseLevel]
    readonly property string licenseStatusString: kLicenseStatusStrings[license.licenseStatus]

    property bool debug: true

    //--------------------------------------------------------------------------

    readonly property var kLicenseTypeStrings: [
        qsTr("Developer"),        // Enums.LicenseTypeDeveloper (0)
        qsTr("Named user"),       // Enums.LicenseTypeNamedUser (1)
        qsTr("License key")       // Enums.LicenseTypeLicenseKey (2)
    ]

    readonly property var kLicenseLevelStrings: [
        qsTr("Developer"),        // Enums.LicenseLevelDeveloper (0)
        qsTr("Lite"),             // Enums.LicenseLevelLite (1)
        qsTr("Basic"),            // Enums.LicenseLevelBasic (2)
        qsTr("Standard"),         // Enums.LicenseLevelStandard (3)
        qsTr("Advanced")          // Enums.LicenseLevelAdvanced (4)
    ]

    readonly property var kLicenseStatusStrings: [
        qsTr("Invalid"),          // Enums.LicenseStatusInvalid (0)
        qsTr("Expired"),          // Enums.LicenseStatusExpired (1)
        qsTr("Login required"),   // Enums.LicenseStatusLoginRequired (2)
        qsTr("Valid")             // Enums.LicenseStatusValid (3)
    ]

    //--------------------------------------------------------------------------

    enabled: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        enabled = true;

        if (debug) {
            log();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(runtimeInfo, true)
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log(logCategory, arguments.callee.name);

        licenseChanged();

        if (debug) {
            log();
        }
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "Version:", ArcGISRuntimeEnvironment.version);

        console.log(logCategory, " - Permanent:", license.permanent);
        console.log(logCategory, " - Type:", license.licenseType, licenseTypeString);
        console.log(logCategory, " - Level:", license.licenseLevel, licenseLevelString);
        console.log(logCategory, " - Status:", license.licenseStatus, licenseStatusString);
        console.log(logCategory, " - Expiry:", license.expiry);
    }

    //--------------------------------------------------------------------------
}
