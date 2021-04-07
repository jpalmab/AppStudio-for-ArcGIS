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

import QtQuick 2.11

import ArcGIS.AppFramework 1.0

Rectangle {
    //--------------------------------------------------------------------------

    property real vertexSize: 30 * AppFramework.displayScaleFactor
    property real vertexOutlineWidth: 2 * AppFramework.displayScaleFactor
    property color vertexOutlineColor: "#ff52ff"
    property color vertexColor: "#30ff52ff"
    property color vertexEditOutlineColor: "#808080"
    property color vertexEditColor: "#30808080"

    //--------------------------------------------------------------------------

    property bool editing: false

    //--------------------------------------------------------------------------

    width: vertexSize
    height: vertexSize
    
    color: editing ? vertexEditColor : vertexColor

    border {
        width: vertexOutlineWidth
        color: editing ? vertexEditOutlineColor : vertexOutlineColor
    }

    //--------------------------------------------------------------------------
}
