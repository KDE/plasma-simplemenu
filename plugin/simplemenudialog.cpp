/***************************************************************************
 *   Copyright (C) 2014 by David Edmundson <kde@davidedmundson.co.uk>      *
 *   Copyright (C) 2014-2016 by Eike Hein <hein@kde.org>                   *
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

#include "simplemenudialog.h"

#include <cmath>

#include <QScreen>

#include <KWindowSystem>

SimpleMenuDialog::SimpleMenuDialog(QQuickItem *parent) : PlasmaQuick::Dialog(parent)
, m_offset(0)
, m_plasmoidLocation(Plasma::Types::BottomEdge)
{
}

SimpleMenuDialog::~SimpleMenuDialog()
{
}

int SimpleMenuDialog::offset() const
{
    return m_offset;
}

void SimpleMenuDialog::setOffset(int offset)
{
    if (m_offset != offset) {
        m_offset = offset;

        emit offsetChanged();
    }
}

Plasma::Types::Location SimpleMenuDialog::plasmoidLocation() const
{
    return m_plasmoidLocation;
}

void SimpleMenuDialog::setPlasmoidLocation(Plasma::Types::Location location)
{
    if (m_plasmoidLocation != location) {
        m_plasmoidLocation = location;

        emit plasmoidLocationChanged();
    }
}

QPoint SimpleMenuDialog::popupPosition(QQuickItem* item, const QSize& size)
{
    QPointF pos = item->mapToScene(QPointF(0, 0));

    if (item->window()) {
        pos = item->window()->mapToGlobal(pos.toPoint());
    } else {
        return QPoint();
    }

    //if the item is in a dock or in a window that ignores WM we want to position the popups outside of the dock
    const KWindowInfo winInfo = KWindowSystem::windowInfo(item->window()->winId(), NET::WMWindowType);
    const bool outsideParentWindow = (winInfo.windowType(NET::AllTypesMask) == NET::Dock) || (item->window()->flags() & Qt::X11BypassWindowManagerHint);

    QRect parentGeometryBounds;
    if (outsideParentWindow) {
        parentGeometryBounds = item->window()->geometry();
    } else {
        parentGeometryBounds = item->mapRectToScene(item->boundingRect()).toRect();
        if (item->window()) {
            parentGeometryBounds.moveTopLeft(item->window()->mapToGlobal(parentGeometryBounds.topLeft()));
            pos = parentGeometryBounds.topLeft();
        }
    }

    const QPoint topPoint(pos.x() + (item->mapRectToScene(item->boundingRect()).width() - size.width()) / 2,
                          parentGeometryBounds.top() - size.height());
    const QPoint bottomPoint(pos.x() + (item->mapRectToScene(item->boundingRect()).width() - size.width()) / 2,
                             parentGeometryBounds.bottom());

    const QPoint leftPoint(parentGeometryBounds.left() - size.width(),
                           pos.y() + (item->mapRectToScene(item->boundingRect()).height() - size.height()) / 2);

    const QPoint rightPoint(parentGeometryBounds.right(),
                            pos.y() + (item->mapRectToScene(item->boundingRect()).height() - size.height()) / 2);

    QPoint dialogPos;
    if (m_plasmoidLocation == Plasma::Types::TopEdge) {
        dialogPos = bottomPoint;
    } else if (m_plasmoidLocation == Plasma::Types::LeftEdge) {
        dialogPos = rightPoint;
    } else if (m_plasmoidLocation == Plasma::Types::RightEdge) {
        dialogPos = leftPoint;
    } else { // Types::BottomEdge
        dialogPos = topPoint;
    }

    //find the correct screen for the item
    //we do not rely on item->window()->screen() because
    //QWindow::screen() is always only the screen where the window gets first created
    //not actually the current window. See QWindow::screen() documentation
    QRect avail = item->window()->screen()->availableGeometry();

    if (dialogPos.x() < avail.left()) {
        // popup hits lhs
        if (m_plasmoidLocation != Plasma::Types::LeftEdge || m_plasmoidLocation == Plasma::Types::RightEdge) {
            // move it
            dialogPos.setX(avail.left() + m_offset);
        } else {
            // swap edge
            dialogPos.setX(rightPoint.x() + m_offset);
        }
    }
    if (dialogPos.x() + size.width() > avail.right()) {
        // popup hits rhs
        if (m_plasmoidLocation == Plasma::Types::TopEdge || m_plasmoidLocation == Plasma::Types::BottomEdge) {
            dialogPos.setX(qMax(avail.left(), (avail.right() - size.width() + 1)) - m_offset);
        } else {
            dialogPos.setX(leftPoint.x() - m_offset);
        }
    }
    if (dialogPos.y() < avail.top()) {
        // hitting top
        if (m_plasmoidLocation == Plasma::Types::LeftEdge || m_plasmoidLocation == Plasma::Types::RightEdge) {
            dialogPos.setY(avail.top() + m_offset);
        } else {
            dialogPos.setY(bottomPoint.y() + m_offset);
        }
    }

    if (dialogPos.y() + size.height() > avail.bottom()) {
        // hitting bottom
        if (m_plasmoidLocation == Plasma::Types::TopEdge || m_plasmoidLocation == Plasma::Types::BottomEdge) {
            dialogPos.setY(topPoint.y() - m_offset);
        } else {
            dialogPos.setY(qMax(avail.top(), (avail.bottom() - size.height() + 1)) + m_offset);
        }
    }

    return dialogPos;
}
