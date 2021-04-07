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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Portal"
import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "../Models"

import "../template/SurveyHelper.js" as Helper


AppPage {
    id: page

    //--------------------------------------------------------------------------

    property bool downloaded: false
    property int updatesAvailable: 0
    property var updateIds: []
    property bool updatesFilter: false

    property var hasSurveysPage
    property Component noSurveysPage
    property bool debug: false

    property Settings settings: app.settings

    readonly property string kSettingsGroup: "DownloadSurveys/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    property color textColor: "#323232"
    property color iconColor: "#505050"
    property real buttonSize: 30 * AppFramework.displayScaleFactor

    property SurveysModel surveysModel

    readonly property bool signedIn: portal.signedIn

    //--------------------------------------------------------------------------

    backPage: surveysFolder.forms.length > 0 ? hasSurveysPage : noSurveysPage
    title: updatesFilter
           ? qsTr("Update Surveys")
           : qsTr("Download Surveys")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        readSettings();

        console.log(logCategory, "signedIn:", signedIn, "updatesFilter:", updatesFilter);
        if (signedIn || updatesFilter) {
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        writeSettings();

        surveysFolder.update();
        surveysModel.updateUpdatesAvailable();
    }

    //--------------------------------------------------------------------------

    onSignedInChanged: {
        if (signedIn) {
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        listView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(page, true)
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Rectangle {
            id: listArea

            anchors.fill: parent

            color: "transparent" //"#40ffffff"
            radius: 10

            Column {
                anchors {
                    fill: parent
                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 10 * AppFramework.displayScaleFactor
                visible: searchModel.count == 0 && !searchRequest.active && signedIn

                AppText {
                    width: parent.width
                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: qsTr('<center>There are no surveys shared with <b>%2</b>, username <b>%1</b>.<br><hr>Please visit <a href="http://survey123.esri.com">http://survey123.esri.com</a> to create a survey or see your system administrator.</center>').arg(portal.user.username).arg(portal.user.fullName)
                    textFormat: Text.RichText

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                ConfirmButton {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Refresh")

                    onClicked: {
                        search();
                    }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                visible: searchModel.count > 0

                RowLayout {
                    id: toolsLayout

                    Layout.fillWidth: true

                    spacing: 5 * AppFramework.displayScaleFactor

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyDate
                        checkedColor: page.headerBarColor

                        source: Icons.icon("clock-%1".arg(searchModel.sortOrder === "desc" ? "up" : "down"))

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyDate;
                                searchModel.sortOrder = searchModel.kSortOrderDesc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height * 0.8
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyTitle
                        checkedColor: page.headerBarColor

                        source: Icons.icon("a-z-%1".arg(searchModel.sortOrder === "desc" ? "up" : "down"))

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyTitle;
                                searchModel.sortOrder = searchModel.kSortOrderAsc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    StyledImageButton {
                        id: filterButton

                        Layout.preferredHeight: toolsLayout.height * 0.8
                        Layout.preferredWidth: Layout.preferredHeight

                        visible: signedIn
                        checkable: true
                        checked: updatesFilter
                        checkedColor: page.headerBarColor

                        source: Icons.icon("filter", checked)

                        onClicked: {
                            updatesFilter = !updatesFilter;
                            filteredGalleryModel.update();
                        }
                    }

                    SearchField {
                        id: searchField

                        Layout.fillWidth: true

                        busy: searchRequest.busy

                        progressBar {
                            visible: searchRequest.active && searchRequest.total > 0
                            value: searchRequest.count
                            from: 0
                            to: searchRequest.total
                        }

                        onEditingFinished: {
                            filteredGalleryModel.filterText = text;
                        }

                        onCancel: {
                            searchRequest.cancel();
                        }
                    }
                }

                ListView {
                    id: listView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: filteredGalleryModel.visualModel
                    spacing: 10 * AppFramework.displayScaleFactor
                    clip: true

                    delegate: surveyDelegateComponent

                    RefreshHeader {
                        enabled: !searchRequest.active && signedIn
                        refreshing: searchRequest.active

                        onRefresh: {
                            search();
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        parent: listView

                        policy: ScrollBar.AsNeeded

                        anchors {
                            top: listView.top
                            right: parent.right
                            rightMargin: -5 * AppFramework.displayScaleFactor
                            bottom: listView.bottom
                        }

                        padding: 0
                    }
                }

                Control {
                    Layout.fillWidth: true
                    Layout.leftMargin: -(page.contentMargins + 2 * AppFramework.displayScaleFactor)
                    Layout.rightMargin: Layout.leftMargin
                    Layout.bottomMargin: Layout.leftMargin

                    visible: portal.isOnline && updatesAvailable > 0

                    contentItem: RowLayout {
                        AppButton {
                            id: updateButton

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: page.contentMargins
                            Layout.bottomMargin: Layout.topMargin

                            enabled: !searchRequest.active

                            text: qsTr("Download updates: %1").arg(updatesAvailable)
                            textPointSize: 15

                            iconSource: Icons.bigIcon("refresh")

                            onClicked: {
                                updateAll();
                            }
                        }
                    }

                    background: Rectangle {
                        color: "#eee"

                        HorizontalSeparator {
                            id: updateSeparator

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }

                            opacity: 0.5
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            visible: searchRequest.active && searchModel.count == 0
            color: page.backgroundColor

            AppText {
                id: searchingText

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                text: qsTr("Searching for surveys")
                color: "darkgrey"
                font {
                    pointSize: 18
                }
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            AppBusyIndicator {
                anchors {
                    top: searchingText.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 10 * AppFramework.displayScaleFactor
                }

                running: parent.visible
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function search() {
        searchModel.update();
    }

    SortedListModel {
        id: searchModel

        signal updated()

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyDate: "modified"

        sortProperty: kPropertyDate
        sortOrder: kSortOrderDesc
        sortCaseSensitivity: Qt.CaseInsensitive

        function update() {
            updatesAvailable = 0;
            updateIds = [];
            updateLocalPaths();

            searchRequest.start();
        }

        function updateLocalPaths() {
            for (var i = 0; i < searchModel.count; i++) {
                var item = searchModel.get(i);
                updateLocalPath(item);
            }
        }

        function updateLocalPath(item) {
            item.isLocal = surveysFolder.fileExists(item.id);

            if (item.isLocal) {
                item.path = searchModel.findForm(surveysFolder.folder(item.id));
            }
        }

        function updateItem(itemInfo) {
            var index = findByKeyValue("id", itemInfo.id);
            if (index >= 0) {
                var item = Helper.removeArrayProperties(itemInfo);

                item.updateAvailable = false;
                item.isLocal = true;
                item.path = searchModel.findForm(surveysFolder.folder(itemInfo.id));

                set(index, item);
            }

            index = surveysModel.findByKeyValue("itemId", itemInfo.id);
            if (index >= 0) {
                surveysModel.setProperty(index, "itemModified", itemInfo.modified);
                surveysModel.setProperty(index, "updateAvailable", false);
            }
        }

        function findForm(folder) {
            var path;

            var files = folder.fileNames("*", true);
            files.forEach(function(fileName) {
                if (folder.fileInfo(fileName).suffix === "xml") {
                    path = folder.filePath(fileName);
                }
            });

            return path;
        }

        function sortItems() {
            sort();
        }

        onUpdated: {
            filteredGalleryModel.update();
        }
    }

    //--------------------------------------------------------------------------

    FilteredListModel {
        id: filteredGalleryModel

        sourceModel: searchModel

        filterFunction: function (item, pattern) {
            if (updatesFilter) {// && filterButton.visible) {
                if (!item.updateAvailable) {
                    return false;
                }
            }

            return defaultFilterFunction(item, pattern);
        }
    }

    //--------------------------------------------------------------------------

    PortalSearch {
        id: searchRequest

        property var idList
        property bool busy

        portal: app.portal
        sortField: searchModel.sortProperty
        sortOrder: searchModel.sortOrder
        num: 25

        onResults: {
            results.forEach(function (result) {
                appendSurvey(result);
            });

            if (updatesFilter) {
                searchModel.updated();
            }

            searchNext();
        }


        onFinished: {

            if (!cancelled && updateQuery()) {
                search();
            } else {
                busy = false;
                searchModel.sortItems();
                searchModel.updated();
            }
        }

        function start() {
            searchModel.clear();
            updatesAvailable = 0;
            updateIds = [];
            idList = buildIdList();

            if (updateQuery()) {
                busy = true;
                search();
            }
        }

        function updateQuery() {
            var query = "";
            var idCount = 0;

            if (Array.isArray(idList)) {
                while (idList.length > 0 && idCount < num) {
                    if (idCount) {
                        query += " OR ";
                    }

                    query += "id:%1".arg(idList.shift());
                    idCount++;
                }

                if (idCount) {
                    if (debug) {
                        console.log(logCategory, arguments.callee.name, "idCount:", idCount, "query:", query);
                    }

                    q = query;
                    return idCount;
                }
            } else {
                return 0;
            }

            idList = null;

            if (signedIn) {
                query = portal.user.orgId > ""
                        ? '((NOT access:public) OR orgid:%1)'.arg(portal.user.orgId)
                        : 'NOT access:public';

                query += ' AND ((type:Form AND NOT tags:"draft" AND NOT typekeywords:draft) OR (type:"Code Sample" AND typekeywords:XForms AND tags:"xform"))';

                if (debug) {
                    console.log(logCategory, arguments.callee.name, "query:", query);
                }

                q = query;
                return -1;
            }

            q = "";
            return 0;
        }

        function buildIdList() {
            console.log(arguments.callee.name, "surveys:", surveysModel.count);

            var ids = [];

            for (var i = 0; i < surveysModel.count; i++) {
                var survey = surveysModel.get(i);
                if (survey.itemId > "" && (signedIn || survey.access === "public")) {
                    ids.push(survey.itemId);
                }
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "ids:", ids.length);
            }

            return ids;
        }

        function appendSurvey(itemInfo) {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "id:", itemInfo.id, itemInfo.title);
            }

            if (searchModel.findByKeyValue("id", itemInfo.id) >= 0) {
                return;
            }

            itemInfo.updateAvailable = false;
            itemInfo.isLocal = surveysFolder.fileExists(itemInfo.id);

            if (itemInfo.isLocal) {
                itemInfo.path = searchModel.findForm(surveysFolder.folder(itemInfo.id));

                var surveysIndex = surveysModel.findByKeyValue("itemId", itemInfo.id);
                if (surveysIndex >= 0 && itemInfo.modified > surveysModel.get(surveysIndex).itemModified) {
                    itemInfo.updateAvailable = true;

                    updatesAvailable++;
                    updateIds.push(itemInfo.id);

                    surveysModel.setProperty(surveysIndex, "updateAvailable", true);
                }
            }

            if (debug) {
                console.log(logCategory, arguments.callee.name, "isLocal:", itemInfo.isLocal, "updateAvailable:", itemInfo.updateAvailable, "id:", itemInfo.id, itemInfo.title);
            }

            searchModel.append(Helper.removeArrayProperties(itemInfo));
        }
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        var value = settings.value(kSettingSortProperty, searchModel.kPropertyDate);
        if ([searchModel.kPropertyTitle, searchModel.kPropertyDate].indexOf(value) < 0) {
            value = searchModel.kPropertyDate;
        }
        searchModel.sortProperty = value;

        value = settings.value(kSettingSortOrder, searchModel.kSortOrderDesc);
        if ([searchModel.kSortOrderAsc, searchModel.kSortOrderDesc].indexOf(value) < 0) {
            value = searchModel.kSortOrderDesc;
        }
        searchModel.sortOrder = value;
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        settings.setValue(kSettingSortProperty, searchModel.sortProperty);
        settings.setValue(kSettingSortOrder, searchModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyDelegateComponent

        SwipeLayoutDelegate {
            id: surveyDelegate

            property var surveyPath: index >= 0 ? listView.model.get(index).path : ""
            property var localSurvey: index >= 0 ? listView.model.get(index).isLocal : false

            width: ListView.view.width

            ThumbnailImage {
                id: thumbnailImage

                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth * 133/200

                url: portal.authenticatedImageUrl(portal.restUrl + "/content/items/" + id + "/info/" + thumbnail)
            }

            ColumnLayout {
                Layout.fillWidth: true

                AppText {
                    Layout.fillWidth: true

                    text: title
                    font {
                        pointSize: 16 * app.textScaleFactor
                        italic: debug && updateAvailable
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                }

                //                                Text {
                //                                    width: parent.width
                //                                    text: modelData.snippet > "" ? modelData.snippet : ""
                //                                    font {
                //                                        pointSize: 12
                //                                    }
                //                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                //                                    color: textColor
                //                                    visible: text > ""
                //                                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Modified: %1").arg(localeProperties.formatDateTime(new Date(modified), Locale.ShortFormat))

                    font {
                        pointSize: 11 * app.textScaleFactor
                    }
                    textFormat: Text.AutoText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: "#7f8183"
                }
            }

            StyledImageButton {
                id: downloadButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: Layout.preferredWidth

                source: Icons.bigIcon(isLocal ? "refresh" : "download")

                color: iconColor
                onClicked: {
                    downloadSurvey.download(listView.model.get(index));
                }
            }

            StyledImage {
                Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                visible: false //delegate.swipe.position === 0

                source: Icons.icon("ellipsis")
                color: app.textColor
            }

            /*
            behindLayout: SwipeBehindLayout {
                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image.source: Icons.bigIcon("map")

                    onClicked: {
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }
                    backgroundColor: "tomato"

                    onClicked: {
                        confirmDelete(index);
                    }
                }
            }
            */
        }
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurvey

        portal: app.portal
        progressPanel: progressPanel
        debug: debug
        succeededPrompt: false

        onSucceeded: {
            page.downloaded = true;
            searchModel.updateItem(itemInfo);

            var index = updateIds.indexOf(itemInfo.id);
            if (index >= 0) {
                updateIds.splice(index, 1);
                updatesAvailable = updateIds.length;
            }

            if (!searchRequest.active) {
                searchModel.sortItems();
                searchModel.update();
            }
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0

        onVisibleChanged: {
            Platform.stayAwake = visible;
        }
    }

    //--------------------------------------------------------------------------

    function updateAll() {
        downloadSurveys.downloadNext();
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurveys

        portal: app.portal
        progressPanel: progressPanel
        debug: debug
        succeededPrompt: false

        onSucceeded: {
            updatesAvailable = updateIds.length;

            searchModel.updateItem(itemInfo);

            if (!downloadNext()) {
                page.downloaded = true;
                searchModel.sortItems();
                searchModel.updated();

                if (updatesFilter) {
                    page.closePage();
                }
            }
        }

        function downloadNext() {
            if (updateIds.length < 1) {
                return;
            }

            var itemId = updateIds.shift();

            console.log(logCategory, "Downloading itemId:", itemId);

            var index = searchModel.findByKeyValue("id", itemId);
            if (index < 0) {
                console.error(logCategory, "Not found itemId:", itemId);
                return;
            }

            var info = searchModel.get(index);
            download(info);

            return info;
        }
    }

    //--------------------------------------------------------------------------
}
