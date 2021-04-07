import QtQuick 2.12

import ArcGIS.AppFramework 1.0

import "SurveyHelper.js" as Helper

import "../Controls"
import "../Controls/Singletons"

Rectangle {
    //--------------------------------------------------------------------------

    property string access
    property alias iconColor: image.color

    //--------------------------------------------------------------------------

    readonly property var accessIcons: {
        "public": "globe",
        "shared": "organization",
        "private": "user"
    }

    readonly property string accessIcon: accessIcons[access] || "blank"

    //--------------------------------------------------------------------------


    implicitWidth: 25 * AppFramework.displayScaleFactor
    implicitHeight: implicitWidth

    color: "transparent"
    radius: height / 2

    //--------------------------------------------------------------------------

    StyledImage {
        id: image

        anchors {
            fill: parent
            margins: parent.height * 0.2
        }

        source: Icons.icon(accessIcon)
        color: "black"
    }

    //--------------------------------------------------------------------------

}
