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

Item {
    readonly property alias linear : linearModel
    readonly property alias area : areaModel
    readonly property alias speed : speedModel

    //--------------------------------------------------------------------------

    readonly property var kTypeModels:
        ({
             "linear": linearModel,
             "area": areaModel,
             "speed": speedModel
         })

    //--------------------------------------------------------------------------

    ListModel {
        id: linearModel

        readonly property string type: "linear"

        ListElement {
            //code: 9001
            name: "m"
            label: "Metre"
            factor: 1
            abbreviation: "m"
        }

        ListElement {
            //code: 1033
            name: "cm"
            label: "Centimetre"
            factor: 0.01
            abbreviation: "cm"
        }

        ListElement {
            //code: 1025
            name: "mm"
            label: "Millimetre"
            factor: 0.001
            abbreviation: "mm"
        }

        ListElement {
            //code: -1
            name: "in"
            label: "Inch"
            factor: 0.0254
            abbreviation: "in"
        }

        ListElement {
            //code: 9002
            name: "ft"
            label: "Foot"
            factor: 0.3048
            abbreviation: "ft"
        }

        ListElement {
            //code: 9096
            name: "yd"
            label: "Yard"
            factor: 0.9144
            abbreviation: "yd"
        }

        ListElement {
            //code: 9036
            name: "km"
            label: "Kilometre"
            factor: 1000
            abbreviation: "km"
        }

        ListElement {
            //code: 9093
            name: "mi"
            label: "Mile"
            factor: 1609.34
            abbreviation: "mi"
        }

        ListElement {
            //code: 9030
            name: "nm"
            label: "Nautical mile"
            factor: 1852
            abbreviation: "NM"
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: areaModel

        readonly property string type: "area"

        ListElement {
            name: "m2"
            label: "Square Metres"
            factor: 1
            abbreviation: "m²"
        }

        ListElement {
            name: "km2"
            label: "Square Kilometres"
            factor: 1e+6
            abbreviation: "km²"
        }

        ListElement {
            name: "mi2"
            label: "Square Miles"
            factor: 2.59e+6
            abbreviation: "mi²"
        }

        ListElement {
            name: "yd2"
            label: "Square Yards"
            factor: 0.836127
            abbreviation: "yd²"
        }

        ListElement {
            name: "ft2"
            label: "Square Feet"
            factor: 0.092903
            abbreviation: "ft²"
        }

        ListElement {
            name: "in2"
            label: "Square Inches"
            factor: 0.00064516
            abbreviation: "in²"
        }

        ListElement {
            name: "ha"
            label: "Hectares"
            factor: 10000
            abbreviation: "ha"
        }

        ListElement {
            name: "ac"
            label: "Acres"
            factor: 4046.86
            abbreviation: "ac"
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: speedModel

        readonly property string type: "speed"

        ListElement {
            name: "m/s"
            label: "Metres per second"
            factor: 1
            abbreviation: "m/s"
        }

        ListElement {
            name: "km/h"
            label: "Kilometres per hour"
            factor: 0.277778
            abbreviation: "km/h"
        }

        ListElement {
            name: "ft/s"
            label: "Feet per second"
            factor: 0.3048
            abbreviation: "ft/s"
        }

        ListElement {
            name: "mph"
            label: "Miles per hour"
            factor: 0.44704
            abbreviation: "mph"
        }

        ListElement {
            name: "kts"
            label: "Knots"
            factor: 0.514444
            abbreviation: "kts"
        }
    }

    //--------------------------------------------------------------------------

    function typeUnit(type, name) {
        var model = kTypeModels[type];

        return modelUnit(model, name);
    }

    //--------------------------------------------------------------------------

    function modelUnit(model, name, noDefault) {
        var unit;

        for (var i = 0; i < model.count; i++) {
            unit = model.get(i);
            if (unit.name === name) {
                unit.type = model.type;
                return unit;
            }
        }

        console.warn("Unit not found:", name);

        if (noDefault) {
            unit = undefined;
        } else {
            unit = model.get(0);
            unit.type = model.type;
        }

        return unit;
    }

    //--------------------------------------------------------------------------
}
