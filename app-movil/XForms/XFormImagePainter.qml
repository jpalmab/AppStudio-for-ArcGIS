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

Canvas {
    id: canvas
    
    //--------------------------------------------------------------------------

    property var path
    property var url
    property bool debug: false

    property bool saveAfterPainted: false
    property bool loaded
    readonly property bool canvasReady: available && loaded

    //--------------------------------------------------------------------------

    property color kInvalidColor

    //--------------------------------------------------------------------------

    signal initialized()
    signal paintOverlay(var ctx)
    signal saved(string path, bool success)
    signal unloadImages()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "ImagePainter:", path);
        }
    }
    
    //--------------------------------------------------------------------------

    Component.onDestruction: {
        if (debug) {
            console.log(logCategory, "Destroying canvas");
        }

        if (url && isImageLoaded(url)) {
            if (debug) {
                console.log(logCategory, "Unloading:", url);
            }

            unloadImage(url);
        }

        unloadImages();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(canvas, true)
    }

    //--------------------------------------------------------------------------

    onCanvasReadyChanged: {
        if (canvasReady) {
            initialized();
        }
    }

    //--------------------------------------------------------------------------

    onPaint: {
        var ctx = getContext('2d');
        
        if (debug) {
            console.log(logCategory, "onPaint:", ctx);
        }

        paintImage(ctx);
        paintOverlay(ctx);
    }

    //--------------------------------------------------------------------------

    onPainted: {
        if (debug) {
            console.log(logCategory, "onPainted saveAfterPainted:", saveAfterPainted);
        }

        if (saveAfterPainted) {
            Qt.callLater(_save)
        }
    }

    function _save() {
        saveAfterPainted = false;
        saveImage();
    }

    //--------------------------------------------------------------------------

    onImageLoaded: {
        if (debug) {
            console.log(logCategory, "Image loaded:", url);
        }

        if (isImageLoaded(url)) {
            loaded = true;
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    ExifInfo {
        id: exifInfo
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", path);
        }

        exifInfo.load(path);

        imageObject.load(path);
        width = imageObject.width;
        height = imageObject.height;
        imageObject.clear();

        if (debug) {
            console.log(logCategory, arguments.callee.name, "width:", width, "height:", height);
        }

        url = AppFramework.resolvedPathUrl(path);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "imageObject:", imageObject.empty, "width:", width, "height:", height, "url:", url);
        }

        loadImage(url);
    }

    //--------------------------------------------------------------------------

    function drawText(ctx, textInfo) {
        if (debug) {
            console.log(logCategory, "textInfo:", JSON.stringify(textInfo, undefined, 2));
        }

        ctx.save();
        ctx.font = textInfo.font;
        ctx.translate(textInfo.x, textInfo.y);
        
        var alignment = textInfo.alignment;
        
        var a = textInfo.angle;
        if (((a + 450) % 360) > 180) {
            a -= 180;
            if (!alignment) {
                alignmnet = "right";
            }
        }
        
        if (!alignment) {
            alignment = "left";
        }
        
        ctx.textAlign = alignment;
        
        var baseline = textInfo.baseline;
        if (!baseline) {
            baseline = "bottom";
        }
        
        ctx.textBaseline = baseline;
        
        ctx.rotate(a * Math.PI / 180);
        
        ctx.fillStyle = textInfo.color;
        ctx.strokeStyle = textInfo.strokeColor;
        ctx.strokeWidth = textInfo.strokeWidth;

        if (textInfo.shadowBlur) {
            ctx.shadowColor = textInfo.shadowColor;
            ctx.shadowBlur = textInfo.shadowBlur;
        }
        
        ctx.fillText(textInfo.text, 0, 0);
        ctx.strokeText(textInfo.text, 0, 0);

        ctx.restore();
    }
    

    //--------------------------------------------------------------------------

    function drawMultiLineText(ctx, textInfo) {
        var lines = textInfo.text.split("\n");
        if (!lines.length) {
            return;
        }

        var direction = -1;

        switch (textInfo.baseline) {
        case "top":
            direction = 1;
            break;
        }

        function drawLine(line) {
            textInfo.text = line;
            drawText(ctx, textInfo);

            textInfo.y += textInfo.lineHeight * direction;
        }

        if (direction < 0) {
            for (var i = lines.length - 1; i >= 0; i--) {
                drawLine(lines[i]);
            }
        } else {
            lines.forEach(drawLine);
        }
    }

    //--------------------------------------------------------------------------

    function paintImage(ctx) {
        if (debug) {
            console.log(logCategory, "paintImage:", url);
        }

        ctx.fillStyle = "black";
        ctx.fillRect(0, 0, width, height);
        
        ctx.drawImage(url, 0, 0, width, height);
    }

    //--------------------------------------------------------------------------

    function saveGrabbedImage(grabResult) {
        var saveResult = grabResult.saveToFile(path);

        if (saveResult) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "Saving EXIF info");
            }
            saveResult = exifInfo.save(path);
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "Canvas saved:", saveResult);
        }

        saved(path, saveResult);
    }
    
    //--------------------------------------------------------------------------

    function saveImage() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", path);
        }

        canvas.grabToImage(saveGrabbedImage, Qt.size(canvas.width, canvas.height));
    }

    //--------------------------------------------------------------------------
}
