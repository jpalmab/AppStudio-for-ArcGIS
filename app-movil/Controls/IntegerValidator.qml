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

import ArcGIS.AppFramework 1.0

InputValidator {
    //--------------------------------------------------------------------------

    property int top: 2147483647
    property int bottom: -2147483648

    //--------------------------------------------------------------------------

    validate: function (text) {
        if (!text) {
            return InputValidator.Acceptable;
        }
        
        var result = {
            input: text.replace(/^0+(?!\.|$)/, '').replace(/[^\d-]/g, ''),
            state: InputValidator.Intermediate
        };
        
        if (result.input.search(/^(?:-?[1-9]\d*$)|(?:^0)$/) < 0) {
            return result;
        }
        
        var value = parseInt(result.input, 10);
        
        if (!isFinite(value)) {
            return result;
        }
        
        result.state = value >= bottom && value <= top
                ? InputValidator.Acceptable
                : InputValidator.Invalid;
        
        return result;
    }

    //--------------------------------------------------------------------------
}
