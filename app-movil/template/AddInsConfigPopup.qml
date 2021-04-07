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
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

ColumnLayoutPopup {
    id: popup
    
    //--------------------------------------------------------------------------

    property Settings settings

    //--------------------------------------------------------------------------

    readonly property string kSettingShowSurveysTile: "AddIns/showSurveysTile"
    readonly property string kSettingShowServicesTab: "AddIns/showServicesTab"
    readonly property string kSettingShowTabText: "AddIns/showTabTextSwitch"
    readonly property string kSettingAllowEsriAddIns: "AddIns/allowEsriAddIns"

    //--------------------------------------------------------------------------

    title: qsTr("Add-Ins")
    width: 250 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    onAboutToHide: {
        settings.setValue(kSettingShowSurveysTile, showSurveysTileSwitch.checked, false);
        settings.setValue(kSettingShowServicesTab, showServicesTabSwitch.checked, false);
        settings.setValue(kSettingShowTabText, showTabTextSwitch.checked, true);
        settings.setValue(kSettingAllowEsriAddIns, allowEsriAddInsSwitch.checked, true);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(popup, true)
    }

    //--------------------------------------------------------------------------

    AppSwitch {
        id: allowEsriAddInsSwitch

        Layout.fillWidth: true

        text: qsTr("Allow add-ins from Esri")
        checked: settings.boolValue(kSettingAllowEsriAddIns, true);
        font: popup.font
    }

    AppSwitch {
        id: showTabTextSwitch

        Layout.fillWidth: true

        text: qsTr("Show text on tabs")
        checked: settings.boolValue(kSettingShowTabText, true);
        font: popup.font
    }

    AppSwitch {
        id: showSurveysTileSwitch

        Layout.fillWidth: true

        text: qsTr("Show surveys as a tile")
        checked: settings.boolValue(kSettingShowSurveysTile, false);
        font: popup.font
    }

    AppSwitch {
        id: showServicesTabSwitch

        Layout.fillWidth: true

        text: qsTr("Show services tab")
        checked: settings.boolValue(kSettingShowServicesTab, false);
        font: popup.font
    }

    //--------------------------------------------------------------------------
}
