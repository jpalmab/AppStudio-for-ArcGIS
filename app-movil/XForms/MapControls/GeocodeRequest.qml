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
import ArcGIS.AppFramework 1.0

NetworkRequest {
    id: geocodeRequest

    method: "GET"

    property bool debug: true

    property var geocoderSpecification: null
    property var operation: null
    property int geocoderIndex: -1
    property int requiresToken: -1
    property string geocoderName: ""
    property bool reverseGeocode: false
    property bool selectFirstCandidateImmediately: false
    property var geocodeResults: []

    signal geocoderError(string error)
    signal reverseGeocodeError(string error)

    signal resultsReturned(string name, var results, int index, var spec)
    signal reverseGeocodeResultsReturned(var candidate)

    signal geocoderDoesNotRequireTokenOrTokenIsInvalid(var spec, int index)
    signal geocoderRequiresToken(var spec, int index)

    signal geocodeRequestComplete()

    //--------------------------------------------------------------------------

    onReadyStateChanged: {

        if (readyState === NetworkRequest.DONE) {

            if (debug) {
                console.log("geocodeURL: ", url);
            }

            try {
                var inResults = JSON.parse(response);

                if (inResults.error) {

                    if (inResults.error.code === 498 || inResults.error.message.search(/(Invalid Token)/i) > -1) {

                        if (debug) {
                            console.log("---------- geocoder doesn't require a token.")
                        }

                        geocoderSpecification.requiresToken = 0;
                        geocoderDoesNotRequireTokenOrTokenIsInvalid(geocoderSpecification, geocoderIndex);
                        geocoderError(inResults.error.message.toString());
                        return;
                    }

                    if (inResults.error.message.search(/(Token Required)/i) > -1) {
                        if (debug) {
                            console.log(">>---------- geocoder requires a token.")
                        }
                        geocoderSpecification.requiresToken = 1;
                        geocoderRequiresToken(geocoderSpecification, geocoderIndex);
                        geocoderError(inResults.error.message.toString());
                        return;
                    }

                    var errorMessage = qsTr("Geocode error.");

                    if (inResults.error.hasOwnProperty("message") && inResults.error.message.toString() > ""){
                        errorMessage = inResults.error.message.toString();
                    }

                    if (inResults.error.hasOwnProperty("details") && inResults.error.details.length > 0) {
                        errorMessage = inResults.error.details[0].toString();
                    }

                    errorMessage = simplifyErrorMessage(errorMessage);

                    if (!geocodeRequest.reverseGeocode) {
                        geocoderError(errorMessage);
                    }
                    else {
                        reverseGeocodeError(errorMessage);
                    }

                    return;
                }

                var spatialReference = inResults.hasOwnProperty("spatialReference") ? inResults.spatialReference : {};

                if (operation.resultsKey > "") {
                    var resultsKey = operation.resultsKey.split(".");
                    var results = null;

                    if (resultsKey.length === 1) {
                        if (!inResults.hasOwnProperty(resultsKey[0])) {
                            return;
                        }
                        else {
                            results = inResults[resultsKey[0]];
                        }
                    }
                    else {
                        if (!inResults.hasOwnProperty(resultsKey[0]) && !inResults[resultsKey[0]].hasOwnProperty(resultsKey[1])){
                            return;
                        }
                        else {
                            results = inResults[resultsKey[0]][resultsKey[1]];
                        }
                    }
                }
                else {
                    results = [inResults];
                }

                if (results.length < 1) {
                    geocoderError(qsTr("No locations found."));
                    resultsReturned(geocoderName, [], geocoderIndex, geocoderSpecification);
                    return;
                }

                for (var elem in results) {

                    var candidate = results[elem];

                    var candidateLocation = {
                        "address": "",
                        "coord": {"y": 0, "x": 0},
                        "spatialReference": spatialReference,
                        "score": -1,
                        "attributes": {},
                        "magicKey": "",
                        "isCollection": false,
                        "type": "",
                        "isHeader": false,
                        "headerText": ""
                    };

                    if (operation.coordinate !== undefined) {
                        candidateLocation.coord.y = candidate[operation.coordinate.key][operation.coordinate.lat];
                        candidateLocation.coord.x = candidate[operation.coordinate.key][operation.coordinate.lon];
                    }

                    if (candidate.hasOwnProperty("attributes")) {
                        candidateLocation.attributes = candidate.attributes;
                        if (candidate.attributes.hasOwnProperty("Addr_type")) {
                            candidateLocation.type = candidate.attributes.Addr_type;
                        }
                    }

                    if (candidate.hasOwnProperty("score")) {
                        candidateLocation.score = candidate.score;
                    }

                    if (candidate.hasOwnProperty("magicKey")) {
                        candidateLocation.magicKey = candidate.magicKey;
                    }

                    if (candidate.hasOwnProperty("isCollection")) {
                        candidateLocation.isCollection = candidate.isCollection;
                    }

                    for (var possibleDisplayField in operation.displayField) {
                        var searchCandidateObject = candidate;
                        var key = operation.displayField[possibleDisplayField].split(".");
                        var levels = key.length;

                        if (!searchCandidateObject.hasOwnProperty(key[0])) {
                            continue;
                        }

                        for (var x = 0; x < levels; x++) {
                            if (searchCandidateObject[key[x]] && typeof searchCandidateObject[key[x]] !== "object" && searchCandidateObject[key[x]] > "") {
                                candidateLocation.address = searchCandidateObject[key[x]];
                                break;
                            }
                            if (searchCandidateObject[key[x]] === "undefined") {
                                break;
                            }
                            searchCandidateObject = searchCandidateObject[key[x]];
                        }

                        if (candidateLocation.address > "") {
                            break;
                        }
                    }

                    if (debug) {
                        console.log(JSON.stringify(candidateLocation));
                    }

                    if (geocodeRequest.reverseGeocode) {
                        reverseGeocodeResultsReturned(candidateLocation)
                        return;
                    }

                    geocodeResults.push(candidateLocation)
                }
                resultsReturned(geocoderName, geocodeResults, geocoderIndex, geocoderSpecification);
            }
            catch (e) {
                if (debug) {
                    console.log(e.toString());
                }
                geocoderError(qsTr("Geocode error."));
            }
            finally {
                geocodeRequestComplete();
            }
        }
    }

    //--------------------------------------------------------------------------

    onErrorTextChanged: {
        var errorMessage = simplifyErrorMessage(errorText);
        geocodeRequestComplete();
        geocoderError(errorMessage);
    }

    //--------------------------------------------------------------------------

    function simplifyErrorMessage(errorText) {

        if (typeof errorText !== "string" || errorText === "") {
            return qsTr("Unknown geocoder error");
        }

        var simplifiedErrorMessage = errorText;

        if (simplifiedErrorMessage.indexOf(url) > -1) {
            simplifiedErrorMessage = simplifiedErrorMessage.replace(url, geocoderName);
        }

        return simplifiedErrorMessage;
    }

    //--------------------------------------------------------------------------

}
