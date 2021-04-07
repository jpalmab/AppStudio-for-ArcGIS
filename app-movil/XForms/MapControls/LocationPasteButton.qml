/* Copyright 2018 Esri
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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0


StyledImageButton {

    property string pasteText
    property var parseOptions

    signal paste()

    //--------------------------------------------------------------------------

    source: "images/paste-location.png"
    
    color: "white"
    visible: pasteText > ""
    
    //--------------------------------------------------------------------------

    onClicked: {
        paste();
        AppFramework.clipboard.clear();
    }


    //--------------------------------------------------------------------------

    Connections {
           target: Qt.application
           onStateChanged: {
              if (Qt.application.state === Qt.ApplicationActive){
                 // Application go in active state
                  checkClipboard();
              }
              else {
                 // Application go in suspend state
              }
           }
    }

    //--------------------------------------------------------------------------

    function checkClipboard() {
        if (!AppFramework.clipboard.dataAvailable) {
            pasteText = "";
            AppFramework.clipboard.clear();
            return;
        }

        var text = AppFramework.clipboard.text;

        console.log("Checking clipboard:", text);

        var found = "";

        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];

            var coordInfo = Coordinate.parse(line, parseOptions);

            if (coordInfo.coordinate) {
                found = line.trim();
                break;
            }
        }

        pasteText = found;

    }

    //--------------------------------------------------------------------------
}
