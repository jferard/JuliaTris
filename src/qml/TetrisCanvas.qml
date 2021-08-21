import QtQuick 2.0
import "."

Canvas {
    width: 12*TILE_SIZE; height: 21*TILE_SIZE

    onPaint: {
        // draw_board
        var ctx = tetrisCanvas.getContext('2d');
        var rows = game.board
        if (rows.length == 0) {
            return;
        }
        drawSquares(ctx, 0, 0, rows, Global.boardRows)
        Global.boardRows = copyRows(rows)
    }
}
