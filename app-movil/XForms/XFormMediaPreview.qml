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
import QtQuick.Layouts 1.12
import QtMultimedia 5.12

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    id: preview

    property var values
    
    color: "#D0000000"

//    Component.onCompleted: {
//        console.log("values", JSON.stringify(values, undefined, 2));
//    }
    
    
    Image {
        id: previewImage

        anchors {
            fill: parent
            margins: 2 * AppFramework.displayScaleFactor
        }

        source: xform.mediaValue(values, "image")
        
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        fillMode: Image.PreserveAspectFit
    }
    
    MouseArea {
        anchors.fill: parent
        
        onClicked: {
        }
        
        onWheel: {
        }
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        StyledImageButton {
            Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            source: ControlsSingleton.backIcon
            padding: ControlsSingleton.backIconPadding
            color: labelText.color

            onClicked: {
                preview.parent.pop();
            }
        }

        XFormText {
            id: labelText

            Layout.fillWidth: true

            text: textValue(values, textValue(values, "", "short"), "long")
            font {
                pointSize: 20
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        XFormAudioButton {
            Layout.preferredWidth: 25 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            audio {
                source: mediaValue(values, "audio")
            }

            ttsText: labelText.text
        }
    }
}
