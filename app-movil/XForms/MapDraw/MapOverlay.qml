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
import QtLocation 5.9

Map {
    property Map baseMap: parent

    //--------------------------------------------------------------------------
    
    anchors.fill: baseMap
    
    plugin: Plugin {
        name: "itemsoverlay"
    }

    gesture.enabled: false
    center: baseMap.center
    color: 'transparent'
    minimumFieldOfView: baseMap.minimumFieldOfView
    maximumFieldOfView: baseMap.maximumFieldOfView
    minimumTilt: baseMap.minimumTilt
    maximumTilt: baseMap.maximumTilt
    minimumZoomLevel: baseMap.minimumZoomLevel
    maximumZoomLevel: baseMap.maximumZoomLevel
    zoomLevel: baseMap.zoomLevel
    tilt: baseMap.tilt;
    bearing: baseMap.bearing
    fieldOfView: baseMap.fieldOfView

    //--------------------------------------------------------------------------
}
