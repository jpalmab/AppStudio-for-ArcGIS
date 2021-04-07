/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtPositioning 5.8

import "XForm.js" as XFormJS

QtObject {
    id: geoposition

    //--------------------------------------------------------------------------

    property real latitude
    property real longitude
    property real altitude
    property real speed: Number.NaN
    property real verticalSpeed: Number.NaN
    property real direction: Number.NaN
    property real magneticVariation: Number.NaN
    property real horizontalAccuracy: Number.NaN
    property real verticalAccuracy: Number.NaN

    property var displayAddress
    property var attributes

    property real hdop: Number.NaN
    property real pdop: Number.NaN
    property real vdop: Number.NaN
    property int fixType: -1
    property real differentialAge: Number.NaN
    property int referenceStationId: -1
    property int satellitesVisible: -1
    property int satellitesInUse: -1
    property real positionAccuracy: Number.NaN
    property real geoidSeparation: Number.NaN
    property int accuracyType: -1
    property real latitudeError: Number.NaN
    property real longitudeError: Number.NaN
    property real altitudeError: Number.NaN

    property int positionSourceType: -1
    property var positionSourceInfo: null

    //--------------------------------------------------------------------------

    readonly property int kWkidWGS84: 4326
    property int wkid: kWkidWGS84

    //--------------------------------------------------------------------------

    readonly property bool isValid: latitudeValid && longitudeValid

    readonly property bool latitudeValid: latitude != 0 && isFinite(latitude)
    readonly property bool longitudeValid: longitude != 0 && isFinite(longitude)
    readonly property bool altitudeValid: isFinite(altitude)
    readonly property bool speedValid: isFinite(speed)
    readonly property bool verticalSpeedValid: isFinite(verticalSpeed)
    readonly property bool directionValid: isFinite(direction)
    readonly property bool magneticVariationValid: isFinite(magneticVariation)
    readonly property bool horizontalAccuracyValid: isFinite(horizontalAccuracy)
    readonly property bool verticalAccuracyValid: isFinite(verticalAccuracy)

    readonly property var displayAddressValid: typeof displayAddress === "string" && displayAddress > ""
    readonly property var attributesValid: typeof attributes === "object" && attributes !== null

    readonly property bool hdopValid: isFinite(hdop)
    readonly property bool pdopValid: isFinite(pdop)
    readonly property bool vdopValid: isFinite(vdop)
    readonly property bool fixTypeValid: fixType >= 0
    readonly property bool differentialAgeValid: isFinite(differentialAge)
    readonly property bool referenceStationIdValid: referenceStationId >= 0
    readonly property bool satellitesVisibleValid: satellitesVisible >= 0
    readonly property bool satellitesInUseValid: satellitesInUse >= 0
    readonly property bool positionAccuracyValid: isFinite(positionAccuracy)
    readonly property bool geoidSeparationValid: isFinite(geoidSeparation)
    readonly property bool accuracyTypeValid: accuracyType >= 0
    readonly property bool latitudeErrorValid: isFinite(latitudeError)
    readonly property bool longitudeErrorValid: isFinite(longitudeError)
    readonly property bool altitudeErrorValid: isFinite(altitudeError)

    readonly property int positionSourceTypeValid: positionSourceType > 0
    readonly property var positionSourceInfoValid: positionSourceInfo !== null && typeof positionSourceInfo === "object"

    //--------------------------------------------------------------------------

    readonly property var kPositionProperties: {
        // Standard properties

        "speed": Number.NaN,
                "verticalSpeed": Number.NaN,
                "direction": Number.NaN,
                "magneticVariation": Number.NaN,
                "horizontalAccuracy": Number.NaN,
                "verticalAccuracy": Number.NaN,

                // Extended properties

                "hdop": Number.NaN,
                "pdop": Number.NaN,
                "vdop": Number.NaN,
                "fixType": -1,
                "differentialAge": Number.NaN,
                "referenceStationId": -1,
                "satellitesVisible": -1,
                "satellitesInUse": -1,
                "positionAccuracy": Number.NaN,
                "geoidSeparation": Number.NaN,
                "accuracyType": -1,
                "latitudeError": Number.NaN,
                "longitudeError": Number.NaN,
                "altitudeError": Number.NaN,

                // Position source properties

                "positionSourceType": -1,
                "positionSourceInfo": null,
    }

    //--------------------------------------------------------------------------

    property bool averaging: false
    property real averageCount: 0
    property date averageStart
    property date averageStop

    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    signal changed()
    signal cleared()

    //--------------------------------------------------------------------------

    function clear() {
        latitude = Number.NaN;
        longitude = Number.NaN;
        altitude = Number.NaN;

        Object.keys(kPositionProperties).forEach(function (name) {
            geoposition[name] = kPositionProperties[name];
        });

        displayAddress = "";
        attributes = null;

        changed();
        cleared();
    }

    //--------------------------------------------------------------------------

    function fromPosition(position) {
        if (debug) {
            console.log("fromPosition:", JSON.stringify(position, undefined, 2));
        }

        function validValue(value, valid, defaultValue) {
            return valid ? value : typeof defaultValue === "undefined" ? Number.NaN : defaultValue;
        }

        latitude = validValue(position.coordinate.latitude, position.latitudeValid);
        longitude = validValue(position.coordinate.longitude, position.longitudeValid);
        altitude = validValue(position.coordinate.altitude, position.altitudeValid);

        Object.keys(kPositionProperties).forEach(function (name) {
            geoposition[name] = position[name + "Valid"] ? position[name] : kPositionProperties[name];
        });

        displayAddress = "";
        attributes = null;

        changed();
    }

    //--------------------------------------------------------------------------

    function toCoordinate() {
        return QtPositioning.coordinate(latitude, longitude, altitude);
    }

    //--------------------------------------------------------------------------

    function toObject() {
        function validValue(value, valid, defaultValue) {
            return valid ? value : defaultValue;
        }

        var o = {
            "type": "point",
            "x": longitude,
            "y": latitude,
            "z": validValue(altitude, altitudeValid, Number.NaN),
            "spatialReference": {
                "wkid": wkid
            },

            "displayAddress": validValue(displayAddress, displayAddressValid),
            "attributes": validValue(attributes, attributesValid),
        }

        Object.keys(kPositionProperties).forEach(function (name) {
            o[name] = validValue(geoposition[name], geoposition[name + "Valid"]);
        });

        if (debug) {
            console.log("Geoposition toObject:", JSON.stringify(o, undefined, 2));
        }

        return o;
    }

    //--------------------------------------------------------------------------

    function fromObject(o) {
        if (o === null || typeof o !== "object") {
            console.trace();
            console.warn("invalid geopoint object", JSON.stringify(o));
            return false;
        }

        if (debug) {
            console.log("fromObject:", JSON.stringify(o, undefined, 2));
        }

        function validObjectValue(name, defaultValue) {
            var value = o[name];

            return typeof value === "number" && isFinite(value) ? value : typeof defaultValue === "undefined" ? Number.NaN : defaultValue;
        }

        if (o.hasOwnProperty("x")) {
            longitude = validObjectValue("x");
        } else if (o.hasOwnProperty("longitude")) {
            longitude = validObjectValue("longitude");
        }

        if (o.hasOwnProperty("y")) {
            latitude = validObjectValue("y");
        } else if (o.hasOwnProperty("latitude")) {
            latitude = validObjectValue("latitude");
        }

        if (o.hasOwnProperty("z")) {
            altitude = validObjectValue("z");
        } else if (o.hasOwnProperty("altitude")) {
            altitude = validObjectValue("altitude");
        } else {
            altitude = Number.NaN;
        }

        Object.keys(kPositionProperties).forEach(function (name) {
            geoposition[name] = validObjectValue(name, kPositionProperties[name]);
        });

        if (!o.hasOwnProperty("horizontalAccuracy") && o.hasOwnProperty("accuracy")) {
            horizontalAccuracy = validObjectValue("accuracy");
        }

        displayAddress = o["displayAddress"];
        attributes = o["attributes"];

        changed();

        return true;
    }

    //--------------------------------------------------------------------------

    function fromCoordinate(coordinate, sourceType) {
        clear();

        if (debug) {
            console.log("fromCoordinate:", coordinate, "sourceType:", sourceType);
        }

        if (!coordinate || !coordinate.isValid) {
            return false;
        }

        wkid = kWkidWGS84;
        longitude = coordinate.longitude;
        latitude = coordinate.latitude;
        altitude = coordinate.altitude;

        if (typeof sourceType === "number") {
            positionSourceType = sourceType;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function toGeopointString() {
        if (!isValid) {
            return;
        }

        return XFormJS.toCoordinateString(toObject());
    }

    //--------------------------------------------------------------------------

    function averageClear() {
        averageCount = -1;
        averaging = false;
    }

    //--------------------------------------------------------------------------

    function averageBegin() {
        averageCount = 0;
        averageStart = new Date();
        averageStop = averageStart;
        averaging = true;
    }

    //--------------------------------------------------------------------------

    function averageEnd() {
        if (!averaging) {
            return;
        }

        averaging = false;
        averageStop = new Date();
    }

    //--------------------------------------------------------------------------

    function averagePosition(position) {
        function averageValue(averagedValue, value) {
            if (!isFinite(averagedValue) || averagedValue == 0) {
                return value;
            }

            return (averagedValue * averageCount + value) / (averageCount + 1);
        }

        latitude = averageValue(latitude, position.coordinate.latitude);
        longitude = averageValue(longitude, position.coordinate.longitude);

        if (position.altitudeValid) {
            altitude = averageValue(altitude, position.coordinate.altitude);
        }

        if (position.horizontalAccuracyValid) {
            horizontalAccuracy = averageValue(horizontalAccuracy, position.horizontalAccuracy);
        } else {
            horizontalAccuracy = Number.NaN;
        }

        if (position.verticalAccuracyValid) {
            verticalAccuracy = averageValue(verticalAccuracy, position.verticalAccuracy);
        } else {
            verticalAccuracy = Number.NaN;
        }

        averageCount++;

        changed();
    }

    //--------------------------------------------------------------------------

    function dump() {
        console.log("latitude:", latitude);
        console.log("longitude:", longitude);
        console.log("altitude:", altitudeValid, altitude);

        Object.keys(kPositionProperties).forEach(function (name) {
            console.log(name + ":", "valid:", geoposition[name + "Valid"], "value:", JSON.stringify(geoposition[name], undefined, 2));
        });

        console.log("displayAddress:", displayAddressValid, displayAddress);
        console.log("attributes:", attributesValid, JSON.stringify(attributes));
    }

    //--------------------------------------------------------------------------

    onChanged: {
        if (!debug) {
            return;
        }

        console.log("geoposition onChanged")
        dump();
    }

    //--------------------------------------------------------------------------
}
