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
import QtQuick.Controls 1.0
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

    function draw_squares(ctx, start_y, start_x, rows) {
        for (var i=0; i<rows.length; i++) {
            var row = rows[i]
            for (var j=0; j<row.length; j++) {
                draw_square(ctx, start_y, start_x, i, j, row[j])
            }
        }
    }

    function draw_square(ctx, start_y, start_x, i, j, square_color) {
        ctx.fillStyle = square_color
        if (square_color == "black") {
            ctx.fillRect(start_x + j*TILE_SIZE, start_y + i*TILE_SIZE, TILE_SIZE, TILE_SIZE)
        } else {
            ctx.fillRect(start_x + j*TILE_SIZE, start_y + i*TILE_SIZE, TILE_SIZE-1, TILE_SIZE-1)
        }
    }

    Game {
        id: tetris_game
    }

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            tetris_game.update()
         }
    }
    Item {
        focus: true
        Keys.onPressed: {
            Julia.key_press(event.key)
            event.accepted = true;
        }
    }
}