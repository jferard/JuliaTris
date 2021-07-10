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

	RowLayout {
        id: rows
        spacing: 2*TILE_SIZE
        anchors.fill: parent

        Canvas {
            width: 12*TILE_SIZE; height: 21*TILE_SIZE
            id: tetris_canvas

            onPaint: {
                var ctx = tetris_canvas.getContext('2d');
                if (game.game_over != 0) {
                    ctx.fillStyle = "white"
                    ctx.font="normal 30px monospace";
                    ctx.fillText("GAME OVER", 1.5*TILE_SIZE, 8*TILE_SIZE)
                    ctx.font="normal 20px monospace";
                    ctx.fillText("Press space", 2*TILE_SIZE, 10*TILE_SIZE)
                    ctx.stroke()
                    return;
                }
                if (game.game_started != 0) {
                    Julia.update_game()
                }

                // draw_board
                var rows = game.board
                ctx.fillStyle = "gray"
                ctx.fillRect(0, 0, 12*TILE_SIZE, 21*TILE_SIZE)
                draw_squares(ctx, 0, 0, rows)

                if (game.game_started == 0) {
                     ctx.fillStyle = "white"
                     ctx.font="normal 20px monospace";
                     ctx.fillText("Press space", 2*TILE_SIZE, 10*TILE_SIZE)
                     ctx.stroke()
                }
            }
        }

        ColumnLayout {
            id: col_infos
            Layout.alignment : Qt.AlignRight

            Text {
                id: lines
                width: 8*TILE_SIZE; height: 2*TILE_SIZE
                horizontalAlignment: Text.AlignRight

                font.pointSize: 24
                text: "Lines\n" + game.lines
            }

            Text {
                id: next
                width: 8*TILE_SIZE; height: 1*TILE_SIZE
                horizontalAlignment: Text.AlignRight
                font.pointSize: 20
                text: "Next"
            }

            Canvas {
                width: 8*TILE_SIZE; height: 2*TILE_SIZE
                id: infos_canvas

                onPaint: {
                    var ctx = infos_canvas.getContext('2d');
                    ctx.fillRect(0, 0, 4*TILE_SIZE, 2*TILE_SIZE)
                    var rows = game.next
                    draw_squares(ctx, 0, 0, rows)
                }
            }

            Text {
                function get_level(lines) {
                    return (lines < 200 ? Math.floor(lines / 10)+1 : 20).toString()
                }

                id: level
                width: 8*TILE_SIZE; height: 2*TILE_SIZE
                font.pointSize: 20
                horizontalAlignment: Text.AlignRight
                text: "Level\n"+get_level(game.lines)
            }

            Text {
                id: score
                width: 8*TILE_SIZE; height: 1*TILE_SIZE
                font.pointSize: 20
                horizontalAlignment: Text.AlignRight
                text: "Score\n" + game.score
            }

            Text {
                id: help
                width: 8*TILE_SIZE; height: 3*TILE_SIZE
                font.pointSize: 10
                text: "← → to move\nB N to rotate\n↓ to drop"
            }
        }

	}
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            score.update();
            tetris_canvas.requestPaint();
            infos_canvas.requestPaint();
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