import QtQuick 2.0
import org.julialang 1.0

Canvas {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    onPaint: {
        var ctx = tetrisCanvas.getContext('2d');
        if (game.gameOver != 0) {
            ctx.fillStyle = "white"
            ctx.font="normal 30px monospace";
            ctx.fillText("GAME OVER", 1.5*TILE_SIZE, 8*TILE_SIZE)
            ctx.font="normal 20px monospace";
            ctx.fillText("Press space", 2*TILE_SIZE, 10*TILE_SIZE)
            ctx.stroke()
            return;
        }
        // draw_board
        var rows = game.board
        ctx.fillStyle = "gray"
        ctx.fillRect(0, 0, 12*TILE_SIZE, 21*TILE_SIZE)
        drawSquares(ctx, 0, 0, rows)

        if (game.gameStarted == 0) {
             ctx.fillStyle = "white"
             ctx.font="normal 20px monospace";
             ctx.fillText("Press space", 2*TILE_SIZE, 10*TILE_SIZE)
             ctx.stroke()
        }
    }
}
