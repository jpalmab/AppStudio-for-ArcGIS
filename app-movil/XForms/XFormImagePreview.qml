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

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

Rectangle {
    id: preview

    //--------------------------------------------------------------------------

    property alias imageUrl: previewImage.source

    //--------------------------------------------------------------------------

    color: "#D0000000"
    
    //--------------------------------------------------------------------------

    Image {
        id: previewImage

        anchors {
            fill: parent
            margins: 2 * AppFramework.displayScaleFactor
        }

        autoTransform: true
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        fillMode: Image.PreserveAspectFit
    }
    
    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
        }
        
        onWheel: {
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10 * AppFramework.displayScaleFactor
        }

        XFormButtonBar {
            padding: 0

            XFormImageButton {
                implicitWidth: xform.style.titleButtonSize
                implicitHeight: xform.style.titleButtonSize

                source: ControlsSingleton.closeIcon
                padding: ControlsSingleton.closeIconPadding

                onClicked: {
                    preview.parent.pop();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
