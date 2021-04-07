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
import QtLocation 5.9

MapQuickItem {
    id: item

    //--------------------------------------------------------------------------

    default property alias contentItems: vertexRectangle.data

    property alias editing: vertexRectangle.editing
    property alias contentItem: vertexRectangle

    //--------------------------------------------------------------------------

    anchorPoint: Qt.point(vertexRectangle.width/2, vertexRectangle.height/2)

    sourceItem: VertexRectangle {
        id: vertexRectangle

    }

    //--------------------------------------------------------------------------
}
