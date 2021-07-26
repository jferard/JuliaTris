import QtQuick 2.0
import org.julialang 1.0

Canvas {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    onPaint: {
        // draw_board
        var ctx = tetrisCanvas.getContext('2d');
        var rows = game.board
        ctx.fillStyle = "gray"
        ctx.fillRect(0, 0, 12*TILE_SIZE, 21*TILE_SIZE)
        drawSquares(ctx, 0, 0, rows)
    }
}
