/***************************************************************************
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.simplemenu 0.1 as SimpleMenu

FocusScope {
    id: root

    focus: true

    property int iconSize: units.iconSizes.huge
    property int cellSize: iconSize + theme.mSize(theme.defaultFont).height
        + (2 * units.smallSpacing)
        + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                        highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property bool searching: (searchField.text != "")

    Layout.minimumWidth: cellSize * 4
    Layout.maximumWidth: cellSize * 4
    Layout.minimumHeight: (cellSize * 4) + searchField.height + paginationBar.height + (2 * units.smallSpacing)
    Layout.maximumHeight: (cellSize * 4) + searchField.height + paginationBar.height + (2 * units.smallSpacing)

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
            pageList.model = rootModel.modelForRow(0);
            paginationBar.model = rootModel.modelForRow(0);
        }

        searchField.text = "";

        pageListScrollArea.focus = true;
        pageList.currentItem.itemGrid.currentIndex = -1;
    }


    PlasmaComponents.TextField {
        id: searchField

        anchors.top: parent.top

        width: parent.width

        placeholderText: i18n("Search...")
        clearButtonShown: true

        onTextChanged: {
            runnerModel.query = text;
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Down) {
                pageList.currentItem.itemGrid.focus = true;
                pageList.currentItem.itemGrid.currentIndex = 0;
            }
        }

        function backspace() {
            focus = true;
            text = text.slice(0, -1);
        }

        function appendText(newText) {
            focus = true;
            text = text + newText;
        }
    }

    PlasmaExtras.ScrollArea {
        id: pageListScrollArea

        anchors {
            fill: parent
            topMargin: searchField.height + units.smallSpacing
            bottomMargin: paginationBar.height + units.smallSpacing
        }

        focus: true

        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

        ListView {
            id: pageList

            anchors.fill: parent

            orientation: Qt.Horizontal
            snapMode: ListView.SnapOneItem

            model: rootModel.modelForRow(0)

            currentIndex: 0

            onCurrentIndexChanged: {
                positionViewAtIndex(currentIndex, ListView.Contain);
            }

            onCurrentItemChanged: {
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

            delegate: Item {
                width: cellSize * 4
                height: cellSize * 4

                property Item itemGrid: gridView

                ItemGridView {
                    id: gridView

                    anchors.fill: parent

                    cellWidth: cellSize
                    cellHeight: cellSize

                    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                    verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                    model: searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)

                    onCurrentIndexChanged: {
                        if (currentIndex != -1) {
                            pageListScrollArea.focus = true;
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

                        var currentGrid = pageList.currentItem.itemGrid;
                        currentGrid.tryActivate(cRow, 0);
                    }

                    onKeyNavLeft: {
                        var newIndex = pageList.currentIndex - 1;
                        var cRow = currentRow();

                        if (newIndex < 0) {
                            newIndex = (pageList.count - 1);
                        }

                        pageList.currentIndex = newIndex;

                        var currentGrid = pageList.currentItem.itemGrid;
                        currentGrid.tryActivate(cRow, 3);
                    }
                }

                SimpleMenu.WheelInterceptor {
                    anchors.fill: parent
                    z: 1

                    onWheelMoved: {
                        if (delta.x > 0 || delta.y > 0) {
                            var newIndex = pageList.currentIndex - 1;

                            if (newIndex < 0) {
                                newIndex = (pageList.count - 1);
                            }

                            pageList.currentIndex = newIndex;
                        } else {
                            var newIndex = pageList.currentIndex + 1;

                            if (newIndex == pageList.count) {
                                newIndex = 0;
                            }

                            pageList.currentIndex = newIndex;
                        }
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

                onWheel: {
                    if (wheel.angleDelta.x > 0 || wheel.angleDelta.y > 0) {
                        var newIndex = pageList.currentIndex - 1;

                        if (newIndex < 0) {
                            newIndex = (pageList.count - 1);
                        }

                        pageList.currentIndex = newIndex;
                    } else {
                        var newIndex = pageList.currentIndex + 1;

                        if (newIndex == pageList.count) {
                            newIndex = 0;
                        }

                        pageList.currentIndex = newIndex;
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Escape) {
            plasmoid.expanded = false;
            return;
        }

        if (searchField.focus) {
            return;
        }

        if (event.key == Qt.Key_Backspace) {
            event.accepted = true;
            searchField.backspace();
        } else if (event.text != "") {
            event.accepted = true;
            searchField.appendText(event.text);
        }
    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
        windowSystem.hidden.connect(reset);
    }
}
