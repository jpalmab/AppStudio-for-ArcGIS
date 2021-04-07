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

import "../XForms"

XFormAddIns {
    id: addIns

    //--------------------------------------------------------------------------

    property AddInsManager addInsManager

    //--------------------------------------------------------------------------

    findAddInInfo: _findAddInInfo
    enumerateAddIns: _enumerateAddIns
//    createInstance: _createInstance

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(addIns, true)
    }

    //--------------------------------------------------------------------------

    function _enumerateAddIns(callback) {
        console.log(arguments.callee.name, "# add-ins:", addInsModel.count);

        for (var i = 0; i < addInsModel.count; i++) {
            callback(addInsModel.get(i));
        }
    }

    //--------------------------------------------------------------------------

    function _findAddInInfo(addInName) {
        console.log(arguments.callee.name, "# add-ins:", addInsModel.count);

        for (var i = 0; i < addInsModel.count; i++) {
            var addInInfo = addInsModel.get(i);

            console.log("addIn:", i, JSON.stringify(addInInfo, undefined, 2))

            if (addInInfo.title === addInName) {
                return addInInfo;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    function _create(addInName, owner, properties) {
        var addInInfo = findInfo(addInName);

        if (!addInInfo) {
            console.error(logCategory, arguments.callee.name, "Not found:", addInName);
            return null;
        }

        if (!properties) {
            properties = {};
        }

        properties.path = addInInfo.path;

        return addInComponent.createObject(owner, properties);
    }

    //--------------------------------------------------------------------------

    function _createInstance(addInName, owner, properties) {
        var addInInfo = findInfo(addInName);

        if (!addInInfo) {
            console.error(logCategory, arguments.callee.name, "Not found:", addInName);
            return null;
        }

        properties.path = addInInfo.path;

        return addInContainerComponent.createObject(owner, properties);
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInsModel

        addInsFolder: addInsManager.addInsFolder
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInComponent

        AddIn {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInContainerComponent

        AddInContainer {

        }
    }

    //--------------------------------------------------------------------------
}
