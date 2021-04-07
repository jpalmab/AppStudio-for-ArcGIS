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
import QtQuick.Controls 2.12

import ArcGIS.AppFramework 1.0

Control {
    id: control

    //--------------------------------------------------------------------------

    property int referenceWidth: 200 * AppFramework.displayScaleFactor
    property bool dynamicSpacing: false
    property int minimumSpacing: 10 * AppFramework.displayScaleFactor
    property int cellSize: 175 * AppFramework.displayScaleFactor

    property alias refreshHeader: refreshHeader
    property alias progressBar: progressBar

    property alias gridView: gridView
    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight
    property alias model: gridView.model
    property alias delegate: gridView.delegate
    property alias count: gridView.count
    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()
    signal indicatorClicked(int indicator)
    signal refresh()

    //--------------------------------------------------------------------------

    padding: 5 * AppFramework.displayScaleFactor

    contentItem: GridView {
        id: gridView

        property int cells: calcCells(width)

        cellWidth: width / cells
        cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth

        clip: true

        //--------------------------------------------------------------------------

        function calcCells(w) {
            if (dynamicSpacing) {
                return Math.max(1, Math.floor(w / (cellSize + minimumSpacing)));
            }

            var rw =  referenceWidth;
            var c = Math.max(1, Math.round(w / referenceWidth));

            var cw = w / c;

            if (cw > rw) {
                c++;
            }

            cw = w / c;

            if (c > 1 && cw < (rw * 0.85)) {
                c--;
            }

            cw = w / c;

            if (cw > rw) {
                c++;
            }

            return c;
        }

        //--------------------------------------------------------------------------

        RefreshHeader {
            id: refreshHeader

            onRefresh: {
                control.refresh();
            }
        }

        //--------------------------------------------------------------------------

        ScrollBar.vertical: ScrollBar {
            parent: control

            policy: ScrollBar.AsNeeded

            anchors {
                top: gridView.top
                right: parent.right
                bottom: gridView.bottom
            }

            padding: 0
        }
    }

    //--------------------------------------------------------------------------

    ProgressBar {
        id: progressBar

        parent: background

        anchors {
            top: parent.top
            topMargin: 2 * AppFramework.displayScaleFactor
            left: parent.left
            right: parent.right
            margins: control.padding
        }

        height: 3 * AppFramework.displayScaleFactor
        opacity: 0.5

        visible: false

        background: Item {}

        contentItem: Item {
            Rectangle {
                width: progressBar.visualPosition * parent.width
                height: parent.height
                radius: height / 2
                color: app.titleBarBackgroundColor
            }
        }
    }

    //--------------------------------------------------------------------------

    function positionViewAtBeginning() {
        gridView.positionViewAtBeginning();
    }

    function positionViewAtEnd() {
        gridView.positionViewAtEnd();
    }

    function positionViewAtIndex(index, mode) {
        gridView.positionViewAtIndex(index, mode);
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    //--------------------------------------------------------------------------
}
