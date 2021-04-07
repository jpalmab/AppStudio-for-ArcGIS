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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0

import "../Models"
import "../Controls/Singletons"

MainViewTab {
    id: tab

    //--------------------------------------------------------------------------

    property alias galleryView: galleryView
    property bool showSurveysTile: /*addInTilesModel.count > 0 &&*/ settings.boolValue("AddIns/showSurveysTile", false);

    readonly property bool showSearchField: tilesModel.count > 6

    property bool debug: false

    //--------------------------------------------------------------------------

    title: qsTr("My Survey123")
    shortTitle: qsTr("Gallery")
    iconSource: Icons.bigIcon("apps", false)

    //--------------------------------------------------------------------------

    menu: AppMenu {
        id: appMenu

        showDownloadSurveys: true
    }

    //--------------------------------------------------------------------------

    actionGroup: mainActionGroup

    //--------------------------------------------------------------------------

    onTitleClicked: {
        galleryView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    function updateTiles() {
        console.log("Updating tiles");

        tilesModel.clear();

        if (!showSurveysTile) {
            for (var i = 0; i < surveysModel.count; i++) {
                var surveyItem = surveysModel.get(i);

                surveyItem.tileType = tilesModel.kTileTypeSurvey;

                tilesModel.append(surveyItem);
            }
        }

        for (i = 0; i < addInTilesModel.count; i++) {
            var addInItem = addInTilesModel.get(i);

            addInItem.tileType = tilesModel.kTileTypeAddIn;

            tilesModel.append(addInItem);
        }

        tilesModel.sort();

        if (showSearchField) {
            filteredTilesModel.update();
        }

        galleryView.forceLayout();
    }

    //--------------------------------------------------------------------------

    function refreshTiles() {
        for (var i = 0; i < surveysModel.count; i++) {
            var surveyItem = surveysModel.get(i);
            if (surveyItem.itemId > "") {
                var tileIndex = tilesModel.findByKeyValue("itemId", surveyItem.itemId);
                tilesModel.setProperty(tileIndex, "updateAvailable", surveyItem.updateAvailable);
            }
        }
    }

    //--------------------------------------------------------------------------

    FilteredListModel {
        id: filteredTilesModel

        sourceModel: tilesModel
        baseItems: 0
        filterText: searchField.text
    }

    //--------------------------------------------------------------------------

    SortedListModel {
        id: tilesModel

        //--------------------------------------------------------------------------

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyModified: "modified"

        //--------------------------------------------------------------------------

        readonly property string kTileTypeAddIn: "addin"
        readonly property string kTileTypeSurvey: "survey"

        //--------------------------------------------------------------------------

        sortProperty: kPropertyTitle
        sortOrder: "asc"
        sortCaseSensitivity: Qt.CaseInsensitive
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInTilesModel

        type: kTypeTool
        mode: kToolModeTile

        addInsFolder: app.addInsFolder
        showSurveysTile: tab.showSurveysTile

        onUpdated: {
            Qt.callLater(updateTiles);
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        enabled: !showSurveysTile
        formsFolder: surveysFolder

        onUpdated: {
            Qt.callLater(updateTiles);
            Qt.callLater(refreshTiles);
        }

        onRefreshed: {
            Qt.callLater(updateTiles); // TODO Improve so only properties are updated
        }
    }

    SurveysRefresh {
        id: surveysRefresh

        model: surveysModel

        onFinished: {
            Qt.callLater(refreshTiles);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        anchors {
            fill: parent
            topMargin: 8 * AppFramework.displayScaleFactor
        }

        spacing: 0

        UpdatesNotification {
            Layout.fillWidth: true
            Layout.topMargin: -layout.anchors.topMargin
            Layout.bottomMargin: layout.anchors.topMargin

            updatesAvailable: surveysModel.updatesAvailable
            busy: surveysRefresh.busy

            onClicked: {
                mainActionGroup.showDownloadPage(true);
            }

            onPressAndHold: {
                tab.debug = !tab.debug;
            }
        }

        SearchField {
            id: searchField

            Layout.fillWidth: true
            Layout.leftMargin: layout.anchors.topMargin
            Layout.rightMargin: Layout.leftMargin

            visible: showSearchField
            focus: false

            onEditingFinished: {
                processCommand(text);
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: !galleryView.visible
        }

        GalleryView {
            id: galleryView

            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: model.count

            model: showSearchField ? filteredTilesModel.visualModel : tilesModel

            delegate: tileDelegate

            progressBar {
                visible: surveysRefresh.busy
                value: surveysRefresh.progress
            }

            refreshHeader {
                enabled: surveysRefresh.enabled
                refreshing: surveysRefresh.busy
            }

            onRefresh: {
                surveysFolder.update();
                surveysRefresh.refresh();
            }

            onClicked: {
                var tileItem = model.get(currentIndex);

                switch (tileItem.tileType) {
                case tilesModel.kTileTypeAddIn:
                    addInSelected(tileItem);
                    break;

                case tilesModel.kTileTypeSurvey:
                    selected(app.surveysFolder.filePath(tileItem.path), false, -1, null, tileItem);
                    break;
                }
            }

            onPressAndHold: {
                var tileItem = model.get(currentIndex);

                switch (tileItem.tileType) {
                case tilesModel.kTileTypeAddIn:
                    break;

                case tilesModel.kTileTypeSurvey:
                    selected(app.surveysFolder.filePath(tileItem.path), true, -1, null, tileItem);
                    break;
                }
            }
        }

        NoSurveysView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            //canDownload: !app.openParameters
            portal: app.portal
            visible: !galleryView.model.count && canDownload
            actionGroup: mainActionGroup
        }
    }

    //--------------------------------------------------------------------------

    MainActionGroup {
        id: mainActionGroup

        stackView: mainStackView
        showDownloadSurveys: true
        surveysModel: surveysModel
    }

    //--------------------------------------------------------------------------

    Component {
        id: tileDelegate

        Item {
            id: item

            property int _index: index
            property string _path: path
            property string _thumbnail: thumbnail
            property string _title: title
            property string _updateAvailable: updateAvailable

            Loader {
                id: loader

                property alias index: item._index
                property alias path: item._path
                property alias thumbnail: item._thumbnail
                property alias title: item._title
                property alias updateAvailable: item._updateAvailable

                asynchronous: true

                sourceComponent: {
                    var tileItem = galleryView.model.get(index);
                    if (!tileItem) {
                        return;
                    }

                    switch (tileItem.tileType) {
                    case tilesModel.kTileTypeAddIn:
                        return addInTileDelegate;

                    case tilesModel.kTileTypeSurvey:
                        return surveyTileDelegate;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInTileDelegate

        GalleryDelegate {
            id: delegate

            galleryView: tab.galleryView

            clip: true

            background.clip: true

            Rectangle {
                parent: delegate.background

                anchors {
                    right: parent.right
                    rightMargin: -width / 2
                    bottom: parent.bottom
                    bottomMargin: -width / 2
                }

                width: 30 * AppFramework.displayScaleFactor
                height: width

                rotation: 45
                color: "#40000000"
                z: 999
            }

            onClicked: {
                galleryView.currentIndex = index;
                galleryView.clicked();
            }

            onPressAndHold: {
                galleryView.currentIndex = index;
                galleryView.pressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyTileDelegate

        SurveysGalleryDelegate {
            galleryView: tab.galleryView
            debug: tab.debug
        }
    }

    //--------------------------------------------------------------------------

    function processCommand(text) {
        console.log("processCommand text:", text);

        var urlInfo = AppFramework.urlInfo(text);

        if (urlInfo.scheme === app.info.value("urlScheme")) {
            onOpenUrl(urlInfo.url);
        }
    }

    //--------------------------------------------------------------------------
}
