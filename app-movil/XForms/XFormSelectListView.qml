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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

Rectangle {
    id: view

    property alias model: itemView.model
    property XFormRadioGroup radioGroup
    property real maxHeight: 150 * AppFramework.displayScaleFactor
    property real padding: 0
    property int changeReason

    //--------------------------------------------------------------------------

    signal clicked()

    //--------------------------------------------------------------------------

    height: visible ? maxHeight + padding * 2 : 0
    
    //--------------------------------------------------------------------------

    ScrollView {
        id: scrollView

        anchors {
            fill: parent
        }

        padding: 8 * AppFramework.displayScaleFactor
        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

        ListView {
            id: itemView

            clip: true
            width: scrollView.availableWidth
            spacing: xform.style.gridSpacing
            delegate: itemDelegate
        }
    }

    Component {
        id: itemDelegate

        XFormRadioControl {
            width: ListView.view.width
            radioGroup: view.radioGroup
            value: view.model[index].value
            label: view.model[index].label
            textColor: (checked && changeReason === 3) ? xform.style.selectAltTextColor : xform.style.selectTextColor

            onClicked: {
                view.clicked();
            }

            /*
            Component.onCompleted: {
                console.log("Created:", index, JSON.stringify(value), JSON.stringify(label));
            }

            Component.onDestruction: {
                console.log("Destroy:", index, JSON.stringify(value), JSON.stringify(label));
            }
*/
        }
    }

    //--------------------------------------------------------------------------
}
