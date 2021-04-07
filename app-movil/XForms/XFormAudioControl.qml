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
import QtQuick.Layouts 1.12
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

import "../Controls/Singletons"

XFormGroupBox {
    id: audioControl

    //--------------------------------------------------------------------------

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var mediatype

    property FileFolder audioFolder: xform.attachmentsFolder
    property alias audioPath: audioFileInfo.filePath
    property url audioUrl
    property string audioPrefix: "Audio"

    property int recordLimit: 120
    property alias sampleRate: audioRecorder.sampleRate

    property bool editing: false
    readonly property bool readOnly: !editable || binding.isReadOnly || editing
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    readonly property int buttonSize: xform.style.buttonBarSize

    readonly property bool hasAudio: audioUrl > ""
    readonly property bool isRecording: audioRecorder.state == AudioRecorder.RecordingState
    readonly property bool isPlaying: audio.playbackState == Audio.PlayingState || audio.playbackState == Audio.PausedState
    readonly property bool isPlayingPaused: audio.playbackState == Audio.PausedState
    readonly property int audioTime: isRecording
                                     ? (audioRecorder.status == AudioRecorder.RecordingStatus ? audioRecorder.duration : -1)
                                     : isPlaying
                                       ? audio.position
                                       : audio.hasAudio ? audio.duration : -1

    //--------------------------------------------------------------------------

    readonly property url kIconRecord: Icons.icon("microphone")
    readonly property url kIconPlay:  Icons.icon("play", true)
    readonly property url kIconPause: Icons.icon("pause", true)
    readonly property url kIconStop: Icons.icon("square", true)
    readonly property url kIconTrash: Icons.icon("trash")

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        audioPrefix = binding.nodeset;
        var i = audioPrefix.lastIndexOf("/");
        if (i >= 0) {
            audioPrefix = audioPrefix.substr(i + 1);
        }

        console.log("audio prefix:", audioPrefix);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        width: parent.width

        Text {
            Layout.fillWidth: true

            visible: hasAudio || isRecording
            text: timeText(audioTime)

            color: xform.style.labelColor
            font {
                family: xform.style.labelFontFamily
                pointSize: xform.style.inputPointSize
                bold: xform.style.boldText
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    audioInfoText.visible = true;
                }
            }
        }

        XFormButtonBar {
            Layout.alignment: Qt.AlignCenter

            spacing: xform.style.buttonBarSize / 2
            leftPadding: visibleItemsCount > 1 ? spacing : padding
            rightPadding: leftPadding

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: !hasAudio && !readOnly && !isRecording
                source: kIconRecord
                enabled: audioRecorder.available && !isPlaying
                opacity: audioRecorder.available ? 1 : 0.25

                onClicked: {
                    console.log("Start recording");
                    audioRecorder.started = false;
                    audioTimer.elapsed = 0;
                    audioRecorder.record();
                    valueModified(audioControl);
                }

                onPressAndHold: {
                    audioInfoText.visible = true;
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: hasAudio && audio.hasAudio
                source: isPlaying ? kIconPause : kIconPlay
                enabled: audioRecorder.state == AudioRecorder.StoppedState && audioUrl > "" && audio.duration > 0

                onClicked: {
                    if (isPlayingPaused || !isPlaying) {
                        audio.play();
                    } else {
                        audio.pause();
                    }
                }

                onPressAndHold: {
                    audioInfoText.visible = true;
                }
            }

            XFormImageButton {
                id: stopButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: kIconStop
                visible: isRecording || isPlaying

                onClicked: {
                    if (isRecording) {
                        recordLimitTimer.stop();
                        audioTimer.stop();
                        audioRecorder.stop();
                    } else if (isPlaying) {
                        audio.stop();
                    }
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: hasAudio && !readOnly
                source: kIconTrash
                enabled: !(isPlaying || isRecording)

                onClicked: {
                    var name = audioFolder.fileInfo(audioPath).fileName;

                    var panel = confirmPanel.createObject(app, {
                                                              title: qsTr("Confirm Audio Delete"),
                                                              question: qsTr("Are you sure you want to delete %1?").arg(name)
                                                          });

                    panel.show(deleteAudio, undefined);
                }

                function deleteAudio() {
                    audioFolder.removeFile(audioPath);
                    setValue(null);
                    valueModified(audioControl);
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            active: isRecording
            visible: active

            sourceComponent: XFormProgressBar {
                minimumValue: 0
                maximumValue: recordLimitTimer.interval
                value: audioTimer.elapsed
            }
        }

        Loader {
            Layout.fillWidth: true

            active: isPlaying
            visible: active

            sourceComponent: XFormProgressBar {
                minimumValue: 0
                maximumValue: audio.duration
                value: audio.position
            }
        }

        XFormFileRenameControl {
            id: renameControl

            Layout.fillWidth: true

            visible: audioUrl > ""
            fileName: audioFileInfo.fileName
            fileFolder: audioFolder
            readOnly: audioControl.readOnly

            onRenamed: {
                audioPath = audioFolder.filePath(newFileName);
                audioUrl = audioFolder.fileUrl(newFileName);
                updateValue();
            }
        }

        Text {
            id: audioErrorText

            Layout.fillWidth: true

            visible: hasAudio && audio.error > Audio.NoError
            color: xform.style.inputErrorTextColor
            text: "Error %1 %2".arg(audio.error).arg(audio.errorString)

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            id: audioInfoText

            Layout.fillWidth: true

            visible: false

            text: hasAudio
                  ? "%1Kb".arg(Math.round(audioFileInfo.size/1024))
                  : "%1 (%2Hz %3) %4s".arg(audioRecorder.inputDescription).arg(audioRecorder.sampleRate).arg(audioRecorder.containerFormatDescription).arg(recordLimit)
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }
    }

    //--------------------------------------------------------------------------

    AudioRecorder {
        id: audioRecorder

        property bool started: false

        //        outputLocation: audioFolder.path
        //        sampleRate: 22050 // @TODO: Research adding back option. Removed to fix crackling audio issue

        quality: AudioRecorder.NormalQuality
        encodingMode: AudioRecorder.ConstantQualityEncoding

        onStatusChanged: {
            console.log("audioRecorder status:", status);

            switch (status) {
            case AudioRecorder.UnloadedStatus:
            case AudioRecorder.LoadedStatus:
                if (started) {
                    finalizeRecording();
                }
                break;

            case AudioRecorder.RecordingStatus:
                started = true;
                recordLimitTimer.start();
                audioTimer.start();
                console.log("Recording to outputLocation:", audioRecorder.outputLocation);
                break;
            }
        }

        onStateChanged: {
            console.log("audioRecorder state:", state);
        }

        onErrorChanged: {
            console.log("audioRecorder error:", error, "errorString:", errorString);
        }
    }


    Timer {
        id: recordLimitTimer

        interval: recordLimit * 1000
        repeat: false
        triggeredOnStart: false

        onTriggered: {
            console.warn("Record limit reached");
            stopButton.clicked();
        }
    }

    Timer {
        id: audioTimer

        property int elapsed

        interval: 100
        repeat: true

        onTriggered: {
            elapsed += interval;
        }
    }

    function finalizeRecording() {

        console.log("audio actualLocation:", audioRecorder.actualLocation);

        var sourceFileInfo = AppFramework.fileInfo(audioRecorder.actualLocation);
        var fileName = audioPrefix + "-" + AppFramework.createUuidString(2) + "." + sourceFileInfo.suffix;
        var filePath = audioFolder.filePath(fileName);

        if (audioFolder.fileExists(fileName)) {
            console.log("Removing existing audio file:", filePath);
            if (!audioFolder.removeFile(fileName)) {
                console.error("Unable to remove:", filePath);
                return;
            }
        }

        console.log("Renaming recording:", sourceFileInfo.filePath, "to:", filePath);

        if (sourceFileInfo.folder.renameFile(sourceFileInfo.fileName, filePath)) {
            audioFileInfo.filePath = filePath;
            audioUrl = audioFileInfo.url;
            updateValue();
        } else {
            console.error("Error renaming audio file");
        }

        //                        console.log("Copying:", sourceFileInfo.filePath, "to:", filePath);

        //                        if (sourceFileInfo.folder.copyFile(sourceFileInfo.fileName, filePath)) {
        //                            audioFileInfo.filePath = filePath;;
        //                            audioUrl = audioFileInfo.url;
        //                            updateValue();

        //                            if (!sourceFileInfo.folder.removeFile(sourceFileInfo.fileName)) {
        //                                console.error("Error deleting source file:", sourceFileInfo.filePath);
        //                            }
        //                        } else {
        //                            console.error("Error copying audio file");
        //                        }

    }
    //--------------------------------------------------------------------------

    Audio {
        id: audio

        source: audioUrl

        onStatusChanged: {
            console.log("audio status:", status);
        }

        onError: {
            console.log("audio error:", error, "errorString:", errorString, "source:", source);
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: audioFileInfo
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            icon: Icons.bigIcon("trash")
            iconColor: xform.style.deleteIconColor
        }
    }

    //--------------------------------------------------------------------------

    function timeText(ms) {
        if (ms < 0) {
            return "--:--";
        }

        var minutes = Math.floor(ms / 60000);
        var seconds = Math.floor((ms - minutes * 60000) / 1000);

        function zNum(n) {
            return n < 10 ? "0" + n.toString() : n.toString();
        }

        return "%1:%2".arg(zNum(minutes)).arg(zNum(seconds));
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var audioName = audioFileInfo.fileName;
        console.log("audio-updateValue", audioName);

        formData.setValue(bindElement, audioName);

        xform.controlFocusChanged(this, false, bindElement);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log("audio-editMode:", editMode);

            editing = editMode > formData.kEditModeAdd;
        } else {
            editing = false;
        }

        console.log("audio-setValue:", value, "readOnly:", readOnly);

        if (value > "") {
            audioPath = audioFolder.filePath(value);
            audioUrl = audioFolder.fileUrl(value);
        } else {
            audioPath = "";
            audioUrl = "";
        }

        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------
}
