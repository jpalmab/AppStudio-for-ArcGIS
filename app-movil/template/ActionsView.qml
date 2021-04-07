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

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Controls"

Control {
    id: control

    //--------------------------------------------------------------------------

    property var actions
    property var model: []
    property alias delegate: repeater.delegate
    property bool checkable: false

    //--------------------------------------------------------------------------

    signal triggered(var action)
    signal toggled(var action)

    //--------------------------------------------------------------------------

    spacing: 1 * AppFramework.displayScaleFactor

    palette {
        //window: "#f9f9f9"
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        add(actions);

        repeater.model = model;
    }

    //--------------------------------------------------------------------------

    function add(object) {
        if (AppFramework.instanceOf(object, "QQuickAction")) {
            addAction(object);
        } else if (Array.isArray(object)) {
            addList(object);
        } else if (AppFramework.instanceOf(object, "list")) {
            addList(object);
        } else if (AppFramework.instanceOf(object, "QQuickActionGroup")) {
            addList(object.actions);
        }
    }

    //--------------------------------------------------------------------------

    function addAction(action) {
        if (action.checkable) {
            checkable = true;
        }

        action.triggered.connect(function (source) { control.triggered(action); });
        action.toggled.connect(function (source) { control.toggled(action); });

        model.push(action);
    }

    //--------------------------------------------------------------------------

    function addList(list) {
        for (var i = 0; i < list.length; i++) {
            add(list[i]);
        }
    }

    //--------------------------------------------------------------------------

    contentItem: VerticalScrollView {
        id: scrollView

        ColumnLayout {
            id: layout

            width: scrollView.availableWidth
            spacing: control.spacing

            Repeater {
                id: repeater

                delegate: AppActionButton {
                    Layout.fillWidth: true

                    action: repeater.model[index]
                    visible: enabled
                    showCheck: control.checkable

                    Rectangle {
                        anchors {
                            top: parent.bottom
                            left: parent.left
                            right: parent.right
                        }

                        height: control.spacing
                        color: control.palette.window
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
