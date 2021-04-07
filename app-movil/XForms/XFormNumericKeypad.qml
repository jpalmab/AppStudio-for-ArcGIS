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
import QtQuick.Layouts 1.12

XFormKeypad {
    property bool showSign: true
    property bool showPoint: true
    property bool showGroupSeparator: true
    property bool showEnter: false
    property alias canDelete: deleteKey.enabled
    property alias zeroEnabled: zeroKey.enabled

    property var locale: Qt.locale()

    //--------------------------------------------------------------------------

    columns: 4
    rows: 4

    //--------------------------------------------------------------------------

    XFormKey {
        key: Qt.Key_7
    }

    XFormKey {
        key: Qt.Key_8
    }

    XFormKey {
        key: Qt.Key_9
    }

    XFormKey {
        id: deleteKey

        key: Qt.Key_Delete
        text: "←"
    }


    XFormKey {
        key: Qt.Key_4
    }

    XFormKey {
        key: Qt.Key_5
    }

    XFormKey {
        key: Qt.Key_6
    }

    XFormKey {
    }


    XFormKey {
        key: Qt.Key_1
    }

    XFormKey {
        key: Qt.Key_2
    }

    XFormKey {
        key: Qt.Key_3
    }

    XFormKey {
    }


    XFormKey {
        visible: showSign
        key: Qt.Key_plusminus
//        text: "±"
    }

    Item {
        implicitWidth: 1
        implicitHeight: 1

        visible: !showSign
    }

    XFormKey {
        id: zeroKey

        Layout.columnSpan: !showPoint ? showSign ? 2 : 1 : 1

        key: Qt.Key_0
    }

    XFormKey {
        visible: showPoint

        key: locale.decimalPoint.charCodeAt(0) //Qt.Key_Period
        //text: locale.decimalPoint
    }

    Item {
        implicitWidth: 1
        implicitHeight: 1

        visible: !showPoint && !showSign
    }

    XFormKey {
        visible: showGroupSeparator

        key: locale.groupSeparator.charCodeAt(0)
        //text: locale.groupSeparator
    }

    XFormKey {
        visible: showEnter

        key: Qt.Key_Return
        text: "↵"
        color: "#007aff"
        textColor: "white"
    }

}
