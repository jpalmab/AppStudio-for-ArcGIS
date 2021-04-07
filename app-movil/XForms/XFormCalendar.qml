/* Copyright 2018 Esri
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

import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

Calendar {
    id: calendar

    property int yearStart: new Date().getFullYear() - 75;
    property int yearEnd: yearStart + 100
    property bool yearPickerVisible: false
    property bool monthPickerVisible: false
    property int padding: 0
    property int barTextSize: xform.style.implicitTextHeight
    property int barHeight: Math.round(barTextSize * 1.1) + padding * 2
    readonly property int monthRepeatInterval: 100
    readonly property int yearRepeatInterval: 50

    //--------------------------------------------------------------------------

    locale: xform.locale

    style: CalendarStyle {

        dayOfWeekDelegate: Rectangle {
            color: gridVisible ? "#fcfcfc" : "transparent"
            implicitHeight: Math.round(xform.style.implicitTextHeight * 1.1)
            Text {
                text: calendar.locale.dayName(styleData.dayOfWeek, control.dayOfWeekFormat)
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#444"
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: 6
                font {
                    family: xform.style.calendarFontFamily
                    pointSize: xform.style.implicitText.font.pointSize
                    bold: true
                }
            }
        }

        dayDelegate: Rectangle {
            anchors {
                fill: parent
                leftMargin: (!addExtraMargin || control.weekNumbersVisible) && styleData.index % CalendarUtils.daysInAWeek === 0 ? 0 : -1
                rightMargin: !addExtraMargin && styleData.index % CalendarUtils.daysInAWeek === CalendarUtils.daysInAWeek - 1 ? 0 : -1
                bottomMargin: !addExtraMargin && styleData.index >= CalendarUtils.daysInAWeek * (CalendarUtils.weeksOnACalendarMonth - 1) ? 0 : -1
                topMargin: styleData.selected ? -1 : 0
            }

            color: styleData.date !== undefined && styleData.selected ? selectedDateColor : "transparent"

            readonly property bool addExtraMargin: control.frameVisible && styleData.selected
            readonly property color sameMonthDateTextColor: "#444"
            readonly property color selectedDateColor: Qt.platform.os === "osx" ? "#3778d0" : SystemPaletteSingleton.highlight(control.enabled)
            readonly property color selectedDateTextColor: "white"
            readonly property color differentMonthDateTextColor: "#bbb"
            readonly property color invalidDateColor: "#dddddd"
            Text {
                id: dayDelegateText
                text: styleData.date.getDate()
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                font {
                    pixelSize: Math.min(parent.height * 0.60, parent.width * 0.60)
                    family: xform.style.calendarFontFamily
                    bold: styleData.selected
                }
                color: {
                    var theColor = invalidDateColor;
                    if (styleData.valid) {
                        // Date is within the valid range.
                        theColor = styleData.visibleMonth ? sameMonthDateTextColor : differentMonthDateTextColor;
                        if (styleData.selected)
                            theColor = selectedDateTextColor;
                    }
                    theColor;
                }
            }
        }

        weekNumberDelegate: Rectangle {
            implicitWidth: Math.round(xform.style.implicitTextHeight * 1.75)

            Text {
                anchors.fill: parent

                text: styleData.weekNumber

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#444"
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: 6

                font {
                    family: xform.style.calendarFontFamily
                    pointSize: xform.style.implicitText.font.pointSize
                }
            }
        }

        navigationBar: Rectangle {
            id: navigationLayout

            height: columnLayout.height
            color: "#f9f9f9"
            
            Rectangle {
                color: Qt.rgba(1,1,1,0.6)
                height: 1
                width: parent.width
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                height: 1
                width: parent.width
                color: "#ddd"
            }
            
            ColumnLayout {
                id: columnLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                spacing: 0

                RowLayout {
                    Layout.fillWidth: true

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-left.png"
                        repeatInterval: monthRepeatInterval

                        onClicked: control.showPreviousMonth()
                        onRepeat: control.showPreviousMonth()
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.margins: 2 * AppFramework.displayScaleFactor

                        text: calendar.locale.standaloneMonthName(control.visibleMonth)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "#444"
                        font {
                            pointSize: xform.style.inputPointSize
                            family: xform.style.inputFontFamily
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                monthPickerLoader.active = true;
                                monthPickerVisible = !monthPickerVisible;
                            }
                        }
                    }

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-right.png"
                        repeatInterval: monthRepeatInterval

                        onClicked: control.showNextMonth()
                        onRepeat: control.showNextMonth();
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#ccc"
                }

                RowLayout {
                    Layout.fillWidth: true

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-left.png"
                        repeatInterval: yearRepeatInterval

                        onClicked: control.showPreviousYear()
                        onRepeat: control.showPreviousYear()
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.margins: 2 * AppFramework.displayScaleFactor

                        text: control.visibleYear
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        font {
                            pointSize: xform.style.inputPointSize
                            family: xform.style.inputFontFamily
                        }
                        color: "#444"

                        MouseArea {
                            anchors.fill: parent

                            enabled: control.visibleYear >= yearStart && control.visibleYear < yearEnd

                            onClicked: {
                                yearPickerLoader.active = true;
                                yearPickerVisible = !yearPickerVisible;
                            }
                        }
                    }


                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-right.png"
                        repeatInterval: yearRepeatInterval

                        onClicked: control.showNextYear()
                        onRepeat: control.showNextYear()
                    }
                }
            }
        }

        background: Rectangle {
            color: "#fff"
            implicitWidth: Math.max(200 * AppFramework.displayScaleFactor, Math.round(xform.style.implicitTextHeight * 12))
            implicitHeight: Math.max(200 * AppFramework.displayScaleFactor, Math.round(xform.style.implicitTextHeight * 12))
        }


        // TODO workaround for CalendarHeaderModel not being refreshing when the locale changes

        property Component panel: Item {
            id: panelItem

            implicitWidth: backgroundLoader.implicitWidth
            implicitHeight: backgroundLoader.implicitHeight

            property alias navigationBarItem: navigationBarLoader.item

            property alias dayOfWeekHeaderRow: dayOfWeekHeaderRow

            readonly property int weeksToShow: 6
            readonly property int rows: weeksToShow
            readonly property int columns: CalendarUtils.daysInAWeek

            // The combined available width and height to be shared amongst each cell.
            readonly property real availableWidth: viewContainer.width
            readonly property real availableHeight: viewContainer.height

            property int hoveredCellIndex: -1
            property int pressedCellIndex: -1
            property int pressCellIndex: -1
            property var pressDate: null

            //------------------------------------------------------------------

            Connections {
                target: calendar

                onLocaleChanged: {
                    repeater.model = headerModel.createObject(repeater);
                }
            }

            Component {
                id: headerModel

                CalendarHeaderModel {
                    locale: control.locale
                }
            }

            //------------------------------------------------------------------

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: gridColor
                visible: control.frameVisible
            }

            Item {
                id: container
                anchors.fill: parent
                anchors.margins: control.frameVisible ? 1 : 0

                Loader {
                    id: backgroundLoader
                    anchors.fill: parent
                    sourceComponent: background
                }

                Loader {
                    id: navigationBarLoader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    sourceComponent: navigationBar
                    active: control.navigationBarVisible

                    property QtObject styleData: QtObject {
                        readonly property string title: control.locale.standaloneMonthName(control.visibleMonth)
                            + new Date(control.visibleYear, control.visibleMonth, 1).toLocaleDateString(control.locale, " yyyy")
                    }
                }

                Row {
                    id: dayOfWeekHeaderRow
                    anchors.top: navigationBarLoader.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: (control.weekNumbersVisible ? weekNumbersItem.width : 0)
                    anchors.right: parent.right
                    spacing: gridVisible ? __gridLineWidth : 0

                    Repeater {
                        id: repeater
                        model: CalendarHeaderModel {
                            locale: control.locale
                        }
                        Loader {
                            id: dayOfWeekDelegateLoader
                            sourceComponent: dayOfWeekDelegate
                            width: __cellRectAt(index).width

                            readonly property int __index: index
                            readonly property var __dayOfWeek: dayOfWeek

                            property QtObject styleData: QtObject {
                                readonly property alias index: dayOfWeekDelegateLoader.__index
                                readonly property alias dayOfWeek: dayOfWeekDelegateLoader.__dayOfWeek
                            }
                        }
                    }
                }

                Rectangle {
                    id: topGridLine
                    color: __horizontalSeparatorColor
                    width: parent.width
                    height: __gridLineWidth
                    visible: gridVisible
                    anchors.top: dayOfWeekHeaderRow.bottom
                }

                Row {
                    id: gridRow
                    width: weekNumbersItem.width + viewContainer.width
                    height: viewContainer.height
                    anchors.top: topGridLine.bottom

                    Column {
                        id: weekNumbersItem
                        visible: control.weekNumbersVisible
                        height: viewContainer.height
                        spacing: gridVisible ? __gridLineWidth : 0
                        Repeater {
                            id: weekNumberRepeater
                            model: panelItem.weeksToShow

                            Loader {
                                id: weekNumberDelegateLoader
                                height: __cellRectAt(index * panelItem.columns).height
                                sourceComponent: weekNumberDelegate

                                readonly property int __index: index
                                property int __weekNumber: control.__model.weekNumberAt(index)

                                Connections {
                                    target: control
                                    onVisibleMonthChanged: __weekNumber = control.__model.weekNumberAt(index)
                                    onVisibleYearChanged: __weekNumber = control.__model.weekNumberAt(index)
                                }

                                Connections {
                                    target: control.__model
                                    onCountChanged: __weekNumber = control.__model.weekNumberAt(index)
                                }

                                property QtObject styleData: QtObject {
                                    readonly property alias index: weekNumberDelegateLoader.__index
                                    readonly property int weekNumber: weekNumberDelegateLoader.__weekNumber
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: separator
                        anchors.topMargin: - dayOfWeekHeaderRow.height - 1
                        anchors.top: weekNumbersItem.top
                        anchors.bottom: weekNumbersItem.bottom

                        width: __gridLineWidth
                        color: __verticalSeparatorColor
                        visible: control.weekNumbersVisible
                    }

                    // Contains the grid lines and the grid itself.
                    Item {
                        id: viewContainer
                        width: container.width - (control.weekNumbersVisible ? weekNumbersItem.width + separator.width : 0)
                        height: container.height - navigationBarLoader.height - dayOfWeekHeaderRow.height - topGridLine.height

                        Repeater {
                            id: verticalGridLineRepeater
                            model: panelItem.columns - 1
                            delegate: Rectangle {
                                x: __cellRectAt(index + 1).x - __gridLineWidth
                                y: 0
                                width: __gridLineWidth
                                height: viewContainer.height
                                color: gridColor
                                visible: gridVisible
                            }
                        }

                        Repeater {
                            id: horizontalGridLineRepeater
                            model: panelItem.rows - 1
                            delegate: Rectangle {
                                x: 0
                                y: __cellRectAt((index + 1) * panelItem.columns).y - __gridLineWidth
                                width: viewContainer.width
                                height: __gridLineWidth
                                color: gridColor
                                visible: gridVisible
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            hoverEnabled: Settings.hoverEnabled

                            function cellIndexAt(mouseX, mouseY) {
                                var viewContainerPos = viewContainer.mapFromItem(mouseArea, mouseX, mouseY);
                                var child = viewContainer.childAt(viewContainerPos.x, viewContainerPos.y);
                                // In the tests, the mouseArea sometimes gets picked instead of the cells,
                                // probably because stuff is still loading. To be safe, we check for that here.
                                return child && child !== mouseArea ? child.__index : -1;
                            }

                            onEntered: {
                                hoveredCellIndex = cellIndexAt(mouseX, mouseY);
                                if (hoveredCellIndex === undefined) {
                                    hoveredCellIndex = cellIndexAt(mouseX, mouseY);
                                }

                                var date = view.model.dateAt(hoveredCellIndex);
                                if (__isValidDate(date)) {
                                    control.hovered(date);
                                }
                            }

                            onExited: {
                                hoveredCellIndex = -1;
                            }

                            onPositionChanged: {
                                var indexOfCell = cellIndexAt(mouse.x, mouse.y);
                                var previousHoveredCellIndex = hoveredCellIndex;
                                hoveredCellIndex = indexOfCell;
                                if (indexOfCell !== -1) {
                                    var date = view.model.dateAt(indexOfCell);
                                    if (__isValidDate(date)) {
                                        if (hoveredCellIndex !== previousHoveredCellIndex)
                                            control.hovered(date);

                                        // The date must be different for the pressed signal to be emitted.
                                        if (pressed && date.getTime() !== control.selectedDate.getTime()) {
                                            control.pressed(date);

                                            // You can't select dates in a different month while dragging.
                                            if (date.getMonth() === control.selectedDate.getMonth()) {
                                                control.selectedDate = date;
                                                pressedCellIndex = indexOfCell;
                                            }
                                        }
                                    }
                                }
                            }

                            onPressed: {
                                pressCellIndex = cellIndexAt(mouse.x, mouse.y);
                                pressDate = null;
                                if (pressCellIndex !== -1) {
                                    var date = view.model.dateAt(pressCellIndex);
                                    pressedCellIndex = pressCellIndex;
                                    pressDate = date;
                                    if (__isValidDate(date)) {
                                        control.selectedDate = date;
                                        control.pressed(date);
                                    }
                                }
                            }

                            onReleased: {
                                var indexOfCell = cellIndexAt(mouse.x, mouse.y);
                                if (indexOfCell !== -1) {
                                    // The cell index might be valid, but the date has to be too. We could let the
                                    // selected date validation take care of this, but then the selected date would
                                    // change to the earliest day if a day before the minimum date is clicked, for example.
                                    var date = view.model.dateAt(indexOfCell);
                                    if (__isValidDate(date)) {
                                        control.released(date);
                                    }
                                }
                                pressedCellIndex = -1;
                            }

                            onClicked: {
                                var indexOfCell = cellIndexAt(mouse.x, mouse.y);
                                if (indexOfCell !== -1 && indexOfCell === pressCellIndex) {
                                    if (__isValidDate(pressDate))
                                        control.clicked(pressDate);
                                }
                            }

                            onDoubleClicked: {
                                var indexOfCell = cellIndexAt(mouse.x, mouse.y);
                                if (indexOfCell !== -1) {
                                    var date = view.model.dateAt(indexOfCell);
                                    if (__isValidDate(date))
                                        control.doubleClicked(date);
                                }
                            }

                            onPressAndHold: {
                                var indexOfCell = cellIndexAt(mouse.x, mouse.y);
                                if (indexOfCell !== -1 && indexOfCell === pressCellIndex) {
                                    var date = view.model.dateAt(indexOfCell);
                                    if (__isValidDate(date))
                                        control.pressAndHold(date);
                                }
                            }
                        }

                        Connections {
                            target: control
                            onSelectedDateChanged: view.selectedDateChanged()
                        }

                        Repeater {
                            id: view

                            property int currentIndex: -1

                            model: control.__model

                            Component.onCompleted: selectedDateChanged()

                            function selectedDateChanged() {
                                if (model !== undefined && model.locale !== undefined) {
                                    currentIndex = model.indexAt(control.selectedDate);
                                }
                            }

                            delegate: Loader {
                                id: delegateLoader

                                x: __cellRectAt(index).x
                                y: __cellRectAt(index).y
                                width: __cellRectAt(index).width
                                height: __cellRectAt(index).height
                                sourceComponent: dayDelegate

                                readonly property int __index: index
                                readonly property date __date: date
                                // We rely on the fact that an invalid QDate will be converted to a Date
                                // whose year is -4713, which is always an invalid date since our
                                // earliest minimum date is the year 1.
                                readonly property bool valid: __isValidDate(date)

                                property QtObject styleData: QtObject {
                                    readonly property alias index: delegateLoader.__index
                                    readonly property bool selected: control.selectedDate.getFullYear() === date.getFullYear() &&
                                                                     control.selectedDate.getMonth() === date.getMonth() &&
                                                                     control.selectedDate.getDate() === date.getDate()
                                    readonly property alias date: delegateLoader.__date
                                    readonly property bool valid: delegateLoader.valid
                                    // TODO: this will not be correct if the app is running when a new day begins.
                                    readonly property bool today: date.getTime() === new Date().setHours(0, 0, 0, 0)
                                    readonly property bool visibleMonth: date.getMonth() === control.visibleMonth
                                    readonly property bool hovered: panelItem.hoveredCellIndex == index
                                    readonly property bool pressed: panelItem.pressedCellIndex == index
                                    // todo: pressed property here, clicked and doubleClicked in the control itself
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: monthPickerLoader

        anchors.fill: parent

        sourceComponent: monthPickerComponent
        active: false
        visible: monthPickerVisible
    }

    Component {
        id: monthPickerComponent

        Rectangle {
            id: monthPicker

            property var calendarControl

            color: "#20000000"

            onVisibleChanged: {
                if (visible) {
                    monthTumbler.setCurrentIndexAt(0, calendar.visibleMonth);
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    monthPickerVisible = false;
                }

                Tumbler {
                    id: monthTumbler

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }

                    Connections {
                        target: calendar

                        onLocaleChanged: {
                            monthsColumn.updateMonthsModel();
                        }
                    }

                    TumblerColumn {
                        id: monthsColumn

                        width: 100 * AppFramework.displayScaleFactor

                        Component.onCompleted: {
                            updateMonthsModel();
                        }

                        onCurrentIndexChanged: {
                            if (monthPickerVisible) {
                                calendar.visibleMonth = currentIndex;
                            }
                        }

                        function updateMonthsModel() {
                            var months = [];
                            for (var month = 0; month < 12; month++) {
                                months.push(calendar.locale.standaloneMonthName(month));
                            }

                            model = months;
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: yearPickerLoader

        anchors.fill: parent

        sourceComponent: yearPickerComponent
        active: false
        visible: yearPickerVisible
    }

    Component {
        id: yearPickerComponent

        Rectangle {
            id: yearPicker

            property var calendarControl

            color: "#20000000"

            onVisibleChanged: {
                if (visible) {
                    yearTumbler.setCurrentIndexAt(0, calendar.visibleYear - yearStart);
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    yearPickerVisible = false;
                }

                Tumbler {
                    id: yearTumbler

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: barHeight + 1
                    }

                    TumblerColumn {
                        Component.onCompleted: {
                            var years = [];
                            for (var year = yearStart; year < yearEnd; year++) {
                                years.push(year);
                            }

                            model = years;
                        }

                        onCurrentIndexChanged: {
                            if (yearPickerVisible) {
                                calendar.visibleYear = currentIndex + yearStart;
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
