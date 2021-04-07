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

import QtQuick 2.12
import QtMultimedia 5.12
import ArcGIS.AppFramework 1.0

Item {
    id: cameraSettings

    //property Settings settings: xform.settings.settings
    property Settings settings: app.settings
    property string kCameraDeviceId: "Camera/deviceId"
    property string kCameraFlashMode: "Camera/flashMode"
    property string kCameraUseFlash: "Camera/useFlash"
    property string kCameraZoom: "Camera/zoom"

    property real defaultZoom: 2.0

    property int defaultFlashMode: Camera.FlashOff

    property bool defaultUseFlash: false

    function deviceId() {
        return settings.value( kCameraDeviceId, "" );
    }

    function setDeviceId( deviceId ) {
        settings.setValue( kCameraDeviceId, deviceId );
    }

    function flashMode() {
        return settings.numberValue( kCameraFlashMode, defaultFlashMode );
    }

    function setFlashMode( flashMode ) {
        settings.setValue( kCameraFlashMode, flashMode );
    }

    function useFlash() {
        return settings.boolValue( kCameraUseFlash, defaultUseFlash );
    }

    function setUseFlash( useFlash ) {
        settings.setValue( kCameraUseFlash, useFlash );
    }

    function zoom() {
        return settings.numberValue( kCameraZoom, defaultZoom );
    }

    function setZoom( zoom ) {
        settings.setValue( kCameraZoom, zoom );
    }

}
