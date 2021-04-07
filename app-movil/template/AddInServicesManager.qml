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


Item {
    id: manager

    //--------------------------------------------------------------------------

    property alias addInsFolder: servicesModel.addInsFolder

    property var services: []
    readonly property int count: services.length

    //--------------------------------------------------------------------------

    enabled: false

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        clear();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(manager, true)
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: servicesModel
        
        type: kTypeTool
        mode: kToolModeService
        
        onUpdated: {
            initialize();
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: serviceComponent

        AddInTool {
            id: addInService
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        if (!enabled) {
            return;
        }

        console.log("Initializing add-in services:", servicesModel.count)
        clear();

        var list = [];

        for (var i = 0; i < servicesModel.count; i++) {
            var addInItem = servicesModel.get(i);

            var service = serviceComponent.createObject(
                        manager,
                        {
                            path: addInItem.path,
                            currentMode: servicesModel.kToolModeService
                        });

            if (service) {
                list.push(service);
                service.start();
            } else {
                console.log(logCategory, "Unabled to create service:", JSON.stringify(addInItem, undefined, 2))
            }
        }

        services = list;
    }

    //--------------------------------------------------------------------------

    function clear() {
        var service = services.pop();
        while (service) {
            service.stop();
            service = services.pop();
        }

        services = [];
    }

    //--------------------------------------------------------------------------
}
