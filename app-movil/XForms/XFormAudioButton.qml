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
import ArcGIS.AppFramework.Speech 1.0

import "../Controls"

StyledImageButton {
    //--------------------------------------------------------------------------

    property alias audio: audio
    readonly property bool tts: AppFramework.urlInfo(audio.source).scheme === "tts"
    property string ttsText

    //--------------------------------------------------------------------------

    width: 25 * AppFramework.displayScaleFactor
    height: 25 * AppFramework.displayScaleFactor
    
    source: tts ? "images/speech-bubble.png" : "images/action_sound_high.png"
    visible: audio.source > "" && (tts ? (Speech.availableEngines.length > 0) : true)

    //--------------------------------------------------------------------------

    Audio {
        id: audio
        source: mediaValue(values, "audio");
    }

    //--------------------------------------------------------------------------

    onClicked: {
        if (audio.source > "") {
            if (tts) {
                console.log("Saying:", ttsText);
                xform.textToSpeech.say(ttsText);
            } else {
                console.log("Playing:", audio.source);
                audio.play();
            }
        }
    }

    //--------------------------------------------------------------------------
}
