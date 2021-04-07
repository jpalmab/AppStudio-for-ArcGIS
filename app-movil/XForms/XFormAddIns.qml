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

import ArcGIS.AppFramework 1.0

import "../Controls/Singletons"

Item {
    id: addIns

    //--------------------------------------------------------------------------

    property bool debug: true
    property var findAddInInfo: function (addInName) { return null; }
    property var enumerateAddIns: function (callback) {}
    property var create: _create
    property var createInstance: _createInstance

    property alias nullAddIn: nullAddIn

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addIns, true)
    }

    //--------------------------------------------------------------------------

    function findInfo(addInName) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "addInName:", addInName);
        }

        var info = findAddInInfo(addInName);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "addInName:", addInName, "info:", JSON.stringify(info, undefined, 2));
        }

        return info;
    }

    //--------------------------------------------------------------------------

    function findAppearanceAlias(appearances) {
        var addInName;

        enumerateAddIns(function (addInInfo) {
            if (addInInfo.appearanceAlias > "") {
                var aliases = addInInfo.appearanceAlias.split(",").map(appearance => appearance.trim()).filter(appearance => appearance > "");
                for (var i = 0; i < aliases.length; i++) {
                    if (appearances.indexOf(aliases[i]) >= 0) {
                        addInName = addInInfo.title;
                    }
                }
            }
        });

        return addInName;
    }

    //--------------------------------------------------------------------------

    function exists(addInName) {
        return !!findInfo(addInName);
    }

    //--------------------------------------------------------------------------

    function icon(addInName) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "addInName:", addInName);
        }

        var info = findInfo(addInName);

        if (!info) {
            return Icons.icon("add-in");
        }

        return info.icon;
    }

    //--------------------------------------------------------------------------

    function createView(addInName, containerItem, properties) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "addInName:", addInName);
        }

        if (!properties) {
            properties = {};
        }

        var addIn = findInfo(addInName);
        //        if (!addIn) {
        //            return;
        //        }

        var addInItem = createInstance(addInName, containerItem, properties);

        if (addInItem) {
            addInItem.parent = containerItem;
            addInItem.anchors.fill = addInItem.parent;
        }

        return addInItem;
    }

    //--------------------------------------------------------------------------

    function _create(addInName, owner, properties) {
        console.error(logCategory, arguments.callee.name);
        return null;
    }

    //--------------------------------------------------------------------------

    function _createInstance(addInName, owner, properties) {
        if (!properties) {
            properties = {};
        }

        properties.addInName = addInName;

        return nullAddIn.createObject(owner, properties);
    }

    //--------------------------------------------------------------------------

    Component {
        id: nullAddIn

        Rectangle {
            property string addInName
            property var instance: null

            implicitHeight: 100
            color: "lightgrey"

            border {
                color: "darkgrey"
            }

            Item {
                anchors {
                    fill: parent
                    margins: 10 * AppFramework.displayScaleFactor
                }

                Image {
                    anchors {
                        fill: parent
                    }

                    source: Icons.bigIcon("add-in")
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.1
                }

                Text {
                    anchors {
                        fill: parent
                    }

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: addInName
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                    font {
                        pointSize: 16
                        bold: true
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
