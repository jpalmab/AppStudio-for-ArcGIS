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
import ArcGIS.AppFramework.Barcodes 1.0

Item {
    id: barcodeSettings

    property string questionType: ""

    property Settings settings: xform.settings.settings
    //property Settings settings: app.settings
    property string kBarcodeDecodeHints: "%1/Barcode/decodeHints".arg(questionType)
    property string kBarcodeCameraDeviceId: "%1/Barcode/Camera/deviceId".arg(questionType)
    property string kBarcodeCameraFlashMode: "%1/Barcode/Camera/flashMode".arg(questionType)
    property string kBarcodeCameraUseFlash: "%1/Barcode/Camera/useFlash".arg(questionType)
    property string kBarcodeCameraZoom: "%1/Barcode/Camera/zoom".arg(questionType)

    property real defaultZoom: 2.0

    property int defaultDecodeHints: BarcodeDecoder.DecodeHintCODE_39 |
                                     BarcodeDecoder.DecodeHintCODE_93 |
                                     BarcodeDecoder.DecodeHintCODE_128 |
                                     BarcodeDecoder.DecodeHintEAN_8 |
                                     BarcodeDecoder.DecodeHintEAN_13 |
                                     BarcodeDecoder.DecodeHintQR_CODE |
                                     BarcodeDecoder.DecodeHintRSS_14 |
                                     BarcodeDecoder.DecodeHintRSS_EXPANDED |
                                     BarcodeDecoder.DecodeHintUPC_A |
                                     BarcodeDecoder.DecodeHintUPC_E |
                                     BarcodeDecoder.DecodeHintUPC_EAN_EXTENSION

    property int defaultFlashMode: Camera.FlashOff

    property bool defaultUseFlash: false

    function decodeHints() {
        return settings.numberValue( kBarcodeDecodeHints, defaultDecodeHints );
    }

    function setDecodeHints( decodeHints ) {
        settings.setValue( kBarcodeDecodeHints, decodeHints );
    }

    function deviceId() {
        return settings.value( kBarcodeCameraDeviceId, "" );
    }

    function setDeviceId( deviceId ) {
        settings.setValue( kBarcodeCameraDeviceId, deviceId );
    }

    function flashMode() {
        return settings.numberValue( kBarcodeCameraFlashMode, defaultFlashMode );
    }

    function setFlashMode( flashMode ) {
        settings.setValue( kBarcodeCameraFlashMode, flashMode );
    }

    function useFlash() {
        return settings.boolValue( kBarcodeCameraUseFlash, defaultUseFlash );
    }

    function setUseFlash( useFlash ) {
        settings.setValue( kBarcodeCameraUseFlash, useFlash );
    }

    function zoom() {
        return settings.numberValue( kBarcodeCameraZoom, defaultZoom );
    }

    function setZoom( zoom ) {
        settings.setValue( kBarcodeCameraZoom, zoom );
    }

}
