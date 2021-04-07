/* Copyright 2015 Esri
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

import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0

Rectangle {

    id: barcodeScanView

    property alias useFlash: cameraControls.useFlash

    property var formElement
    property bool loading: true
    property alias camera: camera
    property alias decodeHints: barcodeFilter.decodeHints // TODO bug workaround
    property bool debugMode: false
    property int retryDuration: 3000
    property int iosVideoOutputOrientation: 0
    property int iosRotationFix: 0
    property bool isPortraitOnly: isIPhone()

    signal codeScanned(string code, int codeType, string codeTypeString)
    signal selectCamera()

    implicitWidth: 100
    implicitHeight: 100

    color: "black"

    onUseFlashChanged: {
        if ( !loading ) {
            barcodeSettings.setUseFlash( useFlash );
        }
    }

    //--------------------------------------------------------------------------

    XFormBarcodeSettings {
        id: barcodeSettings

        questionType: formElement["@ref"] || ""
    }

    VideoOutput {
        id: sensor
        width: 1
        height: 1
        visible: false
        autoOrientation: true
        onOrientationChanged: iOSCameraPatch( sensor.orientation, camera.position, isPortraitOnly );
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: initCameraTimer.start()

    //--------------------------------------------------------------------------

    Timer {
        id: initCameraTimer

        running: false
        repeat: false
        interval: 100

        onTriggered: initCamera()
    }

    //--------------------------------------------------------------------------

    Timer {
        id: autoLockTimer

        running: false
        repeat: false
        interval: 1000

        onTriggered: {
            if ( camera.lockStatus !== Camera.Unlocked ) {
                camera.unlock();
            }
            camera.searchAndLock();
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        camera.stop();
    }

    //--------------------------------------------------------------------------

    Camera {
        id: camera

        property real zoom: opticalZoom * digitalZoom
        property real maximumZoom: maximumOpticalZoom * maximumDigitalZoom
        property int flashMode: flash.mode

        cameraState: Camera.CaptureStillImage

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }

        exposure {
            exposureCompensation: Camera.ExposureAuto
        }

        viewfinder.resolution: Qt.size(640, 480)

        onDeviceIdChanged: {
            debugMode = false;

            if ( !loading ) {
                barcodeSettings.setDeviceId( deviceId );
            }
            iOSCameraPatch( sensor.orientation, camera.position, isPortraitOnly );
        }

        onFlashModeChanged: {
            if ( !loading ) {
                barcodeSettings.setFlashMode( flashMode );
            }
        }

        function selectFocusMode() {
            if (focus.isFocusModeSupported(Camera.FocusContinuous)) {
                focus.focusMode = Camera.FocusContinuous;
            } else if (focus.isFocusModeSupported(Camera.FocusAuto)) {
                focus.focusMode = Camera.FocusAuto;
            }

            if (focus.isFocusPointModeSupported(Camera.FocusPointCenter)) {
                focus.focusPointMode = Camera.FocusPointCenter;
            }
        }

        function setZoom(newZoom) {
            newZoom = Math.max(Math.min(newZoom, maximumZoom), 1.0);

            var newOpticalZoom = 1.0;
            var newDigitalZoom = 1.0;

            if (newZoom > camera.maximumOpticalZoom) {
                newOpticalZoom = camera.maximumOpticalZoom;
                newDigitalZoom = newZoom / camera.maximumOpticalZoom;
            } else {
                newOpticalZoom = newZoom;
                newDigitalZoom = 1.0;
            }

            if (camera.maximumOpticalZoom > 1.0) {
                camera.opticalZoom = newOpticalZoom;
            }

            if (camera.maximumDigitalZoom > 1.0) {
                camera.digitalZoom = newDigitalZoom;
            }

            if ( !loading ) {
                barcodeSettings.setZoom( newZoom );
            }
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top controls --------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

            XFormCameraControls {
                id: cameraControls

                anchors {
                    fill: parent
                }

                camera: barcodeScanView.camera
                preferredFlashMode: Camera.FlashVideoLight

                onSelectCamera: {
                    barcodeScanView.selectCamera();
                }
            }
        }

        // Video output area ---------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            VideoOutput {
                id: videoOutput

                anchors.fill: parent
                source: camera
                autoOrientation: true
                filters: [ barcodeFilter ]

                Item {
                    id: captureFrame
                    property rect captureFrameRect: getCaptureFrameRect(videoOutput.contentRect)
                    x: captureFrameRect.x
                    y: captureFrameRect.y
                    width: captureFrameRect.width
                    height: captureFrameRect.height

                    function getCaptureFrameRect(captureFrameRect) {
                        var cx = captureFrameRect.x + captureFrameRect.width / 2;
                        var cy = captureFrameRect.y + captureFrameRect.height / 2;

                        var newWidth = captureFrameRect.width;
                        var newHeight = captureFrameRect.height;

                        var aspectWidth = 1;
                        var aspectHeight = 1;

                        var hasPDF417 = ( ( barcodeFilter.decodeHints & BarcodeDecoder.DecodeHintPDF_417) !== 0 );

                        if ( hasPDF417 ) {
                            aspectWidth = 50;
                            aspectHeight = 18;
                        }

                        if ( newWidth < newHeight && aspectWidth > aspectHeight ) {
                            var tmp = aspectWidth;
                            aspectWidth = aspectHeight;
                            aspectHeight = tmp;
                        }

                        if (newWidth * aspectHeight > newHeight * aspectWidth) {
                            newWidth = newHeight * aspectWidth / aspectHeight;
                        } else {
                            newHeight = newWidth * aspectHeight / aspectWidth;
                        }

                        newWidth = newWidth * 95 / 100;
                        newHeight = newHeight * 95 / 100;
                        var newX = cx - newWidth / 2;
                        var newY = cy - newHeight / 2;
                        return Qt.rect(newX, newY, newWidth, newHeight);
                    }

                }

                Item {
                    anchors.fill: captureFrame
                    anchors.margins: -captureFrame.width / 25

                    XFormBarcodeScanMarker {
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                    }

                    XFormBarcodeScanMarker {
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        rotation: 90
                    }

                    XFormBarcodeScanMarker {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                        }
                        rotation: 270
                    }

                    XFormBarcodeScanMarker {
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                        rotation: 180
                    }
                }

                Repeater {
                    visible: debugMode
                    model: camera.focus.focusZones

                    Rectangle {
                        border {
                            width: 2
                            color: status == Camera.FocusAreaFocused ? "green" : "white"
                        }
                        color: "transparent"

                        // Map from the relative, normalized frame coordinates
                        property variant mappedRect: videoOutput.mapNormalizedRectToItem(area)

                        x: mappedRect.x
                        y: mappedRect.y
                        width: mappedRect.width
                        height: mappedRect.height
                    }
                }

                PinchArea {
                    property real pinchInitialZoom: 1.0
                    property real pinchScale: 1.0

                    anchors {
                        fill: captureFrame
                    }

                    onPinchStarted: {
                        pinchInitialZoom = camera.zoom;
                        pinchScale = 1.0;
                    }

                    onPinchUpdated: {
                        pinchScale = pinch.scale;
                        camera.setZoom(pinchInitialZoom * pinchScale);
                        zoomControl.updateZoom(pinchInitialZoom * pinchScale);
                    }

                    MouseArea {
                        anchors {
                            fill: parent
                        }

                        enabled: camera.cameraStatus == Camera.ActiveStatus

                        hoverEnabled: true
                        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: toggleFocus()
                        onPressAndHold: toggleFocus()

                        function toggleFocus() {
                            if (camera.lockStatus !== Camera.Unlocked) {
                                camera.unlock();
                            } else {
                                camera.searchAndLock();
                            }
                        }
                    }
                }

                MouseArea {
                    width: 50 * AppFramework.displayScaleFactor
                    height: width
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }

                    onClicked: {
                        if (debugMode) {
                            camera.unlock();
                        }
                    }

                    onPressAndHold: {
                        debugMode = !debugMode;
                        scanMessage.show(debugMode ? "Debug Mode On" : "Debug Mode Off", undefined, "red");
                    }
                }

                XFormText {
                    x: 0
                    y: (videoOutput.contentRect.y + videoOutput.contentRect.height - height ) - 10 * AppFramework.displayScaleFactor
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("%1x").arg(camera.zoom.toFixed(1))
                    color: "black"
                }

            }

        }

        // Bottom tools --------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

            XFormCameraZoomControl {
                id: zoomControl
                visible: camera.maximumZoom > 1
                height: 30 * AppFramework.displayScaleFactor
                width: parent.width * .75
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                minimumZoom: 1
                maximumZoom: camera.maximumZoom > 8 ? 8 : camera.maximumZoom
                onZoomTo: {
                    camera.setZoom(value)
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormCameraDebugInfo {
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        visible: debugMode
        camera: camera
    }

    //--------------------------------------------------------------------------



    /*
    XFormCameraZoomControl {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width : 100 * AppFramework.displayScaleFactor

        currentZoom: camera.digitalZoom
        maximumZoom: Math.min(4.0, camera.maximumDigitalZoom)
        onZoomTo: camera.setDigitalZoom(value)
    }
    */

    //--------------------------------------------------------------------------

    XFormFaderMessage {
        id: scanMessage

        anchors.centerIn: parent
    }

    //--------------------------------------------------------------------------

    BarcodeFilter {
        id: barcodeFilter

        orientation: videoOutput.orientation

        onDecoded: {
            console.log(barcode, barcodeType, barcodeTypeString)

            if (debugMode) {
                scanMessage.hide();
                scanMessage.show(qsTr("%1 (%2)").arg(barcode).arg(barcodeTypeString));
                return;
            }

            codeScanned(barcode, barcodeType, barcodeTypeString);
        }

        onDecodeHintsChanged: {
            if ( !loading  ) {
                barcodeSettings.setDecodeHints( decodeHints );
            }
        }
    }

    //--------------------------------------------------------------------------

    function iOSCameraPatch(sensorOrientation, cameraPosition, isPortraitOnly) {
        if (Qt.platform.os !== "ios") {
            return;
        }

        if (cameraPosition === Camera.FrontFace) {
            if (!isPortraitOnly || (sensorOrientation === 0 || sensorOrientation === 180)) {
                iosVideoOutputOrientation = (sensorOrientation + 90) % 360;
            }
            iosRotationFix = (sensorOrientation + 90) % 360;
        } else {
            if (!isPortraitOnly || (sensorOrientation === 0 || sensorOrientation === 180)) {
                iosVideoOutputOrientation = (sensorOrientation + 270) % 360;
            }
            iosRotationFix = (360 + 90 - sensorOrientation) % 360;
        }

        videoOutput.autoOrientation = false;
        videoOutput.orientation = iosVideoOutputOrientation;
    }

    //--------------------------------------------------------------------------

    function isIPhone() {
        if (Qt.platform.os !== "ios") return false;
        if (!AppFramework.systemInformation.hasOwnProperty("unixMachine")) return false;
        if (!AppFramework.systemInformation.unixMachine.match(/^iPhone/)) return false;
        return true;
    }

    //--------------------------------------------------------------------------

    function initCamera() {
        if (QtMultimedia.availableCameras.length > 0) {
            var cameraDeviceId = camera.deviceId;
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (QtMultimedia.availableCameras[i].position === Camera.BackFace) {
                    cameraDeviceId = QtMultimedia.availableCameras[i].deviceId;
                    break;
                }
            }
            cameraDeviceId = barcodeSettings.deviceId() || cameraDeviceId;
            camera.deviceId = cameraDeviceId;
            camera.start();

            camera.flash.mode = barcodeSettings.flashMode();
            cameraControls.useFlash = barcodeSettings.useFlash();

            var cameraZoom = barcodeSettings.zoom();
            camera.setZoom( cameraZoom );
            zoomControl.updateZoom( cameraZoom );

            if ( Qt.platform.os === "android" ) {
                autoLockTimer.start();
            }

            iOSCameraPatch( sensor.orientation, camera.position, isPortraitOnly );
        }

        barcodeFilter.decodeHints = barcodeSettings.decodeHints() | BarcodeDecoder.DecodeHintTryHarder;

        Qt.inputMethod.hide();

        loading = false;
    }

    //--------------------------------------------------------------------------

}
