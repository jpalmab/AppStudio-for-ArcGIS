import QtQuick 2.7
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import ArcGIS.AppFramework 1.0

import "../template"

Rectangle {

    id: pictureChooserAndroid

    color: xform.style.backgroundColor

    property var pictureUrl
    property string path
    property var imageArray: []
    property bool noImages: true
    property int emulatedFolderCount: 100
    property var androidImagePaths: []

    signal accepted(url fileUrl)
    signal rejected()

    // -------------------------------------------------------------------------

    Stack.onStatusChanged: {
        if (Stack.status === Stack.Active) {
            busyIndicator.running = true;
            getPaths();
        }
    }

    // -------------------------------------------------------------------------

    FileFolder {
        id: fileFolder
    }

    FileInfo {
        id: fileInfo
    }

    // -------------------------------------------------------------------------

    ListModel {
        id: picturesModel
    }

    // -------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.alignment: Qt.AlignTop
            color: xform.style.titleBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: app.titleBarHeight

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    XFormImageButton {
                        anchors {
                            fill: parent
                            margins: 4 * AppFramework.displayScaleFactor
                        }
                        source: "images/back.png"
                        color: xform.style.titleTextColor
                        onClicked: {
                            rejected();
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    XFormImageButton {
                        anchors {
                            fill: parent
                            margins: 4 * AppFramework.displayScaleFactor
                        }
                        source: asc ? "images/sort-time-asc.png" : "images/sort-time-desc.png"
                        color: xform.style.titleTextColor
                        property bool asc: false
                        visible: !noImages
                        enabled: !noImages
                        onClicked: {
                            asc = !asc;
                            sort(asc);
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width
            Layout.maximumWidth: 600 * AppFramework.displayScaleFactor
            Layout.alignment: Qt.AlignHCenter

            GridView {
                id: gridView
                anchors.fill: parent
                model: picturesModel
                focus: true
                clip: true

                cellWidth: gridView.width / 3
                cellHeight: gridView.width / 3

                delegate: Rectangle {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 5 * AppFramework.displayScaleFactor
                        }
                        color: "#eee"
                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: url
                            asynchronous: true
                            autoTransform: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 200
                            sourceSize.height: 200
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    pictureUrl = url;
                                    pictureChooserAndroid.accepted(pictureUrl);
                                    gridView.enabled = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    AppBusyIndicator {
        id: busyIndicator
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: statusText.top
        }
    }

    Text {
        id: statusText
        anchors.centerIn: parent
        wrapMode: Text.Wrap
        maximumLineCount: 2
        color: xform.style.groupLabelColor
        font {
            family: xform.style.fontFamily
            weight: Font.Bold
            pointSize: xform.style.titlePointSize
        }
        visible: text > ""
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    //--------------------------------------------------------------------------

    function hasSubfolders(path) {

        var pathSubfolderTest = AppFramework.fileFolder(path).folderNames();

        if (pathSubfolderTest.length > 0) {
            return true;
        }
        else {
            return false;
        }
    }

    //--------------------------------------------------------------------------

    function getSubfolders(path) {

        var paths = AppFramework.fileFolder(path).folderNames();

        for (var subpath in paths) {

            androidImagePaths.push("file://%1/%2".arg(path).arg(paths[subpath]))

            // Normalize the path's precedeing backslashes ---------------------

            var subpathToTest = "%1/%2".arg(path).arg(paths[subpath]);
            var pathBackslashes = subpathToTest.match(/^\/*/);

            if (pathBackslashes.length > 0) {
                var revisedSubpathToTest = "/" + subpathToTest.substr(pathBackslashes[0].length, subpathToTest.length)
            }

            if (hasSubfolders(revisedSubpathToTest)){
                getSubfolders(revisedSubpathToTest);
            }
        }
    }

    //--------------------------------------------------------------------------

    function getPaths() {

        androidImagePaths = [];

        // Test StandardPaths and subfolders -----------------------------------

        var standardPaths = AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation);

        // @TODO for in loops on arrays should be converted to Array.forEach() loops

        for (var standardPath in standardPaths) {

            fileFolder.path = standardPaths[standardPath];

            if (fileFolder.exists) {
                androidImagePaths.push("file://" + standardPaths[standardPath]);
            }

            if (hasSubfolders(standardPaths[standardPath])) {
                getSubfolders(standardPaths[standardPath]);
            }

        }

        // Test ArcGIS Media folder --------------------------------------------

        var appAttachmentsFolderPath = xform.attachmentsFolder.path;

        fileFolder.path = appAttachmentsFolderPath;

        if (fileFolder.exists) {
            androidImagePaths.push("file://" + appAttachmentsFolderPath);
        }

        // Test BasePath of /storage -------------------------------------------

        var basePath = "/storage";
        var paths = [];

        fileFolder.path = basePath;
        var basePathSubFolders = fileFolder.folderNames();

        // Get DCIM folders within storage paths -------------------------------

        for (var basePathSubFolder in basePathSubFolders) {

            var folderName = basePathSubFolders[basePathSubFolder];
            var pathToSearch = basePath + "/" + folderName + "/";

            if (folderName.search(/emulated/i) > -1) {
                var typicalAndroidEmulatedPath = pathToSearch + "0/DCIM";
                fileFolder.path = typicalAndroidEmulatedPath;
                if (fileFolder.exists) {
                    pathToSearch = typicalAndroidEmulatedPath;
                }
                else {
                    for (var pathCounter = 1; pathCounter < emulatedFolderCount + 1; pathCounter++) {
                        var pathToTest = pathToSearch + pathCounter.toString() + "/DCIM";
                        fileFolder.path = pathToTest;
                        if (fileFolder.exists) {
                            pathToSearch = pathToTest;
                            break;
                        }
                    }
                }
            }
            else {
                pathToSearch += "DCIM";
            }

            fileFolder.path = pathToSearch;

            if (fileFolder.exists) {
                paths.push(pathToSearch);
                androidImagePaths.push("file://" + pathToSearch);
            }
        }

        // Get folders within the DCIM folders ---------------------------------

        for (var storagePath in paths) {

            fileFolder.path = paths[storagePath];

            if (fileFolder.exists) {

                if (hasSubfolders(paths[storagePath])) {
                    getSubfolders(paths[storagePath]);
                }

            }
        }

        console.log("*-*-*-*-*-*-*-*-: ", JSON.stringify(androidImagePaths));

        // Get file paths from dcim folders ------------------------------------

        var firstFileName = [];
        var duplicate = false;

        for (var androidImagePath in androidImagePaths) {

            fileFolder.url = androidImagePaths[androidImagePath];
            var sourceFilesCurrent = fileFolder.fileNames();

            if (sourceFilesCurrent) {

                for (var sourceFile in sourceFilesCurrent) {

                    var file = sourceFilesCurrent[sourceFile];

                    if (file.search(/\.(jpeg|jpg|gif|png|tif|tiff)$/i) > -1){

                        // check for a duplicate first item in each array ------

                        if (sourceFile === 0) {
                            firstFileName.push(file);
                        }

                        if (firstFileName.length > 1 && sourceFile === 0) {
                            for (var fileName in firstFileName) {
                                if (firstFileName[fileName] === file) {
                                    duplicate = true;
                                    break;
                                }
                            }
                        }

                        if (duplicate) {
                            duplicate = false;
                            break;
                        }

                        // add path to the imageArray --------------------------

                        path = androidImagePaths[androidImagePath] + "/" + file;

                        fileInfo.filePath = AppFramework.urlInfo(path).path;
                        imageArray.push({"url": path, "name": file, "created": Date.parse(fileInfo.lastModified)});
                    }
                }
            }
        }

        if (imageArray.length > 0) {
            statusText.text = "";
            sort(false);
            noImages = false;
        }
        else {
            statusText.text = qsTr("Sorry, no photos found.");
            noImages = true;
            busyIndicator.running = false;
        }

    }

    // -------------------------------------------------------------------------

    function sort(asc){
        // asc is oldest to newest
        imageArray = imageArray.sort(function(obj1, obj2) {
            if (asc) {
                return obj1.created - obj2.created;
            }
            else {
                return obj2.created - obj1.created;
            }
        });

        updateModel();
    }

    // -------------------------------------------------------------------------

    function updateModel(){
        picturesModel.clear();
        imageArray.forEach(function(obj){
            picturesModel.append(obj);
        });
        busyIndicator.running = false;
    }

    // End /////////////////////////////////////////////////////////////////////
}
