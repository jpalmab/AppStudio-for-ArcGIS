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

QtObject {
    id: object

    property App app
    property Settings settings

    //--------------------------------------------------------------------------

    property int buildType: 0 // 0=Release, 1=Beta, 2=Alpha
    readonly property string buildTypeSuffix: kBuildTypeSuffix[buildType]

    property bool addIns: false
    property bool listCache: false
    property bool asyncFormLoader: false
    property bool portalBasemaps: false
    property bool enhancedGallery: false
    property bool useSharedTheme: false

    readonly property bool beta: addIns
                                 || listCache
                                 || asyncFormLoader
                                 || portalBasemaps
                                 || enhancedGallery
                                 || useSharedTheme


    //--------------------------------------------------------------------------

    readonly property var kBuildTypeSuffix: ["", "β", "α"]

    readonly property string kPrefix: "features"

    readonly property string kKeyAddIns: "addIns"
    readonly property string kKeyListCache: "listCache"
    readonly property string kKeyAsyncFormLoader: "asyncFormLoader"
    readonly property string kKeyPortalBasemaps: "portalBasemaps"
    readonly property string kKeyEnhancedGallery: "enhancedGallery"
    readonly property string kKeyUseSharedTheme: "useSharedTheme"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var title = app.info.title.toLowerCase();

        if (title.indexOf("beta") >= 0) {
            buildType = 1;
        } else if (title.indexOf("alpha") >= 0) {
            buildType = 2;
        }

        console.log(logCategory, "app buildType:", buildType, buildTypeSuffix);
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(object, true)
    }

    //--------------------------------------------------------------------------

    function featureKey(featureKey) {
        return "%1/%2".arg(kPrefix).arg(featureKey);
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log(logCategory, "Reading features configuration");

        addIns = settings.boolValue(featureKey(kKeyAddIns), false);
        listCache = settings.boolValue(featureKey(kKeyListCache), false);
        asyncFormLoader = settings.boolValue(featureKey(kKeyAsyncFormLoader), false);
        portalBasemaps = settings.boolValue(featureKey(kKeyPortalBasemaps), false);
        enhancedGallery = settings.boolValue(featureKey(kKeyEnhancedGallery), false);
        useSharedTheme = settings.boolValue(featureKey(kKeyUseSharedTheme), false);

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log(logCategory, "Writing features configuration");

        log();

        settings.setValue(featureKey(kKeyAddIns), addIns, false);
        settings.setValue(featureKey(kKeyListCache), listCache, false);
        settings.setValue(featureKey(kKeyAsyncFormLoader), asyncFormLoader, false);
        settings.setValue(featureKey(kKeyPortalBasemaps), portalBasemaps, false);
        settings.setValue(featureKey(kKeyEnhancedGallery), enhancedGallery, false);
        settings.setValue(featureKey(kKeyUseSharedTheme), useSharedTheme, false);
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log(logCategory, "App features - beta:", beta);
        console.log(logCategory, "* Add-ins:", addIns);
        console.log(logCategory, "* List cache:", listCache);
        console.log(logCategory, "* Async form loader:", asyncFormLoader);
        console.log(logCategory, "* Portal basemaps:", portalBasemaps);
        console.log(logCategory, "* Enhanced gallery:", enhancedGallery);
        console.log(logCategory, "* Use shared theme:", useSharedTheme);
    }

    //--------------------------------------------------------------------------
}

