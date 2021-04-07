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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

ColumnLayout {
    id: layout

    //--------------------------------------------------------------------------

    property color selectedTabColor: app.titleBarBackgroundColor
    property color selectedTabBarColor: Qt.lighter(app.titleBarBackgroundColor, 1.5)
    property color pressedTabColor: Qt.lighter(selectedTabColor, 1.5)
    property color tabColor: "grey"
    property alias view: tabsView
    property alias currentTab: tabsView.currentItem

    //--------------------------------------------------------------------------

    spacing: 0

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(layout, true)
    }

    //--------------------------------------------------------------------------

    SwipeView {
        id: tabsView
        
        Layout.fillWidth: true
        Layout.fillHeight: true

        property int visibleCount: 0

        interactive: false

        onCountChanged: {
            Qt.callLater(updateVisibleCount);
        }

        onVisibleChanged: {
            if (visible) {
                Qt.callLater(tabsView.updateVisibleCount);
            }
        }

        function updateVisibleCount() {
            var c = 0;

            for (var i = 0; i < count; i++) {
                var tab = itemAt(i);

                if (tab.visible) {
                    c++;
                }
            }

            visibleCount = c;

            console.log(logCategory, "visibleCount:", visibleCount);
        }
    }
    
    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        
        height: 1 * AppFramework.displayScaleFactor
        color: "#18000000"
    }
    
    PageIndicator {
        id: pageIndicator

        Layout.alignment: Qt.AlignHCenter

        readonly property int visibleCount: tabsView.visibleCount
        readonly property real indicatorWidth: visibleCount > 0
                                               ? (layout.width - visibleCount  * spacing - leftPadding - rightPadding) / (visibleCount + 1)
                                               : 0

        delegate: tabIndicatorComponent
        currentIndex: tabsView.currentIndex
        count: tabsView.count

        visible: visibleCount > 1
    }

    //--------------------------------------------------------------------------

    Component {
        id: tabIndicatorComponent

        Item {
            id: indicator

            property MainViewTab tab: tabsView.itemAt(index)
            property bool selected: index === tabsView.currentIndex
            property color color: mouseArea.pressed ? pressedTabColor : selected ? selectedTabColor : tabColor
            property color barColor: selected ? selectedTabBarColor : tabColor

            implicitWidth: pageIndicator.indicatorWidth
                   ? pageIndicator.indicatorWidth
                   : (showTabTitles ? 70 : 50) * AppFramework.displayScaleFactor
            implicitHeight: layout.childrenRect.height

            visible: tab.visible

            onVisibleChanged: {
                Qt.callLater(tabsView.updateVisibleCount);
            }

            ColumnLayout {
                id: layout

                width: parent.width
                spacing: showTabTitles ? 2 * AppFramework.displayScaleFactor : 0

                Item {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignHCenter

                    Component.onCompleted: {
                        indicatorLoader.active = true;
                    }

                    Loader {
                        id: indicatorLoader

                        anchors.fill: parent

                        sourceComponent: tab.indicator
                        active: false

                        onLoaded: {
                            console.log(logCategory, "Add-in indicator loaded:", item, "tab:", tab.title);

                            if (AppFramework.typeOf(item.iconSource) === "url") {
                                item.iconSource = Qt.binding(function () {
                                    return tab.addIn.iconSource;
                                });
                            }

                            if (typeof item.iconMonochrome === "boolean") {
                                item.iconMonochrome = Qt.binding(function () {
                                    return tab.addIn.iconMonochrome;
                                });
                            }

                            if (typeof item.isCurrentIndicator === "boolean") {
                                item.isCurrentIndicator = Qt.binding(function () {
                                    return indicator.selected;
                                });
                            }

                            if (AppFramework.typeOf(item.currentColor) === "color") {
                                item.currentColor = Qt.binding(function () {
                                    return indicator.color;
                                });
                            }
                        }
                    }
                }

                Text {
                    id: tabText

                    Layout.fillWidth: true

                    visible: showTabTitles
                    text: tab.shortTitle
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: indicator.color

                    font {
                        family: app.fontFamily
                        pointSize: 10
                        bold: indicator.selected
                    }
                }
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    topMargin: 2 * AppFramework.displayScaleFactor
                }

                width: showTabTitles ? tabText.paintedWidth : layout.width
                visible: selected
                height: 2 * AppFramework.displayScaleFactor
                color: indicator.barColor
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                onClicked: {
                    tabsView.currentIndex = index;
                }

                onPressAndHold:  {
                    tabsView.currentItem.indicatorPressAndHold();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        while (tabsView.count) {
            var tabItem = tabs.takeItem(tabsView.count - 1);
        }
    }

    //--------------------------------------------------------------------------
}
