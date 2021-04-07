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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Speech 1.0

import "XFormSingletons"
import "XForm.js" as XFormJS
import "../Controls"

StackView {
    id: xform

    //--------------------------------------------------------------------------

    property url source
    property alias sourceInfo: sourceInfo
    property alias mediaFolder: mediaFolder
    property var json

    property bool reviewMode: false // New survey=false Existing survey=true

    property alias formData: formData
    property alias schema: schema
    property alias bindings: bindings
    property alias listsCache: listsCache
    property alias itemsets: itemsets
    property alias settings: settings

    property XFormPositionSourceManager positionSourceManager

    property alias spacing: controlsLayout.spacing

    //--------------------------------------------------------------------------

    property string defaultLanguage
    property string language: defaultLanguage
    property var languages: []
    property alias languageName: languageText.text

    readonly property alias localeProperties: localeProperties
    readonly property alias localeInfo: localeProperties // Workaround for backward compatibility

    property alias locale: localeProperties.locale
    property alias languageDirection: localeProperties.textDirection
    readonly property alias layoutDirection: localeProperties.layoutDirection
    readonly property alias isRightToLeft: localeProperties.isRightToLeft
    readonly property var numberLocale: localeProperties.numberLocale

    readonly property string kLanguageDefault: "default"
    readonly property string kLanguageDefaultText: qsTr("Default")

    //--------------------------------------------------------------------------

    property string title
    property string instanceName
    property var instance
    property var instances
    property var submission: ({})
    property string version

    property int status: statusNull

    readonly property int statusNull: 0
    readonly property int statusLoading: 1
    readonly property int statusReady: 2
    readonly property int statusError: 3

    property StackView popoverStackView: xform

    readonly property alias name: sourceInfo.baseName

    property bool debug: false

    property Item focusItem

    property var controlNodes: ({})
    property var groupNodes: ({})
    property alias calculateNodes: calculates.nodes

    property XFormStyle style: XFormStyle {}
    property XFormMapSettings mapSettings: XFormMapSettings {}

    property alias attachmentsFolder: attachmentsFolder
    property int captureResolution: 640 // Medium
    property bool allowCaptureResolutionOverride: true

    property bool allowUpdate: true
    property bool allowDelete: false

    readonly property bool editable: !reviewMode || (reviewMode && allowUpdate)

    readonly property alias canPrint: schema.canPrint

    property string layoutStyle
    property alias pageNavigator: pageNavigator
    property alias textToSpeech: textToSpeech
    property bool hasTTS: false
    property bool hasSaveIncomplete: false

    property bool extensionsEnabled: true

    property Item currentActiveControl: null

    property bool isPagesLayout: false
    property bool isGridTheme: false
    property int groupControlColumns: isGridTheme ? 4 : 1

    property alias expressionProperties: expressionProperties

    //--------------------------------------------------------------------------

    property XFormAddIns addIns: XFormAddIns {}

    //--------------------------------------------------------------------------

    readonly property string kObjectTypeControlContainer: "XFormControlContainer"
    readonly property string kObjectTypeCollapsibleGroup: "XFormCollapsibleGroupControl"
    readonly property string kObjectTypeRepeatControl: "XFormRepeatControl"

    //--------------------------------------------------------------------------

    signal clearErrors()
    signal validationError(var error);
    signal closeAction();
    signal saveAction();

    signal controlFocusChanged(Item control, bool active, var binding);

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        refresh();
    }

    //--------------------------------------------------------------------------

    onControlFocusChanged: {
        if (debug) {
            console.log(logCategory, "onControlFocusChanged:", active, JSON.stringify(binding), control);
        }

        currentActiveControl = active ? control : null;

        if (debug) {
            console.log(logCategory, "currentActiveControl:", currentActiveControl);
        }

        if (active) {
            return;
        }

        if (xform.hasSaveIncomplete && !XFormJS.toBoolean(binding["@saveIncomplete"])) {
            return;
        }

        if (debug) {
            console.log(logCategory, "Focus change saveIncomplete:", JSON.stringify(binding), control);
        }

        saveAction();
    }

    //--------------------------------------------------------------------------

    function validate(callback) {
        console.log(logCategory, arguments.callee.name);

        finalize();

        clearErrors();

        var error = formData.validate();

        if (!error) {
            callback();
            return;
        }

        validationError(error);
    }

    onValidationError: {
        if (debug) {
            console.log(logCategory, "onValidationError nodeset:", error.nodeset, "nesting:", JSON.stringify(error.nesting, undefined, 2));
        }

        var controlNode = error.controlNode;
        if (!controlNode) {
            controlNode = controlNodes[error.nodeset];
        }

        var nestedError = Array.isArray(error.nesting) && error.nesting.length > 0;
        if (nestedError) {
            var nestIndex = error.nesting.length - 1;
            var nest = error.nesting[nestIndex];
            error.detailedText = "%1:%2".arg(nest.tableName).arg(nest.rowIndex + 1);
        }

        error.debugText = "Field (.): %1\nLabel: %2\nConstraint: %3\nConstraint check: %4\nNesting: %5"
        .arg(error.field.name)
        .arg(error.label)
        .arg(error.expression)
        .arg(error.activeExpression)
        .arg(JSON.stringify(error.nesting, undefined, 2));


        function popupError() {
            if (debug) {
                console.log(logCategory, "onValidationError: No control node for:", error.nodeset);
            }

            var popup = errorPopup.createObject(xform,
                                                {
                                                    errorInfo: error
                                                });

            popup.open();
        }

        if (!controlNode) {
            popupError();
            return;
        }

        var control = controlNode.control;
        var container = XFormJS.findParent(control, undefined, kObjectTypeControlContainer);
        if (!container) {
            container = XFormJS.findParent(control, undefined, kObjectTypeCollapsibleGroup);
        }

        if (!container) {
            console.warn(logCategory, "onValidationError: No container for:", error.nodeset);
            popupError();
            return;
        }

        var page = XFormJS.findParent(container, Body.kTypeGroup, undefined,
                                      function (item) {
                                          return item.isPage;
                                      });



        if (debug) {
            console.log(logCategory, " - controlNode:", controlNode);
            console.log(logCategory, " - control:", control);
            console.log(logCategory, " - container:", container);
            console.log(logCategory, " - page:", page);
        }


        var didSetError;

        if (nestedError) {
            var repeat = XFormJS.findParent(container, Body.kTypeRepeat);

            if (debug) {
                console.log(logCategory, " - repeat:", repeat);
            }

            if (repeat) {
                repeat.setError(error);
                didSetError = true;
            }
        }

        if (!didSetError) {
            container.setError(error);
        }

        // Ensure page is visible

        if (page) {
            pageNavigator.gotoPage(page);
        }

        // Expand collapsed parent groups

        XFormJS.enumerateParents(container,
                                 function (item) {
                                     if (AppFramework.typeOf(item, true) === kObjectTypeCollapsibleGroup) {
                                         if (item.collapsed) {
                                             item.collapse(false);
                                         }
                                     }

                                     return true;
                                 });


        ensureItemVisible(container);
        xform.style.errorFeedback();

        //        XFormJS.logParents(control);
    }

    Component {
        id: errorPopup

        XFormErrorPopup {
        }
    }

    //--------------------------------------------------------------------------

    initialItem: ColumnLayout {
        id: formLayout

        property alias scrollView: xformView.scrollView

        XFormPageNavigator {
            id: pageNavigator

            Layout.fillWidth: true

            visible: false
            debug: xform.debug

            onPageActivated: {
                scrollView.ensureVisible(currentPage);
            }
        }

        Rectangle {
            id: xformView

            property alias scrollView: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: style.backgroundColor

            function closeAction() {
                xform.closeAction();
            }

            Image {
                anchors.fill: parent

                visible: style.backgroundImage > ""
                source: style.backgroundImage > "" ? sourceInfo.folder.fileUrl(style.backgroundImage) : ""
                fillMode: style.backgroundImageFillMode
            }

            VerticalScrollView {
                id: scrollView

                anchors {
                    fill: parent
                }

                padding: isPagesLayout ? 0 : 4 * AppFramework.displayScaleFactor
                leftPadding: isPagesLayout ? 0 : 12 * AppFramework.displayScaleFactor
                rightPadding: leftPadding

                XFormControlsLayout {
                    id: controlsLayout

                    readonly property bool relevant: true
                    readonly property bool relevantIsDynamic: false
                    readonly property alias editable: xform.editable

                    spacing: 5 * AppFramework.displayScaleFactor

                    //--------------------------------------------------------------
                    // Used to determine if language is right to left base on the language name text

                    TextInput {
                        id: languageText

                        property bool rightToLeft: isRightToLeft(0, length)
                        property int textDirection: rightToLeft ? Qt.RightToLeft : Qt.LeftToRight

                        text: language
                        readOnly: true
                        visible: false
                    }

                    //--------------------------------------------------------------
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(xform, true)
    }

    //--------------------------------------------------------------------------

    XFormLocaleInfo {
        id: localeProperties

        textDirection: languageText.textDirection
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: sourceInfo
        url: source

        onPathChanged: {
            var folderName = sourceInfo.baseName + "-media";
            if (folder.fileExists(folderName)) {
                mediaFolder.path = folder.filePath(folderName);
            } else {
                mediaFolder.path = folder.filePath("media");
            }

            //            listsCache.dataFolder.path = folder.filePath("cache");
            //            listsCache.dataFolder.makeFolder();

            extensionsFolder.path = folder.filePath("extensions");

            settings.initialize(folder, baseName);
        }
    }

    FileFolder {
        id: mediaFolder
    }

    FileFolder {
        id: extensionsFolder
    }

    FileFolder {
        id: attachmentsFolder

        path: "~/ArcGIS/My Survey Attachments"

        Component.onCompleted: {
            makeFolder();
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: xform.positionSourceManager
        stayActiveOnError: true
        listener: "XForm title: %1".arg(title)

        onNewPosition: {
            formData.updateAutoGeometry(position, wkid);
            stop();
        }
    }

    //--------------------------------------------------------------------------

    XFormSettings {
        id: settings
    }

    XFormSchema {
        id: schema
    }

    XFormData {
        id: formData

        schema: schema
        defaultWkid: positionSourceConnection.wkid
        locale: xform.locale
        imagesFolder: attachmentsFolder
    }

    XFormBindings {
        id: bindings

        formData: xform.formData
    }

    XFormCalculates {
        id: calculates

        formData: xform.formData
    }

    XFormListsCache {
        id: listsCache
    }

    XFormItemsets {
        id: itemsets

        listsCache: listsCache
        dataFolder {
            path: mediaFolder.path
        }
    }

    XFormDataLists {
        id: dataLists

        dataFolder: mediaFolder
    }

    //--------------------------------------------------------------------------

    function refresh() {
        status = statusLoading;

        var xml = sourceInfo.folder.readTextFile(AppFramework.resolvedPath(source));

        json = AppFramework.xmlToJson(xml);

        if (!json) {
            json = {};
        }

        if (!json.head) {
            json.head = {};
        }

        if (!json.body) {
            json.body = {};
        }

        //        console.log(logCategory, "Refreshing XForm", JSON.stringify(json, undefined, 2));

        if (debug) {
            var fn = AppFramework.resolvedPath(source).replace(".xml", ".json");
            sourceInfo.folder.writeJsonFile(fn, json);
        }


        refreshInfo();

        initializeLanguages();

        title = json.head ? json.head.title : "";

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;

            console.log(logCategory, "submission:", JSON.stringify(submission, undefined, 2));
        } else {
            submission = {};
        }

        instances = XFormJS.asArray(json.head.model.instance);

        if (debug) {
            console.log(logCategory, instances.length, "instances:", JSON.stringify(instances, undefined, 2));
        }

        instance = instances[0];

        var elements = instance["#nodes"];
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].charAt(0) !== '#') {
                instanceName = elements[i];
                break;
            }
        }

        console.log(logCategory, "instanceName:", instanceName);

        instance = instances[0]; //json.head.model.instance[instanceName];

        version = (((instance || {} )[instanceName] || {})["@version"]) || "";

        console.log(logCategory, "version:", version);

        var instanceNameNodeset = "/" + instanceName + "/meta/instanceName";
        formData.instanceNameBinding = findBinding(instanceNameNodeset);

        bindings.initialize(XFormJS.asArray(json.head.model.bind), instance);

        layoutStyle = json.body["@class"] || "";

        console.log(logCategory, arguments.callee.name, "layoutStyle:", layoutStyle);

        isPagesLayout = XFormJS.contains(layoutStyle, "pages");
        isGridTheme = layoutStyle.indexOf("theme-grid") >= 0;

        console.log(logCategory, "style:", layoutStyle, "groupControlColumns:", groupControlColumns);

        createControls(controlsLayout, json.body);
        addPaddingControl(controlsLayout);

        console.log(logCategory, "Media folder:", mediaFolder.exists, mediaFolder.path);
        console.log(logCategory, "Extensions folder:", extensionsFolder.exists, extensionsFolder.path);

        schema.update(json);

        bindCalculates();

        formData.expressionsList.enabled = true;

        if (reviewMode) {
            setDefaultValues(undefined, true);
        } else {
            preloadValues();
            setDefaultValues();
            updateCurrentPosition();

            console.log(logCategory, "Updating expressions");
            formData.expressionsList.updateExpressions();
        }

        logLocaleInfo();

        status = statusReady;
    }


    function refreshInfo() {
        var formInfo = sourceInfo.folder.readJsonFile(sourceInfo.baseName + ".info");

        refreshDisplayInfo(formInfo.displayInfo);
        refreshImagesInfo(formInfo.imagesInfo);
    }

    function refreshDisplayInfo(displayInfo) {
        if (!displayInfo) {
            displayInfo = {};
        }

        console.log(logCategory, "refreshDisplayInfo", JSON.stringify(displayInfo, undefined, 2));

        if (displayInfo.snippetExpression > "") {
            formData.snippetExpression = displayInfo.snippetExpression;
        }

        refreshStyleInfo(displayInfo.style);
        mapSettings.refresh(sourceInfo.folder.path, displayInfo.map);
    }

    function refreshStyleInfo(styleInfo) {
        if (!styleInfo) {
            return;
        }

        if (styleInfo.textColor > "") {
            style.textColor = styleInfo.textColor;
        }

        if (styleInfo.backgroundColor > "") {
            style.backgroundColor = styleInfo.backgroundColor;
        }

        style.backgroundImage = styleInfo.backgroundImage || "";

        if (styleInfo.toolbarBackgroundColor > "") {
            style.titleBackgroundColor = styleInfo.toolbarBackgroundColor;
        }

        if (styleInfo.toolbarTextColor > "") {
            style.titleTextColor = styleInfo.toolbarTextColor;
        }

        if (styleInfo.inputTextColor > "") {
            style.inputTextColor = styleInfo.inputTextColor;
        }

        if (styleInfo.inputBackgroundColor > "") {
            style.inputBackgroundColor = styleInfo.inputBackgroundColor;
        }
    }

    function refreshImagesInfo(imagesInfo) {
        if (typeof imagesInfo !== "object") {
            imagesInfo = {};
        }

        console.log(logCategory, "refreshImagesInfo", JSON.stringify(imagesInfo, undefined, 2));

        if (imagesInfo.hasOwnProperty("captureResolution")) {
            captureResolution = Number(imagesInfo.captureResolution);
        }

        if (imagesInfo.hasOwnProperty("allowCaptureResolutionOverride")) {
            allowCaptureResolutionOverride = Boolean(imagesInfo.allowCaptureResolutionOverride);
        }
    }

    function isNumber(value) {
        return isFinite(Number(value));
    }

    function isBool(value) {
        return typeof value === "boolean";
    }

    //--------------------------------------------------------------------------

    function bindCalculates(table) {
        if (!table) {
            table = schema.schema;
        }

        console.log(logCategory, arguments.callee.name, "table:", table.name, "nodeset:", table.nodeset);

        table.fields.forEach(function bindField(field) {
            var parentGroup;

            var sep = field.nodeset.lastIndexOf("/");
            if (sep > 0) {
                var parentNodeset = field.nodeset.substr(0, sep);
                parentGroup = groupNodes[parentNodeset];
            }

            if (!(field.calculate > "" || field.relevant > "") && !parentGroup) {
                return;
            }

            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                if (debug) {
                    console.log(logCategory, arguments.callee.name, "Adding calculate element field:", field.name, "nodeset:", field.nodeset);
                }

                var binding = bindings.findByNodeset(field.nodeset);

                if (!binding) {
                    console.error(logCategory, arguments.callee.name, "No binding for field:", field.name, "nodeset:", field.nodeset);
                    return;
                }

                if (field.calculate > "" || field.relevant > "" || parentGroup) {
                    calculates.createCalculate(field, binding, parentGroup);
                }

                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error(logCategory, arguments.callee.name, "No control associated with calculate node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "Binding calculate:", field.name, "=", JSON.stringify(field.calculate), "control:", control);
            }

            if (field.calculate > "") {
                control.calculatedValue = formData.calculateBinding(field.binding);
            }
        });

        table.relatedTables.forEach(function (relatedTable) {
            bindCalculates(relatedTable);
        });
    }

    //--------------------------------------------------------------------------

    function finalize(table) {
        if (!table) {
            table = schema.schema;
        }

        if (!table) {
            return;
        }

        console.log(logCategory, arguments.callee.name, "table:", table.tableName);

        table.fields.forEach(function (field) {
            var value;

            switch (field.preload) {
            case "timestamp":
                switch (field.preloadParams) {
                case "end":
                    value = (new Date()).valueOf();
                    break;
                }
                break;
            }

            var controlNode = controlNodes[field.nodeset];

            if (controlNode) {
                var control = controlNode.control;

                if (control && control.storeValue) {
                    value = control.storeValue();
                }
            }

            if (value) {
                formData.setValue(field.binding, value);
            }
        });
    }

    //--------------------------------------------------------------------------
    // https://opendatakit.org/help/form-design/examples/#Property_values

    function preloadValues(table) {
        if (!table) {
            table = schema.schema;
        }

        function uri(scheme, value) {
            return value > "" ? scheme + ":" + value : undefined;
        }

        table.fields.forEach(function (field) {
            var value;

            switch (field.preload) {
            case "date":
                switch (field.preloadParams) {
                case "today":
                    value = (new Date()).valueOf();
                    break;
                }
                break;

            case "timestamp":
                switch (field.preloadParams) {
                case "start":
                    value = (new Date()).valueOf();
                    break;

                case "end":
                    value = (new Date()).valueOf();
                    break;
                }
                break;

            case "property":
                value = XFormJS.systemProperty(app, field.preloadParams);
                break;

            case "uid":
                value = AppFramework.createUuidString(2);
                break;
            }

            if (!XFormJS.isEmpty(value)) {
                formData.setValue(field.binding, value);
            }
        });
    }

    //--------------------------------------------------------------------------

    XFormGeoposition {
        id: _geoposition
    }

    function setPosition(coordinate, reason) {
        console.log(logCategory, arguments.callee.name, "coordinate:", coordinate, "reason:", reason);

        if (!_geoposition.fromCoordinate(coordinate, 1)) {
            console.error(logCategory, arguments.callee.name, "Invalid coordinate:", coordinate);
            return;
        }

        if (positionSourceConnection.active) {
            console.log(logCategory, "Stopping position source");
            positionSourceConnection.stop();
        }

        var value = _geoposition.toObject();

        var table = schema.schema;

        table.fields.forEach(function (field) {
            if (field.type !== 'geopoint') {
                return;
            }

            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                if (debug) {
                    console.log(logCategory, "setValues setting non-control field:", field.name, "value:", JSON.stringify(value));
                }
                formData.setFieldValue(field, value);
                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error(logCategory, "No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (!control.setValue) {
                console.error(logCategory, "setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }

            if (debug) {
                console.log(logCategory, "setValues setting control field:", field.name, "value:", JSON.stringify(value));
            }

            console.log(logCategory, "control.setValue nodeset:", field.nodeset);
            control.setValue(value, reason);
        });

    }

    //--------------------------------------------------------------------------

    function updateCurrentPosition() {
        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    function setDefaultValues(table, defaultValuesOnly) {
        if (!table) {
            table = schema.schema;
        }

        table.fields.forEach(function (field) {
            var defaultValue = field.defaultValue;

            if (XFormJS.isEmpty(defaultValue)) {
                return;
            }

            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                if (defaultValuesOnly) {
                    return;
                }

                if (debug) {
                    console.log(logCategory, "setting non-control defaultValue:", JSON.stringify(defaultValue), "field:", field.name);
                }

                var calculate = calculates.findByNodeset(field.nodeset);

                if (calculate) {
                    if (calculate.relevant) {
                        calculate.setValue(defaultValue);
                    }
                } else {
                    formData.setValue(field.binding, defaultValue);
                }

                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error(logCategory, "No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (control.setDefaultValue) {
                control.setDefaultValue(defaultValue);
                return;
            }

            if (defaultValuesOnly) {
                return;
            }

            if (!control.setValue) {
                console.error(logCategory, "setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }

            if (debug) {
                console.log(logCategory, "setting control defaultValue:", JSON.stringify(defaultValue), "field:", field.name);
            }

            if (control.relevant) {
                control.setValue(defaultValue);
            }
        });
    }

    //--------------------------------------------------------------------------

    function initializeValues(values) {
        formData.instance = JSON.parse(JSON.stringify(values));

        var rootTable = xform.schema.schema;
        var rootTableName = rootTable.name;
        var rootValues = rowData[rootTableName];

        formData.setInitializing(rootTableName, true);

        setValues(undefined, rootValues, 2, 1);

        triggerExpressions();
        formData.tableRowIndexChanged("", -1);

        formData.setInitializing(rootTableName, false);
    }

    //--------------------------------------------------------------------------

    function setValues(table, values, mode, reason) { // mode: 1=Don't skip empty values (paste), 2=only set if current value is empty
        if (!table) {
            table = schema.schema;
        }

        var metaData;
        if (values) {
            metaData = formData.metaValue(values, undefined);
        } else {
            var data = formData.getTableRow(table.name);
            metaData = formData.metaValue(data, undefined);
        }

        if (debug) {
            console.log(logCategory, "setValues:", table.name, "mode:", mode, "reason:", reason, "values:", JSON.stringify(values), "metaData:", JSON.stringify(metaData));
        }

        table.fields.forEach(function (field) {
            var value = formData.valueByField(field, values);

            if (mode !== 2 && XFormJS.isEmpty(value)) {
                return;
            }

            if (mode === 1) {
                var currentValue = formData.valueByField(field);

                if (!XFormJS.isEmpty(currentValue)) {
                    return;
                }

                if (field.type === "binary") {
                    console.log(logCategory, "Skipping setValue:", field.name, "type:", field.type, "mode:", mode, "value:", currentValue);
                    return;
                }
            }

            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                if (debug) {
                    console.log(logCategory, "setValues setting non-control field:", field.name, "value:", JSON.stringify(value));
                }
                formData.setValue(field.binding, value);
                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error(logCategory, "No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (!control.setValue) {
                console.error(logCategory, "setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }

            if (debug) {
                console.log(logCategory, "setValues setting control field:", field.name, "value:", JSON.stringify(value));
            }

            control.setValue(value, reason, metaData);
        });
    }

    //--------------------------------------------------------------------------

    function pasteValues(values) {
        setValues(undefined, values, 1);
    }

    //--------------------------------------------------------------------------

    function resetValues(table) {
        if (!table) {
            table = schema.schema;
        }

        console.log(logCategory, "resetValues:", table.name);

        table.fields.forEach(function (field) {
            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                formData.setValue(field.binding, undefined);
                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error(logCategory, "No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (!control.setValue) {
                console.error(logCategory, "setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }

            control.setValue(undefined);
        });
    }

    //--------------------------------------------------------------------------

    function triggerExpressions(table, recursive) {
        if (!table) {
            table = schema.schema;
        }

        console.log(logCategory, "Triggering expressions for:", table.name, "nodeset:", table.nodeset);

        table.fields.forEach(function (field) {
            if (!(field.calculate > "")) {
                //console.log(logCategory, "No calculate for:", field.name);
                return;
            }

            if (field.binding["@esri:fieldType"] !== "null") {
                //console.log(logCategory, "Not a null field:", field.name, "binding:", JSON.stringify(field.binding));
                return;
            }

            //console.log(logCategory, "Triggering:", field.name, field.binding, field.calculate);
            formData.expressionsList.triggerExpression(field.binding, "calculate");
        });

        if (recursive) {
            table.relatedTables.forEach(function (relatedTable) {
                triggerExpressions(relatedTable, recursive);
            });
        }
    }

    //--------------------------------------------------------------------------

    function createControls(parentItem, parentNode, skipNodes) {
        if (!parentNode) {
            return;
        }

        var nodeNames = parentNode["#nodes"];

        if (!nodeNames) {
            console.warn(logCategory, "No #nodes found");
            return;
        }

        for (var i = 0; i < nodeNames.length; i++) {
            var name = nodeNames[i];
            if (name.charAt(0) === '#') {
                console.log(logCategory, "Skip", name);
                continue;
            }

            var nodeName = XFormJS.nodeName(name);
            var nodeIndex = XFormJS.nodeIndex(name);

            if (skipNodes) {
                if (skipNodes.indexOf(nodeName) >= 0) {
                    continue;
                }
            }

            //console.log(logCategory, nodeNames[i], "nodeName", nodeName, "nodeIndex", nodeIndex);
            var node;

            if (nodeIndex >= 0) {
                node = parentNode[nodeName][nodeIndex];
            } else {
                node = parentNode[nodeName];
            }

            var ref = node["@ref"];

            var binding = bindings.findByNodeset(ref);

            var container = createControl(parentItem, nodeName, node, binding, i === (nodeNames.length - 1));
        }
    }

    //--------------------------------------------------------------------------

    function createControl(layout, controlType, formElement, binding, isLast) {
        var container;

        if (binding) {
            if (XFormJS.toBoolean(binding.element["@saveIncomplete"])) {
                hasSaveIncomplete = true;
            }
        }

        switch (controlType) {
        case Body.kTypeGroup:
            container = createGroup(layout, formElement, binding);
            break;

        case Body.kTypeRepeat:
            container = createRepeat(layout, formElement, binding);
            break;

        case Body.kTypeInput:
            container = createInput(layout, formElement, binding);
            break;

        case Body.kTypeSelect1:
            container = createSelect1(layout, formElement, binding);
            break;

        case Body.kTypeSelect:
            container = createSelect(layout, formElement, binding);
            break;

        case Body.kTypeUpload:
            container = createUpload(layout, formElement, binding);
            break;

        case Body.kTypeRange:
            container = createRange(layout, formElement, binding);
            break;

        default:
            console.log(logCategory, "Unhandled controlType:", controlType);
            container = defaultControl.createObject(layout, {"text": controlType });
            break;
        }

        if (isGridTheme) {
            var span = container.span;

            if (isLast && layout.columnsRemaining > span) {
                span = layout.columnsRemaining;
            }

            function updateLastItem() {
                if (!layout.lastItem) {
                    return;
                }

                if (layout.lastRemaining > 0 && layout.lastItem.span > 0) {
                    var lastItem = layout.lastItem;

                    lastItem.span = lastItem.span + layout.lastRemaining;
                    lastItem.Layout.columnSpan = lastItem.span;
                }
            }

            if (span > layout.columnsRemaining && layout.columnsRemaining < layout.columns) {
                updateLastItem();

                layout.columnsRemaining = layout.columns;
            }

            if (span > 0) {
                layout.columnsRemaining -= span;
                container.Layout.columnSpan = span;
            }

            var remaining = layout.columnsRemaining;

            if (layout.columnsRemaining <= 0) {
                layout.columnsRemaining = layout.columns;
            }

            layout.lastRemaining = remaining;
            layout.lastItem = container;
        } else {
            //container.Layout.columnSpan = container.span;
        }

        return container;
    }

    //--------------------------------------------------------------------------

    function addControlNode(binding, group, control, formElement) {
        if (!binding) {
            return;
        }

        if (!control) {
            return;
        }

        if (typeof control.valueModified === "function") {
            control.valueModified.connect(onControlValueModified);
        } else {
            if (debug) {
                console.warn(logCategory, arguments.callee.name, "No valueModified signal control:", AppFramework.typeOf(control, true));
            }
        }

        var nodeset = binding.nodeset;

        if (!(nodeset > "")) {
            console.warn(logCategory, "Empty nodeset in binding");
            return;
        }

        var controlNode = {
            group: group,
            control: control,
            formElement: formElement
        };

        if (debug) {
            console.log(logCategory, "addControlNode", nodeset, control);
        }

        controlNodes[nodeset] = controlNode;
    }

    //--------------------------------------------------------------------------

    function onControlValueModified(control) {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        var controlGroup;
        if (control) {
            controlGroup = XFormJS.findParent(control, undefined, kObjectTypeControlContainer);
        }

        if (controlGroup) {
            controlGroup.clearError();
        } else {
            clearErrors();
        }
    }

    //--------------------------------------------------------------------------

    function onSaveIncomplete() {
        console.log(logCategory, "onSaveIncomplete");
    }

    //--------------------------------------------------------------------------

    function parseWidth(appearance, defaultWidth) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "appearance:", appearance, "defaultWidth:", defaultWidth);
        }

        if (!appearance) {
            return defaultWidth;
        }

        var w = appearance.match(/^.*\s*w(\d+)\s*.*$/);
        if (Array.isArray(w) && w.length > 1) {
            var width = parseInt(w[1]);
            if (!isFinite(width) || w <= 0) {
                width = defaultWidth;
            }
            return width;
        } else {
            return defaultWidth;
        }
    }

    //--------------------------------------------------------------------------

    function createGroup(parentItem, formElement, binding) {
        var appearance = formElement["@appearance"];

        var controlColumns = parseWidth(appearance, xform.groupControlColumns);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "controlColumns:", controlColumns);
        }

        var fieldList = XFormJS.contains(appearance, "field-list");
        var isPage = fieldList && isPagesLayout;

        var group = collapsibleGroupControl.createObject(parentItem, {
                                                             objectName: Body.kTypeGroup,
                                                             isPage: isPage,
                                                             formElement: formElement,
                                                             binding: binding,
                                                             formData: formData,
                                                             controlColumns: controlColumns
                                                         });

        if (formElement.label) {
            group.labelControl = groupLabelControl.createObject(group.headerItems, {
                                                                    "objectName": Body.kTypeLabel,
                                                                    "formData": formData,
                                                                    "label": formElement.label,
                                                                    "collapsible": !isPage,
                                                                    "collapsed": !isPage && XFormJS.contains(appearance, "compact"),
                                                                    "required": binding ? binding.isRequiredBinding() : false
                                                                });
        }

        if (formElement.hint) {
            group.hintControl = createHint(group.contentItems, formElement, binding);
        }

        if (isPage) {
            pageNavigator.addPage(group);
        }

        if (isGridTheme) {
            gridHeaderComponent.createObject(group.headerItems);

            var padding = group.padding;

            if (group.labelControl) {
                group.labelControl.Layout.topMargin = 8 * AppFramework.displayScaleFactor;
            }

            group.Layout.alignment = Qt.AlignTop;
            group.Layout.fillHeight = true;
            group.controlSpacing = 0;
            group.flat = true;
            group.padding = 0;
            //group.contentItems.anchors.leftMargin = padding;

            group.border.color = style.gridBorderColor;
            group.border.width = style.gridBorderWidth;

            //            if (group.hintControl) {
            //                group.hintControl.Layout.fillHeight = true;
            //            } else if (group.labelControl) {
            //                group.labelControl.Layout.fillHeight = true;
            //                group.labelControl.Layout.topMargin = padding;;
            //            }
        }

        if (binding) {
            groupNodes[binding.nodeset] = group;
        }

        createControls(group.contentItems, formElement, ["label"]);

        return group;
    }

    //--------------------------------------------------------------------------

    function createRepeat(parentItem, formElement, binding) {
        var nodeset = formElement["@nodeset"];

        schema.repeatNodesets.push(nodeset);

        if (!formElement["#nodes"]) {
            console.warn(logCategory, "No control nodes in repeat");
            return;
        }

        var appearance = formElement["@appearance"];

        binding = bindings.findByNodeset(nodeset);


        var fieldList = XFormJS.contains(appearance, "field-list");
        var isPage = fieldList && isPagesLayout;
        var groupControl = XFormJS.findParent(parentItem, Body.kTypeGroup);

        if (!groupControl) {
            XFormJS.logParents(parentItem);
            return;
        }

        if (!isPage && XFormJS.contains(appearance, "compact")) {
            groupControl.collapse();
        }

        var repeat = repeatControl.createObject(parentItem, {
                                                    objectName: Body.kTypeRepeat,
                                                    formElement: formElement,
                                                    nodeset: nodeset,
                                                    binding: binding,
                                                    formData: formData,
                                                    groupControl: groupControl,
                                                    appearance: appearance
                                                });

        if (formElement.label) {
            groupLabelControl.createObject(repeat.contentItems, {
                                               "objectName": Body.kTypeLabel,
                                               "formData": formData,
                                               "label": formElement.label
                                           });
        }

        if (formElement.hint) {
            createHint(repeat.contentItems, formElement, binding);
        }

        if (isPage) {
            groupControl.isPage = true;
            groupControl.collapse(false);
            var labelControl = groupControl.labelControl;
            if (labelControl) {
                labelControl.collapsible = false;
            }

            pageNavigator.addPage(groupControl);
        }

        if (isGridTheme) {
            //            repeat.border.color = style.gridBorderColor;
            //            repeat.border.width = style.gridBorderWidth;
            repeat.contentItems.spacing = 0;
            repeat.showSeparator = false;
            groupControl.padding = 8 * AppFramework.displayScaleFactor;
            groupControl.backgroundColor = "transparent"
        }

        addControlNode(binding, groupControl, repeat, formElement);
        createControls(repeat.contentItems, formElement, ["label"]);

        return groupControl;
    }

    //--------------------------------------------------------------------------

    function createHint(parentItem, formElement, binding) {
        var control = hintControl.createObject(parentItem, {
                                                   "objectName": Body.kTypeHint,
                                                   "formData": formData,
                                                   "hint": formElement.hint
                                               });

        return control;
    }

    //--------------------------------------------------------------------------

    function createControlContainer(parentItem, formElement, binding, options) {
        if (!options) {
            options = {};
        }

        var container = controlContainer.createObject(parentItem, {
                                                          binding: binding,
                                                          formElement: formElement,
                                                          formData: formData
                                                      });

        if (formElement.label) {
            container.labelControl = labelControl.createObject(container.contentItems,
                                                               {
                                                                   "objectName": Body.kTypeLabel,
                                                                   "formData": formData,
                                                                   "label": formElement.label,
                                                                   "options": options,
                                                                   "required": binding ? binding.isRequiredBinding() : false
                                                               });
        }

        if (formElement.hint) {
            container.hintControl = createHint(container.contentItems, formElement, binding);

            if (container.labelControl) {
                container.labelControl.ttsText = Qt.binding(function() {
                    return container.hintControl.hintText;
                });
            }
        }

        if (isGridTheme) {
            container.Layout.alignment = Qt.AlignTop;
            container.Layout.fillHeight = true;
            container.border.color = style.gridBorderColor;
            container.border.width = style.gridBorderWidth;
            container.background.anchors.margins = container.border.width;
            container.flat = true;

            //            if (container.hintControl) {
            //                container.hintControl.Layout.fillHeight = true;
            //            } else if (container.labelControl) {
            //                container.labelControl.Layout.fillHeight = true;
            //            }
        }

        return container;
    }

    //--------------------------------------------------------------------------

    function createInput(parentItem, formElement, binding) {
        if (formElement["@query"] > "") { // select_one_external ?
            return createSelect1(parentItem, formElement, binding);
        }

        var group = createControlContainer(parentItem, formElement, binding);

        if (!binding) {
            console.warn(logCategory, "No binding for:", JSON.stringify(formElement));
            return;
        }

        var appearance = formElement["@appearance"] || "";
        var esriStyle = formElement["@esri:style"] || "";
        var control;

        var addInName;
        if (esriStyle.indexOf("addIn=") >= 0) {
            var parameters = XFormJS.parseParameters(esriStyle);
            addInName = parameters.addIn;
        } else if (appearance > "") {
            addInName = addIns.findAppearanceAlias(Appearance.toArray(appearance));
        }

        if (addInName > "" && !(binding.type === Bind.kTypeBarcode)) {
            control = addInControl.createObject(group.contentItems,
                                                {
                                                    addInName: addInName,
                                                    formElement: formElement,
                                                    binding: binding,
                                                    formData: formData
                                                });
        } else {
            switch (binding.type) {
            case Bind.kTypeDate:
                if (Appearance.contains(appearance, Appearance.kMonthYear) ||
                        Appearance.contains(appearance, Appearance.kYear)) {
                    control = monthYearControl.createObject(group.contentItems, {
                                                                formElement: formElement,
                                                                binding: binding,
                                                                formData: formData
                                                            });
                } else {
                    control = dateControl.createObject(group.contentItems, {
                                                           formElement: formElement,
                                                           binding: binding,
                                                           formData: formData
                                                       });
                }
                break

            case Bind.kTypeDateTime:
                control = dateTimeControl.createObject(group.contentItems, {
                                                           formElement: formElement,
                                                           binding: binding,
                                                           formData: formData
                                                       });

                break

            case Bind.kTypeTime:
                control = timeControl.createObject(group.contentItems, {
                                                       formElement: formElement,
                                                       binding: binding,
                                                       formData: formData
                                                   });

                break

            case Bind.kTypeGeopoint:
                control = geopointControl.createObject(group.contentItems, {
                                                           formElement: formElement,
                                                           binding: binding,
                                                           formData: formData
                                                       });
                break;

            case Bind.kTypeGeotrace:
                control = geopolyControl.createObject(group.contentItems, {
                                                          formElement: formElement,
                                                          binding: binding,
                                                          formData: formData
                                                      });
                break;

            case Bind.kTypeGeoshape:
                control = geopolyControl.createObject(group.contentItems, {
                                                          formElement: formElement,
                                                          binding: binding,
                                                          formData: formData,
                                                      });
                break;

            case Bind.kTypeString:
                if (Appearance.contains(appearance, Appearance.kMultiline)) {
                    control = multiLineControl.createObject(group.contentItems, {
                                                                formElement: formElement,
                                                                binding: binding,
                                                                formData: formData
                                                            });
                } else {
                    if (binding.element["@readonly"] === "true()") {
                        group.flat = true;
                        control = noteControl.createObject(group.contentItems, {
                                                               binding: binding,
                                                               formData: formData
                                                           });
                    } else {
                        control = inputControl.createObject(group.contentItems, {
                                                                formElement: formElement,
                                                                binding: binding,
                                                                formData: formData
                                                            });
                    }
                }
                break;

            case Bind.kTypeInt:
                if (Appearance.contains(appearance, Appearance.kDistress)) {
                    control = distressControl.createObject(group.contentItems, {
                                                               formElement: formElement,
                                                               binding: binding,
                                                               formData: formData
                                                           });
                } else {
                    control = inputControl.createObject(group.contentItems, {
                                                            formElement: formElement,
                                                            binding: binding,
                                                            formData: formData
                                                        });
                }
                break;

            default:
                control = inputControl.createObject(group.contentItems, {
                                                        formElement: formElement,
                                                        binding: binding,
                                                        formData: formData
                                                    });
                break;
            }
        }

        control.objectName = Body.kTypeInput;
        addControlNode(binding, group, control, formElement);

        return group;
    }

    //--------------------------------------------------------------------------

    function createSelect1(parentItem, formElement, binding) {
        var appearance = formElement["@appearance"] || "";
        var isImageMap = Appearance.contains(appearance, Appearance.kImageMap);
        var groupOptions = {
            "noImage": isImageMap
        };

        var labelElement = formElement.label;
        var tableList = Appearance.contains(appearance, Appearance.kLabel) || Appearance.contains(appearance, Appearance.kListNoLabel);

        if (tableList) {
            formElement.label = undefined;
        }

        var group = createControlContainer(parentItem, formElement, binding, groupOptions);

        //console.log(logCategory, arguments.callee.name, "labelControl:", group.labelControl);

        var items = XFormJS.asArray(formElement.item);
        var control;
        var itemset = null;

        if (formElement.itemset) {
            itemset = controlItemset.createObject(group, {
                                                      formData: formData,
                                                      itemset: formElement.itemset
                                                  });
        } else {
            var query = formElement["@query"];

            if (query > "") {
                var queryItemset = {
                    "external": true,
                    "@nodeset": query,
                    "value": {
                        "@ref": "name"
                    },
                    "label": {
                        "@ref": "jr:itext(label)"
                    }
                }

                itemset = controlItemset.createObject(group, {
                                                          formData: formData,
                                                          itemset: queryItemset
                                                      });
            }
        }

        var controlProperties = {
            binding: binding,
            formData: formData,
            items: items,
            itemset: itemset,
            appearance: appearance,
            groupLabel: labelElement,
            tableList: tableList
        };

        // TODO Improve appearance detection

        if (Appearance.contains(appearance, Appearance.kAutoComplete)) {
            controlProperties.originalitems = Array.isArray(items) ? items: [];
            control = select1ControlAuto.createObject(group.contentItems, controlProperties);
        } else {
            if (tableList) {
                nullControl.createObject(group.contentItems, {});
                group.topPadding = 0;
                group.bottomPadding = 4 * AppFramework.displayScaleFactor;
            }

            control = select1Control.createObject(group.contentItems, controlProperties);
        }

        control.objectName = Body.kTypeSelect1;
        addControlNode(binding, group, control, formElement);

        return group;
    }

    //--------------------------------------------------------------------------

    function createSelect(parentItem, formElement, binding) {
        var appearance = formElement["@appearance"] || "";
        var isImageMap = appearance.indexOf("image-map") >= 0;
        var groupOptions = {
            "noImage": isImageMap
        };

        var group = createControlContainer(parentItem, formElement, binding, groupOptions);

        var items = XFormJS.asArray(formElement.item);

        var controlProperties = {
            objectName: Body.kTypeSelect,
            binding: binding,
            formData: formData,
            items: items,
            appearance: appearance,
            groupLabel: formElement.label
        };

        if (appearance === "minimal" || !(appearance > "")) {
            controlProperties.columns = 1;
        }

        // TODO Improve appearance detection

        var control = selectControl.createObject(group.contentItems, controlProperties);

        addControlNode(binding, group, control, formElement);

        return group;
    }

    //--------------------------------------------------------------------------

    function createUpload(parentItem, formElement, binding) {
        var group = createControlContainer(parentItem, formElement, binding);

        var mediatype = formElement["@mediatype"] || "*/*";
        var appearance = formElement["@appearance"];

        var type = mediatype.split('/')[0];

        console.log(logCategory, "mediatype:", mediatype, "type:", type, "appearance:", appearance);

        var control;

        switch (type) {
        case "image" :
            if (Appearance.contains(appearance, Appearance.kSignature)) {
                control = signatureControl.createObject(group.contentItems, {
                                                            formElement: formElement,
                                                            binding: binding,
                                                            mediatype: mediatype,
                                                            formData: formData
                                                        });
            } else {
                control = imageControl.createObject(group.contentItems, {
                                                        formElement: formElement,
                                                        binding: binding,
                                                        mediatype: mediatype,
                                                        formData: formData
                                                    });
            }
            break;

        case "audio" :
            control = audioControl.createObject(group.contentItems, {
                                                    formElement: formElement,
                                                    binding: binding,
                                                    mediatype: mediatype,
                                                    formData: formData
                                                });
            break;

        }

        if (control) {
            control.objectName = Body.kTypeUpload;
            addControlNode(binding, group, control, formElement);
        }

        return group;
    }

    //--------------------------------------------------------------------------

    function createRange(parentItem, formElement, binding) {
        var group = createControlContainer(parentItem, formElement, binding);

        var control = rangeControl.createObject(group.contentItems,
                                                {
                                                    objectName: Body.kTypeRange,
                                                    formElement: formElement,
                                                    binding: binding,
                                                    formData: formData
                                                });

        addControlNode(binding, group, control, formElement);

        return group;
    }

    //--------------------------------------------------------------------------

    function addPaddingControl(parentItem) {
        paddingControl.createObject(parentItem, {
                                    });
    }

    Component {
        id: paddingControl

        XFormPaddingControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    function findObject(ref) {
        var body = json.body;

        for (var propertyName in body) {
            if (body.hasOwnProperty(propertyName)) {

                var propertyValue = body[propertyName];

                if (propertyValue["@ref"] === ref) {
                    propertyValue["#tagName"] = propertyName;

                    return propertyValue;
                } else if (propertyValue.length > 0) {
                    for (var i = 0; i < propertyValue.length; i++) {
                        if (propertyValue[i]["@ref"] === ref) {
                            propertyValue[i]["#tagName"] = propertyName;

                            return propertyValue[i];
                        }
                    }
                }
            }
        }

        return null;
    }

    function findBinding(ref) {
        var bindArray = XFormJS.asArray(json.head.model.bind);

        for (var i = 0; i < bindArray.length; i++) {
            var bind = bindArray[i];

            if (bind["@nodeset"] === ref) {
                return bind;
            }
        }

        for (i = 0; i < bindArray.length; i++) {
            bind = bindArray[i];

            var nodeset = bind["@nodeset"];
            var j = nodeset.lastIndexOf("/");
            if (j >= 0) {
                nodeset = nodeset.substr(j + 1);
            }

            if (nodeset === ref) {
                return bind;
            }
        }

        return null;
    }

    function textLookup(object) {
        if (typeof object === 'string') {
            if (object.substr(0, 9) === 'jr:itext(') {
                return textValue({
                                     "@ref": object
                                 });
            } else {
                return object;
            }
        } else {
            return textValue(object);
        }
    }

    //--------------------------------------------------------------------------

    function translationTextValue(object, language, form) {
        if (!object) {
            return "";
        }

        if (typeof object === 'string') {
            return object;
        }

        var ref = object["@ref"];
        if (ref) {
            var translation = findTranslation(textId(ref), language);

            if (debug) {
                console.log(logCategory, "itext translation:", JSON.stringify(translation, undefined, 2));
            }

            if (translation) {
                var value = translation.value;

                if (typeof value === "string") {
                    return value;
                }

                var values = XFormJS.asArray(value);

                if (debug) {
                    console.log(logCategory, "itext translation values:", JSON.stringify(values, undefined, 2));
                }

                for (var i = 0; i < values.length; i++) {
                    var v = values[i];

                    var vForm = v["@form"];

                    if (!form) {
                        // Return first value object without 'form' attribute

                        if (!vForm) {
                            return v;
                        }
                    } else if (vForm === form) {
                        return v;
                    }

                }
            }
        }

        return object;
    }

    //--------------------------------------------------------------------------

    function textValue(object, defaultText, form, language) {
        if (!object) {
            return defaultText ? defaultText : "";
        }

        if (typeof object === 'string') {
            return object;
        }

        var ref = object["@ref"];
        if (ref) {
            var translation = findTranslation(textId(ref), language);
            if (translation) {
                var value = translation.value;

                if (typeof value === "string") {
                    return value;
                }

                var values = XFormJS.asArray(value);
                if (values.length > 0) {
                    for (var i = 0; i < values.length; i++) {
                        var v = values[i];
                        var vForm = v["@form"];

                        // Skip media forms if no specifc form specified

                        if (!form) {
                            switch (vForm) {
                            case "image":
                            case "audio":
                            case "video":
                                continue;
                            }
                        }

                        if (!form || vForm === form) {
                            if (typeof v === "string") {
                                return v;
                            } else {
                                return v["#text"];
                            }
                        }
                    }

                    for (i = 0; i < values.length; i++) {
                        v = values[i];
                        if (typeof v === "string") {
                            return v;
                        }
                    }

                } else {
                    console.log(logCategory, "Translation value", JSON.stringify(value));
                    return value;
                }
            } else {
                console.log(logCategory, "No text for ", ref);
            }
        }

        if (object["#text"]) {
            return object["#text"];
        }

        // console.log(logCategory, "DefaultText", defaultText);

        return defaultText ? defaultText : "";
    }

    //--------------------------------------------------------------------------

    function mediaUrl(text) {
        if (typeof text !== "string") {
            if (debug) {
                console.error(logCategory, arguments.callee.name, "invalid text:", JSON.stringify(text));
            }

            return "";
        }

        if (text > "") {
            var urlInfo = AppFramework.urlInfo(text);
            if (urlInfo.scheme === "jr") {
                var fileName = urlInfo.fileName;

                if (fileName === "-") {
                    return fileName;
                } else if (fileName > "") {
                    if (mediaFolder.fileExists(fileName)) {
                        return mediaFolder.fileUrl(fileName);
                    }
                } else {
                    if (urlInfo.hasFragment && urlInfo.fragment === "tts") {
                        hasTTS = true;
                        return "tts://" + urlInfo.query;
                    }
                }
            }
        }

        return "";
    }

    function mediaValue(object, type) {
        var value = textValue(object, "", type);
        var url = mediaUrl(value);
        if (url === "-") {
            value = textValue(object, "", type, defaultLanguage);
            url = mediaUrl(value);
        }

        //console.log(logCategory, "mediaValue:", url, "value:", value);
        return url;
    }

    //--------------------------------------------------------------------------

    function findTranslation(id, language) {

        // console.log(logCategory, "findTransation", id);

        var translationSet = findTranslationSet(language);
        if (!translationSet) {
            return null;
        }

        var texts = XFormJS.asArray(translationSet.text);

        for (var t = 0; t < texts.length; t++) {
            var text = texts[t];

            if (text["@id"] === id) {
                return text;
            }
        }

        console.log(logCategory, "No translation for", id)

        return null;
    }

    function findTranslationSet(language) {
        var itext = json.head.model.itext;
        if (!itext) {
            return;
        }

        if (!language) {
            language = xform.language;
        }

        var translations = XFormJS.asArray(itext.translation);

        for (var i = 0; i < translations.length; i++) {
            var translation = translations[i];

            if (language > "") {
                if (translation["@lang"] !== language) {
                    continue;
                }
            }

            return translation;
        }

        console.log(logCategory, "No translation set found", language);

        return null;
    }

    //--------------------------------------------------------------------------

    function initializeLanguages() {
        if (!json.head || !json.head.model) {
            return;
        }

        var itext = json.head.model.itext;
        if (!itext) {
            return;
        }

        var translations = XFormJS.asArray(itext.translation);

        var list = [];
        for (var i = 0; i < translations.length; i++) {
            var translation = translations[i];

            var lang = translation["@lang"];
            list.push(lang);

            if (typeof translation["@default"] === "string") {
                defaultLanguage = lang;
            }
        }


        if (list.length > 0 && !(defaultLanguage > "")) {
            // Match locale name

            for (i = 0; i < list.length; i++) {
                if (list[i].name > "") {
                    if (localeProperties.systemLocale.name === Qt.locale(list[i]).name) {
                        defaultLanguage = list[i];
                        break;
                    }
                }
            }

            // Match language code

            if (XFormJS.isEmpty(defaultLanguage)) {
                for (i = 0; i < list.length; i++) {
                    if (list[i].name > "") {
                        var locale = Qt.locale(list[i].name);
                        if (locale.name !== "C") {
                            var localeInfo = AppFramework.localeInfo(locale.name);
                            if (localeProperties.systemLocaleInfo.languageCode === localeInfo.languageCode) {
                                defaultLanguage = list[i];
                                break;
                            }
                        }
                    }
                }
            }

            // Default to 1st language

            if (!(defaultLanguage > "")) {
                defaultLanguage = list[0];
            }
        }

        languages = list;

        console.log(logCategory, arguments.callee.name, "defaultLanguage:", defaultLanguage, "languages:", JSON.stringify(languages, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function enumerateLanguages(callback) {
        if (!Array.isArray(languages)) {
            return;
        }

        if (languages.length <= 1) {
            return;
        }

        var defaultLocale = localeProperties.systemLocale;

        for (var i = 0; i < languages.length; i++) {

            var language = languages[i];
            var languageText;
            var locale;

            if (language === xform.kLanguageDefault) {
                languageText = xform.kLanguageDefaultText;
            } else {
                locale = Qt.locale(language);

                if (locale.name === "C") {
                    var languageInfo = parseLanguage(language);
                    if (languageInfo) {
                        locale = Qt.locale(languageInfo.code);
                        languageText = languageInfo.name;
                        if (locale === "C") {
                            locale = defaultLocale;
                        }
                    } else {
                        languageText = language;
                        locale = defaultLocale;
                    }
                } else {
                    languageText = locale.nativeLanguageName > "" ? locale.nativeLanguageName : language;
                }
            }

            callback(language, languageText, locale);
        }
    }

    //--------------------------------------------------------------------------

    onLanguageChanged: {
        var defaultLocale = localeProperties.systemLocale;

        if (language == kLanguageDefault) {
            locale = defaultLocale;
            languageText.text = kLanguageDefaultText;
            languageDirection = locale.textDirection;
        } else {
            var loc = Qt.locale(language);

            if (loc.name === "C") {
                var languageInfo = parseLanguage(language);
                if (languageInfo) {
                    console.log(logCategory, "languageInfo:", JSON.stringify(languageInfo, undefined, 2));

                    locale = Qt.locale(languageInfo.code);
                    languageText.text = languageInfo.name;
                    if (locale === "C") {
                        locale = defaultLocale;
                        languageDirection = languageText.textDirection;
                    } else {
                        languageDirection = locale.textDirection;
                    }
                } else {
                    locale = defaultLocale;
                    languageText.text = language;
                    languageDirection = languageText.textDirection;
                }
            } else {
                locale = loc;
                languageText.text = locale.nativeLanguageName > "" ? locale.nativeLanguageName : language;
                languageDirection = locale.textDirection;
            }
        }

        console.log(logCategory, "languageChanged:", language);

        if (locale.name !== localeProperties.kNeutralLocale.name) {
            console.log(logCategory, "Setting app locale to:", locale.name);

            AppFramework.defaultLocale = locale.name;
        }

        if (hasTTS) {
            textToSpeech.say(language == kLanguageDefault
                             ? locale.nativeLanguageName
                             : languageText.text);
        }

        logLocaleInfo();
    }

    //--------------------------------------------------------------------------

    function logLocaleInfo() {
        console.log(logCategory, arguments.callee.name);

        console.log(logCategory, "defaultLanguage:", defaultLanguage);
        console.log(logCategory, "languages:", JSON.stringify(languages));
        console.log(logCategory, "language:", language);
        console.log(logCategory, "languageName:", languageName);

        localeInfo.log();
    }

    //--------------------------------------------------------------------------

    function parseLanguage(language) {
        if (!(language > "")) {
            return;
        }

        var tokens = language.match(/(.*)\((.*)\)/);
        if (!tokens || tokens.length < 2) {
            console.error(logCategory, "Unknown language format:", language);
            return;
        }

        return {
            name: tokens[1].trim(),
            code: tokens[2].trim()
        };
    }

    //--------------------------------------------------------------------------

    function textId(ref) {
        var tokens = ref.match(/jr:itext\('(.*)'\)/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return ref;
        }

        /*
        var l = ref.indexOf("'");
        if (l < 0) {
            return ref;
        }

        var r = ref.lastIndexOf("'");
        return ref.substr(l + 1, r - l - 1);
        */
    }

    //--------------------------------------------------------------------------

    function requiredText(text, isRequired) {
        var encodedText = XFormJS.encodeHTMLEntities(text.trim());

        if (isRequired) {
            return encodedText + " " + style.requiredSymbol;
        } else {
            return encodedText;
        }
    }

    //--------------------------------------------------------------------------

    function ensureItemVisible(item) {
        if (!xform.currentItem.scrollView) {
            console.warn(logCategory, "ensureVisible: No scrollView for:", item);
            return;
        }

        xform.currentItem.scrollView.ensureVisible(item);
    }

    //--------------------------------------------------------------------------

    function scrollToTop() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        xformView.scrollView.scrollTo(findScrollToItem(Window.activeFocusItem));
    }

    //--------------------------------------------------------------------------

    function scrollToBottom() {
        if (debug) {
            console.log(logCategory, arguments.callee.name);
        }

        xformView.scrollView.scrollTo(findScrollToItem(Window.activeFocusItem), true);
    }

    function findScrollToItem(item) {
        if (!item) {
            return;
        }

        var scrollItem = XFormJS.findParent(item, undefined, kObjectTypeRepeatControl);
        if (scrollItem) {
            scrollItem = XFormJS.findParent(scrollItem, undefined, kObjectTypeCollapsibleGroup);
        }

        return scrollItem;
    }

    //--------------------------------------------------------------------------

    function setControlFocus(nodeset) {
        //console.log(logCategory, "setControlFocus", nodeset);

        var controlNode = controlNodes[nodeset];

        if (!controlNode) {
            console.error(logCategory, "setControlFocus: No control node for:", nodeset);
            return;
        }

        setControlNodeFocus(controlNode);
    }

    function setControlNodeFocus(controlNode) {
        ensureItemVisible(controlNode.group);

        var control = controlNode.control;

        if (control.forceActiveFocus) {
            control.forceActiveFocus();
        }
    }

    //--------------------------------------------------------------------------

    function nextControl(control, forward) {
        if (typeof forward === "undefined") {
            forward = true;
        }

        var item = control.nextItemInFocusChain(forward);
        if (!item) {
            return false;
        }

        //ensureItemVisible(item);

        function setActiveFocus(item) {
            if (item.forceActiveFocus) {
                item.forceActiveFocus(Qt.TabFocusReason);
            } else if (typeof item.focus == "boolean") {
                item.focus = true;
            }
        }

        if (Qt.platform.os === "ios") {
            Qt.callLater(setActiveFocus, item);
        } else {
            setActiveFocus(item);
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function openLink(link) {
        console.log(logCategory, arguments.callee.name, "link:", link);

        Qt.openUrlExternally(link);
    }

    //--------------------------------------------------------------------------

    function showPagesPopup() {
        var popup = pagesPopup.createObject(parent,
                                            {
                                            });

        popup.open();
    }

    //--------------------------------------------------------------------------

    QtObject {
        id: expressionProperties

        property string mode: formData.editMode == formData.kEditModeAdd
                              ? "new"
                              : "edit";

        property string status
    }

    //--------------------------------------------------------------------------

    Component {
        id: pagesPopup

        XFormPagesPopup {
            //            anchors.centerIn: undefined
            //            x: Math.round((parent.width - width) / 2)
            //            //y: Math.round((parent.height - height) / 2)
            //            y: parent.height - height

            pageNavigator: xform.pageNavigator
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: controlContainer

        XFormControlContainer {
            Layout.columnSpan: span > 0 ? span : 1
            Layout.fillWidth: span <= 0 || ((Layout.column + Layout.columnSpan) === parent.columns)
            Layout.preferredWidth: span <= 0 ? -1 : parent.columnWidth * Layout.columnSpan

            //implicitWidth: span <= 0 ? parent.width : parent.columnWidth * Layout.columnSpan
            implicitWidth: parent.width

            Connections {
                target: xform

                onClearErrors: {
                    clearError();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: collapsibleGroupControl

        XFormCollapsibleGroupControl {
            Layout.columnSpan: span > 0 ? span : 1
            Layout.fillWidth: span <= 0 || ((Layout.column + Layout.columnSpan) === parent.columns)
            Layout.preferredWidth: span <= 0 ? -1 : parent.columnWidth * Layout.columnSpan

            implicitWidth: parent.width
        }
    }

    Component {
        id: gridHeaderComponent

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 2 * AppFramework.displayScaleFactor
            //Layout.leftMargin: 12 * AppFramework.displayScaleFactor
            Layout.bottomMargin: -7 * AppFramework.displayScaleFactor

            color: style.gridBorderColor
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: groupLabelControl

        XFormGroupLabel {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: labelControl

        XFormLabelControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: hintControl

        XFormHintControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: inputControl

        XFormInputControl {
            Layout.fillWidth: true

            onFocusChanged: {
                if (focus) {
                    focusItem = this;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: multiLineControl

        XFormMultiLineControl {
            Layout.fillWidth: true

            onFocusChanged: {
                if (focus) {
                    focusItem = this;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: monthYearControl

        XFormMonthYearControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dateTimeControl

        XFormDateTimeControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dateControl

        XFormDateTimeControl {
            Layout.fillWidth: true

            showTime: false
        }
        //        XFormDateControl {
        //            Layout.fillWidth: true
        //        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: timeControl

        XFormDateTimeControl {
            Layout.fillWidth: true

            showDate: false
        }
        //        XFormTimeControl {
        //            Layout.fillWidth: true
        //        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointControl

        XFormGeopointControl {
            Layout.fillWidth: true
            // Layout.fillHeight: isGridTheme
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopolyControl

        XFormGeopolyControl {
            Layout.fillWidth: true
            // Layout.fillHeight: isGridTheme
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectControl

        XFormSelectControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: select1Control

        XFormSelect1Control {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: select1ControlAuto

        XFormSelect1ControlAuto {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageControl

        XFormImageControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: signatureControl

        XFormSignatureControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: audioControl

        XFormAudioControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: repeatControl

        XFormRepeatControl {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            Connections {
                target: xform

                onClearErrors: {
                    clearError();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: noteControl

        XFormNoteControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: rangeControl

        XFormRangeControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: distressControl

        XFormDistressControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: defaultControl

        Text {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInControl

        XFormAddInControl {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: nullControl

        Item {
            Layout.fillWidth: true
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: valuesPreview

        XFormMediaPreview {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: controlItemset

        XFormItemset {
        }
    }

    //--------------------------------------------------------------------------

    TextToSpeech {
        id: textToSpeech

        locale: xform.locale.name
    }

    //--------------------------------------------------------------------------
}
