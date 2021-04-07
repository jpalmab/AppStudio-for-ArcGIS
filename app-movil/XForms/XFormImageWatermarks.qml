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

import ArcGIS.AppFramework 1.0

QtObject {
    id: watermarks
    
    //--------------------------------------------------------------------------

    property bool debug: false
    property var element
    property var location


    //--------------------------------------------------------------------------

    property Component watermarksPainterComponent: XFormImageWatermarksPainter {
        debug: watermarks.debug

        parametersInstantiator: watermarkParameters
    }

    //--------------------------------------------------------------------------

    property Instantiator watermarkParameters: Instantiator {
        id: watermarkParameters
        
        model: [
            { name: "watermark", position: "bottomRight" },
            
            { name: "topLeftWatermark", position: "topLeft" },
            { name: "topCenterWatermark", position: "topCenter" },
            { name: "topRightWatermark", position: "topRight" },
            
            { name: "leftCenterWatermark", position: "leftCenter" },
            { name: "centerWatermark", position: "center" },
            { name: "rightCenterWatermark", position: "rightCenter" },
            
            { name: "bottomLeftWatermark", position: "bottomLeft" },
            { name: "bottomCenterWatermark", position: "bottomCenter" },
            { name: "bottomRightWatermark", position: "bottomRight" },
        ]
        
        delegate: XFormWatermarkParameters {
            debug: watermarks.debug
            element: watermarks.element
            
            parameterName: watermarkParameters.model[index].name
            defaultWatermarkPosition: watermarkParameters.model[index].position
        }
    }
    
    //--------------------------------------------------------------------------

    function enabledWatermarksCount() {
        var count = 0;

        for (var i = 0; i < watermarkParameters.count; i++) {
            if (watermarkParameters.objectAt(i).enabled) {
                count++;
            }
        }

        return count;
    }

    //--------------------------------------------------------------------------
    
    function paintWatermarks(owner, path, location, compassAzimuth, callback) {
        if (!enabledWatermarksCount()) {
            Qt.callLater(callback);
            return;
        }

        var watermarksPainter = watermarksPainterComponent.createObject(owner,
                                                                        {
                                                                            path: path,
                                                                            location: location,
                                                                            compassAzimuth: compassAzimuth,
                                                                            callback: callback,
                                                                            x: owner.width
                                                                        });
    }
    
    //--------------------------------------------------------------------------
}
