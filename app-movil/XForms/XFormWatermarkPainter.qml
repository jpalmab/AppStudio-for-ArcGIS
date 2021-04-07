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
import QtPositioning 5.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0

import "SketchControl/SketchLib.js" as SketchLib
import "XForm.js" as XFormJS

Item {
    id: watermarkPainter

    //--------------------------------------------------------------------------

    readonly property XFormImagePainter painter: parent
    property bool debug: false

    //--------------------------------------------------------------------------

    property var locale
    property string watermarkText
    property font watermarkFont: xform.style.implicitText.font
    property color watermarkColor: "#00b2ff"
    property color watermarkOutlineColor: "white"
    property int watermarkOutlineWidth: 1
    property color watermarkShadowColor: SketchLib.contrastColor(watermarkOutlineColor)
    property int watermarkShadowBlur: 20
    property string watermarkPosition: kPositionBottomRight
    property int watermarkMargin: 5
    property url watermarkImageUrl
    property string watermarkImagePath
    property int watermarkImageSize: 0

    property var location: ({})
    property double compassAzimuth: Number.NaN

    //--------------------------------------------------------------------------

    property color kInvalidColor

    readonly property string kValueLocationPrefix: "location."

    readonly property string kValueLatitude: "latitude"
    readonly property string kValueLongitude: "longitude"
    readonly property string kValueAltitude: "altitude"
    readonly property string kValueLatitudeLongitude: "latitude longitude"
    readonly property string kValueLongitudeLatitude: "longitude latitude"
    readonly property string kValueMGRS: "mgrs"
    readonly property string kValueUSNG: "usng"
    readonly property string kValueUTM: "utm"
    readonly property string kValueUPS: "ups"

    readonly property string kValueAccuracy: "accuracy"
    readonly property string kValueHorizontalAccuracy: "horizontalAccuracy"
    readonly property string kValueSpeed: "speed"
    readonly property string kValueDirection: "direction"
    readonly property string kValueCompass: "compass"

    readonly property string kValueDate: "date"
    readonly property string kValueDateTime: "datetime"
    readonly property string kValueTime: "time"
    readonly property string kValueTimeStamp: "timestamp"

    readonly property string kFormatDD: "dd"
    readonly property string kFormatDMS: "dms"
    readonly property string kFormatDDM: "ddm"

    readonly property string kFormatLong: "long"
    readonly property string kFormatShort: "short"
    readonly property string kFormatNarrow: "narrow"

    readonly property string kPositionTopLeft: "topleft"
    readonly property string kPositionTopCenter: "topcenter"
    readonly property string kPositionTopRight: "topright"
    readonly property string kPositionBottomLeft: "bottomleft"
    readonly property string kPositionBottomCenter: "bottomcenter"
    readonly property string kPositionBottomRight: "bottomright"
    readonly property string kPositionLeftCenter: "leftcenter"
    readonly property string kPositionCenter: "center"
    readonly property string kPositionRightCenter: "rightcenter"

    property string noValue: "--"

    //--------------------------------------------------------------------------

    property string text
    property int drawX: 0
    property int drawY: 0
    property int drawDirectionX: 0
    property int drawDirectionY: 0
    property string textAlignment
    property string textBaseline

    property bool watermarkReady: false

    property bool useImageObject: false

    //--------------------------------------------------------------------------

    signal initialized();

    //--------------------------------------------------------------------------

    anchors.fill: parent

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log(logCategory, "Completed text:", watermarkText, "image:", watermarkImagePath)
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(watermarkPainter, true)
    }

    //--------------------------------------------------------------------------

    Connections {
        target: painter

        onImageLoaded: {
            if (!watermarkImageObject.empty && painter.isImageLoaded(watermarkImageObject.url)) {
                if (debug) {
                    console.log(logCategory, "Image loaded:", painter.isImageLoaded(watermarkImageObject.url), watermarkImageObject.url, "path:", watermarkImagePath);
                }

                ready(true);
            }
        }

        onUnloadImages: {
            if (!watermarkImageObject.empty && painter.isImageLoaded(watermarkImageObject.url)) {
                if (debug) {
                    console.log(logCategory, "Unloading:", watermarkImageObject.url, "path:", watermarkImagePath);
                }

                painter.unloadImage(watermarkImageObject.url);
            }
        }

        onPaintOverlay: {
            if (watermarkReady) {
                paintWatermark(ctx);
            }
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: watermarkImageObject
    }

    Image {
        id: watermarkImage

        source: watermarkImageUrl
        asynchronous: false
        visible: false
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", watermarkText);
        }

        text = substitutePlaceholders(watermarkText);
        if (!loadWatermarkImage()) {
            ready();
        }
    }

    //--------------------------------------------------------------------------

    function ready(callLater) {
        if (watermarkReady) {
            console.warn(logCategory, arguments.callee.name, "Already ready");
            return;
        }

        if (callLater) {
            Qt.callLater(_ready);
        } else {
            _ready();
        }
    }

    function _ready() {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", text, "image:", watermarkImagePath);
        }

        watermarkReady = true;
        initialized();
    }

    //--------------------------------------------------------------------------

    function paintWatermark(ctx) {
        initializeDrawPosition();

        if (useImageObject) {
            if (!watermarkImageObject.empty) {
                paintWatermarkImage(ctx);
            }
        } else {
            if (watermarkImage.source > "") {
                paintWatermarkImage(ctx);
            }
        }

        if (text > "") {
            paintWatermarkText(ctx);
        }
    }

    //--------------------------------------------------------------------------

    function initializeDrawPosition() {
        switch (watermarkPosition.toLowerCase()) {
        case kPositionLeftCenter:
            textAlignment = "left";
            textBaseline = "middle";
            drawX = watermarkMargin;
            drawY = height / 2;
            drawDirectionX = 1;
            drawDirectionY = 0;
            break;

        case kPositionCenter:
            textAlignment = "center";
            textBaseline = "middle";
            drawX = width / 2;
            drawY = height / 2;
            drawDirectionX = 0;
            drawDirectionY = 0;
            break;

        case kPositionRightCenter:
            textAlignment = "right";
            textBaseline = "middle";
            drawX = width - watermarkMargin;
            drawY = height / 2;
            drawDirectionX = -1;
            drawDirectionY = 0;
            break;

        case kPositionTopLeft:
            textAlignment = "left";
            textBaseline = "top";
            drawX = watermarkMargin;
            drawY = watermarkMargin;
            drawDirectionX = 1;
            drawDirectionY = 1;
            break;

        case kPositionTopCenter:
            textAlignment = "center";
            textBaseline = "top";
            drawX = width / 2;
            drawY = watermarkMargin;
            drawDirectionX = 0;
            drawDirectionY = 1;
            break;

        case kPositionTopRight:
            textAlignment = "right";
            textBaseline = "top";
            drawX = width - watermarkMargin;
            drawY = watermarkMargin;
            drawDirectionX = -1;
            drawDirectionY = 1;
            break;

        case kPositionBottomLeft:
            textAlignment = "left";
            textBaseline = "bottom";
            drawX = watermarkMargin;
            drawY = height - watermarkMargin;
            drawDirectionX = 1;
            drawDirectionY = -1;
            break;

        case kPositionBottomCenter:
            textAlignment = "center";
            textBaseline = "bottom";
            drawX = width / 2
            drawY = height - watermarkMargin;
            drawDirectionX = 0;
            drawDirectionY = -1;
            break;

        case kPositionBottomRight:
        default:
            textAlignment = "right";
            textBaseline = "bottom";
            drawX = width - watermarkMargin;
            drawY = height - watermarkMargin;
            drawDirectionX = -1;
            drawDirectionY = -1;
            break;
        }
    }

    //--------------------------------------------------------------------------

    function paintWatermarkText(ctx) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", text);
        }
        
        var textInfo = {
            text: text,
            x: drawX,
            y: drawY,
            alignment: textAlignment,
            baseline: textBaseline,
            font: SketchLib.toFontString(watermarkFont),
            lineHeight: Math.round(watermarkFont.pixelSize * 1.1),
            color: watermarkColor,
            strokeColor: watermarkOutlineColor === kInvalidColor ? watermarkColor : watermarkOutlineColor,
            strokeWidth: watermarkOutlineWidth,
            shadowColor: watermarkShadowColor === kInvalidColor ? SketchLib.contrastColor(watermarkColor) : watermarkShadowColor,
            shadowBlur: watermarkShadowBlur
        }
        
        //painter.drawText(ctx, textInfo);
        painter.drawMultiLineText(ctx, textInfo);
    }

    //--------------------------------------------------------------------------

    function loadWatermarkImage() {
        if (!useImageObject) {
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "path:", watermarkImagePath);
        }

        if (!(watermarkImagePath > "")) {
            return;
        }

        if (!watermarkImageObject.load(watermarkImagePath)) {
            console.error(logCategory, arguments.callee.name, "path:", watermarkImagePath);
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "empty:", watermarkImageObject.empty, "url:", watermarkImageObject.url);
        }

        painter.loadImage(watermarkImageObject.url);

        return true;
    }

    //--------------------------------------------------------------------------

    function paintWatermarkImage(ctx) {
        if (useImageObject) {
            if (!painter.isImageLoaded(watermarkImageObject.url)) {
                console.error(logCategory, arguments.callee.name, "image not loaded:", watermarkImageObject.url, "path:", watermarkImagePath);
                return;
            }
        } else {
            if (watermarkImage.status !== Image.Ready) {
                console.error(logCategory, arguments.callee.name, "image not ready:", watermarkImage.status, watermarkImage.source);
                return;
            }
        }


        var imageWidth;
        var imageHeight;

        if (useImageObject) {
            imageWidth = watermarkImageObject.width;
            imageHeight = watermarkImageObject.height;
        } else {
            imageWidth = watermarkImage.sourceSize.width;
            imageHeight = watermarkImage.sourceSize.height;
        }

        if (watermarkImageSize > 0) {
            var aspectRatio = imageWidth / imageHeight;

            if (aspectRatio > 1) {
                imageWidth = watermarkImageSize;
                imageHeight = Math.round(imageWidth / aspectRatio);
            } else {
                imageHeight = watermarkImageSize;
                imageWidth = Math.round(imageHeight * aspectRatio);
            }
        }

        var imageX = drawX;
        var imageY = drawY;

        if (drawDirectionX < 0) {
            imageX -= imageWidth;
        } else if (!drawDirectionX) {
            imageX -= imageWidth / 2;
            if (drawDirectionY) {
                drawY += drawDirectionY * (imageHeight + watermarkMargin);
            } else {
                drawY += imageHeight / 2 + watermarkMargin;
                textBaseline = "top";
            }
        }

        drawX += drawDirectionX * (imageWidth + watermarkMargin);

        if (drawDirectionY < 0) {
            imageY -= imageHeight;
        } else if (!drawDirectionY) {
            imageY -= imageHeight / 2;
        }

        if (useImageObject) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "image:", watermarkImageObject.url, "imageX:", imageX, "imageY:", imageY, "imageWidth:", imageWidth, "imageHeight:", imageHeight);
            }

            ctx.drawImage(watermarkImageObject.url, imageX, imageY, imageWidth, imageHeight);
        } else {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "image:", watermarkImage.source, "imageX:", imageX, "imageY:", imageY, "imageWidth:", imageWidth, "imageHeight:", imageHeight);
            }

            ctx.drawImage(watermarkImage, imageX, imageY, imageWidth, imageHeight);
        }
    }

    //--------------------------------------------------------------------------

    function substitutePlaceholders(text) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", text, "location:", JSON.stringify(location));
        }

        var placeholders = matchPlaceholders(text);

        placeholders.forEach(function (placeholder) {
            var replacement = toValueText(placeholder);
            text = XFormJS.replaceAll(text, placeholder, replacement);
        });

        text = XFormJS.replaceAll(text, "\\r", "");
        text = XFormJS.replaceAll(text, "\\n", "\n");

        return text;
    }

    //--------------------------------------------------------------------------

    function matchPlaceholders(text) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", text);
        }

        var m = text.match(/(?:\@\[)([\w\s\.]+)(?:\:([\w\s:/\\\-\.]+))?(?:\])/gm);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "placeholders:", JSON.stringify(m));
        }

        return m ? m : []
    }

    //--------------------------------------------------------------------------

    function toValueText(text) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "text:", text);
        }

        var m = text.match(/\@\[([\w\s\.]+)(?:\:([\w\s:/\\\-\.]+))?\]/);

        var name = m[1].trim().toLowerCase();
        var format = (typeof m[2] === "string") ? m[2] : undefined;
        return formatValue(name, getValue(name), format);
    }

    //--------------------------------------------------------------------------

    function getValue(name) {
        if (!location) {
            location = {};
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "name:", JSON.stringify(name));
        }

        if (name.startsWith(kValueLocationPrefix)) {
            var propertyName = name.substring(kValueLocationPrefix.length);
            var isValid = XFormJS.toBoolean(XFormJS.getPropertyPathValue(location, propertyName + "Valid"), true);
            var value = XFormJS.getPropertyPathValue(location, propertyName);

            if (debug) {
                console.log(logCategory, arguments.callee.name, "propertyName:", JSON.stringify(propertyName), "isValid:", isValid, "value:", value);
            }

            return isValid
                    ? (XFormJS.isNullOrUndefined(value) ? noValue : value)
                    : noValue;
        }

        var coordinate = QtPositioning.coordinate(location.latitude, location.longitude);

        switch (name) {
        case kValueDate:
        case kValueDateTime:
        case kValueTime:
            return new Date();

        case kValueTimeStamp:
            return location.timestamp;

        case kValueAltitude :
            return isFinite(location.altitude) ? location.altitude : undefined;

        case kValueCompass :
            return compassAzimuth;

        case kValueSpeed :
            return isFinite(location.speed) ? location.speed : undefined;

        case kValueDirection :
            return isFinite(location.direction) ? location.direction : undefined;

        case kValueAccuracy :
        case kValueHorizontalAccuracy :
            return isFinite(location.horizontalAccuracy) ? location.horizontalAccuracy : undefined;

        case kValueLatitude :
        case kValueLongitude :
        case kValueLatitudeLongitude :
        case kValueLongitudeLatitude :
        case kValueMGRS :
        case kValueUSNG :
        case kValueUTM :
        case kValueUPS:
            return coordinate;

        default:
            return "*%1*".arg(name);
        }
    }

    //--------------------------------------------------------------------------

    function formatValue(name, value, format) {
        if (value === undefined || value === null) {
            return "";
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, name, "=", JSON.stringify(value), "format:", format);
        }

        if (value instanceof Date) {
            return toDateTimeString(name, value, format);
        }

        var valueType = AppFramework.typeOf(value);

        switch (valueType) {
        case "coordinate":
            return toCoordinateString(name, value, format);
        }

        switch (name) {
        case kValueCompass:
            return isFinite(value) ? "%1°".arg(Math.round(value).toString()) : noValue;

        case kValueSpeed:
            return XFormJS.toLocaleSpeedString(value, locale);
        }

        return (typeof value == "string") ? value : JSON.stringify(value);
    }

    //--------------------------------------------------------------------------

    function toDateTimeString(name, date, format) {
        var dateFormat = Locale.LongFormat;

        switch (format) {
        case kFormatLong:
            dateFormat = Locale.LongFormat;
            break;

        case kFormatShort:
            dateFormat = Locale.ShortFormat;
            break;

        case kFormatNarrow:
            dateFormat = Locale.NarrowFormat;
            break;

        default:
            if (format > "") {
                dateFormat = format;
            }
            break;
        }

        var text;
        switch (name) {
        case kValueDate:
            text = date.toLocaleDateString(locale, dateFormat);
            break;

        case kValueTime:
            text = date.toLocaleTimeString(locale, dateFormat);
            break;

        case kValueDateTime:
        case kValueTimeStamp:
        default:
            text = date.toLocaleString(locale, dateFormat);
            break;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "date:", date, "format:", format, "=>", dateFormat, "text:", text);
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function toCoordinateString(name, coordinate, format) {
        if (!coordinate.isValid) {
            return noValue;
        }

        switch (name) {
        case kValueMGRS:
            return toMGRS(coordinate, format, false);

        case kValueUSNG:
            return toMGRS(coordinate, format, true);

        case kValueUTM:
        case kValueUPS:
            return toUniversalGrid(coordinate);
        }

        var text = coordinate.toString();

        var ll;

        switch (format) {
        case kFormatDMS:
            ll = Coordinate.convert(coordinate, "dms").dms;
            break;

        case kFormatDDM:
            ll = Coordinate.convert(coordinate, "ddm").ddm;
            break;

        case kFormatDD:
        default:
            ll = Coordinate.convert(coordinate, "dd").dd;
            break;
        }

        switch (name) {
        case kValueLatitude:
            return ll.latitudeText;

        case kValueLongitude:
            return ll.longitudeText;

        case kValueLatitudeLongitude:
            return "%1 %2".arg(ll.latitudeText).arg(ll.longitudeText);

        case kValueLongitudeLatitude:
            return "%2 %1".arg(ll.latitudeText).arg(ll.longitudeText);
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function toMGRS(coordinate, precision, isUSNG) {
        var options = {
            spaces: isUSNG
        }

        if (precision > 0) {
            options.precision = Number(precision);
        } else if (isUSNG) {
            options.precision = 10;
        }

        var mgrs = Coordinate.convert(coordinate, "mgrs", options).mgrs;

        if (debug) {
            console.log("toMGRS:", JSON.stringify(mgrs, undefined, 2));
        }

        return mgrs.text;
    }

    //------------------------------------------------------------------------------

    function toUniversalGrid(coordinate) {
        var universalGrid = Coordinate.convert(coordinate, "universalGrid").universalGrid;

        if (debug) {
            console.log("toUniversalGrid:", JSON.stringify(universalGrid, undefined, 2));
        }

        return "%2%3 %4E %5N"
        .arg(universalGrid.zone ? universalGrid.zone : "")
        .arg(universalGrid.band)
        .arg(Math.floor(universalGrid.easting).toString())
        .arg(Math.floor(universalGrid.northing).toString());
    }

    //--------------------------------------------------------------------------
}
