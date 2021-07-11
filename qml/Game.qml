import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

RowLayout {
    signal update()

    onUpdate: {
        tetris_canvas.requestPaint();
        next_box.update();
    }

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

        Lines {}

        Next {
            id: next_box
        }

        Score {}

        Best {}

        Help {}
    }

}
