/*
 JuliaTris - A Tetris clone in Julia/Qt
  Copyright (C) 2021 J. Férard <https://github.com/jferard>

 This file is part of JuliaTris.

 JuliaTris is free software: you can redistribute it and/or modify it under the
 terms of the GNU General Public License as published by the Free Software
 Foundation, either version 3 of the License, or (at your option) any later
 version.

 JuliaTris is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 for more details.

 You should have received a copy of the GNU General Public License along with
 this program. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.0
import org.julialang 1.0

ApplicationWindow {
    id: tetris
    title: "JuliaTris"
    width: 20*TILE_SIZE
    height: 21*TILE_SIZE
    visible: true

    Component.onCompleted: {
        tetris.x = tetris.screen.virtualX + tetris.screen.width / 2 - tetris.width / 2;
        tetris.y = tetris.screen.virtualY + tetris.screen.height / 2 - tetris.height / 2;
    }

    function drawSquares(ctx, startY, startX, rows, previousRows) {
        if (previousRows == null) {
            for (var i=0; i<rows.length; i++) {
                var row = rows[i]
                for (var j=0; j<row.length; j++) {
                    drawSquare(ctx, startY, startX, i, j, row[j])
                }
            }
        } else {
            for (var i=0; i<rows.length; i++) {
                var row = rows[i]
                var previousRow = previousRows[i]
                for (var j=0; j<row.length; j++) {
                    if (row[j] == previousRow[j] && row[j] != "rainbow") {
                        // do not redraw
                    } else {
                        drawSquare(ctx, startY, startX, i, j, row[j])
                    }
                }
            }
        }
    }

    function drawSquare(ctx, startY, startX, i, j, squareColor) {
        if (squareColor == "black") {
            ctx.fillStyle = squareColor
            ctx.fillRect(startX + j*TILE_SIZE, startY + i*TILE_SIZE, TILE_SIZE, TILE_SIZE)
        } else {
            var color;
            if (squareColor == "rainbow") {
                var s = Math.floor(Date.now() / 100) % 7
                color = ["red", "orange", "yellow", "green", "blue", "indigo", "violet"][s]
            } else {
                color = squareColor
            }
            ctx.fillStyle = "dimgray"
            ctx.fillRect(startX + j*TILE_SIZE, startY + i*TILE_SIZE, TILE_SIZE, TILE_SIZE)
            ctx.fillStyle = color
            ctx.fillRect(startX + j*TILE_SIZE, startY + i*TILE_SIZE, TILE_SIZE-1, TILE_SIZE-1)
        }
    }

    function copyRows(rows) {
        var otherRows = []
        for (var i=0; i<rows.length; i++) {
            var row = rows[i]
            var otherRow = []
            for (var j=0; j<row.length; j++) {
                otherRow.push(row[j])
            }
            otherRows.push(otherRow)
        }
        return otherRows
    }

    StackView {
        id: stack
        focus: true
        initialItem: menu
        Keys.onPressed: {
            Julia.key_press(event.key)
            event.accepted = true;
        }

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 200
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to:0
                duration: 200
            }
        }
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 200
            }
        }
        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to:0
                duration: 200
            }
        }
    }

    TetrisMenu {
        id: menu
        visible: false
    }

    Game {
        id: tetrisGame
        visible: false
    }
}