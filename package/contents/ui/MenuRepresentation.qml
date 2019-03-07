/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.huge
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
        + (2 * units.smallSpacing)
        + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                        highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")

    onVisibleChanged: {
        if (!visible) {
            reset();
        } else {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
        }
    }

    onHeightChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onWidthChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onSearchingChanged: {
        if (searching) {
            pageList.model = runnerModel;
            paginationBar.model = runnerModel;
        } else {
            reset();
        }
    }

    function reset() {
        if (!searching) {
            if (filterListScrollArea.visible) {
                filterList.currentIndex = 0;
            } else {
                pageList.model = rootModel.modelForRow(0);
                paginationBar.model = rootModel.modelForRow(0);
            }
        }

        searchField.text = "";

        pageListScrollArea.focus = true;
        pageList.currentIndex = 0;
        pageList.currentItem.itemGrid.currentIndex = -1;
    }

    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;
        //QtBug - QTBUG-64115
        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);

        var offset = units.gridUnit;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;

        if (plasmoid.location == PlasmaCore.Types.BottomEdge) {
            var horizMidPoint = screen.x + (screen.width / 2);
            var appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location == PlasmaCore.Types.TopEdge) {
            var horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = parent.height + panelSvg.margins.bottom + offset;
        } else if (plasmoid.location == PlasmaCore.Types.LeftEdge) {
            var vertMidPoint = screen.y + (screen.height / 2);
            var appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (plasmoid.location == PlasmaCore.Types.RightEdge) {
            var vertMidPoint = screen.y + (screen.height / 2);
            var appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }

        return Qt.point(x, y);
    }


    FocusScope {
        Layout.minimumWidth: (cellSize * 6) + Math.max(systemFavoritesGrid.width, filterListScrollArea.width) + units.smallSpacing
        Layout.maximumWidth: (cellSize * 6) + Math.max(systemFavoritesGrid.width, filterListScrollArea.width) + units.smallSpacing
        Layout.minimumHeight: (cellSize * 4) + searchField.height + paginationBar.height + (2 * units.smallSpacing)
        Layout.maximumHeight: (cellSize * 4) + searchField.height + paginationBar.height + (2 * units.smallSpacing)

        focus: true

    PlasmaExtras.Heading {
        id: dummyHeading

        visible: false

        width: 0

        level: 5
    }

    TextMetrics {
        id: headingMetrics

        font: dummyHeading.font
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: visualParent.actionTriggered(actionId, actionArgument)

        onClosed: {
            if (pageList.currentItem) {
                pageList.currentItem.itemGrid.currentIndex = -1;
            }
        }
    }

    PlasmaComponents3.TextField {
        id: searchField

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: systemFavoritesGrid.left
        anchors.rightMargin: units.smallSpacing

        width: parent.width

        placeholderText: i18n("Search...")

        onTextChanged: {
            runnerModel.query = text;
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Down) {
                event.accepted = true;
                pageList.currentItem.itemGrid.tryActivate(0, 0);
            } else if (event.key == Qt.Key_Right) {
                if (cursorPosition == length) {
                    event.accepted = true;

                    if (pageList.currentItem.itemGrid.currentIndex == -1) {
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    } else {
                        pageList.currentItem.itemGrid.tryActivate(0, 1);
                    }
                }
            } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                if (text != "" && pageList.currentItem.itemGrid.count > 0) {
                    event.accepted = true;
                    pageList.currentItem.itemGrid.tryActivate(0, 0);
                    pageList.currentItem.itemGrid.model.trigger(0, "", null);
                    root.visible = false;
                }
            } else if (event.key == Qt.Key_Tab) {
                event.accepted = true;
                systemFavoritesGrid.tryActivate(0, 0);
            } else if (event.key == Qt.Key_Backtab) {
                event.accepted = true;

                if (!searching) {
                    filterList.forceActiveFocus();
                } else {
                    systemFavoritesGrid.tryActivate(0, 0);
                }
            }
        }

        function backspace() {
            if (!root.visible) {
                return;
            }

            focus = true;
            text = text.slice(0, -1);
        }

        function appendText(newText) {
            if (!root.visible) {
                return;
            }

            focus = true;
            text = text + newText;
        }
    }

    ItemGridView {
        id: systemFavoritesGrid

        anchors {
            top: parent.top
            right: parent.right
        }

        width: cellWidth * 4
        height: searchField.height

        cellWidth: height
        cellHeight: height

        iconSize: height - units.smallSpacing

        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        dragEnabled: true
        showLabels: false

        model: systemFavorites

        onCurrentIndexChanged: {
            focus = true;
        }

        onKeyNavLeft: {
            currentIndex = -1;
            searchField.focus = true;
        }

        onKeyNavDown: {
            pageListScrollArea.focus = true;

            if (pageList.currentItem) {
                pageList.currentItem.itemGrid.tryActivate(0, 0);
            }
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Tab) {
                event.accepted = true;

                currentIndex = -1;

                if (!searching) {
                    filterList.forceActiveFocus();
                } else {
                    searchField.focus = true;
                }
            } else if (event.key == Qt.Key_Backtab) {
                event.accepted = true;
                currentIndex = -1;
                searchField.focus = true;
            }
        }
    }

    PlasmaExtras.ScrollArea {
        id: pageListScrollArea

        anchors {
            left: parent.left
            top: searchField.bottom
            topMargin: units.smallSpacing
            bottom: paginationBar.top
            bottomMargin: units.smallSpacing
        }

        width: (cellSize * 6)

        focus: true

        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        ListView {
            id: pageList

            anchors.fill: parent

            orientation: Qt.Horizontal
            snapMode: ListView.SnapOneItem

            currentIndex: 0

            model: rootModel.modelForRow(0)

            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain);
            }

            onCurrentItemChanged: {
                if (!currentItem) {
                    return;
                }

                currentItem.itemGrid.focus = true;
            }

            onModelChanged: {
                currentIndex = 0;
            }

            onFlickingChanged: {
                if (!flicking) {
                    var pos = mapToItem(contentItem, root.width / 2, root.height / 2);
                    var itemIndex = indexAt(pos.x, pos.y);
                    currentIndex = itemIndex;
                }
            }

            function cycle() {
                enabled = false;
                enabled = true;
            }

            function activateNextPrev(next) {
                if (next) {
                    var newIndex = pageList.currentIndex + 1;

                    if (newIndex == pageList.count) {
                        newIndex = 0;
                    }

                    pageList.currentIndex = newIndex;
                } else {
                    var newIndex = pageList.currentIndex - 1;

                    if (newIndex < 0) {
                        newIndex = (pageList.count - 1);
                    }

                    pageList.currentIndex = newIndex;
                }
            }

            delegate: Item {
                width: cellSize * 6
                height: cellSize * 4

                property Item itemGrid: gridView

                ItemGridView {
                    id: gridView

                    anchors.fill: parent

                    cellWidth: cellSize
                    cellHeight: cellSize

                    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                    verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                    dragEnabled: (index == 0)

                    model: searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(filterListScrollArea.visible ? filterList.currentIndex : 0).modelForRow(index)

                    onCurrentIndexChanged: {
                        if (currentIndex != -1 && !searching) {
                            pageListScrollArea.focus = true;
                            focus = true;
                        }
                    }

                    onCountChanged: {
                        if (searching && index == 0) {
                            currentIndex = 0;
                        }
                    }

                    onKeyNavUp: {
                        currentIndex = -1;
                        searchField.focus = true;
                    }

                    onKeyNavRight: {
                        var newIndex = pageList.currentIndex + 1;
                        var cRow = currentRow();

                        if (newIndex == pageList.count) {
                            newIndex = 0;
                        }

                        pageList.currentIndex = newIndex;
                        pageList.currentItem.itemGrid.tryActivate(cRow, 0);
                    }

                    onKeyNavLeft: {
                        var newIndex = pageList.currentIndex - 1;
                        var cRow = currentRow();

                        if (newIndex < 0) {
                            newIndex = (pageList.count - 1);
                        }

                        pageList.currentIndex = newIndex;
                        pageList.currentItem.itemGrid.tryActivate(cRow, 5);
                    }
                }

                Kicker.WheelInterceptor {
                    anchors.fill: parent
                    z: 1

                    property int wheelDelta: 0

                    function scrollByWheel(wheelDelta, eventDelta) {
                        // magic number 120 for common "one click"
                        // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                        wheelDelta += eventDelta;

                        var increment = 0;

                        while (wheelDelta >= 120) {
                            wheelDelta -= 120;
                            increment++;
                        }

                        while (wheelDelta <= -120) {
                            wheelDelta += 120;
                            increment--;
                        }

                        while (increment != 0) {
                            pageList.activateNextPrev(increment < 0);
                            increment += (increment < 0) ? 1 : -1;
                        }

                        return wheelDelta;
                    }

                    onWheelMoved: {
                        wheelDelta = scrollByWheel(wheelDelta, delta.y);
                    }
                }
            }
        }
    }

    ListView {
        id: paginationBar

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        width: model.count * units.iconSizes.small
        height: units.iconSizes.small

        orientation: Qt.Horizontal

        model: rootModel.modelForRow(0)

        delegate: Item {
            width: units.iconSizes.small
            height: width

            Rectangle {
                id: pageDelegate

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                width: parent.width / 2
                height: width

                property bool isCurrent: (pageList.currentIndex == index)

                radius: width / 2

                color: theme.textColor
                opacity: 0.5

                Behavior on width { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
                Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                states: [
                    State {
                        when: pageDelegate.isCurrent
                        PropertyChanges { target: pageDelegate; width: parent.width - (units.smallSpacing * 2) }
                        PropertyChanges { target: pageDelegate; opacity: 0.8 }
                    }
                ]
            }

            MouseArea {
                anchors.fill: parent
                onClicked: pageList.currentIndex = index;

                property int wheelDelta: 0

                function scrollByWheel(wheelDelta, eventDelta) {
                    // magic number 120 for common "one click"
                    // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                    wheelDelta += eventDelta;

                    var increment = 0;

                    while (wheelDelta >= 120) {
                        wheelDelta -= 120;
                        increment++;
                    }

                    while (wheelDelta <= -120) {
                        wheelDelta += 120;
                        increment--;
                    }

                    while (increment != 0) {
                        pageList.activateNextPrev(increment < 0);
                        increment += (increment < 0) ? 1 : -1;
                    }

                    return wheelDelta;
                }

                onWheel: {
                    wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
                }
            }
        }
    }

    PlasmaExtras.ScrollArea {
        id: filterListScrollArea

        anchors {
            left: pageListScrollArea.right
            leftMargin: units.smallSpacing
            top: searchField.bottom
            topMargin: units.smallSpacing
            bottom: paginationBar.top
            bottomMargin: units.smallSpacing
        }

        property int desiredWidth: 0

        width: plasmoid.configuration.showFilterList ? desiredWidth : 0

        enabled: !searching
        visible: plasmoid.configuration.showFilterList

        property alias currentIndex: filterList.currentIndex

        opacity: root.visible ? (searching ? 0.30 : 1.0) : 0.3

        Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

        verticalScrollBarPolicy: (opacity == 1.0) ? Qt.ScrollBarAsNeeded : Qt.ScrollBarAlwaysOff

        onEnabledChanged: {
            if (!enabled) {
                filterList.currentIndex = -1;
            }
        }

        ListView {
            id: filterList

            focus: true

            property bool allApps: false
            property int eligibleWidth: width
            property int hItemMargins: highlightItemSvg.margins.left + highlightItemSvg.margins.right
            model: filterListScrollArea.visible ? rootModel : null

            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            spacing: 0
            keyNavigationWraps: true

            delegate: MouseArea {
                id: item

                property int textWidth: label.contentWidth
                property int mouseCol

                width: parent.width
                height: label.paintedHeight + highlightItemSvg.margins.top + highlightItemSvg.margins.bottom

                Accessible.role: Accessible.MenuItem
                Accessible.name: model.display

                acceptedButtons: Qt.LeftButton

                hoverEnabled: true

                onContainsMouseChanged: {
                    if (!containsMouse) {
                        updateCurrentItemTimer.stop();
                    }
                }

                onPressed: {
                    if (!plasmoid.configuration.switchCategoriesOnHover) {
                        ListView.view.currentIndex = index;
                    }
                }

                onPositionChanged: { // Lazy menu implementation.
                    if (!plasmoid.configuration.switchCategoriesOnHover) {
                        return;
                    }

                    mouseCol = mouse.x;

                    if (index == ListView.view.currentIndex) {
                        updateCurrentItem();
                    } else if ((index == ListView.view.currentIndex - 1) && mouse.y < (item.height - 6)
                        || (index == ListView.view.currentIndex + 1) && mouse.y > 5) {

                        if (mouse.x > ListView.view.eligibleWidth - 5) {
                            updateCurrentItem();
                        }
                    } else if (mouse.x > ListView.view.eligibleWidth) {
                        updateCurrentItem();
                    }

                    updateCurrentItemTimer.start();
                }

                function updateCurrentItem() {
                    ListView.view.currentIndex = index;
                    ListView.view.eligibleWidth = Math.min(width, mouseCol);
                }

                Timer {
                    id: updateCurrentItemTimer

                    interval: 50
                    repeat: false

                    onTriggered: parent.updateCurrentItem()
                }

                PlasmaExtras.Heading {
                    id: label

                    anchors {
                        fill: parent
                        leftMargin: highlightItemSvg.margins.left
                        rightMargin: highlightItemSvg.margins.right
                    }

                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    opacity: 1.0

                    level: 5

                    text: model.display
                }
            }

            highlight: PlasmaComponents.Highlight {
                anchors {
                    top: filterList.currentItem ? filterList.currentItem.top : undefined
                    left: filterList.currentItem ? filterList.currentItem.left : undefined
                    bottom: filterList.currentItem ? filterList.currentItem.bottom : undefined
                }

                opacity: filterListScrollArea.focus ? 1.0 : 0.7

                width: (highlightItemSvg.margins.left
                    + filterList.currentItem.textWidth
                    + highlightItemSvg.margins.right
                    + units.smallSpacing)

                visible: filterList.currentItem
            }

            highlightFollowsCurrentItem: false
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            onCurrentIndexChanged: applyFilter()

            onCountChanged: {
                var width = 0;

                for (var i = 0; i < rootModel.count; ++i) {
                    headingMetrics.text = rootModel.labelForRow(i);

                    if (headingMetrics.width > width) {
                        width = headingMetrics.width;
                    }
                }

                filterListScrollArea.desiredWidth = width + hItemMargins + units.gridUnit;
            }

            function applyFilter() {
                if (filterListScrollArea.visible && !searching && currentIndex >= 0) {
                    pageList.model = rootModel.modelForRow(currentIndex);
                    paginationBar.model = pageList.model;
                }
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_left) {
                    event.accepted = true;

                    var currentRow = Math.max(0, Math.ceil(currentItem.y / cellSize) - 1);

                    if (pageList.currentItem) {
                        pageList.currentItem.itemGrid.tryActivate(currentRow, 5);
                    }
                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    searchField.focus = true;
                } else if (event.key == Qt.Key_Backtab) {
                    event.accepted = true;
                    systemFavoritesGrid.tryActivate(0, 0);
                }
            }
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
            event.accepted = true;

            if (searching) {
                reset();
            } else {
                root.visible = false;
            }

            return;
        }

        if (searchField.focus) {
            return;
        }

        if (event.key == Qt.Key_Backspace) {
            event.accepted = true;
            searchField.backspace();
        } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Backtab) {
            if (pageListScrollArea.focus == true && pageList.currentItem.itemGrid.currentIndex == -1) {
                event.accepted = true;
                pageList.currentItem.itemGrid.tryActivate(0, 0);
            }
        } else if (event.text != "") {
            event.accepted = true;
            searchField.appendText(event.text);
        }
    }

    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
        dragHelper.dropped.connect(pageList.cycle);
    }
}
