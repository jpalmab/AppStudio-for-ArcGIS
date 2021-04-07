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
import QtQuick.Controls 2.5
import QtQuick.Controls 1.4 as QC1
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
import QtQuick.Window 2.11
import QtSensors 5.12

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

Rectangle {
    id: page

    property string title: "Camera"
    property FileFolder imagesFolder
    property string imagePrefix: "Image"
    property string makerNote

    property color backgroundColor: "black"
    property color buttonColor: "white"

    readonly property bool isDesktop: Qt.platform.os === "windows" || Qt.platform.os === "osx"
    readonly property bool isPortrait : Screen.orientation === Qt.PortraitOrientation || Screen.orientation === Qt.InvertedPortraitOrientation
    readonly property bool isUWP: Qt.platform.os === "winrt"
    readonly property bool isIOS: Qt.platform.os === "ios"
    readonly property bool isPortraitOnly: isIPhone()

    property int iosVideoOutputOrientation: 270
    property int iosRotationFix: 90

    property size resolution
    property var location
    property double compassAzimuth: NaN

    property bool loading: true
    property bool closing: false
    property bool cameraInitialized: false
    property var newVideoOutput: null
    property var newPreviewImage: null
    property bool exifLoaded: false
    property bool iPhone: false
    property int screenOrientationAtCapture: -1
    property int rotationFix: 0
    property string lastCapturedImagePath: ""

    property bool autoClose: true

    property int defaultCaptureResolution: 1280

    //--------------------------------------------------------------------------

    property int buttonHeight: 35 * AppFramework.displayScaleFactor

    property bool debug: false

    //--------------------------------------------------------------------------

    signal captured(string path, url url)

    //--------------------------------------------------------------------------

    color: backgroundColor

    /*

      Instantiation:
      1. Instantiate a new VideoOutput when the stack view becomes active.
        a. Also start compass and positionSource
      2. Camera.imageCapture.onReady() -> set the camera's resolution

      Capture call stack:
      1. camera.imageCapture.capture() -> capture the image
      2. camera.imageCapture.imageCaptured()
        a. at this point create a new screencapture of VideoOutput and populate a dynamic created image (so VideoOutput can be nulled)
      3. camera.imageCapture.imageSaved()
        a. read saved image's ExifInfo and then establish if it needs a rotation fix
      4. updateExif() --> update and saves file's Exif data
      5. rotate() --> if rotation required, then dynamically create an ImageObject and rotate and save back to path
      6. captured() signal called
        a. calls closeControl();
      7. closeControl()
        a. nulls dynamically created objects
        b. saves settings
        c. closes capture message
        d. pops the view off the stack.

      */

    //--------------------------------------------------------------------------

    XFormCameraSettings {
        id: cameraSettings
    }

    //--------------------------------------------------------------------------

    onCaptured: {
        if (autoClose) {
            closeControl();
        }
    }

    //--------------------------------------------------------------------------

    // @TODO Once code moves to 2.0 StackView, this logic needs to be updated

    QC1.Stack.onStatusChanged:  {

        if (QC1.Stack.status === QC1.Stack.Activating) {
            positionSourceConnection.start();
            compass.start();
        }

        if (QC1.Stack.status === QC1.Stack.Active) {

            iPhone = isIPhone();

            if (!cameraInitialized) {

                // @TODO FIX This "remembering" seems be broken in some devices, appears to work on Windows

                // iPhones seem to require this to occur before the videoOutput is instantiated.
                if (iPhone || isUWP){
                    camera.stop();
                    camera.start();
                }

                newVideoOutput = videoOutputComponent.createObject( videoOutputContainer, { source: camera } );
                newVideoOutput.anchors.top = videoOutputContainer.top;
                newVideoOutput.anchors.bottom = videoOutputContainer.bottom;
                newVideoOutput.anchors.left = videoOutputContainer.left;
                newVideoOutput.anchors.right = videoOutputContainer.right;

/*
                if (iPhone){
                    newVideoOutput.autoOrientation = false;
                }
*/

                if (!iPhone){
                    camera.stop();
                    camera.start();
                }

                initCameraTimer.start();

            }

        }

    }

    //----------------------------------------------------------------------

    Component.onCompleted: {
        Qt.inputMethod.hide();
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        closing = true;

        if (compass.active) {
            compass.stop();
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48 * AppFramework.displayScaleFactor

            RowLayout {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                XFormImageButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight
                    source: "images/back.png"
                    color: buttonColor

                    onClicked: {
                        closeControl();
                    }
                }

                Rectangle {
                    //for spacing when camera combobox is not visible
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "transparent"

                    XFormCameraComboBox {
                        id: cameraComboBox

                        width: Math.min(parent.width, 300 * AppFramework.displayScaleFactor)
                        anchors.verticalCenter: parent.verticalCenter
                        camera: camera

                        onActivated: {
                            cameraComboBox.visible = false;
                            cameraControls.switchButton.visible = true;
                        }
                    }
                }

                XFormCameraControls {
                    id: cameraControls

                    Layout.preferredHeight: parent.height
                    Layout.margins: 5 * AppFramework.displayScaleFactor
                    Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                    Layout.rightMargin: 10 * AppFramework.displayScaleFactor

                    spacing: 25 * AppFramework.displayScaleFactor
                    camera: camera
                    buttonColor: page.buttonColor

                    preferredFlashMode: Camera.FlashOn

                    onSelectCamera: {
                        cameraComboBox.visible = true;
                        switchButton.visible = false;
                    }

                    onUseFlashChanged: {
                        if ( !loading ) {
                            cameraSettings.setUseFlash( useFlash );
                        }
                    }

                    onCameraSwitched: {

                        if (zoomControl.sliderValue > 1) {
                            zoomControl.sliderValue = 1;
                            camera.setZoom(1);
                        }

                        if (newVideoOutput !== null) {

                            // iOS ---------------------------------------------

                            if (isIOS) {
                                newVideoOutput.autoOrientation = false;
                                newVideoOutput.orientation = iosVideoOutputOrientation;
                            }

                            // UWP ---------------------------------------------

                            if (isUWP) {

                                newVideoOutput.autoOrientation = Qt.binding(function(){
                                    if (camera.position === Camera.FrontFace){
                                        return false;
                                    }
                                    else {
                                        return true;
                                    }
                                });
                                newVideoOutput.orientation = Qt.binding(function(){
                                    var currentOrientation = parseInt(Screen.orientation, 10);
                                    if (camera.position === Camera.FrontFace) {
                                        if (currentOrientation === 1 || currentOrientation === 0) {
                                            return camera.orientation + 90;
                                        }
                                        else if (currentOrientation === 2 || currentOrientation === 0) {
                                            return camera.orientation;
                                        }
                                        else if (currentOrientation === 4) {
                                            return camera.orientation - 90;
                                        }
                                        else {
                                            return camera.orientation + 180;
                                        }
                                    }
                                });
                            }

                        }
                        //------------------------------------------------------
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    visible: positionSourceConnection.valid

                    XFormImageButton {
                        id: positionButton

                        anchors.fill: parent

                        source: Icons.icon(positionSourceConnection.active ? "gps-on" : "gps-off")
                        color: buttonColor

                        onClicked: {
                            if (positionSourceConnection.active) {
                                positionSourceConnection.stop();
                            }
                            else {
                                positionSourceConnection.start();
                            }
                        }
                    }

                    QC1.BusyIndicator {
                        anchors.fill: parent
                        running: positionSourceConnection.active
                    }
                }
            }
        }

        Rectangle {
            color: backgroundColor
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: videoOutputContainer
                anchors.fill: parent
            }

            Item {
                id: previewImageContainer
                anchors.fill: parent
            }

            XFormText {
                id: zoomText
                visible: camera.maximumZoom > 1
                z: 100

                anchors {
                    horizontalCenter: videoOutputContainer.horizontalCenter
                    bottom: zoomControlContainer.top
                    bottomMargin: 5 * AppFramework.displayScaleFactor
                }

                text: qsTr("%1x").arg(camera.zoom.toFixed(1))
                color: buttonColor
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                id: zoomControlContainer
                visible: camera.maximumZoom > 1
                width: parent.width * .75
                height: 30 * AppFramework.displayScaleFactor
                z: 100
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 10 * AppFramework.displayScaleFactor
                }

                XFormCameraZoomControl {
                    id: zoomControl
                    anchors.fill: parent
                    minimumZoom: 1
                    maximumZoom: camera.maximumZoom
                    onZoomTo: {
                        camera.setZoom(value);
                    }
                }
            }
        }

        Rectangle {
            color: backgroundColor
            Layout.fillWidth: true
            Layout.preferredHeight: 88 * AppFramework.displayScaleFactor

            XFormImageButton {
                id: captureImageButton
                height: 50 * AppFramework.displayScaleFactor
                width: 50 * AppFramework.displayScaleFactor
                anchors.centerIn: parent

                source: "images/camera-click.png"
                enabled: false
                color: buttonColor
                opacity: enabled ? 1 : 0.4

                onClicked: {
                    screenOrientationAtCapture = parseInt(Screen.orientation, 10);
                    enabled = false;
                    captureImage();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        visible: !cameraInitialized
        width: 60 * AppFramework.displayScaleFactor
        height: 60 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    XFormFaderMessage {
        id: captureMessage
        anchors.centerIn: parent
    }

    //--------------------------------------------------------------------------

    ExifInfo {
        id: exifInfo
    }

    //--------------------------------------------------------------------------

    Compass {
        id: compass

        onReadingChanged: {
            if (connectedToBackend) {
                compassAzimuth = Math.round(reading.azimuth * 100) / 100;
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        listener: "XFormCameraCapture image: %1".arg(imagePrefix)
        positionSourceManager: xform.positionSourceManager

        onNewPosition: {
            updateLocation(position);
        }

        //----------------------------------------------------------------------

        function updateLocation(position) {
            if (page.debug) {
                console.log(logCategory, arguments.callee.name, "position:", JSON.stringify(position));
            }

            var location = JSON.parse(JSON.stringify(position));

            location.datum = "WGS-84";
            location.latitude = position.coordinate.latitude;
            location.longitude  = position.coordinate.longitude;
            location.altitude = position.coordinate.altitude;

            page.location = location;

            positionSourceConnection.stop();
        }
    }

    //--------------------------------------------------------------------------

    Camera {
        id: camera

        property real zoom: opticalZoom * digitalZoom
        property real maximumZoom: maximumOpticalZoom * maximumDigitalZoom
        property int flashMode: flash.mode

        captureMode: Camera.CaptureStillImage
        cameraState: Camera.UnloadedState

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }

        exposure {
            exposureCompensation: Camera.ExposureAuto
        }

        onDeviceIdChanged: {
            if ( !loading && !closing ) {
                cameraSettings.setDeviceId( deviceId );
            }
            iOSCameraPatch(sensor.orientation, camera.position, isPortraitOnly);
        }

        onFlashModeChanged: {
            if ( !loading && !closing  ) {
                cameraSettings.setFlashMode( flashMode );
            }
        }

        onCameraStateChanged: {
            if (cameraState === Camera.ActiveState){
                captureImageButton.enabled = true;
            }
        }

        imageCapture {

            onErrorStringChanged: {
                captureMessage.hide();
                if (camera.imageCapture.errorString > "") {
                    captureMessage.show(camera.imageCapture.errorString, 4000);
                    captureImageButton.enabled = true;
                }
            }

            onImageSaved: {

                page.lastCapturedImagePath = path;

                exifLoaded = exifInfo.load(path);

                var o = exifInfo.imageValue(ExifInfo.ImageOrientation);

                var exifOrientation = o ? o : 1;

                var exifOrientationAngle = 0;
                switch (exifOrientation) {
                case 3:
                    exifOrientationAngle = 180;
                    break;

                case 6:
                    exifOrientationAngle = 270;
                    break;

                case 8:
                    exifOrientationAngle = 90;
                    break;
                }

                page.rotationFix = 0;

                switch (Qt.platform.os) {

                case "android":
                    page.rotationFix = -exifOrientationAngle;
                    break;

                case "ios":
                    page.rotationFix = iosRotationFix;
                    break;

                default:
                    if (newVideoOutput !== null) {
                        page.rotationFix = -newVideoOutput.orientation;
                    }
                    break;
                }

                if (newVideoOutput !== null) {
                    newVideoOutput = null;
                }

                updateExif(path);
            }

            onImageCaptured: {
                if (newVideoOutput !== null) {
                    newVideoOutput.grabToImage(function(result) {
                        newPreviewImage = previewImageComponent.createObject(previewImageContainer);
                        newPreviewImage.width = previewImageContainer.width;
                        newPreviewImage.source = result.url;
                    },
                    Qt.size(videoOutputContainer.width, videoOutputContainer.height));
                }
            }

            onReadyChanged: {

                if (!cameraInitialized) {

                    if (captureResolution <= 0 && camera.imageCapture.supportedResolutions && camera.imageCapture.supportedResolutions.length > 0) {
                        // unrestricted image size requested, so set to maximum resolution

                        var availableResolutions = camera.imageCapture.supportedResolutions;
                        var highestResolution = availableResolutions.pop();
                        availableResolutions = null;

                        var resolutionToQtSize = null;
                        var maximumDimension = highestResolution.width > highestResolution.height
                                ? highestResolution.width
                                : highestResolution.height;

                        if (app.height > app.width) {
                            camera.imageCapture.resolution.height = maximumDimension;
                        }
                        else {
                            camera.imageCapture.resolution.width = maximumDimension;
                        }
                        if (iPhone){
                            camera.viewfinder.resolution = Qt.size(0,0); // Not sure why this works.
                        }
                        else {
                            camera.viewfinder.resolution = camera.imageCapture.resolution;
                        }

                    }
                    else if (page.resolution.width > 0 && page.resolution.height > 0) {
                        // This only gets set via SketchCapture currently, but might need
                        // revision is other components call it in the future with
                        // specific resolution requests.
                        camera.imageCapture.resolution = Qt.size(videoOutputContainer.width * 2, videoOutputContainer.height * 2);
                        if (Qt.platform.os !== "windows") {
                            // Windows doesn't compensate for odd resolutions well.
                            camera.viewfinder.resolution = Qt.size(videoOutputContainer.width, videoOutputContainer.height);
                        }
                    }
                    else {
                        if (app.height > app.width) {
                            camera.imageCapture.resolution.height = defaultCaptureResolution;
                        }
                        else {
                            camera.imageCapture.resolution.width = defaultCaptureResolution;
                        }
                        camera.viewfinder.resolution = camera.imageCapture.resolution;
                    }

                    cameraInitialized = true;
                }
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

            if ( !loading && !closing ) {
                cameraSettings.setZoom( newZoom );
            }
        }
    }

    //----------------------------------------------------------------------

    VideoOutput {
        id: sensor

        autoOrientation: true

        onOrientationChanged: {
            iOSCameraPatch(sensor.orientation, camera.position, isPortraitOnly);
        }
    }

    //----------------------------------------------------------------------

    Component {
        id: imageObjectComponent

        ImageObject {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: videoOutputComponent

        VideoOutput {
            autoOrientation: true
            fillMode: VideoOutput.PreserveAspectFit
            focus : visible // to receive focus and capture key events when visible

            PinchArea {
                id: cameraPinchControl
                property real pinchInitialZoom: 1.0
                property real pinchScale: 1.0

                anchors {
                    fill: parent
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

                    onClicked: {
                        if (camera.lockStatus !== Camera.Unlocked) {
                            camera.unlock();
                        }
                        camera.searchAndLock();
                    }

                    onPressAndHold: {
                        if (camera.lockStatus !== Camera.Unlocked) {
                            camera.unlock();
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: previewImageComponent
        Image {
            fillMode: Image.PreserveAspectFit
        }
    }

    //--------------------------------------------------------------------------

    function updateExif(filePath) {

        var infoChanged = false;

        if (!exifLoaded) {
            exifInfo.load(filePath);
        }

        if (exifInfo.imageValue(ExifInfo.ImageOrientation) !== 1) {
            exifInfo.setImageValue(ExifInfo.ImageOrientation, 1);
            infoChanged = true;
        }

        if (location) {
            exifInfo.setImageValue(ExifInfo.ImageDateTime, new Date());
            exifInfo.setImageValue(ExifInfo.ImageSoftware, app.info.title);
            exifInfo.setImageValue(ExifInfo.ImageXPTitle, title);

            exifInfo.setExtendedValue(ExifInfo.ExtendedDateTimeOriginal, new Date());
            exifInfo.setExtendedValue(ExifInfo.ExtendedDateTimeDigitized, new Date());
            if (makerNote > "") {
                exifInfo.setExtendedValue(ExifInfo.ExtendedMakerNote, makerNote);
            }

            exifInfo.setGpsValue(ExifInfo.GpsDateStamp, location.timestamp);
            exifInfo.setGpsValue(ExifInfo.GpsTimeStamp, location.timestamp);
            exifInfo.setGpsValue(ExifInfo.GpsMapDatum, location.datum);
            exifInfo.gpsLongitude = location.longitude;
            exifInfo.gpsLatitude = location.latitude;

            if (location.altitudeValid)
            {
                exifInfo.gpsAltitude = location.altitude;
            }

            if (location.horizontalAccuracyValid)
            {
                exifInfo.setGpsValue(ExifInfo.GpsHorizontalPositionError, location.horizontalAccuracy);
            }

            if (location.speedValid) {
                exifInfo.setGpsValue(ExifInfo.GpsSpeed, location.speed * 3.6); // Convert M/S to KM/H
                exifInfo.setGpsValue(ExifInfo.GpsSpeedRef, "K");
            }

            if (location.directionValid) {
                exifInfo.setGpsValue(ExifInfo.GpsTrack, location.direction);
                exifInfo.setGpsValue(ExifInfo.GpsTrackRef, "T");
            }

            infoChanged = true;
        }

        if (isFinite(compassAzimuth)) {
            exifInfo.setGpsValue(ExifInfo.GpsImageDirection, compassAzimuth);
            exifInfo.setGpsValue(ExifInfo.GpsImageDirectionRef, "M");

            infoChanged = true;
        }

        if (infoChanged) {
            exifInfo.save(filePath);
            console.log(logCategory, "EXIF info updated:", filePath, "location:", JSON.stringify(location, undefined, 2), "compassAzimuth:", compassAzimuth);
        }

        rotate(true);
    }

    //--------------------------------------------------------------------------

    function rotate(finished) {

        if (rotationFix !== 0) {
            var imageObj = imageObjectComponent.createObject(page, {});
            imageObj.load(lastCapturedImagePath);
            imageObj.rotate(rotationFix);
            var saved = imageObj.save(lastCapturedImagePath);
            if (saved) {
                imageObj.clear();
                imageObj = null;
            }
        }

        if (finished) {
            var url = AppFramework.resolvedPathUrl(lastCapturedImagePath);

            captured(lastCapturedImagePath, url);
        }
    }

    //--------------------------------------------------------------------------

    function zeroPad(num, places) {
        var zero = places - num.toString().length + 1;
        return new Array(+(zero > 0 && zero)).join("0") + num;
    }

    //--------------------------------------------------------------------------

    function captureImage() {
        captureMessage.show(qsTr("Capturing image"), 20000);

        var imageDate = new Date();

        var imageName = imagePrefix + "-" +
                imageDate.getUTCFullYear().toString() +
                zeroPad(imageDate.getUTCMonth() + 1, 2) +
                zeroPad(imageDate.getUTCDate(), 2) +
                "-" +
                zeroPad(imageDate.getUTCHours(), 2) +
                zeroPad(imageDate.getUTCMinutes(), 2) +
                zeroPad(imageDate.getUTCSeconds(), 2) +
                ".jpg";

        camera.imageCapture.captureToLocation(imagesFolder.filePath(imageName));
    }

    //--------------------------------------------------------------------------

    function closeControl() {

        app.settings.setValue("Camera/deviceId", camera.deviceId);

        if (camera.cameraStatus === Camera.ActiveStatus){
            camera.stop();
        }

        if (newVideoOutput !== null) {
            newVideoOutput = null;
        }

        if (newPreviewImage !== null) {
            newPreviewImage = null;
        }

        captureMessage.hide(false);

        parent.pop();
    }

    //--------------------------------------------------------------------------

    function isIPhone() {
        if (Qt.platform.os !== "ios") return false;
        if (!AppFramework.systemInformation.hasOwnProperty("unixMachine")) return false;
        if (!AppFramework.systemInformation.unixMachine.match(/^iPhone/)) return false;
        return true;
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

        if (newVideoOutput) {
            newVideoOutput.autoOrientation = false;
            newVideoOutput.orientation = iosVideoOutputOrientation;
        }
    }


    function initCamera() {

        if (QtMultimedia.availableCameras.length > 0) {
            var cameraDeviceId = camera.deviceId;
            var i = 0;
            for (i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (QtMultimedia.availableCameras[i].deviceId === Camera.BackFace) {
                    cameraDeviceId = QtMultimedia.availableCameras[i].deviceId;
                    break;
                }
            }
            for (i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (QtMultimedia.availableCameras[i].deviceId === cameraSettings.deviceId()) {
                    cameraDeviceId = QtMultimedia.availableCameras[i].deviceId;
                    break;
                }
            }
            camera.deviceId = cameraDeviceId;
        }

        var cameraZoom = cameraSettings.zoom();
        camera.setZoom( cameraZoom );
        zoomControl.updateZoom( cameraZoom );

        var cameraFlashMode = cameraSettings.flashMode();
        camera.flash.mode = cameraFlashMode;

        cameraControls.useFlash = cameraSettings.useFlash();

        iOSCameraPatch(sensor.orientation, camera.position, isPortraitOnly);

        loading = false;
    }

    Timer {
        id: initCameraTimer
        repeat: false
        interval: 100
        running: false
        onTriggered: initCamera()
    }

}
