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

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Window 2.12

ScrollView {
    id: scrollView

    //--------------------------------------------------------------------------

    default property Item flickableContent

    property bool keepActiveFocusItemVisible: true

    //--------------------------------------------------------------------------

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    //--------------------------------------------------------------------------

    clip: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        flickableContent.parent = flickable.contentItem;
        flickableContent.width = Qt.binding(function () { return scrollView.availableWidth; });
    }

    //--------------------------------------------------------------------------

    onHeightChanged: {
        if (keepActiveFocusItemVisible) {
            var item = Window.activeFocusItem;
            if (item) {
                ensureVisible(item);
            }
        }
    }

    //--------------------------------------------------------------------------

    Flickable {
        id: flickable

        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: flickableContent.width
        contentHeight: flickableContent.height

        Behavior on contentY {
            NumberAnimation {
                id: scrollAnimation

                duration: 0
            }
        }
    }

    //--------------------------------------------------------------------------

    function ensureVisible(item) {
        scrollAnimation.duration = 0;

        var mappedXY = item.mapToItem(flickable.contentItem, 0, 0);

        if (item.height > availableHeight) {
            flickable.contentY = mappedXY.y;
        } else {
            if (mappedXY.y < flickable.contentY) {
                flickable.contentY = mappedXY.y;
            } else if ((mappedXY.y + item.height) >= (flickable.contentY + availableHeight)) {
                flickable.contentY = mappedXY.y - availableHeight + item.height;
            }
        }
    }

    //--------------------------------------------------------------------------

    function scrollTo(item, bottom) {
        scrollAnimation.duration = 250;

        if (item) {
            var mappedXY = item.mapToItem(flickable.contentItem, 0, 0);

            if (bottom) {
                if (flickable.contentHeight > availableHeight) {
                    flickable.contentY = mappedXY.y - availableHeight + item.height;
                } else {
                    flickable.contentY = 0;
                }
            } else {
                flickable.contentY = mappedXY.y;
            }
        } else {
            if (bottom && flickable.contentHeight > availableHeight) {
                flickable.contentY = flickable.contentHeight - availableHeight;
            } else {
                flickable.contentY = 0;
            }
        }
    }

    //--------------------------------------------------------------------------
}
