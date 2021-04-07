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

import QtQuick 2.11
import QtLocation 5.9

import ArcGIS.AppFramework 1.0

MapQuickItem {
    id: marker

    //--------------------------------------------------------------------------

    property alias image: markerImage
    property real imageScale: defaultImageScale
    property real anchorX: defaultAnchorX
    property real anchorY: defaultAnchorY

    property url defaultImageSource: "images/stickPin.png"
    property real defaultImageScale: 1
    property real defaultAnchorX: 0.5
    property real defaultAnchorY: 1

    //--------------------------------------------------------------------------

    anchorPoint {
        x: markerImage.width * anchorX
        y: markerImage.height * anchorY
    }
    
    sourceItem: Image {
        id: markerImage
        
        width: 50 * AppFramework.displayScaleFactor * imageScale
        height: width
        source: defaultImageSource
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
    }

    //--------------------------------------------------------------------------

    function reset() {
        image.source = defaultImageSource;
        imageScale = defaultImageScale;
        anchorX = defaultAnchorX;
        anchorY = defaultAnchorY
    }

    //--------------------------------------------------------------------------

    function initialize(sourceMarker) {
        if (!sourceMarker) {
            reset();
            return;
        }

        image.source = sourceMarker.image.source;
        imageScale = sourceMarker.imageScale;
        anchorX = sourceMarker.anchorX;
        anchorY = sourceMarker.anchorY
    }

    //--------------------------------------------------------------------------
}
