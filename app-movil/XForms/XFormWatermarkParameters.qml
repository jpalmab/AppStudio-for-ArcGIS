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

import "XForm.js" as XFormJS

XFormControlParameters {
    
    //--------------------------------------------------------------------------

    property bool enabled: watermark > "" || watermarkImagePath > ""

    property string parameterName
    property string watermark
    property string watermarkText
    property color watermarkColor
    property color watermarkOutlineColor
    property int watermarkOutlineWidth
    property color watermarkHaloColor
    property string watermarkPosition
    property font watermarkFont
    property int watermarkMargin
    property string watermarkImagePath
    property url watermarkImageUrl
    property int watermarkImageSize
    
    //--------------------------------------------------------------------------

    readonly property color kDefaultWatermarkColor: "#00b2ff" //"#FF9933"
    readonly property int kDefaultWatermarkSize: 15
    property string defaultWatermarkPosition: "bottomRight"

    property color kInvalidColor

    readonly property string kUrlPrefx: "watermark://?text="

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        bind(undefined, "watermark", parameterName);
    }
    
    //--------------------------------------------------------------------------

    onWatermarkChanged: {
        if (debug) {
            console.log(logCategory, parameterName, "=", JSON.stringify(watermark));
        }
        
        resetWatermark();
        
        if (!(watermark > "")) {
            watermarkText = "";
            return;
        }

        // Escape # -> %23

        var watermarkDef = watermark.replace(/(?:=#(?:(?:[0-9a-f]{6})|(?:[0-9a-f]{8})|(?:[0-9a-f]{3})|(?:[0-9a-f]{4})))/gim,
                                             function (text) {
                                                 return text.replace("#", "%23");
                                             });

        var urlInfo = AppFramework.urlInfo("");
        urlInfo.fromUserInput(watermarkDef);

        if (urlInfo.isValid && !urlInfo.hasQuery) { // Special case if only text is supplied
            urlInfo.fromUserInput(kUrlPrefx + watermarkDef);
        }

        if (!urlInfo.isValid) {
            console.warn(logCategory, "Invalid url:", watermarkDef);
            var url = kUrlPrefx + watermarkDef;
            urlInfo.fromUserInput(url);
            if (!urlInfo.isValid) {
                console.warn(logCategory, "Invalid url:", url);
                watermarkText = watermarkDef
                return;
            }
            console.log(logCategory, "watermark url:", url);
        }
        
        console.log(logCategory, "watermark url:", urlInfo.url);
        
        if (debug) {
            console.log(logCategory, "watermark host:", JSON.stringify(urlInfo.host), "queryParameters:", JSON.stringify(urlInfo.queryParameters));
        }
        
        var parameters = urlInfo.queryParameters;
        var keys = Object.keys(parameters);
        
        keys.forEach(function (key) {
            var value = parameters[key];
            
            if (debug) {
                console.log(logCategory, "key:", JSON.stringify(key), "=", JSON.stringify(value));
            }
            
            switch (key) {
            case "text":
                watermarkText = value;
                break;
                
            case "color" :
                watermarkColor = value;
                if (watermarkColor === kInvalidColor) {
                    watermarkColor = kDefaultWatermarkColor;
                }
                break;
                
            case "outlineColor" :
                watermarkOutlineColor = value;
                break;
                
            case "outlineWidth":
                watermarkOutlineWidth = value;
                break;
                
            case "haloColor" :
                watermarkHaloColor = value;
                break;
                
            case "font":
                watermarkFont.family = value;
                break;
                
            case "position":
                watermarkPosition = value;
                break;
                
            case "margin":
                watermarkPosition = value;
                break;
                
            case "size":
                watermarkFont.pixelSize = Math.max(Math.round(XFormJS.toNumber(value), kDefaultWatermarkSize), 10);
                break;
                
            case "bold":
                watermarkFont.bold = XFormJS.toBoolean(value);
                break;
                
            case "italic":
                watermarkFont.italic = XFormJS.toBoolean(value);
                break;
                
            case "image":
                watermarkImagePath = xform.mediaFolder.filePath(value);
                watermarkImageUrl = xform.mediaFolder.fileUrl(value);
                break;
                
            case "imageSize":
                watermarkImageSize = value;
                break;
            }
        });
    }
    
    //--------------------------------------------------------------------------

    function resetWatermark() {
        watermarkText = "";
        watermarkFont = xform.style.implicitText.font;
        watermarkFont.pixelSize = kDefaultWatermarkSize;
        watermarkColor = kDefaultWatermarkColor;
        watermarkOutlineColor = kInvalidColor;
        watermarkOutlineWidth = 1;
        watermarkHaloColor = kInvalidColor;
        watermarkPosition = defaultWatermarkPosition;
        watermarkMargin = 5;
        watermarkImagePath = "";
        watermarkImageUrl = "";
        watermarkImageSize = 0;
    }

    //--------------------------------------------------------------------------
}
