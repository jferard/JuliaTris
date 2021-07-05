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
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

ApplicationWindow {
    id: tetris
    title: "JuliaTris"
    width: 400
    height: 500
    visible: true

	ColumnLayout {
        id: root
        spacing: 6
        anchors.fill: parent

        Canvas {
            id: tetris_canvas
            anchors.fill: parent

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
                    ctx.fillRect(start_x + j*20, start_y + i*20, 20, 20)
                } else {
                    ctx.fillRect(start_x + j*20, start_y + i*20, 19, 19)
                }
            }

            onPaint: {
                var ctx = tetris_canvas.getContext('2d');
                var [lines_count, score, game_over, game_started] = Julia.get_game_state()
                if (game_over != 0) {
                    ctx.fillStyle = "white"
                    ctx.font="normal 30px monospace";
                    ctx.fillText("GAME OVER", 30, 200)
                    ctx.font="normal 20px monospace";
                    ctx.fillText("Press space", 40, 240)
                    ctx.stroke()
                    return;
                }
                if (game_started != 0) {
                    Julia.update_game()
                }
                ctx.fillStyle = "gray"
                ctx.fillRect(0, 0, 240, 420)
                ctx.fillRect(280, 100, 80, 40)
                ctx.stroke()

                // draw_board
                var rows = Julia.get_board()
                draw_squares(ctx, 0, 0, rows)

                // add lines
                ctx.font="normal 25px monospace";
                ctx.fillStyle = "black"
                ctx.fillText("Lines", 280, 30)
                ctx.clearRect(280, 30, 100, 30)
                ctx.fillText(lines_count, 280, 55)

                // add next
                ctx.font="normal 20px monospace";
                ctx.fillText("Next", 300, 85)
                var rows = Julia.get_next_tetromino()
                draw_squares(ctx, 100, 280, rows)

                // add level
                ctx.fillStyle = "black"
                ctx.fillText("Level", 280, 220)
                ctx.clearRect(280, 220, 100, 20)
                ctx.fillText(lines_count < 200 ? Math.floor(lines_count / 10)+1 : 20, 280, 240)
                // add score
                ctx.fillText("Score", 280, 280)
                ctx.clearRect(280, 280, 100, 20)
                ctx.fillText(score, 280, 300)
                ctx.stroke()
                // add help
                ctx.font="normal 14px monospace";
                ctx.fillText("← → to move", 270, 340)
                ctx.fillText("B N to rotate", 270, 355)
                ctx.fillText("↓ to drop", 270, 370)
                ctx.stroke()

                if (game_started == 0) {
                     ctx.fillStyle = "white"
                     ctx.font="normal 20px monospace";
                     ctx.fillText("Press space", 40, 240)
                     ctx.stroke()
                }
           }
        }

        Timer {
            interval: 16
            running: true
            repeat: true
            onTriggered: {
                tetris_canvas.requestPaint();
           }
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