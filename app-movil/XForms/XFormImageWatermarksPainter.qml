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

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

XFormImagePainter {
    id: imagePainter
    
    //--------------------------------------------------------------------------

    property Instantiator parametersInstantiator
    property var callback
    
    property var location: ({})
    property double compassAzimuth: Number.NaN

    //--------------------------------------------------------------------------

    property var resolve
    property var reject

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var promise = new Promise(function (_resolve, _reject) {
            resolve = _resolve;
            reject = _reject;
        });
        
        for (var i = 0; i < watermarkRepeater.count; i++) {
            var watermark = watermarkRepeater.itemAt(i);
            if (watermark.enabled) {
                promise.then(watermark.start);
            }
        }
        
        promise.then(finalize);
        
        initialize();
    }
    
    //--------------------------------------------------------------------------

    onInitialized: {
        resolve();
    }
    
    //--------------------------------------------------------------------------

    onSaved: {
        console.log(logCategory, "onSaved:", success, path);
        imagePainter.callback();
    }

    //--------------------------------------------------------------------------

    function finalize() {
        saveAfterPainted = true;
        requestPaint();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(imagePainter, true)
    }

    //--------------------------------------------------------------------------

    Repeater {
        id: watermarkRepeater

        model: parametersInstantiator.count

        delegate: XFormWatermarkPainter {
            locale: xform.locale

            readonly property XFormWatermarkParameters watermarkParameters: parametersInstantiator.objectAt(index)

            watermarkText: watermarkParameters.watermarkText
            watermarkColor: watermarkParameters.watermarkColor
            watermarkOutlineColor: watermarkParameters.watermarkOutlineColor
            watermarkOutlineWidth: watermarkParameters.watermarkOutlineWidth
            watermarkShadowColor: watermarkParameters.watermarkHaloColor
            watermarkFont: watermarkParameters.watermarkFont
            watermarkPosition: watermarkParameters.watermarkPosition
            watermarkMargin: watermarkParameters.watermarkMargin
            watermarkImagePath: watermarkParameters.watermarkImagePath
            watermarkImageUrl: watermarkParameters.watermarkImageUrl
            watermarkImageSize: watermarkParameters.watermarkImageSize

            location: imagePainter.location
            compassAzimuth: imagePainter.compassAzimuth

            debug: imagePainter.debug

            property var resolve
            property var reject

            function start() {
                return new Promise(function (_resolve, _reject) {
                    resolve = _resolve;
                    reject = _reject;

                    initialize();
                });
            }

            onInitialized: {
                resolve();
            }
        }
    }

    //--------------------------------------------------------------------------
}
