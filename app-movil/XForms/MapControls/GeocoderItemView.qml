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

import QtQuick 2.9
import QtLocation 5.9

import ArcGIS.AppFramework 1.0

MapItemView {
    id: view

    property GeocoderSearch search

    //--------------------------------------------------------------------------

    signal clicked(int index, var location)

    //--------------------------------------------------------------------------

    model: search.geocodeModel

    //--------------------------------------------------------------------------

    delegate: LocationMarker {
        selected: search.currentIndex === index
        z: selected ? search.geocodeModel.count : index
        visible: !selected && score > -1
        text: search.geocoderResultsIndex[index] + 1

        selectedPinTextColor: search.selectedPinTextColor
        locationPinTextColor: search.locationPinTextColor

        onClicked: {
            var location = search.getLocation(index);
            view.clicked(index, location);
        }
    }

    //--------------------------------------------------------------------------
}
