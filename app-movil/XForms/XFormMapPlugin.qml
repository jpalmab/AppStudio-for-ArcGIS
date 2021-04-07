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
import QtLocation 5.12

Plugin {
    //--------------------------------------------------------------------------

    property XFormMapSettings settings
    property bool offline

    //--------------------------------------------------------------------------

    preferred: [settings.provider]
    
    //--------------------------------------------------------------------------

    PluginParameter {
        id: debugParameter

        name: "ArcGIS.debug"
        value: false
    }

    PluginParameter {
        name: "ArcGIS.mapping.mapTypes.append"
        value: settings.appendMapTypes
    }
    
    PluginParameter {
        name: "ArcGIS.mapping.mapTypes.sort"
        value: settings.sortMapTypes
    }
    
    PluginParameter {
        name: "ArcGIS.mapping.mapTypes.mapSources"
        value: settings.mapSources
    }
    
    PluginParameter {
        name: "ArcGIS.mapping.mapTypes.filter.mode"
        value: offline ? "offline" : "any"
    }
}
