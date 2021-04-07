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
import ArcGIS.AppFramework.Positioning 1.0

import "../Controls"
import "../Controls/Singletons"

Item {
    id: control

    //--------------------------------------------------------------------------

    property color color: xform.style.titleTextColor

    property XFormPositionSourceManager positionSourceManager

    readonly property bool hasError: positionSourceManager && positionSourceManager.positionSource.sourceError !== PositionSource.NoError
    readonly property bool isConnecting: positionSourceManager && positionSourceManager.isConnecting
    readonly property bool isConnected: positionSourceManager && positionSourceManager.isConnected
    readonly property bool isWarmingUp: positionSourceManager && positionSourceManager.isWarmingUp

    // set these to provide access to location settings (we can't reference these components from here directly)
    property var settingsTabContainer
    property var settingsTabLocation

    property url errorIcon: Icons.icon("exclamation-mark-triangle", false)

    property int linkIconIndex: 0
    property int linkStep: 1
    property url linkIcon: Icons.icon("satellite-%1".arg(linkIconIndex), false)

    property int qualityIconIndex: 3
    property string qualityIcon: Icons.icon("satellite-%1".arg(qualityIconIndex), true)

    property var internalQualities: [50, 25, 10]
    property var externalQualities: [25, 10, 3]

    property int positionSourceType: XFormPositionSourceManager.PositionSourceType.System
    property var qualities: positionSourceType > XFormPositionSourceManager.PositionSourceType.System
                             ? externalQualities
                             : internalQualities

    property var position: ({})

    property bool debug: false

    //--------------------------------------------------------------------------

    visible: positionSourceManager && !positionSourceManager.onDetailedSettingsPage && (positionSourceManager.active || isConnecting)
    enabled: visible && button.source > ""

    //--------------------------------------------------------------------------

    onPositionChanged: {
        if (debug) {
            console.log(logCategory, "position:", JSON.stringify(position, undefined, 2));
        }

        if (position.positionSourceTypeValid) {
            positionSourceType = position.positionSourceType;
        }

        var qualityIndex = 3;

        if (position.horizontalAccuracyValid) {
            for (var i = 0; i < qualities.length; i++) {
                if (position.horizontalAccuracy > qualities[i]) {
                    qualityIndex = i;
                    break;
                }
            }
        }

        qualityIconIndex = qualityIndex;

        if (debug) {
            console.log(logCategory,
                        "connectionType:", positionSourceManager.controller.connectionType,
                        "positionSourceType:", positionSourceType,
                        "qualities:", JSON.stringify(qualities),
                        "qualityIconIndex:", qualityIconIndex);
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }

    //--------------------------------------------------------------------------

    StyledImage {
        anchors {
            fill: parent
            margins: button.padding
        }

        visible: isConnected && !isWarmingUp && !hasError
        source: Icons.icon("satellite-3", true)
        color: control.color
        opacity: 0.4
    }

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: button

        anchors.fill: parent

        color: control.color
        source: hasError
                ? errorIcon
                : isConnecting
                  ? linkIcon
                  : isWarmingUp
                    ? Icons.icon("satellite-%1".arg(positionSourceManager.positionCount % 4), false)
                    : isConnected
                      ? qualityIcon
                      : ""

        padding: 8 * AppFramework.displayScaleFactor
        opacity: isConnecting ? 0.5 : 1

        onClicked: {
            forceActiveFocus();
            Qt.inputMethod.hide();

            xform.popoverStackView.push({
                                            item: positionSourceManager.isGNSS
                                                  ? gnssInfoPage
                                                  : locationInfoPage
                                        });
        }

        onPressAndHold: {
            debug = !debug;
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: 200
        repeat: true
        running: control.visible && isConnecting

        onTriggered: {
            var index = linkIconIndex + linkStep;
            if (index < 0) {
                index = 1;
                linkStep = 1;
            } else if (index > 3) {
                index = 2;
                linkStep = -1;
            }
            linkIconIndex = index;
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        onNewPosition: {
            control.position = position;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: locationInfoPage

        XFormLocationInfoPage {
            positionSourceManager: control.positionSourceManager

            settingsTabContainer: control.settingsTabContainer
            settingsTabLocation: control.settingsTabLocation
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: gnssInfoPage

        XFormGNSSInfoPage {
            positionSourceManager: control.positionSourceManager

            settingsTabContainer: control.settingsTabContainer
            settingsTabLocation: control.settingsTabLocation
        }
    }

    //--------------------------------------------------------------------------
}
