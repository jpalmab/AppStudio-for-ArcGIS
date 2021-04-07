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

.pragma library

.import QtPositioning 5.8 as Positioning

.import ArcGIS.AppFramework 1.0 as AF
.import ArcGIS.AppFramework.Sql 1.0 as Sql
.import ArcGIS.AppFramework.Networking 1.0 as Net

.import "XForm.js" as XFormJS

//------------------------------------------------------------------------------

var debug = false;

var kKeyLastReverseGeocodeUrl = "lastReverseGeocodeUrl";
var kKeyLastReverseGeocodeResponse = "lastReverseGeocodeResponse";

//------------------------------------------------------------------------------

function pulldata_geopoint(context, geopoint, propertyName, param1, param2, param3) {
    if (typeof geopoint === "string") {
        geopoint = XFormJS.parseGeopoint(geopoint);
    }

    if (typeof geopoint !== "object") {
        console.error("geopoint is not an object:", typeof geopoint, geopoint);
        return;
    }

    if (typeof propertyName !== "string") {
        console.error("propertyName not a string", typeof propertyName, propertyName);
        return;
    }

    var coordinate = Positioning.QtPositioning.coordinate(geopoint.y, geopoint.x, geopoint.z);

    if (!coordinate.isValid) {
        console.error("Invalid geopoint coordinate:", JSON.stringify(geopoint));
        return;
    }

    var converter;

    switch (propertyName) {
    case "longitude":
    case "lon":
        propertyName = "x";
        break;

    case "latitude":
    case "lat":
        propertyName = "y";
        break;

    case "altitude":
    case "alt":
        propertyName = "z";
        break;

    case "accuracy":
        propertyName = "horizontalAccuracy";
        break;

    case "sog":
        propertyName = "speed";
        break;

    case "cog":
        propertyName = "direction";
        break;

    default:
        var propertyParts = propertyName.split(".");

        switch (propertyParts[0].toLowerCase()) {
        case "dd":
            converter = toDD;
            break;

        case "dms":
            converter = toDMS;
            break;

        case "ddm":
            converter = toDDM;
            break;

        case "utm":
        case "utmups":
        case "ups":
            converter = toUniversalGrid;
            break;

        case "mgrs":
        case "usng":
            converter = toMGRS;
            break;

        case "reversegeocode":
            converter = reverseGeocode;
            break;
        }
        break;
    }

    if (debug) {
        console.log("coordinate:", coordinate);
        console.log("property:", propertyName, JSON.stringify(propertyParts));
        console.log("converter:", converter);
    }

    var value = converter
            ? convert(converter, context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3)
            : XFormJS.getPropertyPathValue(geopoint, propertyName);

    if (debug) {
        console.log("propertyName:", propertyName, "=", JSON.stringify(value), "geopoint:", JSON.stringify(geopoint));
    }

    switch (typeof value) {
    case "number":
        return  isFinite(value) ? value : undefined;

    case "object":
        return value ? JSON.stringify(value) : undefined;

    default:
        return value;
    }
}

//------------------------------------------------------------------------------

function convert(converter, context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3) {
    var info = converter(context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3);

    if (propertyParts && propertyParts.length > 1 && typeof info === "object") {
        propertyParts.shift();
        return XFormJS.getPropertyPathValue(info, propertyParts.join("."));
    } else {
        return info;
    }
}

//------------------------------------------------------------------------------

function toDD(context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3) {
    var dd = Sql.Coordinate.convert(coordinate, "dd").dd;

    if (debug) {
        console.log("toDD:", JSON.stringify(dd, undefined, 2));
    }

    dd.text = "%1 %2".arg(dd.latitudeText).arg(dd.longitudeText);

    return dd;
}

//------------------------------------------------------------------------------

function toDMS(context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3) {
    var dms = Sql.Coordinate.convert(coordinate, "dms").dms;

    if (debug) {
        console.log("toDMS:", JSON.stringify(dms, undefined, 2));
    }

    dms.text = "%1 %2".arg(dms.latitudeText).arg(dms.longitudeText);

    return dms;
}

//------------------------------------------------------------------------------

function toDDM(context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3) {
    var ddm = Sql.Coordinate.convert(coordinate, "ddm").ddm;

    if (debug) {
        console.log("toDDM:", JSON.stringify(ddm, undefined, 2));
    }

    ddm.text = "%1 %2".arg(ddm.latitudeText).arg(ddm.longitudeText);

    return ddm;
}

//------------------------------------------------------------------------------

function toUniversalGrid(context, geopoint, coordinate, propertyName, propertyParts, param1, param2, param3) {
    var universalGrid = Sql.Coordinate.convert(coordinate, "universalGrid").universalGrid;

    if (debug) {
        console.log("toUniversalGrid:", JSON.stringify(universalGrid, undefined, 2));
    }

    var info = {
        type: universalGrid.type,
        easting: Math.floor(universalGrid.easting),
        northing: Math.floor(universalGrid.northing),
        zone: universalGrid.zone,
        band: universalGrid.band,
        text: "%2%3 %4E %5N".arg(universalGrid.zone ? universalGrid.zone : "").arg(universalGrid.band).arg(Math.floor(universalGrid.easting).toString()).arg(Math.floor(universalGrid.northing).toString())
    };

    return info;
}

//------------------------------------------------------------------------------

function toMGRS(context, geopoint, coordinate, propertyName, propertyParts, precision, param2, param3) {
    var isUSNG = propertyName.toLowerCase() === "usng";

    var options = {
        spaces: isUSNG
    }

    if (precision > 0) {
        options.precision = Number(precision);
    } else if (isUSNG) {
        options.precision = 10;
    }

    var mgrs = Sql.Coordinate.convert(coordinate, "mgrs", options).mgrs;

    if (debug) {
        console.log("toMGRS:", JSON.stringify(mgrs, undefined, 2));
    }

    return mgrs.text;
}

//------------------------------------------------------------------------------

function reverseGeocode(context, geopoint, coordinate, propertyName, propertyParts, locator, parameters, param3) {
    if (!Net.Networking.isOnline) {
        return;
    }

    var langCode = AF.AppFramework.localeInfo(context.xform.locale.uiLanguages[0]).esriName;

    //var parameters = XFormJS.parseParameters(param1);

    var locatorUrl;

    if (locator > "") {
        locatorUrl = locator;
    } else {
        var locators = XFormJS.getPropertyPathValue(context.portal, "info.helperServices.geocode");

        if (debug) {
            console.log("locators:", JSON.stringify(locators, undefined, 2));
        }

        if (Array.isArray(locators) && locators.length > 1) {
            locator = locators[0];

            locatorUrl = locator.url;
        }
    }

    if (!locatorUrl) {
        locatorUrl = "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer";
    }

    if (debug) {
        console.log("Using locator:", JSON.stringify(locator, undefined, 2));
    }

    var reverseGeocodeParameters = 'f=pjson&location={"x":%1,"y":%2,"spatialreference":{"wkid":%3}}&outSR=%3&langCode=%4&forStorage=%5%6'
    .arg(coordinate.longitude.toString())
    .arg(coordinate.latitude.toString())
    .arg(4326) // wkid/outSR
    .arg(langCode)
    .arg("true") // forStorage
    .arg(parameters > "" ? "&%1".arg(parameters): "");

    var reverseGeocodeUrl = "%1/reverseGeocode?%2"
    .arg(locatorUrl)
    .arg(reverseGeocodeParameters);

    // Check if same as last reverse geocode request

    var lastReverseGeocodeUrl = context.objectCache[kKeyLastReverseGeocodeUrl];
    var lastReverseGeocodeResponse = context.objectCache[kKeyLastReverseGeocodeResponse];

    if (lastReverseGeocodeUrl === reverseGeocodeUrl && lastReverseGeocodeResponse) {
        if (debug) {
            console.log("Using cached reverseGeocode response for:", reverseGeocodeUrl);
        }

        return lastReverseGeocodeResponse;
    } else {
        context.objectCache[kKeyLastReverseGeocodeUrl] = undefined;
        context.objectCache[kKeyLastReverseGeocodeResponse] = undefined;
    }

    var locatorInfo = context.objectCache[locatorUrl] || {};

    var retry = typeof locatorInfo.requiresToken != "boolean";
    var requiresToken = XFormJS.toBoolean(locatorInfo.requiresToken, true);
    var tryCount = 0;

    if (debug) {
        console.log("reverseGeocode requiresToken:", requiresToken, "typeof:", typeof locatorInfo.requiresToken, "retry:", retry);
    }

    do {
        var url = "%1%2"
        .arg(reverseGeocodeUrl)
        .arg((context.portal.signedIn && requiresToken) ? "&token=%1".arg(context.portal.token) : "");

        if (debug) {
            console.log("reverseGeocode:", url, "parameters:", JSON.stringify(parameters, undefined, 2));
        }

        var xhr = new XMLHttpRequest();

        xhr.open("GET", url, false);
        xhr.send();

        if (xhr.status != 200) {
            console.error("reverseGeocode error status:", xhr.status);
            return;
        }

        tryCount++;

        var response = JSON.parse(xhr.responseText);

        if (response.error) {
            console.log("reverseGeocode error:", JSON.stringify(response, undefined, 2));
            console.log("url:", url);
            console.log("locator:", JSON.stringify(locator, undefined, 2));

            if (retry && tryCount == 1 && response.error.code === 498) {
                requiresToken = false;
                console.log("reverseGeocode retry:", retry, "requiresToken:", requiresToken);
                continue;
            }
        }

        retry = false;
        context.objectCache[kKeyLastReverseGeocodeUrl] = reverseGeocodeUrl;
        context.objectCache[kKeyLastReverseGeocodeResponse] = response;
    } while (retry);

    locatorInfo.requiresToken = requiresToken;
    context.objectCache[locatorUrl] = locatorInfo;


    if (debug) {
        console.log("reverseGeocode:", xhr.responseText, JSON.stringify(response, undefined, 2));
    }

    return response;
}

//------------------------------------------------------------------------------
