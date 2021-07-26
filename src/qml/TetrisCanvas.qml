import QtQuick 2.0
import org.julialang 1.0

Canvas {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    onPaint: {
        var ctx = tetrisCanvas.getContext('2d');
        if (game.gameOver != 0) {
            information.text = "GAME OVER\nPress space"
            return;
        }
        // draw_board
        var rows = game.board
        ctx.fillStyle = "gray"
        ctx.fillRect(0, 0, 12*TILE_SIZE, 21*TILE_SIZE)
        drawSquares(ctx, 0, 0, rows)
    }
}
