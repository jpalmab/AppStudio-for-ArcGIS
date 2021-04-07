/* Copyright 2020 Esri
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
import QtQuick 2.13
import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.13
import ArcGIS.AppFramework.WebView 1.0
Item {
    signal next();
    signal back();
    // App Page
    Page{
        anchors.fill: parent
        // Adding App Page Header Section

        // Header Section ends

        // Page Body
        // TODO:-Provide Code here to add items to the Page
        // Button to navigate to next page

        Rectangle{
            id: rectangle
            width: 640
            height: 440


            anchors.fill: parent

            border.color: "#888"
            radius: 2
            anchors.bottomMargin: 0
            anchors.rightMargin: 0
            clip: false
            visible: true
            border.width: 1

            Image {
                id: image
                anchors.fill: parent


                antialiasing: true
                clip: true
                source: "images/paisaje-natural.jpg"
                fillMode: Image.PreserveAspectCrop

            }


            Label
            {
                id: label
                height: 120
                color: "#eff0ef"
                text: qsTr("rECOrre")
                horizontalAlignment: Text.AlignHCenter
                anchors.right: parent.right
                anchors.rightMargin: 147
                anchors.left: parent.left
                anchors.leftMargin: 149
                anchors.top: parent.top
                anchors.topMargin: 53


                fontSizeMode: Text.FixedSize
                wrapMode: Text.WordWrap
                font.pointSize: 70

                padding: 16*app.scaleFactor
            }


            Button{
                text: "Iniciar Sesión"
                font.weight: Font.Light
                font.kerning: true
                font.preferShaping: true
                font.bold: false
                opacity: 1
                visible: true
                enabled: true
                Material.elevation :10

                palette {
                    button: "white"
                }


                anchors.centerIn: parent
                    font.pixelSize: app.titleFontSize
                    //font.bold: true
                    //wrapMode: Text.Wrap
                    padding: 16*app.scaleFactor
                    highlighted: false
                    flat: false
                    display: AbstractButton.TextOnly
                    anchors.verticalCenterOffset: 700

                    onClicked:{
                        browserView.show();
                    }
                }



                Button{
                    Material.elevation :10
                    font.pixelSize: app.titleFontSize
                    //font.bold: true
                    //wrapMode: Text.Wrap
                    padding: 16*app.scaleFactor
                    text: qsTr("Survey123")
                    font.weight: Font.Light
                    anchors.verticalCenterOffset: 900
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    transformOrigin: Item.Center

                    palette {
                        button: "white"
                    }

                    onClicked:{
                        next();
                    }

                }




            BrowserView
            {
                id: browserView
                x: 0
                y: 0
                anchors.rightMargin: 302
                clip: true
                anchors.bottomMargin: 282
                opacity: 1
                anchors.fill: parent
                primaryColor:"#8f499c"
                foregroundColor: "#f7d4f4"
                url: "http://www.recorreueb.com/indice.php"
            }


        }

    }
}















































/*##^## Designer {
    D{i:0;autoSize:true;height:480;width:640}D{i:3;anchors_height:911;anchors_width:479;anchors_x:"-8";anchors_y:0}
D{i:4;anchors_height:120;anchors_width:344;anchors_x:8;anchors_y:53}
}
 ##^##*/
