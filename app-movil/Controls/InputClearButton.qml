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

import "Singletons"

import ArcGIS.AppFramework 1.0

Button {
    id: control
    
    //--------------------------------------------------------------------------

    property color color: ControlsSingleton.inputTextColor

    //--------------------------------------------------------------------------

    width: ControlsSingleton.inputTextHeight
    height: width
    
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    
    activeFocusOnTab: false
    
    icon {
        source: ControlsSingleton.inputClearButtonIcon
        color: AppFramework.alphaColor(control.color, ControlsSingleton.inputClearButtonOpacity)
        height: ControlsSingleton.inputTextHeight
        width: ControlsSingleton.inputTextHeight
    }
    
    display: AbstractButton.IconOnly
    background: null

    //--------------------------------------------------------------------------
}
